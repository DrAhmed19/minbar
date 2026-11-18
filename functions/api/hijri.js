/* التاريخ الهجري اليوم (النجف الأشرف): GET /api/hijri  →  { y, m, d, src }
   يُقرأ من الصفحة الرئيسية للمصدر الرسمي ويُحفظ 3 ساعات. التطبيق والموقع يضبطان تاريخهما عليه. */
const MONTHS = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
const J = (o, s = 200, c = 0) => new Response(JSON.stringify(o), { status: s, headers: { 'content-type': 'application/json; charset=utf-8', 'access-control-allow-origin': '*', 'cache-control': c ? 'public, max-age=' + c : 'no-store' } });
const norm = (s) => s.replace(/[٠-٩]/g, (c) => c.charCodeAt(0) - 1632).replace(/[۰-۹]/g, (c) => c.charCodeAt(0) - 1776).replace(/[ً-ْـ]/g, '').replace(/[أإآ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه').replace(/\s+/g, ' ');
const MN = MONTHS.map(norm);
function monthIdx(name) {
  const t = norm(name).replace(/الحرام|شهر|المبارك/g, '').trim();
  let i = MN.findIndex((m) => m === t); if (i >= 0) return i + 1;
  i = MN.findIndex((m) => t.includes(m) || m.includes(t)); return i >= 0 ? i + 1 : 0;
}
function parse(html) {
  const t = norm(html.replace(/<script[\s\S]*?<\/script>|<style[\s\S]*?<\/style>/gi, ' ').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' '));
  const re = /(\d{1,2}) *[-–—] *([؀-ۿ ]{3,20}?) *[-–—] *(14\d\d|15\d\d) *ه/g; let m;
  while ((m = re.exec(t))) { const mo = monthIdx(m[2]); if (mo) return { y: +m[3], m: mo, d: +m[1] }; }
  return null;
}
export async function onRequestGet({ request }) {
  const cache = caches.default, key = new Request('https://hijri.cache/v1'); const hit = await cache.match(key); if (hit) return hit;
  for (const u of ['https://www.sistani.org/', 'https://www.sistani.org/arabic/']) {
    try {
      const r = await fetch(u, { headers: { 'user-agent': 'Mozilla/5.0 (compatible; Minbar)', 'accept-language': 'ar' }, cf: { cacheTtl: 600 } }); if (!r.ok) continue;
      const h = parse(await r.text());
      if (h && h.d >= 1 && h.d <= 30) { const res = J(Object.assign({ src: 'najaf', at: Date.now() }, h), 200, 10800); await cache.put(key, res.clone()); return res; }
    } catch (e) {}
  }
  return J({ error: 'تعذّر قراءة التاريخ' }, 502);
}
