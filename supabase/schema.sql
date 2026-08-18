create table if not exists public.emotion_points (
  id text primary key,
  lng numeric(9, 3) not null,
  lat numeric(8, 3) not null,
  name text default '',
  scene text default '不指定',
  emotion text not null,
  emotion2 text default '',
  color text default '',
  color2 text,
  note text default '',
  emotion_date date,
  captured_at timestamptz default now(),
  created_at timestamptz default now()
);

alter table public.emotion_points enable row level security;

-- No public anon policy is created. Netlify Functions use the service role key on the server side.
