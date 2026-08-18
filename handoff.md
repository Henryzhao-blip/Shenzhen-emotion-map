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
- 当前已有后端数据库，但坐标采用**模糊存储**：后端把经纬度四舍五入到 3 位小数，大约街区/百米级。
- 本地作者入口只是 demo：用于个人主页和本机点管理，不是真正安全账号系统。

---

## 3. 文件结构

| 文件 | 说明 |
|---|---|
| `index.html` | 主文件，单文件静态前端，含 HTML/CSS/JS。 |
| `netlify/functions/points.js` | Netlify Function，读写 Supabase 的公共情绪点 API。 |
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
- 保存新点时仍写入 localStorage 作为本地备份，同时尝试同步到后端数据库。

### 4.3 情绪颜色引擎

- 纯前端词典规则，不是真 AI，不联网分析文本。
- 二维情绪模型：效价 valence（-1 到 +1）× 唤醒 arousal（0 到 1）→ HSL 颜色。
- 程度词调节：`非常/超级/太…` arousal +0.3；`有点/稍微…` arousal -0.3。
- 否定词翻转效价 ×0.65：`不快乐`→蓝、`不焦虑`→橙。
- 旧数据兜底：`colorOf(p)` / `emotionText(p)` 仍支持旧 `dir/from/to` 数据。

### 4.4 本地作者入口 + 个人主页

- 顶部按钮：`#authorBtn`，未登录显示「作者入口」，登录后显示「我的主页」。
- 固定作者入口：
  - 用户名可留空或填 `作者`
  - 口令：`sz2026`
  - 常量：`AUTHOR_USER` / `AUTHOR_PASS` / `AUTHOR_EMOJI`
- localStorage keys：
  - `sz_emotion_map_users_v1`
  - `sz_emotion_map_session_v1`
  - `sz_emotion_map_points_v1`
  - `sz_emotion_map_demo_hidden_v1`
- 我的本地点可编辑、删除、拖动；远程公共点只读。
- 个人主页展示：情绪总数、覆盖场景、常见季节、时间跨度、情绪洞察、情绪光谱、我的每一笔。
- 洞察包括：地点/场景规律、季节规律、月份规律、工作日/周末规律、复杂矛盾情绪。
- 个人主页右上角有「导出 / 导入」JSON，方便迁移 localStorage 点。

### 4.5 后端数据库

- 后端方案：Supabase + Netlify Functions。
- 表：`public.emotion_points`，建表 SQL 在 `supabase/schema.sql`。
- API：`/.netlify/functions/points`
  - `GET`：读取最多 1000 条公共点，按 `created_at desc` 排序。
  - `POST`：追加新公共点。
- Netlify 环境变量：
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` 只在 Netlify Function 服务器端使用，不写入 `index.html`。
- 后端坐标降精度：`roundCoord()` 把 `lng/lat` 保留 3 位小数。
- API 不开放 CORS 自定义头，不做公开更新/删除。
- 如果 Supabase 环境变量没配好，Function 返回安全通用错误：`{"error":"Database request failed."}`；前端会继续本地模式。
- Function 内已增强服务端日志：Supabase 请求失败时 `console.error` 打印 HTTP status、statusText、Supabase response body、实际 REST 路径；不打印 API key。

---

## 5. 重要 bug 记录

### 5.1 提交一次出现两个点（已修复）

原因：
- 前端本地创建点时 id 是 `s...`。
- 旧版 `pointForBackend(p)` 没把这个 id 发给后端。
- 后端 `normalizePoint()` 自己生成了 `p...` id。
- 页面重新 `loadRemotePoints()` 后，因为 local id 和 remote id 不同，同一条记录显示为两个点。

修复：
- `index.html` 的 `pointForBackend(p)` 已发送 `id: p.id`。
- `netlify/functions/points.js` 的 `normalizePoint(raw)` 已优先使用 `cleanText(raw.id, 80)`，没有时才 fallback 生成 `p...`。
- 最新 commit：`45358a9 Prevent duplicate markers after backend sync`，已 push 到 `origin/main`。

注意：
- 修复只阻止之后的新提交重复。
- 已经进 Supabase 的旧重复数据，需要手动删除 `p_...` 那条远程重复记录。

---

## 6. 技术实现要点

- 数据模型（前端本地点）：`{ id, lng, lat, name, scene, emotion, emotion2, color, color2, note, time, capturedAt, owner }`。
- 数据模型（远程点）：后端返回同类字段，但前端渲染时会加 `{ remote: true }`，因此只读。
- `isMine(p)`：远程点 `p.remote` 直接 false；本地点有 `id` 且 owner 为空或 owner 等于 currentUser 时可编辑。
- `remotePoints` / `remoteMarkers`：用于数据库公共点。
- `renderRemoteMarkers()` 会用本地 id 集合过滤远程点，避免同 id 重复显示。
- `syncPointToBackend(p)` 只在新建本地点时调用；编辑本地点目前只改 localStorage，不公开覆盖数据库旧点。
- `loadRemotePoints()` 在地图初始化后调用；数据库未配置时静默失败。

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
4. Supabase 建库：打开 Supabase SQL Editor，运行 `supabase/schema.sql`。
5. Netlify 环境变量：确认 `SUPABASE_URL` 和 `SUPABASE_SERVICE_ROLE_KEY` 已配置；配置后 redeploy。
6. 如果 endpoint 仍返回 `{"error":"Database request failed."}`，去 Netlify Function logs 看 `[supabase] request failed` 的 status/body/path。

---

## 8. 仍未解决 / 后续方向

- 当前作者入口不是安全账号系统；如要真正多用户账户，需要正式认证。
- 删除/编辑数据库里的公共点还没有做，当前公共投稿是追加式。
- 数据审核/反垃圾还没有做。
- 情绪分析仍是词典规则，不是真 AI；如果未来接 AI，需要认真处理匿名和隐私边界。
- 文案仍可继续打磨：共鸣/空城 slogan、时刻氛围场景归属、人群枚举如何收敛到情绪轴。
