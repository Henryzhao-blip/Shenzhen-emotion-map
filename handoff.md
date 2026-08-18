# 深圳情绪地图 — 交接文档（Handoff）

> 写于 2026-08-17。目的：让一个没有上下文的对话，读完这份就能接着干。
> 主文件（唯一在改的代码）：`index.html`，单文件静态 HTML。

---

## 1. 一句话

一个**公开、匿名、参与式**的网站（公众号文章配套）：每个人在深圳地图上留下「此时此刻我在哪、什么情绪」，让别人看见——**「空城里，原来也有人在这里」**。

---

## 2. 已锁定的约束（不要推翻）

- **公共地图匿名**：公共地图不展示身份，没有私聊、配对、关注、评论。
- 当前代码里有一个**本地 demo 账号**：只存在 localStorage，用来保存“我的情绪日记 / 个人主页”，不是安全登录，也不是公开身份系统。
- **不是交友/配对**：没有私聊、配对、关注、评论。
- **主题是「看见 / 共鸣」**（他人也存在），**不是「遇见 / 认识」**。
- 意象锁定两个：**共鸣**（同频振动，锚在情绪/场景上，不指向灵魂/交友）、**空城**（底色，措辞待定）。

---

## 3. 文件在哪

| 文件 | 说明 |
|---|---|
| `index.html` | **主文件，唯一在改的代码**。单文件，含全部 HTML/CSS/JS，可直接作为 Netlify 入口。 |
| `深圳情绪地图_人群与场景枚举.xlsx` | 场景枚举：人群 86 条 + 场景 76 条（地点型 + 时刻氛围）。生成脚本 `/tmp/build_enum_xlsx.py`。 |
| `深圳情绪地图_人群-情绪阶段.xlsx` | **旧版**（v1，「转折/从→到」思路），已被推翻，仅参考。生成脚本 `/tmp/build_emotion_map_xlsx.py`。 |
| `handoff.md` | 本文件。 |

---

## 4. 已经完成了什么

### 4.1 地图底座（已稳定，不要动搜索/定位逻辑）
- 高德 JS API 2.0（`webapi.amap.com/maps?v=2.0`），暗色主题 `amap://styles/dark`。
- **场景搜索**：`AMap.PlaceSearch`（city 深圳，citylimit），自定义结果列表。
- **自行定位**：地图点击落点 → `AMap.Geocoder.getAddress()` 逆地理编码自动填地名。
- 自定义 HTML 标记（发光脉冲圆点 `.dot`，`--c` CSS 变量上色）。
- `localStorage` 持久化（key = `sz_emotion_map_points_v1`），无后端。
- 26 条公共演示数据 `SEED_POINTS`（只读、无 owner，可一键「隐藏演示 / 显示演示」）。

### 4.2 情绪 → 颜色光谱引擎（最新改动，核心）
用户拍板的新方向：**放弃「上行/下行」和「从→到」**，改为**自由文本情绪 + 实时前端分析 → 颜色**。

- 情绪输入已拆成两个字段：`#emotionInput` 主情绪、`#emotionInput2` 副情绪（可选）。`#emSwatch` 中心显示主颜色，外圈光芒显示副颜色，下方实时显示识别结果 `#emLabel`。
- **纯前端词典分析**（`analyzeEmotion()`），不联网、不传文字，符合匿名。
- 二维情绪模型：**效价 valence（-1 消极 ~ +1 积极）× 唤醒 arousal（0 平静 ~ 1 强烈）→ HSL 颜色**。
- 颜色锚点（已实测验证）：
  - 开心 = 橙 `hsl(~28°)`、兴奋/激动 = 橙红 `hsl(~10°)`、平静 = 绿 `hsl(~105°)`、难过/孤独 = 蓝 `hsl(~250°)`、焦虑/愤怒 = 紫 `hsl(~270°)`。
- 程度词调节：`非常/超级/太…` arousal +0.3；`有点/稍微…` arousal -0.3。
- 否定词翻转效价 ×0.65：`不快乐`→蓝、`不焦虑`→橙。
- 旧数据兜底：`colorOf(p)` / `emotionText(p)` 让旧的 `dir/from/to` 数据（种子点）仍能正确渲染，无需迁移。

### 4.3 输入面板（已重写）
- 删掉「从→到」「走向」字段，只剩：**地点 · 情绪 · 一句话 · 日期**。
- 日期底层仍用 `<input type="date" id="timeInput">`，但 UI 已改成自定义暗色日历（`#datePicker`），支持日 / 月 / 十年切换。
- 标题副文案：「把这一刻的情绪，落在城市的坐标上」；计数器「个情绪」。

### 4.4 本地账号 + 个人主页（demo，最新）
- 顶部有 `#authorBtn`：未登录显示「登录」，登录后显示「我的主页」。
- 固定作者入口已开启：
  - 用户名可留空或填 `作者`
  - 口令：`sz2026`
  - 常量位置：`AUTHOR_USER` / `AUTHOR_PASS` / `AUTHOR_EMOJI`
