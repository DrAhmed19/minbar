/* تقديم ملفات القصائد من KV مع دعم التقديم الجزئي (Range) وتخزين مؤقت على حافة الشبكة لتقليل القراءات */
const TYPES = { mp3: 'audio/mpeg', m4a: 'audio/mp4', aac: 'audio/aac', ogg: 'audio/ogg', opus: 'audio/ogg', wav: 'audio/wav', jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', bin: 'application/octet-stream' };
export async function onRequest({ request, env, params, waitUntil }) {
  if (request.method !== 'GET' && request.method !== 'HEAD') return new Response('', { status: 405 });
  const key = [].concat(params.path || []).join('/'); const ext = (key.split('.').pop() || '').toLowerCase();
  const ck = new Request(new URL(request.url).origin + '/media/u/' + key, { method: 'GET' }); const cache = caches.default;
  let full = await cache.match(ck), buf, type;
  if (full) { buf = await full.arrayBuffer(); type = full.headers.get('content-type'); }
  else {
    if (!env.MEDIA) return new Response('', { status: 500 });
    const r = await env.MEDIA.getWithMetadata(key, { type: 'arrayBuffer', cacheTtl: 86400 }); if (!r || !r.value) return new Response('', { status: 404 });
    buf = r.value; type = (r.metadata && r.metadata.type) || TYPES[ext] || 'application/octet-stream';
    waitUntil(cache.put(ck, new Response(buf, { headers: { 'content-type': type, 'cache-control': 'public, max-age=31536000, immutable' } })));
  }
  const n = buf.byteLength, base = { 'content-type': type, 'accept-ranges': 'bytes', 'cache-control': 'public, max-age=31536000, immutable', 'access-control-allow-origin': '*' };
  const m = /bytes=(\d*)-(\d*)/.exec(request.headers.get('range') || '');
  if (m && (m[1] || m[2])) {
    let a = m[1] === '' ? Math.max(0, n - +m[2]) : +m[1], b = m[1] === '' || m[2] === '' ? n - 1 : Math.min(n - 1, +m[2]);
    if (a >= n || a > b) return new Response('', { status: 416, headers: { 'content-range': 'bytes */' + n } });
    return new Response(request.method === 'HEAD' ? null : buf.slice(a, b + 1), { status: 206, headers: Object.assign({}, base, { 'content-range': `bytes ${a}-${b}/${n}`, 'content-length': String(b - a + 1) }) });
  }
  return new Response(request.method === 'HEAD' ? null : buf, { headers: Object.assign({}, base, { 'content-length': String(n) }) });
}
