-- 攻略地图 · 朋友提交需求（在 schema.sql 之后运行，可以重复运行）
-- 朋友不用登录：只能新增「待审核」的需求，不能读、不能改；网站主人登录后审核（通过 → 待处理 / 拒绝 → 已拒绝）

alter table public.requests add column if not exists submitter text not null default '';      -- 称呼，朋友自己填
alter table public.requests add column if not exists source    text not null default 'owner';  -- owner 你自己 / friend 朋友

alter table public.requests drop constraint if exists requests_source_check;
alter table public.requests add constraint requests_source_check check (source in ('owner', 'friend'));

alter table public.requests drop constraint if exists requests_status_check;
alter table public.requests add constraint requests_status_check
  check (status in ('待审核', '待处理', '处理中', '已完成', '已取消', '已拒绝'));

-- 朋友（匿名）只能新增「待审核」，字段长度有上限，不能预填结果
drop policy if exists "friend insert" on public.requests;
create policy "friend insert" on public.requests
  for insert to anon with check (
    status = '待审核' and source = 'friend'
    and char_length(submitter) between 1 and 20
    and char_length(city) between 1 and 30
    and char_length(note) <= 500
    and char_length(coalesce(from_city, '')) <= 20
    and char_length(coalesce(plan, '')) <= 10
    and char_length(coalesce(transport, '')) <= 10
    and char_length(coalesce(province, '')) <= 20
    and char_length(coalesce(prefecture, '')) <= 30
    and coalesce(array_length(prefs, 1), 0) <= 8
    and log = '' and result_url = '' and result_title = ''
    and (guide_url = '' or guide_url like 'https://climb0516.github.io/travel-guide-map/%')
  );
grant insert on public.requests to anon;

-- 防刷：待审核超过 50 条时拒绝新的提交（函数用定义者权限数数，匿名用户本身读不到表）
create or replace function public.limit_pending() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = '待审核' and (select count(*) from public.requests where status = '待审核') >= 50 then
    raise exception '待审核的需求太多了，请过几天再提交';
  end if;
  return new;
end $$;
drop trigger if exists limit_pending on public.requests;
create trigger limit_pending before insert on public.requests
  for each row execute function public.limit_pending();

-- 自检：应该有 4 条规则（friend insert、owner insert、owner select、owner update）
select policyname, roles, cmd from pg_policies where tablename = 'requests' order by policyname;
