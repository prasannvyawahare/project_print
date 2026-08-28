-- Admin role support for the web admin panel.
--
-- Admins sign in through the same Supabase Auth (no separate system) but get
-- write access to catalog/pricing data via an `is_admin` flag on `profiles`.
-- Regular mobile-app users stay read-only on this data (see policies from
-- 20260829000000_init_schema.sql).

alter table public.profiles
  add column is_admin boolean not null default false;

-- Helper used in RLS policies below. security definer so it can read
-- `profiles` regardless of the caller's own row-level access.
create function public.is_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select coalesce(
    (select is_admin from public.profiles where id = auth.uid()),
    false
  );
$$;

-- print_configs: admins can write, everyone authenticated can still read
-- (read policy already exists from the init migration).
create policy "print_configs: admin write" on public.print_configs
  for insert to authenticated with check (public.is_admin());

create policy "print_configs: admin update" on public.print_configs
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "print_configs: admin delete" on public.print_configs
  for delete to authenticated using (public.is_admin());

create policy "paper_quality_options: admin write" on public.paper_quality_options
  for insert to authenticated with check (public.is_admin());

create policy "paper_quality_options: admin update" on public.paper_quality_options
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "paper_quality_options: admin delete" on public.paper_quality_options
  for delete to authenticated using (public.is_admin());

create policy "paper_size_options: admin write" on public.paper_size_options
  for insert to authenticated with check (public.is_admin());

create policy "paper_size_options: admin update" on public.paper_size_options
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "paper_size_options: admin delete" on public.paper_size_options
  for delete to authenticated using (public.is_admin());

-- Admins also need visibility into orders/order_items for fulfillment
-- (read-only for now — extend if the admin panel needs to change order status).
create policy "orders: admin read all" on public.orders
  for select to authenticated using (public.is_admin());

create policy "order_items: admin read all" on public.order_items
  for select to authenticated using (public.is_admin());

-- No self-service sign-up path grants is_admin — it must be set manually:
--   update public.profiles set is_admin = true where id = '<user-uuid>';
