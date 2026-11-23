// تشغيل استيراد يوتيوب على GitHub Actions: MODE = list | import | scan
import { GoogleAuth } from 'google-auth-library';
import { execFile } from 'node:child_process';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import * as L from './ytlib.mjs';

const P = 'minbar-8f037', FS = `https://firestore.googleapis.com/v1/projects/${P}/databases/(default)/documents`;
const SITE = (process.env.SITE || 'https://minbar-95z.pages.dev').replace(/\/+$/, '');
const IKEY = process.env.IMPORT_KEY || '';
const MODE = process.env.MODE || 'scan';
const JOB = process.env.JOB || (MODE === 'scan' ? 'scan' : '');
const WORK = path.join(process.env.RUNNER_TEMP || '/tmp', 'ytwork');
if (!/^[A-Za-z0-9_-]{4,60}$/.test(JOB)) { console.error('::error::معرّف المهمة غير صالح'); process.exit(1); }
if (!IKEY || IKEY.length < 24) { console.error('::error::السر IMPORT_KEY ناقص أو قصير (24 حرفاً على الأقل)'); process.exit(1); }

/* ---------- Firestore ---------- */
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/datastore'] });
async function call(method, url, data) {
  const c = await auth.getClient(); let last;
  for (let i = 0; i < 4; i++) {
    try { return await c.request({ url, method, data }); } catch (e) {
      last = e; const s = e.response && e.response.status;
      if (s && s !== 429 && s < 500) throw e;
      await L.sleep(1500 * (i + 1));
    }
  }
  throw last;
}
const store = {
  async get(p) { try { const r = await call('GET', `${FS}/${p}`); return L.fromFs({ mapValue: { fields: r.data.fields || {} } }); } catch (e) { if (e.response && e.response.status === 404) return null; throw e; } },
  async set(p, o) { await call('PATCH', `${FS}/${p}`, { fields: L.toFields(o) }); },
  async patch(p, o) { const q = Object.keys(o).map((k) => 'updateMask.fieldPaths=' + encodeURIComponent(k)).join('&'); await call('PATCH', `${FS}/${p}?${q}`, { fields: L.toFields(o) }); },
  async list(col, fields) {
    const out = []; let tok = '';
    do {
      const q = ['pageSize=300'].concat((fields || []).map((f) => 'mask.fieldPaths=' + encodeURIComponent(f))); if (tok) q.push('pageToken=' + encodeURIComponent(tok));
      const r = await call('GET', `${FS}/${col}?${q.join('&')}`);
      for (const d of r.data.documents || []) out.push(Object.assign({ id: d.name.split('/').pop() }, L.fromFs({ mapValue: { fields: d.fields || {} } })));
      tok = r.data.nextPageToken || '';
    } while (tok);
    return out;
  },
};

/* ---------- الأدوات الخارجية ---------- */
const run = (cmd, args, timeout) => new Promise((res, rej) => execFile(cmd, args, { maxBuffer: 256 * 1024 * 1024, timeout: timeout || 600000 }, (err, so, se) => {
  if (err) return rej(new Error(String(se || '').trim().split('\n').slice(-6).join(' ') || err.message)); res(String(so)); }));
let JSR = false, COOKIES = '';
try { JSR = /js-runtimes/.test(await run('yt-dlp', ['--help'])); } catch (e) {}
if (process.env.YT_COOKIES && process.env.YT_COOKIES.trim().length > 50) { await mkdir(WORK, { recursive: true }); COOKIES = path.join(WORK, 'cookies.txt'); await writeFile(COOKIES, process.env.YT_COOKIES.trim() + '\n'); }
const ytdlp = (args, o) => run('yt-dlp', ['--no-warnings', '--ignore-config', '--retries', '5', '--fragment-retries', '5', '--socket-timeout', '30']
  .concat(JSR ? ['--js-runtimes', 'node'] : []).concat(o && o.cookies && COOKIES ? ['--cookies', COOKIES] : []).concat(args), 25 * 60e3);

async function upload(key, file, type) {
  const buf = await readFile(file); let last;
  for (let i = 0; i < 4; i++) {
    try {
      const r = await fetch(SITE + '/api/up/' + key, { method: 'PUT', headers: { 'x-import-key': IKEY, 'content-type': type }, body: buf });
      const j = await r.json().catch(() => ({}));
      if (!(r.ok && j.ok)) throw new Error(j.error || ('رفض الخادم الرفع (' + r.status + ')'));
      const h = await fetch(SITE + '/media/u/' + key, { method: 'HEAD' });
      if (!h.ok || +h.headers.get('content-length') !== buf.length) throw new Error('فشل التحقق من الملف المرفوع');
      return buf.length;
    } catch (e) { last = e; await L.sleep(3000 * (i + 1)); }
  }
  throw last;
}

