# 深圳情绪地图 — 交接文档（Handoff）

> 更新于 2026-08-18。目的：让一个没有上下文的新对话，读完这份就能接着干。
> 当前项目目录：`/Users/ziheng/Desktop/公众号文章/emotion map`
> GitHub：`https://github.com/Henryzhao-blip/Shenzhen-emotion-map`
> Netlify：已连接 GitHub，推送 `main` 后自动部署。

---

## 1. 一句话

一个**公开、匿名、参与式**的网站（公众号文章配套）：每个人在深圳地图上留下「此时此刻我在哪、什么情绪」，让别人看见——**「空城里，原来也有人在这里」**。

---

## 2. 已锁定的约束

- **公共地图匿名**：公共地图不展示身份，没有私聊、配对、关注、评论。
- **不是交友/配对**：没有私聊、配对、关注、评论。
- **主题是「看见 / 共鸣」**，不是「遇见 / 认识」。
- 意象锁定两个：**共鸣**（同频振动，锚在情绪/场景上，不指向灵魂/交友）、**空城**（底色）。
- 当前已有后端数据库，但坐标采用**模糊存储**：数据库把经纬度四舍五入到 3 位小数，大约街区/百米级。
- 登录用 **Supabase Auth 邮箱免密（Magic Link）**；所有注册用户都能写点，但只能增删改自己的记录（RLS 强制）。

---

## 3. 文件结构

| 文件 | 说明 |
|---|---|
| `index.html` | 主文件，单文件静态前端，含 HTML/CSS/JS。 |
| `netlify/functions/points.js` | 已废弃：CRUD 迁到前端直连 Supabase，现返回 410 占位。保留以备用（AI/审核/管理）。 |
| `supabase/schema.sql` | Supabase 建表 SQL。 |
| `netlify.toml` | Netlify 配置，发布目录为仓库根目录。 |
| `README.md` | GitHub/Netlify/Supabase 设置说明。 |
| `handoff.md` | 本文件。 |
| `深圳情绪地图_人群与场景枚举.xlsx` | 场景枚举：人群 86 条 + 场景 76 条。 |
| `深圳情绪地图_人群-情绪阶段.xlsx` | 旧版“从→到 / 上下行”方案，仅参考。 |

---

## 4. 已完成

### 4.1 地图底座

- 高德 JS API 2.0，暗色主题 `amap://styles/dark`。
- **地点搜索**：`AMap.PlaceSearch`，city 深圳，citylimit，自定义结果列表。
- **地图点选**：点击地图落点，`AMap.Geocoder.getAddress()` 逆地理编码自动填地点名。
- **当前位置**：输入面板的地点旁有 `#geoBtn`「当前位置」，调用 `navigator.geolocation`；授权后自动落点并反查地点名。
- 点位可拖动：我的本地点可以直接拖动，编辑面板里的青色 draft marker 也可拖动。
- 26 条公共演示数据 `SEED_POINTS`，只读，可一键「隐藏演示 / 显示演示」。

### 4.2 输入面板

- 字段：场景类型、地点、主情绪、副情绪、一句话、日期。
- 新建记录时日期默认今天；用户仍可打开自定义暗色日历修改。
- 主情绪 `#emotionInput` 生成中心颜色，副情绪 `#emotionInput2` 生成外圈光芒颜色。
- `#emSwatch` 实时预览主/副颜色。
- 保存新点时仍写入 localStorage 作为本地备份，同时同步到 Supabase。

### 4.3 情绪颜色引擎

- 纯前端词典规则，不是真 AI，不联网分析文本。
- 二维情绪模型：效价 valence（-1 到 +1）× 唤醒 arousal（0 到 1）→ HSL 颜色。
- 程度词调节：`非常/超级/太…` arousal +0.3；`有点/稍微…` arousal -0.3。
- 否定词翻转效价 ×0.65：`不快乐`→蓝、`不焦虑`→橙。
- 旧数据兜底：`colorOf(p)` / `emotionText(p)` 仍支持旧 `dir/from/to` 数据。

### 4.4 登录 + 个人主页（Supabase Auth · 邮箱免密）

- 顶部按钮：`#authorBtn`，未登录显示「登录」，登录后显示「我的主页」。
- 邮箱免密：`#authEmail` 输入邮箱 → `supabase.auth.signInWithOtp` 发登录链接 → 用户点击邮件里的链接 → `getSession()` 恢复会话。
- 没有密码、没有注册/登录切换、没有本地模拟账号；旧的 `AUTHOR_USER / AUTHOR_PASS / sz2026` 已删除。
- 登录态：`authUserId` / `currentUserEmail`（来自 `session.user.id / email`）。
- `onAuthStateChange` 监听状态变化（`SIGNED_IN` 关登录框、`SIGNED_OUT` 关主页）。
- 我的点可编辑、删除、拖动；他人（含未登录）的点只读。
- 个人主页展示：情绪总数、覆盖场景、常见季节、时间跨度、情绪洞察、情绪光谱、我的每一笔。
- 「我的每一笔」= 本地备份点 + 云端属于我的点（`remotePoints.filter(isMine)`），支持跨设备编辑。
- 洞察包括：地点/场景规律、季节规律、月份规律、工作日/周末规律、复杂矛盾情绪。
- 个人主页右上角有「导出 / 导入」JSON，方便迁移 localStorage 点。

