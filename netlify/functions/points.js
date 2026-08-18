const json = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json; charset=utf-8' },
  body: JSON.stringify(body),
});

const cleanText = (value, max = 500) => String(value == null ? '' : value).trim().slice(0, max);
const roundCoord = (value) => {
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.round(n * 1000) / 1000;
};

function normalizePoint(raw) {
  const lng = roundCoord(raw.lng);
  const lat = roundCoord(raw.lat);
  if (lng == null || lat == null) return null;
  if (lng < 113.4 || lng > 115.2 || lat < 21.8 || lat > 23.2) return null;
  return {
    id: cleanText(raw.id, 80) || ('p_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8)),
    lng,
    lat,
    name: cleanText(raw.name, 160),
    scene: cleanText(raw.scene || '不指定', 120),
    emotion: cleanText(raw.emotion, 120),
    emotion2: cleanText(raw.emotion2, 120),
    color: cleanText(raw.color, 40),
    color2: cleanText(raw.color2, 40),
    note: cleanText(raw.note, 240),
    time: /^\d{4}-\d{2}-\d{2}$/.test(String(raw.time || '')) ? raw.time : null,
    capturedAt: new Date().toISOString(),
  };
}

function toClient(row) {
  return {
    id: row.id,
    lng: Number(row.lng),
    lat: Number(row.lat),
    name: row.name || '',
    scene: row.scene || '不指定',
    emotion: row.emotion || '',
    emotion2: row.emotion2 || '',
    color: row.color || '',
    color2: row.color2 || null,
    note: row.note || '',
    time: row.emotion_date || '',
    capturedAt: row.captured_at || row.created_at,
  };
}

async function supabaseFetch(path, options = {}) {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    const err = new Error('Supabase environment variables are not configured.');
    err.statusCode = 503;
    throw err;
  }
  const requestUrl = `${url.replace(/\/$/, '')}/rest/v1/${path}`;
  const res = await fetch(requestUrl, {
    ...options,
    headers: {
      apikey: key,
      authorization: `Bearer ${key}`,
      'content-type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const text = await res.text();
  if (!res.ok) {
    console.error('[supabase] request failed', {
      status: res.status,
      statusText: res.statusText,
      path: requestUrl.replace(url.replace(/\/$/, ''), ''),
      body: text,
    });
    const err = new Error(text || `Supabase request failed: ${res.status}`);
    err.statusCode = res.status;
    throw err;
  }
  return text ? JSON.parse(text) : null;
}

exports.handler = async (event) => {
  try {
    if (event.httpMethod === 'GET') {
      const rows = await supabaseFetch('emotion_points?select=*&order=created_at.desc&limit=1000');
      return json(200, { points: (rows || []).map(toClient) });
    }

    if (event.httpMethod === 'POST') {
      const point = normalizePoint(JSON.parse(event.body || '{}'));
      if (!point || !point.emotion) return json(400, { error: 'Invalid emotion point.' });
      const row = {
        id: point.id,
        lng: point.lng,
        lat: point.lat,
        name: point.name,
        scene: point.scene,
        emotion: point.emotion,
        emotion2: point.emotion2,
        color: point.color,
        color2: point.color2 || null,
        note: point.note,
        emotion_date: point.time,
        captured_at: point.capturedAt,
      };
      const saved = await supabaseFetch('emotion_points', {
        method: 'POST',
        headers: { prefer: 'return=representation' },
        body: JSON.stringify(row),
      });
      return json(201, { point: toClient(saved[0]) });
    }

    return json(405, { error: 'Method not allowed.' });
  } catch (err) {
    const statusCode = err.statusCode || 500;
    return json(statusCode, { error: 'Database request failed.' });
  }
};
