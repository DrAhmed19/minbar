/* تشغيل استيراد يوتيوب (للمالك فقط): POST /api/yt/run {job, mode} → يشغّل GitHub Action
   الأسرار المطلوبة في Cloudflare Pages: GH_TOKEN (توكن GitHub بصلاحية Actions: Read and write على الريبو فقط) */
import { ownerFrom, json } from '../../../srv/auth.js';
export async function onRequest({ request, env, params }) {
  if (request.method !== 'POST') return json({ error: 'طريقة غير مدعومة' }, 405);
  if (!(await ownerFrom(request))) return json({ error: 'غير مصرّح' }, 403);
  const pth = [].concat(params.path || []).join('/');
  if (pth === 'cancel') {   /* إيقاف فوري: يلغي أي تشغيل جارٍ أو منتظر للـ workflow */
    if (!env.GH_TOKEN) return json({ error: 'لم يُضف السر GH_TOKEN في Cloudflare' }, 500);
    const base = 'https://api.github.com/repos/' + (env.GH_REPO || 'DrAhmed19/minbar') + '/actions', h = { authorization: 'Bearer ' + env.GH_TOKEN, accept: 'application/vnd.github+json', 'user-agent': 'minbar-import', 'x-github-api-version': '2022-11-28' };
    let n = 0;
    for (const st of ['in_progress', 'queued']) {
      const r = await fetch(base + '/workflows/yt-import.yml/runs?per_page=20&status=' + st, { headers: h });
      if (!r.ok) return json({ error: 'تعذّر قراءة التشغيلات (' + r.status + ')' }, 502);
      for (const run of (await r.json()).workflow_runs || []) { const c = await fetch(base + '/runs/' + run.id + '/cancel', { method: 'POST', headers: h }); if (c.status === 202) n++; }
    }
    return json({ ok: true, cancelled: n });
  }
  if (pth !== 'run') return json({ error: 'مسار غير معروف' }, 404);
  let b; try { b = await request.json(); } catch (e) { return json({ error: 'طلب غير صالح' }, 400); }
  const job = String((b && b.job) || ''), mode = String((b && b.mode) || '');
  if (!/^[A-Za-z0-9_-]{4,60}$/.test(job) || !['list', 'import', 'scan', 'covers', 'dates'].includes(mode)) return json({ error: 'معطيات غير صالحة' }, 400);
  if (!env.GH_TOKEN) return json({ error: 'لم يُضف السر GH_TOKEN في Cloudflare' }, 500);
  const r = await fetch('https://api.github.com/repos/' + (env.GH_REPO || 'DrAhmed19/minbar') + '/actions/workflows/yt-import.yml/dispatches', {
    method: 'POST',
    headers: { authorization: 'Bearer ' + env.GH_TOKEN, accept: 'application/vnd.github+json', 'user-agent': 'minbar-import', 'x-github-api-version': '2022-11-28', 'content-type': 'application/json' },
    body: JSON.stringify({ ref: env.GH_REF || 'main', inputs: { job, mode } }),
  });
  if (r.status === 204) return json({ ok: true });
  const t = (await r.text()).slice(0, 200);
  return json({ error: r.status === 401 || r.status === 403 ? 'توكن GitHub غير صالح أو بلا صلاحية Actions' : r.status === 404 ? 'لم يُعثر على الـ workflow (تأكد أنه مدموج بفرع main)' : 'رفض GitHub التشغيل (' + r.status + ')', detail: t }, 502);
}