### 4.5 数据库（Supabase 直连 + RLS）

- 前端直接连 Supabase，不再走 Netlify Function。
- 表：`public.emotion_points`，建表 SQL 在 `supabase/schema.sql`。
- 客户端：`window.supabase.createClient(PUBLIC_DB_URL, PUBLIC_DB_KEY)`（supabase-js v2，CDN 加载）。
- 配置常量在 `index.html` 顶部：`PUBLIC_DB_URL`、`PUBLIC_DB_KEY`。
- `PUBLIC_DB_KEY` 可暴露在浏览器；**切勿**填 `service_role` key。
- RLS 四策略：select 公开（anon/authenticated 都可读）；insert/update/delete 仅 `authenticated` 且 `auth.uid() = user_id`。
- 数据读写：`.from('emotion_points')` 的 select / insert / update / delete。
- 坐标降精度：数据库列 `numeric(9,3)/numeric(8,3)` 自动四舍五入到 3 位小数（约街区/百米级）。
- Supabase 没配好（或没登录）时前端静默回退本地模式：点仍存 localStorage，只是不跨设备同步。

---

## 5. 重要 bug 记录

### 5.1 提交一次出现两个点（已修复）

原因（历史）：前端本地创建点时 id 是 `s...`，旧版 `pointForBackend(p)` 没把这个 id 发给后端，后端 `normalizePoint()` 自己生成 `p...` id，导致 `loadRemotePoints()` 后同一条记录显示成两个点。

当前修复（Supabase 直连后，问题自然消除）：
- 前端 `pointRow(p)` 始终发送 `id: p.id`，前端本地点和 Supabase 行共用同一个 id。
- `renderRemoteMarkers()` 用本地 id 集合过滤远程点，同 id 只显示一个。
- `netlify/functions/points.js` 已不再做 `normalizePoint()` / `cleanText()` / `roundCoord()`（整条 CRUD 迁到前端直连，该文件现为 410 占位），不会再自造 `p...` id。

注意：
- 已经进 Supabase 的旧 `p_...` 重复记录，需要手动删除。

---

## 6. 技术实现要点

- 数据模型（前端点）：`{ id, lng, lat, name, scene, emotion, emotion2, color, color2, note, time, capturedAt, user_id }`。
  - `time` ↔ 数据库 `emotion_date`；`capturedAt` ↔ `captured_at`。
- `pointRow(p)`：前端点 → Supabase 行（含 `user_id = authUserId`）。
- `toClientPoint(row)`：Supabase 行 → 前端点（`lng/lat` 转 Number）。
- `isMine(p)`：`p.remote` 时 = 已登录且 `p.user_id === authUserId`；本地点 = 恒 true（本浏览器自己的备份）。
- `remotePoints` / `remoteMarkers`：Supabase 里的公共点。
- `renderRemoteMarkers()` 用本地 id 集合过滤远程点，避免同 id 重复显示。
- `syncPointToBackend(p)` / `updatePointInBackend(p)` / `deletePointFromBackend(id)`：写回 Supabase 的入口；未登录或未配 Supabase 时静默跳过。
- `loadRemotePoints()` 在地图初始化后调用：`select('*').order('created_at').limit(1000)`。

---

## 7. 部署 / 运维提醒

1. 修改代码后：
   ```bash
   cd "/Users/ziheng/Desktop/公众号文章/emotion map"
   git status
   git add .
   git commit -m "message"
   git push
   ```
2. GitHub push 后 Netlify 自动部署。
3. 高德控制台必须把 Netlify 域名加入 key 的域名白名单，否则地图/搜索可能失败。
4. Supabase 建库：打开 Supabase SQL Editor，运行 `supabase/schema.sql`（建表 + RLS + 授权）。
5. 填 `index.html` 顶部 `PUBLIC_DB_URL` + `PUBLIC_DB_KEY`（public key，不是 `service_role`）。
6. Supabase Auth 配置：启用 Email（Magic Link）；把 Site URL 和 Redirect URLs 设成 Netlify 域名。
7. 收不到登录邮件时：确认邮箱没进垃圾箱、Supabase 的 Email 模板/发送限额正常。

---

## 8. 仍未解决 / 后续方向

- 数据审核/反垃圾还没有做。
- 情绪分析仍是词典规则，不是真 AI；如果未来接 AI，需要认真处理匿名和隐私边界。
- 文案仍可继续打磨：共鸣/空城 slogan、时刻氛围场景归属、人群枚举如何收敛到情绪轴。
- 未来若加「仅本人可访问的精确位置」（用于个人记忆），需另加独立列 + 列级 RLS（见 `schema.sql` 顶部注释）。
