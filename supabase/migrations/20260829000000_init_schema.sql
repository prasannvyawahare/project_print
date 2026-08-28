-- PrintHub initial schema for Supabase migration.
--
-- Inferred from the Flutter client's existing API contracts
-- (lib/core/constants/api_constants.dart and the *_model.dart files under
-- lib/features/**/data/models/). No production data exists yet, so this is a
-- fresh schema, not a migration of existing rows.
--
-- ASSUMPTIONS TO VERIFY against the real Node/Express backend source before
-- treating this as final:
--   1. Order pricing formula (base_rate + per-page/copy/paper extras) is not
--      implemented here yet — it belongs in the `order-create` Edge Function,
--      which still needs to be written once the real calc logic is shared.
--   2. print_categories (`print-type/get`) and print_configs (`print-config/get`)
--      looked like overlapping/duplicate catalogs in the Flutter models, so
--      they've been merged into one `print_configs` table here. Split them
--      back out if the real backend treats them as genuinely distinct.
--   3. The old "storage-exists / create-storage" Google Drive folder concept
--      is dropped entirely — Supabase Storage doesn't need a pre-created
--      per-user folder, paths are implicit on first upload.

-- ---------------------------------------------------------------------------
-- profiles (1:1 with auth.users, holds the mobile number Firebase/Supabase
-- auth doesn't carry for Google/Apple sign-in)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  mobile text,
  display_name text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: read own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles: update own" on public.profiles
  for update using (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, mobile, display_name)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'phone',
    new.raw_user_meta_data ->> 'full_name'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- print_configs (catalog data — replaces `print-type/get` + `print-config/get`)
-- ---------------------------------------------------------------------------
create table public.print_configs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  avatar_url text,
  base_rate numeric not null default 0,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.print_configs enable row level security;

create policy "print_configs: readable by authenticated users" on public.print_configs
  for select to authenticated using (true);

create table public.paper_quality_options (
  id uuid primary key default gen_random_uuid(),
  print_config_id uuid not null references public.print_configs (id) on delete cascade,
  name text not null,
  gsm text,
  extra numeric not null default 0,
  sort_order int not null default 0
);

alter table public.paper_quality_options enable row level security;

create policy "paper_quality_options: readable by authenticated users" on public.paper_quality_options
  for select to authenticated using (true);

create table public.paper_size_options (
  id uuid primary key default gen_random_uuid(),
  print_config_id uuid not null references public.print_configs (id) on delete cascade,
  name text not null,
  width numeric,
  height numeric,
  extra numeric not null default 0,
  sort_order int not null default 0
);

alter table public.paper_size_options enable row level security;

create policy "paper_size_options: readable by authenticated users" on public.paper_size_options
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- addresses (per-user, was `address/*`)
-- ---------------------------------------------------------------------------
create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  address_type text not null default '',
  address text not null default '',
  flat text not null default '',
  landmark text not null default '',
  pincode int not null default 0,
  selected boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.addresses enable row level security;

create policy "addresses: crud own" on public.addresses
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- orders / order_items (was `order/*`)
-- ---------------------------------------------------------------------------
create type public.order_status as enum (
  'draft',      -- order/create called, items still uploading
  'placed',     -- order/checkout succeeded
  'cancelled'
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  print_config_id uuid not null references public.print_configs (id),
  address_id uuid references public.addresses (id),
  status public.order_status not null default 'draft',
  payment_method text,
  base_rate numeric not null default 0,
  total_amount numeric not null default 0,
  delivery_charge numeric not null default 0,
  grand_total numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders enable row level security;

create policy "orders: crud own" on public.orders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  file_name text not null,
  file_type text not null default '',
  mime_type text not null default '',
  file_size bigint not null default 0,
  paper_quality_id uuid references public.paper_quality_options (id),
  size_id uuid references public.paper_size_options (id),
  number_of_pages int not null default 1,
  number_of_copy int not null default 1,
  same_page boolean not null default true,
  storage_path text,
  upload_status text not null default 'pending', -- pending | uploaded | failed
  rate numeric,
  total numeric,
  created_at timestamptz not null default now()
);

alter table public.order_items enable row level security;

create policy "order_items: crud own via parent order" on public.order_items
  for all using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Storage: one bucket for print-ready uploads, private, path-scoped per user.
-- Client uploads directly to `print-uploads/{auth.uid()}/{order_id}/{filename}`.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('print-uploads', 'print-uploads', false)
on conflict (id) do nothing;

create policy "print-uploads: user manages own folder" on storage.objects
  for all using (
    bucket_id = 'print-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'print-uploads'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
