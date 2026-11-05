# 🗺 攻略地图 · travel-guide-map

高德足迹式的中国点亮地图：做过旅行攻略的城市整块点亮，点进去直接看攻略；点没亮的城市填需求，生成一句指令，复制到本地 Claude Code 里用 go-travel-guide 生成，做完推送上来它就亮了。

**🌐 在线访问：[https://climb0516.github.io/travel-guide-map/](https://climb0516.github.io/travel-guide-map/)**

---

## 功能

- **点亮地图**：370 个地级行政单元（直辖市、港澳台按整体），有攻略的整块点亮并带光圈；拖动平移、滚轮 / 双指缩放、「全国」复位；缩小只显示省名和点亮城市，放大显示视野内城市名
- **悬停**：城市、所属省份、本省点亮进度（如 浙江 1/11）
- **点城市**
  - 已点亮：攻略标题、天数、出发地、更新日期、简介，「打开攻略」直达；「刷新」「改版」生成对应指令
  - 没点亮：需求表单（出发地默认杭州、三天两晚、最近的周五、自驾、偏好、备注），提交后生成指令，一键复制
- **搜城市**：支持地级市名，县城、景区也能填（生成指令时不带区划代码）
- **我的足迹**：按省份分组，显示本省点亮进度（如 浙江 1 / 11 市）和每份攻略的缩略图
- **我的攻略**：封面卡片墙，封面、天数、简介，顶边用城市主题色
- **全国热门**：携程、同程等平台 2026 春节 / 暑期 / 国庆榜单汇总。「热门榜」按上榜次数排（携程 / 同程优先），带平台标签；「黑马榜」用携程 / 同程的同比增幅。只有转载来源的标「转载」，数据来源可展开查看
- **从杭州出发**：「自驾」「远程」两栏，按耗时排，写推荐理由和当季亮点
- 推荐里点「生成指令」打开表单，天数和偏好按推荐预填；各栏城市不重复，已点亮的和杭州不出现；地图上推荐城市带蓝色虚线圈
- **攻略页**：吸顶导航最左边有「← 攻略地图」返回链接
- **提交需求**：朋友不用登录，在地图上点城市填表（要填称呼）直接提交，进「待审核」；网站主人用邮箱登录（Supabase 邮箱魔法链接）后提交的直接「待处理」。登录后有「我的需求」列表：待审核（通过 / 拒绝）、待处理 / 处理中（可取消）、已完成、已取消 / 已拒绝；地图上待处理的城市闪蓝框。匿名只能提交、看不到任何需求
- 深色 / 浅色跟随系统，手机可用

---

## 技术架构

```
本地 Claude Code：/go-travel-guide（~/.claude/skills/go-travel-guide/）
  ↓ WebSearch：门票 / 开放时间 / 交通 / 城市概况
  ↓ 用户 Chrome（已登录，只读）：小红书、高德扫街榜 + 分区榜 + 店铺详情 + 相册、大众点评
  │    sandbox iframe 批量读 → POST 到本机接收器 recv_server.py（127.0.0.1:8777）→ scratchpad
  ↓ OpenStreetMap：Overpass 底图（fetch_osm.sh）+ Nominatim 坐标（geocode.py）
  ↓ 脚本：maps.py 路线图 / sketch_city.py 全市草图 / build_areas.py 区县商圈榜单 / dl_images.py 实拍图
  ↓ 套模板 example-zhoushan.html → check_theme.py + apply_theme.py 城市主题
  ↓ make_web_page.py 网页版 → <城市拼音>/index.html + img/
  ↓ extract_data.py → data.json（本地，刷新对比基准）；bundle_html.py → <城市><N>日.html（本地单文件）
  ↓ 更新 guides.json（点亮清单）→ git push
       ↓
GitHub Pages（climb0516/travel-guide-map，无 workflow，push 即发布）
  ├─ index.html：内嵌 #china-data 地图数据，fetch guides.json + recommend.json → 点亮 / 推荐
  ├─ <城市拼音>/index.html：各城市攻略页（单页，图片在 img/）
  └─ Supabase（requests 表）：朋友匿名提交「待审核」，主人登录后审核 / 提交「待处理」
       ↑                                   ↓
  requests_db.py（本机私密密钥）读写 ← /go-travel-guide 处理攻略请求
       ↓
pages-dashboard 大屏「攻略地图」卡片：读 guides.json + china-lite.json
```

---

## 数据来源

**网站本身**

| 来源 | 方式 | 条数/范围 | 备注 |
|------|------|-----------|------|
| DataV.GeoAtlas 市级边界 | `build_china.py` 离线生成，内嵌到 index.html 的 `#china-data` | 370 个地级单元（`units`） | Albers 投影；直辖市、港澳台按整体；含南海诸岛插图 |
| `guides.json` | 页面 `fetch`（`cache: 'no-store'`） | 当前 5 条（舟山、嘉兴、潮汕、北京、上海） | 由 /go-travel-guide 交付时写入 |
| `recommend.json` | 页面 `fetch` | 10 份榜单（rank 7 份、growth 3 份）、自驾 9 城、远程 6 城、profiles 41 城，`top_n` = 12 | 节假日后按 skill「更新推荐」手动更新；当前 `updated` = 2026-11-03 |
| Supabase `requests` 表 | supabase-js@2.45.4（CDN）直连 | 主人登录后读最近 200 条 | 页面用公开（publishable）密钥，权限由 RLS 规则限制 |

**攻略内容（/go-travel-guide 抓取）**

| 来源 | 方式 | 条数/范围 | 备注 |
|------|------|-----------|------|
| 高德扫街榜（全城） | 用户 Chrome 打开 `amap.com/ranking/<城市拼音>/food`、`/scenic`，正则解析 `main` 文本 + img 取地点编号 | 美食、景区各前 20（网页版只显示 20） | 榜单页不用登录 |
| 高德分区榜 | `/ranking/<city>/food/<区划代码>`、`/scenic/<区划代码>`，同页 iframe 批量读 | 条数不固定，网页版常只有部分区县 | 编号和店名可能错位，按详情页店名重对 |
| 高德店铺详情 | `amap.com/ssr/place/<地点编号>`，同源 iframe（加 sandbox）读文字 | 行程站点 + 全城榜 + 分区榜 | 需登录；评分、评价数、人均、营业时间、地址、营业状态 |
| 高德相册 | 详情页相册 / 顶部轮播 `img[class*="poiDetailImage"]` | 每站 2–6 张；扫街榜每家 1 张门店照 | 大图加 `?operate=merge&w=1200&h=900&position=5` |
| 小红书 | 用户 Chrome 搜索，读高赞帖正文 + 点赞最高评论 | 每个主要景点、吃饭片区各搜一次，另搜「避雷」 | 只读；页面引用写「@作者《标题》」不放链接 |
| 大众点评 | 同源 `fetch` + `DOMParser` 读列表页（`#shop-all-list li`） | 美食按商圈前 8、全区前 10（`o11` 评价最多）；景点只按区县 | 用户自己登录并过一次验证；每页间隔 4.5–7 秒 |
| OpenStreetMap Overpass | `fetch_osm.sh`：海岸线、主要道路、湖泊河流、景区小路、区县边界（`ADMIN=6`） | 按 bbox | 镜像轮换 + 递增等待重试，User-Agent 如实写用途 |
| OpenStreetMap Nominatim | `geocode.py` | 每个地名最多 3 个候选 | WGS84，每次请求间隔 1.2 秒 |
| WebSearch / WebFetch | Claude 检索 | 门票、开放时间、交通、城市概况（区划 / 面积 / 人口 / GDP / 产业）、平台节假日榜单 | 数字记年份和出处 |
| 维基共享资源 | 浏览器同源 fetch | 只在用户不要求实拍时用 | 不伪装 User-Agent |

---

## 数据处理规则

**推荐（index.html 的 `computeRecs()`）**

- 热门榜：只统计 `kind === 'rank'` 的榜单，每座城统计上榜次数 `n`、上携程 / 同程榜次数 `ct`、携程 / 同程里最好名次 `best`；排序依次比 `n` 降序 → `ct` 降序 → `best` 升序 → 平均名次升序，取 `top_n`（12）
- 黑马榜：只统计 `kind === 'growth'`，每城取最大增幅 `max` 降序；热门榜里已出现的不再出现
- 自驾 / 远程：`from_hz.drive` / `from_hz.remote` 按小时数升序；前面栏目已出现的不再出现
- 统一跳过（`skip()`）：出发地杭州 `HOME = 330100`、已点亮的城市（`litSet()`）、已在别的栏出现的、不在地图单元里的 adcode
- 点亮判定 `guideForUnit()`：`adcode` 或 `also_adcodes` 命中；没填 adcode 时退回按城市名匹配
- 待处理需求高亮 `openReqForUnit()`：状态为「待处理」「处理中」且 adcode 相同的城市闪蓝框

**地图数据（`build_china.py`）**

- 投影：Albers 等积圆锥，标准纬线 25°N、47°N，中央经线 105°E
- 简化：Douglas-Peucker（`dp()`），容差参数默认 0.35；网站内嵌版用 0.5，`china-lite.json` 用 1.8 后去掉 `jd`、`inset` 字段
- 面积过滤：地级单元 `min_area = 0.15`，省界 `min_area = 0.4`（容差 × 1.2）
- 名称简写 `short()`：去掉「省 / 市 / 自治区 / 地区 / 盟」等后缀和民族名，如「延边朝鲜族自治州」→「延边」
- 直辖市和港澳台（110000、120000、310000、500000、710000、810000、820000）按整体一块

**需求（Supabase 规则，见下文「数据结构」）**

- 匿名（anon）只能新增 `status = '待审核'`、`source = 'friend'` 的行，字段有长度上限，不能读、不能改
- 待审核超过 50 条时触发器 `limit_pending()` 拒绝新提交
- 主人（`is_owner()` 按登录邮箱判断）可读、可新增「待处理」、可改；不开放删除，取消用改状态
- 页面上审核只改 `status = '待审核'` 的行（通过 → 待处理，拒绝 → 已拒绝），取消只改「待处理」的行

---

## 数据结构

### Supabase：`requests` 表（`supabase/schema.sql` + `supabase/friends.sql`）

```
requests
├── id            text         主键，形如 1103-182036（月日-时分秒）
├── created_at    timestamptz  默认 now()
├── updated_at    timestamptz  默认 now()
├── type          text         '新建' | '刷新' | '改版'，默认 '新建'
├── city          text         目的地（县城、景区也可以），必填
├── adcode        integer      所属地级市区划代码，对不上时为空
├── province      text
├── prefecture    text         所属地级市全称
├── from_city     text         默认 '杭州'
├── plan          text         三天两晚 / 两天一晚 / …
├── days          integer
├── nights        integer
├── start_date    date
├── transport     text         自驾 / 高铁 / 飞机
├── prefs         text[]       默认 '{}'
├── note          text
├── guide_url     text         刷新 / 改版时要改的那份
├── status        text         '待审核' | '待处理' | '处理中' | '已完成' | '已取消' | '已拒绝'
├── log           text         Claude 处理时写的进度和说明
├── result_url    text         做好的攻略网址
├── result_title  text
├── submitter     text         称呼（friends.sql 新增），朋友提交时 1–20 字
└── source        text         'owner' | 'friend'（friends.sql 新增）

索引：requests_status_created (status, created_at)
RLS 规则：owner select / owner insert / owner update（authenticated）、friend insert（anon）
触发器：limit_pending（待审核 ≥ 50 条拒绝）
```

密钥：网页用公开（publishable）密钥；本机 `requests_db.py` 用 `SUPABASE_URL`、`SUPABASE_SECRET_KEY`（存在 `~/.config/go-travel-guide/supabase.env`，不进仓库）。

### guides.json（数组，一城一条）

```
[
  {
    "city": "潮汕",
    "adcode": 445100,              主城区划代码，必填，地图按它点亮
    "also_adcodes": [440500],      可选，一份攻略跨两个地级市时另一个也点亮
    "pinyin": "chaoshan",
    "title": "潮汕四日",
    "url": "chaoshan/",
    "days": 4,
    "nights": 3,
    "from": "杭州",
    "updated": "2026-11-04",
    "summary": "一句话路线 + 主题",
    "local_dir": "~/Desktop/AI/travel-guide-map/chaoshan",
    "cover": "chaoshan/img/g_gjq1.jpg",    首屏大图之一，卡片封面
    "accent": "#e6b85a"                     城市主题 dark.accent，卡片顶边
  }
]
```

### recommend.json

```
{
  "updated": "2026-11-03",
  "note": "口径说明",
  "top_n": 12,
  "lists": [
    {
      "id": "ctrip-cny", "platform": "携程", "event": "2026 春节",
      "metric": "口径", "kind": "rank | growth", "repost": false,
      "source": {"title": "...", "url": "..."},
      "items": [[adcode, "城市"], ...]                       rank：按名次
               [[adcode, "城市", 增幅数字, "可选文字"], ...]  growth
    }
  ],
  "from_hz": {
    "drive":  [[adcode, "约 1 小时", 1], ...],
    "remote": [[adcode, "飞机约 3.5 小时", 3.5], ...],
    "sources": [{"title": "...", "url": "..."}]
  },
  "profiles": {
    "510100": {"city": "成都", "province": "四川", "plan": "三天两晚",
               "prefs": ["吃", "博物馆"], "reason": "一句话", "season": "当季亮点"}
  }
}
```

prefs 只能从「吃、海边、古城、拜佛、带娃、自然风光、博物馆、夜景」里选；plan 只能是「三天两晚 / 两天一晚 / 四天三晚 / 五天四晚 / 一天」。

### 地图数据（index.html 内嵌的 `#china-data` / china-lite.json）

```
{
  "vb": [0, 0, 1032, 873],          SVG viewBox
  "prov": "M...Z",                  全部省界合成一条 path
  "units": [
    {"a": 110000, "n": "北京市", "s": "北京", "p": "北京", "c": [756.8, 336.7], "d": "M...Z"}
                                    a 区划代码 / n 全称 / s 简称 / p 省简称 / c 中心点 / d 轮廓
  ],
  "jd": "M...",                     九段线（只在内嵌版）
  "inset": [x, y, w, h]             南海诸岛插图取景（只在内嵌版）
}
```

### <城市拼音>/data.json（只在本地，被 .gitignore 挡住）

```
{
  "city": "北京", "fetched_at": "2026-11-05",
  "rank": {"food": [{rank, name, score, tags, amap_id}], "scenic": [...]},   全城扫街榜前 20（跨城攻略每条带 city）
  "poi": {"<地点编号>": {name, rating, reviews, avg, hours, address, status}},
  "itinerary_pois": ["<地点编号>", ...],      行程用到的地点
  "timetables": [{header / name, rows}],      页面里的时刻表
  "xhs_notes": [{id, author, date, title}],   页脚引用的小红书笔记
  "new_notes": [{id, title, date, likes, kind}],  刷新时上次之后的新帖
  "intro": {"fetched_at", "areas": {区县: [{k, gf, gs, df, ds}]}},  build_areas.py 输出（较新的几城直接存 {区县: [...]}）
  "rank_district": {"food/<区划代码>": ...},  高德分区榜原始数据
  "dp": {...},                                 大众点评原始数据（部分城市）
  "note": "抓取说明"
}
```

旧快照另存 `data-<日期>.json`（如 `zhoushan/data-2026-10-29.json`）。

---

## 前端

- **单页**：`index.html` 一个文件，原生 JS（IIFE），无构建；唯一外部脚本是 jsDelivr 上的 `@supabase/supabase-js@2.45.4`
- **地图**：SVG，370 个 `path` 按 adcode 着色；点亮的用 `#litfill` 渐变 + `#glowf` 高斯模糊光圈；滚轮缩放（`wheel` → `zoomAt()`）、拖动平移、双指缩放、「全国」复位；缩小时只显示省名和点亮城市，放大后显示视野内城市名；南海诸岛插图复用 `#provpath` / `#jdpath`
- **城市卡片**（`#card`）：已点亮显示攻略信息 + 「打开攻略」「刷新」「改版」；未点亮显示需求表单（出发地、方案、最近的周五 `nextFriday()`、出行方式、偏好、备注）
- **提交需求**：已登录 → `insert` 一行「待处理」；未登录 → 朋友填称呼提交「待审核」；也能生成 `/go-travel-guide …` 指令，`navigator.clipboard` 一键复制（失败时退回 textarea）
- **登录**：Supabase 邮箱魔法链接（`signInWithOtp`，`flowType: 'implicit'`），会话由 supabase-js 存在浏览器 localStorage
- **我的需求**（`#reqs-sec`）：按状态分页签（待审核 / 待处理·处理中 / 已完成 / 已取消·已拒绝），待审核可通过 / 拒绝，待处理可取消
- **我的足迹 / 我的攻略 / 全国热门 / 从杭州出发**：分别渲染到 `#foot-prov`、`#my`、`#hot`、`#hz`
- **主题**：深色默认，`prefers-color-scheme: light` 切浅色；断点 900px / 820px / 520px
- **kit 组件**：未使用（index.html 里没有 `kit-sheet`、`#/item/`），没有详情抽屉和 hash 路由；城市详情用页面内的 `#card` 面板
- **攻略页**（`<城市拼音>/index.html`）：/go-travel-guide 模板生成的独立单页，结构见 skill 的 `references/page-spec.md`；`make_web_page.py` 加「← 攻略地图」返回链接、「返回顶部」按钮、随滚动伸长的时间轴进度线

---

## 本地运行

```
cd ~/Desktop/AI/travel-guide-map
python3 -m http.server 8000
```

然后访问 http://localhost:8000 。Chrome 不能用 file:// 打开（fetch 会失败）。攻略页中文乱码时，换一个带 `charset=utf-8` 的静态服务器。

重新生成地图数据（需要先下载 DataV.GeoAtlas 的 `100000_full.json` 和各省 `<adcode>_full.json` 到同一目录）：

```
python3 -I ~/.claude/skills/go-travel-guide/scripts/build_china.py <datav 目录> <输出 json> 0.5     # 嵌进 index.html 的 #china-data
python3 -I ~/.claude/skills/go-travel-guide/scripts/build_china.py <datav 目录> china-lite.json 1.8 # 再去掉 jd、inset 字段
```

需求表首次建表：在 Supabase 后台 SQL Editor 依次运行 `supabase/schema.sql`（先把 `is_owner()` 里的邮箱换成自己的）和 `supabase/friends.sql`。

---

## 自动更新机制

本仓库没有 GitHub Actions workflow，没有定时任务，所以也不存在心跳文件和「仓库 60 天无提交 GitHub 停用定时任务」的问题；内容全部由本地 /go-travel-guide 生成后推送。

| 触发方式 | 时机 |
|---------|------|
| push 到 main（GitHub Pages 自动发布） | 推送后约 1–2 分钟生效 |
| /go-travel-guide 新建 / 刷新 / 改版攻略 | 交付时更新 `<城市拼音>/`、`guides.json`，`git commit -m "guide: <城市> <N> 天"` 后 push |
| /go-travel-guide 处理攻略请求 | 手动执行；`requests_db.py` 把需求改成「处理中」→ 上线后「已完成」并回写 `result_url` |
| 更新推荐（`recommend.json`） | 手动；元旦、春节、五一、暑期、国庆平台发榜后由 skill 提醒 |
| pages-dashboard 大屏 | 每 10 分钟重新读 `guides.json`、`china-lite.json` |
| Supabase 免费项目 | 一周没访问会被暂停，网站提交报错时去 Supabase 后台恢复 |

---

## Skill 流程（/go-travel-guide）

Skill 目录：`~/.claude/skills/go-travel-guide/`

```
SKILL.md                    主流程（231 行）
references/
  page-spec.md              攻略页版式规范：区块顺序、版式细节、内容规则
  browser-snippets.md       浏览器脚本：小红书、高德（扫街榜 / 分区榜 / 详情 / 相册 / 限流）、大众点评、刷新
  map-config.md             maps.py / sketch_city.py 的配置写法，大陆海岸、江南水网的处理
  city-themes.md            城市主题怎么定、主题 JSON 字段、现成主题表
scripts/                    15 个脚本（见下表）
templates/
  example-zhoushan.html     样板页（舟山三日，含「认识舟山」和扫街榜地区选择）
  zhoushan-sketch.json      全市草图配置示例
  zhoushan-areas.json       区县 / 商圈榜单配置示例
  themes/                   10 套主题：beijing、chaoshan、chaozhou、chengdu、jiaxing、shanghai、suzhou、xiamen、xian、zhoushan
```

### 流程总览

```
分流：新建 / 刷新（仓库里已有城市文件夹）/ 改版（加减天数、加板块）/ 处理网页请求
  ↓
第零步 问需求：默认杭州出发、三天两晚（最近的周五到周日）、自驾，开场提示用了哪些默认值，只追问目的地
第一步 出方案：页面结构、每天怎么走、商圈初稿、城市主题、数据来源、风险 → 等用户回复「执行」
第二步 查资料：WebSearch / 小红书 / 高德扫街榜 + 详情 / 交叉对照 / 城市概况 / 分区榜 + 点评 → build_areas.py
第三步 排行程：geocode.py 查坐标 → 按时间顺序连线看折返（有就先停下问用户）→ 跨岛 / 跨区按出入口算车程
第四步 配图：高德相册 + 小红书原图 → 缩略图墙挑图 → dl_images.py 下载压缩
第五步 画地图：fetch_osm.sh → sketch_city.py（全市草图）→ maps.py（总览 + 每天一张）→ qlmanage 渲染 PNG 检查遮挡
第六步 生成页面：复制样板 → 替换内容 → check_theme.py + apply_theme.py → node --check → 本地预览
第七步 交付：make_web_page.py → extract_data.py（data.json）→ bundle_html.py（单文件）→ 更新 guides.json → push
```

### 数据来源与抓取方式

- **高德**：扫街榜（2025 状元榜）`amap.com/ranking/<city>/food|scenic`，全城前 20；分区榜 `/<区划代码>`；店铺详情 `amap.com/ssr/place/<编号>`（评分 / 评价数 / 人均 / 营业时间 / 地址 / 营业状态）；相册取门店实拍。坐标是 GCJ-02 取不到，地图坐标统一用 Nominatim（WGS84）
- **小红书**：每个主要景点和吃饭片区各搜一次，专门搜「避雷」；记笔记 ID、作者、日期、关键事实。`/explore/<ID>` 不带 xsec_token 打不开，页面只写「@作者《标题》」
- **大众点评**：城市页 `/<city>/ch10`（美食）、`/ch35`（景点）；`o11` 评价最多；商区 `r<编号>`；县可能是单独城市页（如岱山、嵊泗）
- **OpenStreetMap**：Overpass 底图（海岸线 coast、主要道路 roads、水面 water / water_rel、景区小路 detail_roads、区县边界 admin）；Nominatim 查坐标
- **WebSearch**：门票、开放时间、交通（按出行方式）、当季注意事项、城市概况、节假日平台榜单

### 浏览器只读抓取

- 全部在用户自己的 Chrome 里跑（claude-in-chrome 的 javascript_tool），借已登录账号只读：不点赞、不评论、不收藏、不改设置
- **sandbox iframe 批量读**：详情页数据是前端渲染的，用同源 iframe 打开再读文字；所有 iframe 加 `sandbox="allow-same-origin allow-scripts"`，读完先 `src='about:blank'` 再移除（防止整页跳走 / 卡死）
- **本机接收器**：`recv_server.py` 只监听 127.0.0.1:8777，页面 `fetch('http://127.0.0.1:8777/save?name=xxx.json', {method:'POST'})` 直接写进 scratchpad；每 8–10 家落一次盘；另一个会话占用时改端口（如 8778）。备用方案是 Blob 下载到「下载」再挪走
- **长任务**：javascript_tool 单次 45 秒超时，放进 async IIFE 后台跑；浏览器批量操作约 80 秒超时；后台标签页被限速，开始前切到前台
- **限流 / 验证码即停**：高德弹「哎呀，有异常情况」就停，不扫码绕过；并发最多 2 个 iframe、每家间隔 1.5 秒以上，先读行程站点和全城榜，分区榜放最后；两个会话同时做城市时只让一个会话抓高德。点评每页间隔 4.5–7 秒，`res.url` 或正文出现 `verify.meituan` / `验证中心` 就停。不伪装 User-Agent

### 地图算法

- **`maps.py` 真实经纬度投影**：`Map` 类按 bbox 做等距圆柱投影，经度乘以中纬度余弦（`s.c = cos(中纬度)`），宽度给定、高度按比例算；输出米色纸质 SVG（站点按吃 / 逛 / 行 / 住着色，路段区分开车、巴士、步行、轮渡、索道、返程），带比例尺、指北针、说明框、图例；Douglas-Peucker 简化（`dp()`，默认容差 0.6）
- **`close_coast` 海岸线闭合**：配置里 `"close_coast": true` 时，`close_open()` 先把首尾相接的海岸线段串成一条，再沿底图外框（取道路数据范围）逆时针接成环（OSM 海岸线前进方向左边是陆地），解决大陆海岸在下载范围内不闭合被画成海的问题；maps.py 和 sketch_city.py 都认
- **其他开关**：`min_island_km2`（小岛过滤）、`min_water_km2`（江南水网跳过小水塘，如 2）、`waterways`（总览只画 river）、`road_tolerance`（如 1.5）；大湖 relation 存 `water_rel.json` 拼环、湖心岛画回陆地；内陆城市没有 coast.json 时整张底色画陆地
- **`sketch_city.py` 全市草图**：复用 maps.py 的投影、标签、比例尺；区县多边形着色 + 区县界（`ADMIN=6` 的 relation）、只画落在区县内的 motorway / trunk、商圈编号点、`trip_box` 行程范围框；`pip()` 点在多边形内判断归属

### 商圈归类（`build_areas.py`）

- 输入：data.json 的全城榜 `rank` 和 `poi`、高德分区榜 `gd_lists`、分区榜新地点详情 `gd_poi_extra`、完整地址 `addresses`、点评原始数据 `dp_files`、手动归类 `manual`、区县规则 `districts`
- 高德：全城前 20 + 分区榜合并去重（`add()`，按地点编号），地址里去掉「<城市>市」
- 归类 `place()`：先看 `manual`；否则地址里包含区县名 → 再按该区县 `rules` 的地址关键词归到商圈，没命中就只归区县
- 高德列表 `g_list()`：按综合分降序
- 点评合并 `d_merge()`：多个商区键（可用点号取嵌套，如 `food.沈家门商圈`）合并，按评价数降序、按店铺编号去重；每个商圈取 `n` 条，默认全区 10、商圈 8
- 输出 zs.json（`{区县: [{k, gf, gs, df, ds}]}`，gf/gs 高德美食/景点、df/ds 点评美食/景点），并写回 data.json 的 `intro`；打印没归到区县的地点

### 主题系统

- 主题 JSON：`city`、`name`（三段式，如「海岛 · 佛国 · 渔港」）、`why`、`font_display`、`font_link`（只用 Google Fonts）、`ornament.kind / color`、`dark` / `light` 两套色（bg、panel、panel2、line、fg、fg2、fg3、accent、accentSoft、sea、seaSoft、land、landEdge、water、warn、ok）
- **`check_theme.py`**：WCAG 相对亮度算对比度，fg / fg2 / fg3 / accent / sea / warn 对 bg 和 panel 都要 ≥ 4.5，不达标退出码 1
- **`apply_theme.py`**：替换页面开头三组主题变量（深色默认、浅色媒体查询、`data-theme`），加标题字体和纹样（海浪 / 浪花 / 回纹 / 冰裂纹 / 竹节 / 城垛 / 扇形，定义在 `PATTERNS`）；重复执行会先去掉旧主题
- 不随主题变：版式、吃 / 逛 / 行 / 住颜色（#e8692c / #2f7fc1 / #6b7280 / #7a5cc7）、地图卡片米色纸面 #fbf8f2

### 页面打包

- **`make_web_page.py <城市文件夹>`**（可重复跑）：去掉 Artifact 专用 meta → 补 `<!doctype html>`、`lang="zh-CN"`、UTF-8、viewport 和基础样式 → 吸顶导航插「← 攻略地图」（链到 `../`）→ 「返回顶部」按钮 → 时间轴随滚动变色（当天时间轴顶部过窗口 60% 高度后伸长）→ 打印 `img/g_hero_*.jpg` 供挑 cover
- **`bundle_html.py <页面目录> <输出.html>`**：补全文档头，img/ 下图片全部 base64 内嵌，脚本里 `'img/'+k+'.jpg'` 改成 `IMGSRC(k)`；输入是网页版时先剥掉文档头和返回链接；生成的单文件留本地不上传

### 刷新流程

1. 读 `data.json` 的 `fetched_at`；没有的老攻略先跑 `extract_data.py` 补一份
2. 浏览器重新抓：扫街榜前 20、所有地点详情（识别「暂停营业 / 已关闭 / 停业 / 已闭园 / 歇业 / 搬迁」；「休息中 / 已打烊」不算关店）、时刻表、`fetched_at` 之后的小红书新帖、分区榜
3. **`diff_data.py <旧> <新>`** 分级输出：一、会影响行程（地点暂停营业 / 关闭、行程地点营业时间变了、时刻表任一格变了）；二、榜单变化（新上榜、掉出前 20、名次变化 ≥ 3）；三、店铺信息（评分变化 ≥ 0.1、人均变化 ≥ 10 元、营业时间 / 地址 / 状态变了）；四、新口碑
4. 用户多选要应用的项 → 改页面 → 旧快照存 `data-<旧日期>.json` → 跑 make_web_page.py、bundle_html.py → `guides.json` 的 updated 改成今天 → push

### 需求处理（`requests_db.py`）

- 密钥从 `~/.config/go-travel-guide/supabase.env` 读（变量 `SUPABASE_URL`、`SUPABASE_SECRET_KEY`），走 Supabase REST `/rest/v1/requests`，不打印密钥
- 命令：`check`（连接检查）、`list [状态]`（默认「待处理 + 处理中」，按提交时间从早到晚）、`list 待审核`、`get <编号>`、`set <编号> 字段=值 …`（自动更新 `updated_at`）、`add <json>`
- 状态流转：

```
朋友匿名提交 ──→ 待审核 ──(主人在网站点通过)──→ 待处理
                    └──(拒绝)──→ 已拒绝
主人登录提交 ──→ 待处理 ──(skill 接单 set status=处理中)──→ 处理中 ──(上线后回写 result_url / result_title)──→ 已完成
                    └──(网站上取消 / 用户说取消)──→ 已取消        处理中 ──(先不做)──→ 待处理
```

- skill 只处理「待处理」，不动「待审核」、不替用户审核；朋友提交的在汇总里写「来自 <称呼>」并提醒把链接发给朋友
- 网站没登录时还可以生成 `/go-travel-guide 做攻略 · 嘉兴（浙江 嘉兴市，区划代码 330400） · …` 这类用 ` · ` 分隔的指令，复制到本地执行

### 上线

- 更新 `guides.json`：同城已有就覆盖；字段见上文「数据结构」。`adcode` 必填（县城、景区填所属地级市代码，直辖市用省级代码）；跨两个地级市时主城填 `adcode`、另一个写进 `also_adcodes`（地图两个都点亮，列表只出现一次）；`cover` 从 make_web_page.py 打印的首屏大图里挑；`accent` 取主题 JSON 的 `dark.accent`
- 推荐算法（`recommend.json`，页面自己算）：热门榜按上榜次数（同数时携程 / 同程优先）、黑马榜按携程 / 同程增幅、各栏去重、已点亮的城市和出发地杭州隐藏；更新推荐时优先找携程、同程原文，只在转载里见到的标 `repost: true`，过时一年以上的榜单删掉
- 提交前看 `git status`，只提交 index.html、img/、guides.json 等；`git commit -m "guide: <城市> <N> 天"` 后 push
- **pages-dashboard 联动**：大屏「攻略地图」卡片读 `guides.json` + `china-lite.json` 自动点亮，不用改大屏；地图数据重新生成时 `china-lite.json` 用 `build_china.py … 1.8` 再去掉 `jd`、`inset` 生成。注意：大屏目前只按 `adcode` 点亮，不读 `also_adcodes`（潮汕只亮潮州）

### 脚本清单（15 个）

| 脚本 | 用途 | 输入 → 输出 |
|------|------|-------------|
| `apply_theme.py` | 给攻略页套城市主题（三组变量、标题字体、纹样） | `<index.html> <theme.json>` → 原地改 index.html |
| `build_areas.py` | 合并高德分区榜 + 大众点评，按区县 → 商圈出榜单 | `<config.json>` → zs.json，并写回 data.json 的 `intro` |
| `build_china.py` | DataV 市级边界 → Albers 投影的 SVG 地图数据 | `<datav 目录> <输出 json> [容差]` → `{vb, units, prov, jd, inset}` |
| `bundle_html.py` | 打包成图片内嵌的单文件 HTML | `<页面目录> <输出.html>` → 单文件 |
| `check_theme.py` | 检查主题深浅两套的 WCAG 对比度 ≥ 4.5 | `<theme.json> [...]` → 打印不达标项，退出码 1 |
| `diff_data.py` | 对比新旧 data.json，分四级出变化表 | `<旧 data.json> <新 data.json>` → Markdown 到 stdout |
| `dl_images.py` | 按清单下载图片、裁剪压缩 | `<list.json> <out_dir> [--crop WxH] [--max WxH]`（默认 `--max 1200x900`）→ img/ |
| `extract_data.py` | 从做好的页面提取会过期的数据（用 node 执行页面里的 RANK / POI / INFO / PH / notes） | `<攻略目录> <城市名> <YYYY-MM-DD>` → data.json |
| `fetch_osm.sh` | 从 Overpass 下载底图，镜像轮换重试 | `<南> <西> <北> <东> <out_dir> [detail_bbox]`，环境变量 `ADMIN=6`、`ONLY="..."` → coast / roads / water / water_rel / detail_roads / admin.json |
| `geocode.py` | Nominatim 查坐标（WGS84） | `<out.json> <lon_min,lat_max,lon_max,lat_min> 地名...` → 每个地名最多 3 个候选 |
| `make_web_page.py` | 整理成网站用的网页版（文档头、返回链接、返回顶部、时间轴进度线） | `<城市文件夹>` → 原地改 index.html，打印 cover 候选 |
| `maps.py` | 按真实经纬度画路线图 SVG | `config.json` → `<out_dir>/<id>.svg`（总览 + 每天） |
| `recv_server.py` | 本机接收器，只收 POST JSON 写文件 | `<输出目录>` → 监听 127.0.0.1:8777 |
| `requests_db.py` | 读写 Supabase `requests` 表 | `check / list / get / set / add` → 打印结果 |
| `sketch_city.py` | 全市草图（区县着色、商圈编号、行程范围框） | `<config.json>` → sketch.svg |

说明：本 README 旧版「加一座城市」里提到的 `scripts/sync_site.py` 在 skill 目录里不存在，复制和补返回链接现在由 `make_web_page.py` 完成（攻略直接在仓库城市文件夹里做）。

---

## 目录

```
index.html      点亮地图（地图数据内嵌）
guides.json     已点亮城市清单，地图按 adcode 点亮；cover / accent 给卡片用
recommend.json  推荐数据：各平台榜单（lists）、从杭州出发（from_hz）、城市资料（profiles），节假日后更新
zhoushan/ jiaxing/ chaoshan/ beijing/ shanghai/
                各城市攻略：index.html + img/ 上传；data*.json、单文件 <城市><N>日.html 只留本地（.gitignore）
china-lite.json pages-dashboard 大屏用的精简地图数据
artifact.html 等 旧 claude.ai 版和样式草稿，不进仓库（.gitignore）
supabase/       需求表 requests 的建表 SQL 和访问规则（schema.sql；朋友提交的补充规则 friends.sql）
```

## 加一座城市

go-travel-guide 交付时自动完成：

1. 攻略直接在 `<城市拼音>/` 里做，go-travel-guide 的 `scripts/make_web_page.py` 补文档头、插入返回链接
2. 在 `guides.json` 加一行：city、adcode（地级市行政区划代码）、also_adcodes（可选，跨两个地级市时）、pinyin、title、url（`<城市拼音>/`）、days、nights、from、updated、summary、local_dir、cover、accent
3. 提交推送，GitHub Pages 1–2 分钟后生效

## 数据与说明

- 需求存在 Supabase（项目 maicvqkbksangtneiinn）。网页里放的是公开密钥，读写权限由数据库访问规则限制；私密密钥只在本机，本地 Claude Code 用它处理需求

- 行政区划边界：DataV.GeoAtlas（数据来自高德开放平台），按市级行政区分块，Albers 投影，仅作示意，不作为国界、行政区划的依据；南海诸岛见左下角插图
- 推荐城市的理由、车程、当季亮点是汇总估算，来源写在页面上
- 攻略照片来自高德、小红书、大众点评等平台的实拍，仅供个人参考
- 地图数据由 go-travel-guide 的 `scripts/build_china.py` 生成
