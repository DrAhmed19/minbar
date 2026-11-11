/* نقل ملفات القصائد من KV إلى R2 (للمالك فقط) — POST /api/migrate?cursor=...  يعالج دفعة صغيرة ويرجع المؤشر التالي */
import { ownerFrom, json } from '../../srv/auth.js';
export async function onRequest({ request, env }) {
  const bucket = env.R2 || env['minbar-media'];
  if (!bucket || !env.MEDIA) return json({ error: 'الربط ناقص (R2 أو MEDIA)' }, 500);
  if (!(await ownerFrom(request))) return json({ error: 'غير مصرّح' }, 403);
  const cursor = new URL(request.url).searchParams.get('cursor') || undefined;
  const l = await env.MEDIA.list({ limit: 6, cursor });
  let copied = 0, skipped = 0; const failed = [];
  for (const k of l.keys) {
    try {
      if (await bucket.head(k.name)) { skipped++; continue; }
      const r = await env.MEDIA.getWithMetadata(k.name, { type: 'arrayBuffer' });
      if (!r || !r.value) { failed.push(k.name); continue; }
      await bucket.put(k.name, r.value, { httpMetadata: { contentType: (r.metadata && r.metadata.type) || 'application/octet-stream' } });
      copied++;
    } catch (e) { failed.push(k.name); }
  }
  return json({ ok: true, copied, skipped, failed, done: l.list_complete, cursor: l.list_complete ? null : l.cursor });
}