const ctx = { work: WORK, ytdlp, exec: (c, a) => run(c, a), upload, store, hasCookies: !!COOKIES };

/* ---------- المهمة ---------- */
const jobPatch = (o) => store.patch('ytJobs/' + JOB, Object.assign({ upd: Date.now() }, o));
const clip = (s, n) => String(s || '').slice(0, n);

async function registry() { const m = {}; for (const d of await store.list('ytDrafts', ['status'])) m[d.id] = d.status; return m; }

async function modeList() {
  const job = await store.get('ytJobs/' + JOB); if (!job || !job.url) throw new Error('لا توجد مهمة بهذا المعرّف');
  const pu = L.parseUrl(job.url); if (!pu || pu.kind === 'unsupported') throw new Error(pu && pu.msg || 'الرابط غير مدعوم: ألصق رابط فيديو أو قائمة تشغيل أو قناة يوتيوب');
  await jobPatch({ status: 'running', phase: 'جلب القائمة…', msg: '' });
  let entries = [], playlists = [], title = '', kind = pu.kind;
  if (pu.kind === 'video') {
    const info = JSON.parse(await L.ytTry(ctx, ['-J', '--no-playlist', pu.url]));
    entries = [{ id: pu.id, t: clip(info.title, 120), d: Math.round(info.duration || 0), x: ['is_live', 'is_upcoming'].includes(info.live_status) ? 'بث مباشر' : '', p: [] }]; title = info.channel || info.uploader || '';
  } else if (pu.kind === 'playlist') {
    const flat = L.parseFlat(await L.ytTry(ctx, ['-j', '--flat-playlist', pu.url]));
    title = (flat.find((e) => e.playlist_title) || {}).playlist_title || 'قائمة تشغيل';
    playlists = [{ id: pu.id, t: clip(title, 120) }]; entries = L.videoEntries(flat).map((e) => Object.assign(e, { p: [0] }));
  } else {
    const vf = L.parseFlat(await L.ytTry(ctx, ['-j', '--flat-playlist', '--playlist-end', '1500', pu.url + '/videos']));
    title = (vf.find((e) => e.channel || e.uploader) || {}).channel || (vf.find((e) => e.uploader) || {}).uploader || '';
    entries = L.videoEntries(vf).map((e) => Object.assign(e, { p: [] }));
    let pls = []; try { pls = L.playlistEntries(L.parseFlat(await L.ytTry(ctx, ['-j', '--flat-playlist', pu.url + '/playlists']))).slice(0, 80); } catch (e) { console.log('لا قوائم تشغيل أو تعذّر جلبها:', e.message); }
    const byId = new Map(entries.map((e) => [e.id, e]));
    for (let i = 0; i < pls.length; i++) {
      await jobPatch({ phase: 'قوائم التشغيل (' + (i + 1) + '/' + pls.length + ')' });
      try { const it = L.videoEntries(L.parseFlat(await L.ytTry(ctx, ['-j', '--flat-playlist', 'https://www.youtube.com/playlist?list=' + pls[i].id]))); const idx = playlists.length; let n = 0; it.forEach((v) => { const e = byId.get(v.id); if (e) { e.p.push(idx); n++; } }); if (n) playlists.push({ id: pls[i].id, t: clip(pls[i].t, 120) }); } catch (e) { console.log('تخطي قائمة', pls[i].t, e.message); }
    }
  }
  if (!entries.length) throw new Error('لم أجد أي فيديو في هذا الرابط');
  const reg = await registry();
  entries = entries.slice(0, 1500).map((e) => Object.assign(e, { t: clip(e.t, 120), k: reg[e.id] || '' }));
  await jobPatch({ status: 'done', phase: 'جاهزة للاختيار', kind, title: clip(title, 120), entries, playlists });
}

const CAP = 120;   // أقصى عدد قصائد في التشغيلة الواحدة؛ الباقي يُكمَل تلقائياً في التشغيلات التالية (مرتين يومياً)

