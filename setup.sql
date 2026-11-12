-- =====================================================================
-- DOUZI Custom Minifigs — Supabase setup
-- 在 Supabase 后台 → SQL Editor → New query，粘贴全部内容，点 Run。
-- Run this whole file once in Supabase → SQL Editor.
-- =====================================================================

-- ---------- Tables ----------
create table if not exists public.products (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text not null default '',
  price       numeric(10,2) not null default 0,
  category    text not null default 'Minifigs',
  condition   text not null default 'New',
  grade       text not null default '',
  status      text not null default 'active' check (status in ('active','hidden')),
  images      jsonb not null default '[]'::jsonb,
  sort        int  not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.settings (
  id     int primary key default 1 check (id = 1),
  wechat text not null default ''
);

-- Who may use the merchant admin
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- ---------- Helper: is the signed-in user an admin? ----------
create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admins where user_id = auth.uid()); $$;

grant execute on function public.is_admin() to anon, authenticated;

-- keep updated_at fresh
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists products_touch on public.products;
create trigger products_touch before update on public.products
for each row execute function public.touch_updated_at();

-- ---------- Row level security ----------
alter table public.products enable row level security;
alter table public.settings enable row level security;
alter table public.admins   enable row level security;   -- no policies: nobody reads/writes it through the API

drop policy if exists "read products"  on public.products;
drop policy if exists "admin products" on public.products;
create policy "read products"  on public.products for select
  using (status = 'active' or public.is_admin());
create policy "admin products" on public.products for all
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "read settings"  on public.settings;
drop policy if exists "admin settings" on public.settings;
create policy "read settings"  on public.settings for select using (true);
create policy "admin settings" on public.settings for all
  using (public.is_admin()) with check (public.is_admin());

-- ---------- Image storage (public bucket, only admins upload) ----------
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

drop policy if exists "admin upload images" on storage.objects;
drop policy if exists "admin update images" on storage.objects;
drop policy if exists "admin delete images" on storage.objects;
create policy "admin upload images" on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images' and public.is_admin());
create policy "admin update images" on storage.objects for update to authenticated
  using (bucket_id = 'product-images' and public.is_admin());
create policy "admin delete images" on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and public.is_admin());

-- ---------- Starting data ----------
insert into public.settings (id, wechat) values (1, 'DamonZhu3278')
on conflict (id) do nothing;

insert into public.products (title, description, price, category, condition, grade, status, images, sort)
select * from (values
  ('Saint Louis (Wave 1)',
   'Saint Louis minifigure, crafted with precision and care and printed on all six sides. Wave 1 includes two hair pieces, one of them an exclusive hair piece with an ahoge.',
   260, 'Minifigs', 'New', 'A grade', 'active',
   '["img/card.jpg","img/front.jpg","img/side.jpg","img/front2.jpg","img/box.jpg"]'::jsonb, 1),
  ('Saint Louis (B Grade)',
   'B-grade printed minifigure, designed by Douzi. B grade means some details may be slightly distorted or blurred, or have small alignment issues, but overall the flaws are negligible.',
   200, 'Minifigs', 'New', 'B grade', 'active',
   '["img/box.jpg","img/front.jpg"]'::jsonb, 2)
) as v(title, description, price, category, condition, grade, status, images, sort)
where not exists (select 1 from public.products);

-- =====================================================================
-- 最后一步（先在 Authentication → Users 里创建好你自己的账号，再单独运行这一句）：
-- Last step — after creating your own user under Authentication → Users,
-- run this line on its own with your email filled in:
--
-- insert into public.admins (user_id) select id from auth.users where email = '你的邮箱@example.com';
-- =====================================================================
