-- ============================================================
-- 深圳情绪地图 · Supabase 建表 + RLS
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
  emotion_date date,
  captured_at timestamptz default now(),
  created_at timestamptz default now(),
  user_id uuid references auth.users(id) on delete set null
);

create index if not exists emotion_points_user_id_idx
  on public.emotion_points(user_id);

-- 深圳大致范围（沿用旧后端校验）：经度 113.4~115.2，纬度 21.8~23.2。
-- NOT VALID：只约束之后的新增/修改，不扫描既有历史数据。
alter table public.emotion_points
  drop constraint if exists emotion_points_bbox_check;
alter table public.emotion_points
  add constraint emotion_points_bbox_check
  check (lng between 113.4 and 115.2 and lat between 21.8 and 23.2)
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