async function importJob(jid, resume) {
  const jp = (o) => store.patch('ytJobs/' + jid, Object.assign({ upd: Date.now() }, o));
  const job = await store.get('ytJobs/' + jid); if (!job) throw new Error('لا توجد مهمة بهذا المعرّف');
  const reg = await registry();
  const base = resume && Array.isArray(job.rest) ? job.rest : (job.sel || []);
  const all = [...new Set(base.filter((x) => L.RE_ID.test(x)))].filter((v) => !(resume && (reg[v] === 'draft' || reg[v] === 'published')));
  if (!all.length) { await jp({ status: 'done', rest: [], resume: false, stop: false, paused: false, cur: '', stage: '', phase: 'اكتمل' }); return { ok: 0, skip: 0, fail: 0 }; }
  const ids = all.slice(0, CAP);
  const o = job.opts || {}, plOf = {}, tl = {};
  (job.entries || []).forEach((e) => { tl[e.id] = e.t; if (e.p && e.p.length) plOf[e.id] = e.p.map((i) => job.playlists && job.playlists[i]).filter(Boolean).map((p) => ({ id: p.id, t: p.t })); });
  const prev = (resume && job.res) || {};
  await jp({ status: 'running', phase: 'بدء الاستيراد (' + ids.length + ')', res: prev, done: 0, total: ids.length, rest: all, resume: false, stop: false, started: Date.now(), cur: '', stage: '', err: '' });
  ctx.stage = (s) => jp({ stage: s }).catch(() => {});
  ctx.meta = (m) => jp({ curT: m.t, curD: m.d }).catch(() => {});
  const res = await L.runBatch(ctx, ids, {
    reciter: o.reciter || '', cat: o.cat || 'لطميات', subs: o.subs !== false, plOf, job: jid, names: [o.reciter, job.title], force: true,
    shouldStop: async () => { const j = await store.get('ytJobs/' + jid).catch(() => null); return !!(j && j.stop); },
    onStart: (vid, i, n) => jp({ cur: vid, curT: tl[vid] || '', curD: 0, stage: 'بدء', phase: '(' + i + '/' + n + ') ' + clip(tl[vid], 60) }),
  }, (r, i, n, vid) => jp({ res: Object.assign({}, prev, r), done: i, total: n, cur: '', stage: '' }));
  const stopped = ctx.stopped, merged = Object.assign({}, prev, res), c = { ok: 0, skip: 0, fail: 0 }; Object.values(merged).forEach((r) => { c[r.st]++; });
  const rest = all.filter((v) => !(v in res));
  const msg = 'اكتمل: ' + c.ok + ' مسودة' + (c.skip ? ' · ' + c.skip + ' متخطّاة' : '') + (c.fail ? ' · ' + c.fail + ' فشلت' : '');
  await jp({ status: stopped ? 'stopped' : 'done', rest, res: merged, done: Object.keys(res).length, total: ids.length, cur: '', stage: '', stop: false, paused: stopped ? true : false,
    phase: stopped ? 'أُوقفت · ' + msg + ' · تبقّى ' + rest.length : msg + (rest.length ? ' · تبقّى ' + rest.length + ' تُستورد تلقائياً في التشغيلات القادمة' : '') });
  return c;
}

async function modeImport() {
  const j = await store.get('ytJobs/' + JOB);
  const c = await importJob(JOB, !!(j && j.resume));
  if (c.fail && !c.ok) process.exitCode = 1;
}

