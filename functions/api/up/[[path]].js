/* رفع وحذف ملفات القصائد (للمالك فقط) — PUT /api/up/a/<id>.mp3 ، DELETE /api/up/a/<id>.mp3 */
import { ownerFrom, json } from '../../../srv/auth.js';
const KEY = /^(a|c|u|n)\/[A-Za-z0-9_-]{3,64}\.(mp3|m4a|aac|ogg|opus|wav|jpg|jpeg|png|webp|bin)$/;
export async function onRequest({ request, env, params }) {
  if (!env.MEDIA) return json({ error: 'لم يُربط مخزن MEDIA' }, 500);
  const key = [].concat(params.path || []).join('/');
  if (!KEY.test(key)) return json({ error: 'مسار غير صالح' }, 400);
  if (!(await ownerFrom(request))) return json({ error: 'غير مصرّح' }, 403);
  if (request.method === 'PUT') {
    const len = +request.headers.get('content-length') || 0; if (len > 25 * 1024 * 1024 - 1024) return json({ error: 'الملف أكبر من 25 ميغابايت' }, 413);
    const buf = await request.arrayBuffer(); if (!buf.byteLength) return json({ error: 'ملف فارغ' }, 400);
    await env.MEDIA.put(key, buf, { metadata: { type: request.headers.get('content-type') || 'application/octet-stream', size: buf.byteLength } });
    return json({ ok: true, url: '/media/u/' + key, size: buf.byteLength });
  }
  if (request.method === 'DELETE') { await env.MEDIA.delete(key); return json({ ok: true }); }
  return json({ error: 'طريقة غير مدعومة' }, 405);
}
