-- InfoShare App V1.0
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'viewer' check (role in ('viewer','admin')),
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text not null default '',
  body text not null default '',
  category_id uuid references public.categories(id) on delete set null,
  tags text[] not null default '{}',
  image_urls text[] not null default '{}',
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz
);

create index if not exists articles_status_updated_idx on public.articles(status, updated_at desc);
create index if not exists articles_category_idx on public.articles(category_id);
create index if not exists articles_tags_idx on public.articles using gin(tags);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists articles_set_updated_at on public.articles;
create trigger articles_set_updated_at before update on public.articles
for each row execute function public.set_updated_at();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.articles enable row level security;

drop policy if exists "profile self read" on public.profiles;
create policy "profile self read" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
drop policy if exists "admin manage profiles" on public.profiles;
create policy "admin manage profiles" on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "categories public read" on public.categories;
create policy "categories public read" on public.categories for select to anon, authenticated using (true);
drop policy if exists "categories admin write" on public.categories;
create policy "categories admin write" on public.categories for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "published articles public read" on public.articles;
create policy "published articles public read" on public.articles for select to anon, authenticated
using (status = 'published' or public.is_admin());
drop policy if exists "admin articles write" on public.articles;
create policy "admin articles write" on public.articles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Public image bucket. Upload/delete are restricted to authenticated admins.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('article-images', 'article-images', true, 10485760, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public = true;

drop policy if exists "public view article images" on storage.objects;
create policy "public view article images" on storage.objects for select to anon, authenticated
using (bucket_id = 'article-images');
drop policy if exists "admin upload article images" on storage.objects;
create policy "admin upload article images" on storage.objects for insert to authenticated
with check (bucket_id = 'article-images' and public.is_admin());
drop policy if exists "admin update article images" on storage.objects;
create policy "admin update article images" on storage.objects for update to authenticated
using (bucket_id = 'article-images' and public.is_admin())
with check (bucket_id = 'article-images' and public.is_admin());
drop policy if exists "admin delete article images" on storage.objects;
create policy "admin delete article images" on storage.objects for delete to authenticated
using (bucket_id = 'article-images' and public.is_admin());

-- Starter categories
insert into public.categories(name, slug) values
('综合资料','general'), ('技术资料','technology'), ('图片资料','gallery')
on conflict do nothing;

-- Realtime: Supabase Dashboard -> Database -> Replication, enable articles table.