/* تصحيح الصور: القصائد المنشورة بلا صورة خاصة تأخذ صورتها من يوتيوب (مربّعة 1000px) بدل صورة الإصدار */
async function modeCovers() {
  await jobPatch({ status: 'running', phase: 'فحص القصائد المنشورة…', done: 0, total: 0, msg: '' });
  const todo = [];
  for (const d of (await store.list('ytDrafts', ['status', 'trackId', 'covFix'])).filter((x) => x.status === 'published' && x.trackId && !x.covFix)) {
    const t = await store.get('tracks/' + d.trackId);
    if (t && !t.cover && !t.covYt) todo.push({ vid: d.id, tid: d.trackId }); else await store.patch('ytDrafts/' + d.id, { covFix: 1 });   // سليمة أو محذوفة: تُعلَّم ولا تُفحص ثانية
  }
  let ok = 0, fail = 0; const bad = [];
  for (let i = 0; i < todo.length; i++) {
    const { vid, tid } = todo[i]; await jobPatch({ total: todo.length, done: i, phase: '(' + (i + 1) + '/' + todo.length + ')' });
    try {
      let buf = null;
      for (const n of ['maxresdefault', 'sddefault', 'hqdefault']) { const r = await fetch('https://i.ytimg.com/vi/' + vid + '/' + n + '.jpg'); if (r.ok) { const b = Buffer.from(await r.arrayBuffer()); if (b.length > 4000) { buf = b; break; } } }
      if (!buf) throw new Error('لا توجد صورة في يوتيوب');
      const src = path.join(WORK, 'cv-' + vid + '.jpg'), out = path.join(WORK, 'cvq-' + vid + '.jpg'); await writeFile(src, buf);
      await run('ffmpeg', ['-y', '-v', 'error', '-i', src, '-vf', "crop='min(iw,ih)':'min(iw,ih)',scale=1000:1000:flags=lanczos", '-q:v', '3', out]);
      await upload('c/yt' + vid + '.jpg', out, 'image/jpeg');
      await store.patch('tracks/' + tid, { cover: 'media/u/c/yt' + vid + '.jpg', covYt: 1 }); await store.patch('ytDrafts/' + vid, { covFix: 1 }); ok++;
    } catch (e) { fail++; bad.push(vid + ': ' + L.friendlyErr(e.message)); }
  }
  await jobPatch({ status: 'done', done: todo.length, total: todo.length, phase: todo.length ? 'صُحّحت ' + ok + ' قصيدة' + (fail ? ' · فشلت ' + fail : '') : 'لا شيء يحتاج تصحيحاً', msg: bad.slice(0, 5).join(' | ').slice(0, 600) });
  if (fail && !ok) process.exitCode = 1;
}

/* ضبط تاريخ إصدارات رُفعت يدوياً (الأسماء والتواريخ في relDates.json): كل قصيدة بلا تاريخ يوتيوب تأخذ تاريخ إصدارها مع حفظ ترتيبها؛ لا يُمَسّ إلا الحقلان at وatYt */
async function modeSetDates() {
  await jobPatch({ status: 'running', phase: 'ضبط تواريخ الإصدارات…', done: 0, total: 0, msg: '' });
  const map = JSON.parse(await readFile(new URL('./relDates.json', import.meta.url), 'utf8'));
  const albs = await store.list('albums', ['name', 'at']), tracks = await store.list('tracks', ['title', 'album', 'at', 'atYt', 'yt']);
  const lines = []; let n = 0;
  for (const [name, day] of Object.entries(map)) {
    const base = Date.parse(day + 'T12:00:00Z'), key = L.normAr(name).replace(/\s+/g, '');
    const ids = albs.filter((a) => L.normAr(a.name).replace(/\s+/g, '') === key).map((a) => a.id);
    if (!ids.length) { lines.push(name + ': الإصدار غير موجود'); continue; }
    for (const id of ids) {
      const ts = tracks.filter((t) => t.album === id && !t.atYt && !t.yt).sort((a, b) => (a.at || 0) - (b.at || 0) || String(a.id).localeCompare(b.id));
      for (let i = 0; i < ts.length; i++) { await store.patch('tracks/' + ts[i].id, { at: base + i * 1000, atYt: 1 }); n++; }
      if (ts.length) await store.patch('albums/' + id, { at: base + ts.length * 1000 });
      lines.push(name + ': ' + ts.length);
    }
  }
  await jobPatch({ status: 'done', phase: 'ضُبط تاريخ ' + n + ' قصيدة', msg: lines.join(' | ').slice(0, 800) });
  console.log(lines.join('\n'));
}

/* إكمال الدفعات المتبقية من مهام استيراد كبيرة (دفعة واحدة لكل تشغيل) */
async function drainQueue() {
  const q = (await store.list('ytJobs', ['rest', 'paused'])).filter((j) => j.id !== JOB && !j.paused && Array.isArray(j.rest) && j.rest.length);
  if (!q.length) return '';
  try { const c = await importJob(q[0].id, true); return 'إكمال الطابور: ' + c.ok + ' مسودة' + (c.fail ? ' · فشل ' + c.fail : ''); } catch (e) { return 'إكمال الطابور: ' + L.friendlyErr(e.message); }
}

