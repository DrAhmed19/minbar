/* معلومات مقطع تيك توك: GET /api/tt?url=<رابط المقطع أو الرابط المختصر>
   يحوّل الرابط المختصر لرابط كامل، ويجلب العنوان والصورة من oEmbed الرسمي.
   مسموح فقط لروابط tiktok.com حتى لا يُستغل كوسيط لمواقع أخرى. */
const OK = /^https:\/\/([a-z0-9-]+\.)*tiktok\.com\//i;
const J = (o, s = 200, c = 0) => new Response(JSON.stringify(o), { status: s, headers: { 'content-type': 'application/json; charset=utf-8', 'access-control-allow-origin': '*', 'cache-control': c ? 'public, max-age=' + c : 'no-store' } });

export async function onRequestGet({ request }) {
  let url = new URL(request.url).searchParams.get('url') || '';
  url = url.trim().replace(/^http:/, 'https:');
  if (!/^https:/.test(url)) url = 'https://' + url.replace(/^\/+/, '');
  if (!OK.test(url) || url.length > 400) return J({ error: 'رابط تيك توك غير صالح' }, 400);
  // الروابط المختصرة (vm.tiktok.com / vt.tiktok.com / tiktok.com/t/...) نتبع التحويل يدوياً وبحد أقصى
  for (let i = 0; i < 5 && !/\/video\/\d+/.test(url); i++) {
    let r;
    try { r = await fetch(url, { redirect: 'manual', headers: { 'user-agent': 'Mozilla/5.0' } }); } catch (e) { break; }
    const loc = r.headers.get('location'); if (!loc) break;
    const nx = new URL(loc, url).toString(); if (!OK.test(nx)) break; url = nx;
  }
  const m = url.match(/@([\w.-]+)\/video\/(\d{8,25})/);
  if (!m) return J({ error: 'ما لكينا رقم المقطع بهذا الرابط' }, 400);
  const clean = 'https://www.tiktok.com/@' + m[1] + '/video/' + m[2];
  let o = {};
  try { const r = await fetch('https://www.tiktok.com/oembed?url=' + encodeURIComponent(clean)); if (r.ok) o = await r.json(); } catch (e) {}
  return J({ id: m[2], user: m[1], url: clean, title: (o.title || '').slice(0, 300), thumb: o.thumbnail_url || '', author: o.author_name || '' }, 200, 3600);
}
