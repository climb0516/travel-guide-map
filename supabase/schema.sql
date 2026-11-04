-- 攻略地图 · 需求表（requests）
-- 在 Supabase 后台 SQL Editor 里整段粘贴运行。运行前把下面 is_owner() 里的「你的邮箱@example.com」换成你登录网站要用的邮箱。
-- 可以重复运行：表已存在时不重建，规则会先删再建。

create table if not exists public.requests (
  id           text primary key,                       -- 编号，形如 1103-182036（月日-时分秒）
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  type         text not null default '新建' check (type in ('新建', '刷新', '改版')),
  city         text not null,                          -- 目的地（县城、景区也可以）
  adcode       integer,                                -- 所属地级市行政区划代码，对不上时为空
  province     text default '',
  prefecture   text default '',                        -- 所属地级市全称
  from_city    text default '杭州',
  plan         text default '',                        -- 三天两晚 / 两天一晚 / …
  days         integer,
  nights       integer,
  start_date   date,
  transport    text default '',                        -- 自驾 / 高铁 / 飞机
  prefs        text[] not null default '{}',
  note         text not null default '',
  guide_url    text not null default '',               -- 刷新 / 改版时要改的那份
  status       text not null default '待处理' check (status in ('待处理', '处理中', '已完成', '已取消')),
  log          text not null default '',               -- Claude 处理时写的进度和说明
  result_url   text not null default '',               -- 做好的攻略网址
  result_title text not null default ''
);

create index if not exists requests_status_created on public.requests (status, created_at);

-- 只有你（指定邮箱登录后）能读写；不开放删除，取消用改状态
alter table public.requests enable row level security;

create or replace function public.is_owner() returns boolean
language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) = lower('你的邮箱@example.com')
$$;

drop policy if exists "owner select" on public.requests;
drop policy if exists "owner insert" on public.requests;
drop policy if exists "owner update" on public.requests;

create policy "owner select" on public.requests
  for select to authenticated using (public.is_owner());

create policy "owner insert" on public.requests
  for insert to authenticated with check (public.is_owner() and status = '待处理');

create policy "owner update" on public.requests
  for update to authenticated using (public.is_owner()) with check (public.is_owner());

revoke all on public.requests from anon;
grant select, insert, update on public.requests to authenticated;

-- 自检：应该返回 3 条规则
select policyname, cmd from pg_policies where tablename = 'requests' order by policyname;