async function modeScan() {
  const srcs = (await store.list('ytSrc')).filter((s) => s.auto !== false && s.url);
  await store.patch('ytJobs/' + JOB, { upd: Date.now(), status: 'running', phase: 'فحص القنوات (' + srcs.length + ')', kind: 'scan' });
  const titles = new Set((await store.list('tracks', ['title'])).map((t) => L.normAr(t.title)).filter(Boolean));
  const reg = await registry(); let nNew = 0, nFail = 0; const lines = [];
  for (const s of srcs) {
    const pu = L.parseUrl(s.url); if (!pu || (pu.kind !== 'channel' && pu.kind !== 'playlist')) { lines.push((s.name || s.url) + ': رابط غير صالح'); continue; }
    try {
      const cur = L.videoEntries(L.parseFlat(await L.ytTry(ctx, ['-j', '--flat-playlist', '--playlist-end', '30', pu.kind === 'channel' ? pu.url + '/videos' : pu.url])));
      if (!cur.length) { lines.push((s.name || s.url) + ': لا فيديوهات'); continue; }
      if (!s.base) { await store.patch('ytSrc/' + s.id, { base: true, seen: cur.map((e) => e.id), last: { at: Date.now(), n: 0, msg: 'سُجّل الوضع الحالي، وسيُستورد الجديد فقط' } }); lines.push((s.name || s.url) + ': سُجّل الوضع الحالي'); continue; }
      const seen = new Set(s.seen || []), keep = new Set(s.seen || []); const names = [s.reciter, s.name]; const todo = [];
      for (const e of cur) {
        if (seen.has(e.id) || reg[e.id]) { keep.add(e.id); continue; }
        if (e.x || (e.d && (e.d < 45 || e.d > 45 * 60))) { keep.add(e.id); continue; }        // بث أو قصير جداً أو طويل جداً
        if (titles.has(L.normAr(L.cleanTitle(e.t, names)))) {                                  // موجودة عندك سابقاً بالاسم
          await store.set('ytDrafts/' + e.id, { vid: e.id, status: 'skipped', ti: e.t, why: 'dup', at: Date.now() }); reg[e.id] = 'skipped'; keep.add(e.id); continue; }
        todo.push(e.id);
      }
      let ok = 0, fail = 0;
      if (todo.length) {
        const res = await L.runBatch(ctx, todo, { reciter: s.reciter || s.name || '', cat: s.cat || 'لطميات', subs: true, plOf: {}, job: JOB, names }, () => {});
        for (const [v, r] of Object.entries(res)) { if (r.st === 'ok') { ok++; reg[v] = 'draft'; keep.add(v); } else if (r.st === 'skip') keep.add(v); else fail++; }
      }
      nNew += ok; nFail += fail;
      await store.patch('ytSrc/' + s.id, { seen: [...keep].slice(-400), last: { at: Date.now(), n: ok, fail, msg: ok ? 'أُضيفت ' + ok + ' مسودة جديدة' : 'لا جديد' } });
      lines.push((s.name || s.url) + ': ' + (ok ? ok + ' جديدة' : 'لا جديد') + (fail ? ' · فشل ' + fail : ''));
    } catch (e) { nFail++; lines.push((s.name || s.url) + ': ' + L.friendlyErr(e.message)); await store.patch('ytSrc/' + s.id, { last: { at: Date.now(), n: 0, msg: L.friendlyErr(e.message) } }).catch(() => {}); }
  }
  const qm = await drainQueue(); if (qm) lines.push(qm);
  await store.patch('ytJobs/' + JOB, { upd: Date.now(), status: 'done', phase: nNew ? 'أُضيفت ' + nNew + ' مسودة جديدة' : 'لا جديد', msg: lines.join(' | ').slice(0, 900), nNew });
  if (nFail && !nNew && srcs.length) process.exitCode = 1;
}

try {
  await mkdir(WORK, { recursive: true });
  console.log('yt-dlp js-runtimes:', JSR, '· cookies:', !!COOKIES, '· mode:', MODE, '· job:', JOB);
  if (MODE === 'list') await modeList(); else if (MODE === 'import') await modeImport(); else if (MODE === 'scan') await modeScan(); else if (MODE === 'covers') await modeCovers(); else if (MODE === 'setdates') await modeSetDates(); else throw new Error('نمط غير معروف: ' + MODE);
} catch (e) {
  console.error('::error::' + e.message);
  try { await jobPatch({ status: 'failed', phase: 'فشل', msg: L.friendlyErr(e.message) }); } catch (x) { console.error('تعذّر تسجيل الفشل:', x.message); }
  process.exit(1);
}
