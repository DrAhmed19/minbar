const V = 'minbar-v3.90';
const FILES = ['./', 'index.html', 'style.css', 'app.js', 'audiofx.js','player.js','cmfilter.js','plrviz.js','plrdev.js','lyrai.js','catalog.json', 'manifest.webmanifest', 'lib/mp4-muxer.js', 'lib/mp4box.all.min.js', 'lib/firebase-app-compat.js', 'lib/firebase-auth-compat.js', 'lib/firebase-firestore-compat.js', 'firebase-config.js', 'auth.js',  'icons/icon-192.png', 'icons/icon-512.png', 'icons/icon-maskable-512.png', 'icons/brand-mark.png', 'icons/favicon.png', 'icons/apple-touch-icon.png',
  'fonts/cairo.woff2', 'fonts/cairo-latin.woff2', 'fonts/tajawal.woff2', 'fonts/amiri.woff2', 'fonts/aref-ruqaa.woff2', 'fonts/reem-kufi.woff2', 'fonts/el-messiri.woff2', 'fonts/lalezar.woff2', 'fonts/katibeh.woff2', 'fonts/noto-naskh-arabic.woff2', 'fonts/rakkas.woff2', 'fonts/aref-ruqaa-ink.woff2', 'fonts/vibes.woff2', 'fonts/mirza.woff2', 'fonts/scheherazade-new.woff2', 'fonts/noto-kufi-arabic.woff2', 'fonts/reem-kufi-ink.woff2', 'fonts/blaka-ink.woff2', 'fonts/lateef.woff2'];
self.addEventListener('install', (e) => { e.waitUntil(caches.open(V).then((c) => c.addAll(FILES)).then(() => self.skipWaiting())); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== V && k.startsWith('minbar-')).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
/* قائمة المنزَّل للاستماع بدون إنترنت: غير المنزَّل يمرّ مباشرة للمتصفح (تمرير بث الصوت عبر الـSW يسبب تقطيعاً) */
let OFF = null; const loadOff = () => caches.open('mbr-offline').then((c) => c.keys()).then((ks) => { OFF = new Set(ks.map((k) => k.url.split('?')[0])); }).catch(() => { OFF = null; }); loadOff();
self.addEventListener('message', (e) => { if (e.data === 'off') loadOff(); });
self.addEventListener('fetch', (e) => {
  /* القصائد المنزّلة للاستماع بدون إنترنت (مع دعم المقاطع الجزئية Range) */
  if (e.request.method === 'GET' && /\/media\/u\//.test(e.request.url)) {
    if (OFF && !OFF.has(e.request.url.split('?')[0])) return;
    e.respondWith(caches.open('mbr-offline').then((c) => c.match(e.request.url, { ignoreSearch: true })).then(async (r) => {
      if (!r) return fetch(e.request); const rg = e.request.headers.get('range'); if (!rg) return r;
      const b = await r.arrayBuffer(), n = b.byteLength, m = /bytes=(\d*)-(\d*)/.exec(rg) || [], a = m[1] === '' || m[1] == null ? Math.max(0, n - +(m[2] || 0)) : +m[1], z = m[2] && m[1] !== '' ? Math.min(n - 1, +m[2]) : n - 1;
      return new Response(b.slice(a, z + 1), { status: 206, headers: { 'content-type': r.headers.get('content-type') || 'audio/mpeg', 'content-range': 'bytes ' + a + '-' + z + '/' + n, 'content-length': String(z - a + 1), 'accept-ranges': 'bytes' } });
    }));
    return;
  }
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin || e.request.headers.has('range') || /\/media\//.test(e.request.url)) return;
  /* كاش أولاً مع تحديث بالخلفية — فتح فوري؛ الكتالوج أولاً من الشبكة. لا نخزّن ولا نقدّم استجابات محوّلة (redirect) لأنها تُفشل التنقل */
  const net = /catalog\.json$/.test(new URL(e.request.url).pathname);
  const clean = (r) => (r && r.redirected) ? r.blob().then((b) => new Response(b, { status: r.status, statusText: r.statusText, headers: r.headers })) : r;
  const fresh = () => fetch(e.request).then((r) => { if (r && r.ok && !r.redirected && r.type === 'basic') { const cp = r.clone(); caches.open(V).then((c) => c.put(e.request, cp)); } return r; });
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then((hit) => {
    if (net) return fresh().catch(() => hit || fetch(e.request));
    if (hit) { fresh().catch(() => {}); return clean(hit); }
    return fresh();
  }).catch(() => fetch(e.request)));
});
