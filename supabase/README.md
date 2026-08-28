# Supabase backend for PrintHub

Migration files live in `supabase/migrations/` and are meant to be applied via
the Supabase CLI (`supabase db push`) once it's installed and linked. Until
then, apply them manually.

## Applying `20260829000000_init_schema.sql` manually

1. Open the project's SQL editor: https://supabase.com/dashboard/project/qblifzfywackglkbkhzq/sql/new
2. Paste the full contents of `20260829000000_init_schema.sql`
3. Run it

This creates:
- `profiles` (1:1 with `auth.users`, auto-populated via trigger on signup)
- `print_configs`, `paper_quality_options`, `paper_size_options` — catalog data, readable by any authenticated user
- `addresses`, `orders`, `order_items` — per-user, RLS-scoped to `auth.uid()`
- `print-uploads` storage bucket, path-scoped per user (`{user_id}/...`)

Then apply `20260829000001_admin_role.sql` the same way. It adds `profiles.is_admin`
and write policies so a web admin panel (signed in via the same Supabase Auth)
can manage `print_configs`/paper quality/size catalog data and read all
orders. No sign-up flow grants `is_admin` — promote a user manually once they
exist:

```sql
update public.profiles set is_admin = true where id = '<user-uuid>';
```

## Known open items (need the real backend source to finalize)

- **Order pricing formula** isn't implemented yet. The old `order/create`
  endpoint computed `baseRate`/`totalAmount`/`deliveryCharge`/`grandTotal`
  server-side from `printConfigId` + item options (paper quality/size extras,
  page/copy counts) — this needs to become a Postgres function or Edge
  Function once the real calculation logic is available.
- `print_configs` merges what the Flutter client called `print-type/get` and
  `print-config/get` — they looked like overlapping catalogs from the client
  models alone. Confirm against the real backend whether they're actually
  distinct entities.
- Checkout status transitions (`orders.status`) — only `draft`/`placed`/
  `cancelled` modeled so far; add more if the real backend has intermediate
  states (e.g. printing, out for delivery).

## Once the Supabase CLI/MCP is connected

Instead of applying SQL by hand, link the project and push migrations:

```bash
supabase link --project-ref qblifzfywackglkbkhzq
supabase db push
```
