/* إدارة تخزين منبر (للمالك فقط) — بيانات حقيقية من R2 و KV
   GET  /api/store?s=r2|kv&c=<cursor>   → صفحة من الملفات: { items:[[key,size,uploadedMs,etag]], cursor, done }
   POST /api/store { del:[keys] }       → حذف ملفات من R2 و KV: { ok, r2, kv, failed }
   كل طلب خفيف (قائمة واحدة أو دفعة حذف واحدة) حتى لا يتجاوز حدود Cloudflare المجانية. */
import { ownerFrom, json } from '../../srv/auth.js';

const OK_KEY = /^(a|c|u|n)\/[^\s\\]{1,200}$/;
const PAGE = 1000, MAX_DEL_R2 = 200, MAX_DEL_KV = 40;
const nocache = { 'cache-control': 'no-store' };
const out = (o, s) => { const r = json(o, s); Object.entries(nocache).forEach(([k, v]) => r.headers.set(k, v)); return r; };

export async function onRequest({ request, env }) {
  const bucket = env.R2 || env['minbar-media'], kv = env.MEDIA;
  if (!(await ownerFrom(request))) return out({ error: 'للمالك فقط' }, 403);
  if (!bucket && !kv) return out({ error: 'لم يُربط مخزن' }, 500);

  if (request.method === 'GET') {
    const u = new URL(request.url), s = u.searchParams.get('s') || 'r2', c = u.searchParams.get('c') || undefined, after = u.searchParams.get('a') || undefined;
    try {
      if (s === 'r2') {
        if (!bucket) return out({ items: [], cursor: null, done: true, none: true });
        /* ترقيم بالمفتاح الأخير (startAfter) بدل المؤشّر المبهم: ثابت ولا يكرّر الصفحات */
        const r = await bucket.list(after ? { limit: PAGE, startAfter: after } : { limit: PAGE });
        const items = r.objects.map((o) => [o.key, o.size, o.uploaded ? +new Date(o.uploaded) : 0, o.etag || '']);
        return out({ items, last: items.length ? items[items.length - 1][0] : null, done: !r.truncated || !items.length });
      }
      if (!kv) return out({ items: [], cursor: null, done: true, none: true });
      const r = await kv.list({ limit: PAGE, cursor: c });
      return out({ items: r.keys.map((k) => [k.name, (k.metadata && +k.metadata.size) || 0, 0, '']), cursor: r.list_complete ? null : r.cursor, done: !!r.list_complete });
    } catch (e) { return out({ error: 'تعذّرت قراءة المخزن: ' + (e && e.message || e) }, 502); }
  }

  if (request.method === 'POST') {
    let b; try { b = await request.json(); } catch (e) { return out({ error: 'طلب غير صالح' }, 400); }
    const keys = Array.isArray(b.del) ? [...new Set(b.del.map(String))] : null;
    if (!keys || !keys.length) return out({ error: 'لا ملفات للحذف' }, 400);
    if (keys.some((k) => !OK_KEY.test(k) || k.includes('..'))) return out({ error: 'مسار غير صالح' }, 400);
    const st = b.store === 'kv' ? 'kv' : 'r2';
    try {
      if (st === 'r2') {
        if (!bucket) return out({ error: 'R2 غير مربوط' }, 500);
        if (keys.length > MAX_DEL_R2) return out({ error: 'الحد ' + MAX_DEL_R2 + ' ملفاً بالطلب' }, 413);
        await bucket.delete(keys);
        return out({ ok: true, store: 'r2', deleted: keys.length });
      }
      if (!kv) return out({ error: 'KV غير مربوط' }, 500);
      if (keys.length > MAX_DEL_KV) return out({ error: 'الحد ' + MAX_DEL_KV + ' ملفاً بالطلب' }, 413);
      const res = await Promise.allSettled(keys.map((k) => kv.delete(k)));
      const failed = keys.filter((_, i) => res[i].status === 'rejected');
      return out({ ok: !failed.length, store: 'kv', deleted: keys.length - failed.length, failed });
    } catch (e) { return out({ error: 'تعذّر الحذف: ' + (e && e.message || e) }, 502); }
  }
  return out({ error: 'طريقة غير مدعومة' }, 405);
}
