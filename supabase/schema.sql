-- ============================================================
-- Emotion Map · Supabase 建表 + RLS
--
-- 坐标隐私策略（重要：不要假设未来只有这一套坐标）：
--   - lng / lat 是「公开模糊坐标」，列类型 numeric(9,3) / numeric(8,3)
--     已在数据库层把经纬度四舍五入到 3 位小数（约百米 / 街区级）。
--     公开地图继续用这两列。
--   - 未来若增加「仅本人可访问的精确位置」（用于“路过旧地点提醒”等个人记忆），
--     请另加独立列（如 precise_lng / precise_lat，或 PostGIS geometry），
--     不要改 lng / lat 的含义，也不要把精确值塞进公开列。
--     精确列需要用列级 RLS / GRANT 只允许 auth.uid() = user_id 本人读取。
-- ============================================================

create table if not exists public.emotion_points (
  id text primary key,
  lng numeric(9, 3) not null,   -- 公开模糊坐标（3 位小数）
  lat numeric(8, 3) not null,   -- 公开模糊坐标（3 位小数）
  name text default '',
  scene text default '不指定',
  emotion text not null,
  emotion2 text default '',
  color text default '',
  color2 text,
  note text default '',
  display_name text default '',
  country text,
  province text,
  city text,
  district text,
  emotion_date date,
  captured_at timestamptz default now(),
  created_at timestamptz default now(),
  user_id uuid references auth.users(id) on delete set null
);

alter table public.emotion_points
  add column if not exists display_name text default '',
  add column if not exists country text,
  add column if not exists province text,
  add column if not exists city text,
  add column if not exists district text;

create index if not exists emotion_points_user_id_idx
  on public.emotion_points(user_id);

-- 公开坐标仅校验合法经纬度范围，不再锁死深圳/中国，方便未来扩展。
-- NOT VALID：只约束之后的新增/修改，不扫描既有历史数据。
alter table public.emotion_points
  drop constraint if exists emotion_points_bbox_check;
alter table public.emotion_points
  add constraint emotion_points_bbox_check
  check (lng between -180 and 180 and lat between -90 and 90)
  not valid;

alter table public.emotion_points enable row level security;

-- 公开读取：所有人（含未登录 anon）都能读全部情绪点（匿名，不暴露身份）。
drop policy if exists emotion_points_select_public on public.emotion_points;
create policy emotion_points_select_public
  on public.emotion_points for select
  using (true);

-- 已登录用户只能新增「user_id = 自己」的记录。
drop policy if exists emotion_points_insert_own on public.emotion_points;
create policy emotion_points_insert_own
  on public.emotion_points for insert to authenticated
  with check (auth.uid() = user_id);

-- 已登录用户只能修改自己的记录。
drop policy if exists emotion_points_update_own on public.emotion_points;
create policy emotion_points_update_own
  on public.emotion_points for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 已登录用户只能删除自己的记录。
drop policy if exists emotion_points_delete_own on public.emotion_points;
create policy emotion_points_delete_own
  on public.emotion_points for delete to authenticated
  using (auth.uid() = user_id);

grant usage on schema public to anon, authenticated;
grant select on public.emotion_points to anon, authenticated;
grant insert, update, delete on public.emotion_points to authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_guest boolean not null default true,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles for select to authenticated
  using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

grant select, insert, update on public.profiles to authenticated;
