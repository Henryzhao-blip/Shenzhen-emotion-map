// ============================================================
// 深圳情绪地图 · Netlify Function（占位）
//
// 从前的 emotion_points 读写 CRUD 已迁移到前端直连 Supabase：
//   客户端用 publishable (anon) key + 用户 JWT 直接调 Supabase REST，
//   由 RLS 限制「只能读写自己的记录」，身份来自当前 session。
//
// 本函数不再处理普通 CRUD。保留 Netlify Functions 机制，只用于将来
// 需要 server secret 的服务端逻辑，例如：
//   - AI 情绪分析 / 关键词 / 摘要
//   - 语音处理
//   - 内容审核 / 反垃圾
//   - 管理员后台操作
//   - 第三方 API 代理
//
// 将来写这类函数时：用 process.env 读 secret（如 SUPABASE_SERVICE_ROLE_KEY），
// 不要把 secret 写进 index.html 或提交到 GitHub。
// ============================================================

const json = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json; charset=utf-8' },
  body: JSON.stringify(body),
});

exports.handler = async () => json(410, {
  error: 'This function no longer serves emotion_points CRUD.',
  detail: 'Client CRUD now goes directly to Supabase with the publishable key + user JWT + RLS. This function is reserved for future server-side logic (AI, moderation, admin, third-party APIs).',
});