- 注册 / 登录信息只存在本机 `localStorage`：
  - `sz_emotion_map_users_v1`
  - `sz_emotion_map_session_v1`
- 新提交点会写入 `owner: currentUser()`，公共地图上仍不显示 owner。
- 我的点可编辑、删除、拖动；旧版本机点若有 `id` 但没有 `owner`，也按“我的点”兼容处理；演示点无 `id/owner`，只读。
- 个人主页展示：情绪总数、覆盖场景、常见季节、时间跨度、情绪洞察、按时间排列的情绪光谱、我的每一笔。
- 情绪洞察已包括：场景/地点规律、季节规律、月份规律、工作日/周末规律、复杂矛盾情绪。
- 个人主页右上角已有「导出 / 导入」：
  - 导出文件名：`深圳情绪地图备份-YYYY-MM-DD.json`
  - 导出内容：`{ app, version, exportedAt, points }`
  - 导入策略：按 `id` 合并去重；同 id 用导入文件覆盖，新增 id 追加；不包含代码里的 `SEED_POINTS` 测试点。
- 登录 / 退出后会重绘本地 marker，确保“我的点”的编辑/拖动权限跟着当前 session 刷新。

---

## 5. 技术实现要点（新对话要接得上）

- **高德 key 配置在 HTML 内**（文件约 344 行附近）：
  - `AMAP_KEY` = Web端(JS API) key
  - `AMAP_SECURITY` = securityJsCode（安全密钥），**地点搜索/逆地理编码必需**，`window._AMapSecurityConfig = { securityJsCode: AMAP_SECURITY }`。
- **数据模型**（新点）：`{ id, lng, lat, name, scene, emotion, emotion2, color, color2, note, time, owner }`（替换旧的 `dir/from/to`）。
- 点的归属：`owner === currentUser()` = 当前用户自己的点（可编辑/删除/拖动）；兼容旧数据：有 `id` 但无 `owner` 的本地保存点也可编辑；无 `id/owner` = 种子演示点（只读）。
- 演示点显隐：`LS_DEMO_HIDDEN_KEY = sz_emotion_map_demo_hidden_v1`。
- 情绪引擎代码块：`EMOTION_LEXICON`（词典）、`EM_INTENSIFY`/`EM_SOFTEN`、`emotionColor()`、`emotionLabel()`、`analyzeEmotion()`、`colorOf()`、`emotionText()`。

---

## 6. 当前卡在哪 / 未解决的问题

1. **情绪分析是「词典 + 规则」，不是真 AI**。静态 HTML 里跑不了大模型。要让它「真懂」情绪（如理解「说不上来的那种空落落」），必须接后端调模型——**这会破坏纯匿名/无后端设计，是待权衡的取舍**。
2. **个人「emotion mapping」只在本机**（localStorage，按设备隔离），跨设备同步没做；当前本地账号只是 demo，不是真正账号系统。
3. **部署没做**。用户刚问起「放到互联网上」（Netlify），还没上线。
4. **文案待定**：共鸣/空城的 slogan 措辞。
5. **分类待定**：「时刻·氛围」类场景（如「深夜一个人在空荡的街上走」）到底属于「地点」轴还是「情绪」轴，还没定。
6. **身份收敛**：人群枚举（86 条）如何收敛到情绪轴，还没定。

---

## 7. 下一步计划

**优先级最高：上线到 Netlify**（用户已主动提出）。
1. `index.html` 已经是入口文件，拖到 Netlify Drop 即可。
2. 拖到 [app.netlify.com/drop](https://app.netlify.com/drop) → 拿到 `xxx.netlify.app`。
3. **必踩坑**：去高德控制台给 key 的「域名白名单」加上 `https://xxx.netlify.app`，否则地图/搜索上线后直接白屏失败。
4. （可选）自定义域名：任何注册商买域名 → Netlify Domain settings 加 CNAME，HTTPS 自动配。

**其次（设计讨论，用户拍板后再动代码）**：
- 共鸣/空城 slogan 措辞。
- 时刻·氛围场景的归属。
- 是否接后端做真·情绪分析（及其对匿名的取舍）。

---

## 8. 给下一个对话的关键提醒（坑）

- **不要动「场景搜索」和「自行定位」代码**（`setupSearch`、`setPicking`/`handlePick`/`reverseGeocode`）——用户明确要求保持不变。
- 情绪引擎是纯前端词典，别把它说成「AI」，对用户要诚实。
- 上线前**必须**改高德 key 域名白名单，否则部署等于失败。
- 情绪词典里删掉重复词后，`analyzeEmotion` 的否定逻辑是「先 strip 否定词再找程度词」，改的时候别把「不太」里的「太」误判成加强词（已有注释说明）。
- 记得同步更新本机记忆文件 `~/.claude/projects/-Users-ziheng/memory/sz-emotion-map.md`，它记录了项目锁定约束和现状。
