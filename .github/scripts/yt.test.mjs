import test from 'node:test';
import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { writeFile, mkdtemp, readdir } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import * as L from './ytlib.mjs';

const run = (c, a) => new Promise((res, rej) => execFile(c, a, (e, so, se) => e ? rej(new Error(String(se))) : res(String(so))));

test('parseUrl: فيديو وقائمة وقناة وموسيقى', () => {
  assert.deepEqual(L.parseUrl('https://youtu.be/dQw4w9WgXcQ?si=abc'), { kind: 'video', id: 'dQw4w9WgXcQ', url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' });
  assert.equal(L.parseUrl('https://music.youtube.com/watch?v=dQw4w9WgXcQ&list=RDAMVM').kind, 'video');
  assert.equal(L.parseUrl('https://music.youtube.com/playlist?list=OLAK5uy_abcdefghijklmnop').kind, 'playlist');
  assert.equal(L.parseUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLabcdefghijklmnop').kind, 'video');
  assert.deepEqual(L.parseUrl('https://youtube.com/@basimkarbalaei?si=dvbTVF22OHpbW7Hi'), { kind: 'channel', url: 'https://www.youtube.com/@basimkarbalaei' });
  assert.equal(L.parseUrl('https://www.youtube.com/@basimkarbalaei/videos').url, 'https://www.youtube.com/@basimkarbalaei');
  assert.equal(L.parseUrl('https://www.youtube.com/channel/UCabc123/featured').url, 'https://www.youtube.com/channel/UCabc123');
  assert.equal(L.parseUrl('https://www.youtube.com/shorts/dQw4w9WgXcQ').id, 'dQw4w9WgXcQ');
  assert.equal(L.parseUrl('https://music.youtube.com/browse/MPREb_x').kind, 'unsupported');
  assert.equal(L.parseUrl('https://example.com/watch?v=dQw4w9WgXcQ'), null);
  assert.equal(L.parseUrl('نص عشوائي'), null);
  assert.equal(L.parseUrl(''), null);
});

test('cleanTitle: يحذف اسم الرادود والوسوم ويبقي العنوان', () => {
  const n = ['باسم الكربلائي'];
  assert.equal(L.cleanTitle('يا سبع الدجيل | باسم الكربلائي', n), 'يا سبع الدجيل');
  assert.equal(L.cleanTitle('باسم الكربلائي - خط الشعائر (Official Video)', n), 'خط الشعائر');
  assert.equal(L.cleanTitle('نار ودخان ودماء [HD] | الرادود باسم الكربلائي | محرم 1446', n), 'نار ودخان ودماء');
  assert.equal(L.cleanTitle('يا أكبر جبل', n), 'يا أكبر جبل');
  assert.equal(L.cleanTitle('يا حسين (يا مظلوم) - باسم الكربلائي', n), 'يا حسين يا مظلوم');
  assert.equal(L.cleanTitle('باسم الكربلائي', n), 'باسم الكربلائي');   // لا يفرغ العنوان أبداً
});

test('guessPoet من الوصف', () => {
  assert.equal(L.guessPoet('🎙 الرادود: باسم\n✍️ كلمات: السيد فلان الموسوي\nمونتاج: x'), 'السيد فلان الموسوي');
  assert.equal(L.guessPoet('- الشاعر : حيدر الحلي ✨'), 'حيدر الحلي');
  assert.equal(L.guessPoet('اشترك بالقناة'), '');
});

test('normAr يوحّد الهمزات والتشكيل', () => {
  assert.equal(L.normAr('يَا أَكْبَرَ جَبَل!'), L.normAr('يا اكبر جبل'));
  assert.notEqual(L.normAr('يا حسين'), L.normAr('يا عباس'));
});

test('الترجمة: اختيار اللغة وتحليل json3 وإزالة التكرار', () => {
  assert.deepEqual(L.pickSubLang({ subtitles: { ar: [{}], en: [{}] }, automatic_captions: { 'ar-orig': [{}] } }), { kind: 'manual', lang: 'ar' });
  assert.deepEqual(L.pickSubLang({ subtitles: {}, automatic_captions: { 'ar-orig': [{}], ar: [{}] } }), { kind: 'auto', lang: 'ar-orig' });
  assert.equal(L.pickSubLang({ subtitles: {}, automatic_captions: { ar: [{}], en: [{}] } }), null);   // ar وحدها قد تكون ترجمة آلية
  assert.equal(L.pickSubLang({}), null);
  const cues = L.parseJson3({ events: [{ tStartMs: 1000, dDurationMs: 2000, segs: [{ utf8: 'يا حسين' }] }, { tStartMs: 3000, segs: [] }, { tStartMs: 3000, dDurationMs: 1500, segs: [{ utf8: 'يا حسين' }, { utf8: '\nيا مظلوم' }] }] });
  assert.equal(cues.length, 2); assert.equal(cues[0].t, 1); assert.equal(cues[0].e, 3); assert.equal(cues[1].l, 'يا حسين يا مظلوم');
  const auto = L.cuesToLines([{ t: 1, e: 2, l: 'يا حسين' }, { t: 2, e: 3, l: 'يا حسين' }, { t: 3, e: 4, l: 'يا مظلوم يا حسين' }, { t: 4, e: 5, l: 'يا حسين' }], 'auto');
  assert.deepEqual(auto.map((x) => x.l), ['يا حسين', 'يا مظلوم يا حسين']);
});

test('Firestore: تحويل القيم ذهاباً وإياباً', () => {
  const o = { a: 'x', n: 5, f: 1.5, b: true, z: null, arr: [{ id: 'p', t: 'q' }, 'k'], m: { 'a-b': [1, 2] } };
  assert.deepEqual(L.fromFs({ mapValue: { fields: L.toFields(o) } }), o);
  assert.equal(L.toFields({ u: undefined }).u, undefined);
});

test('friendlyErr', () => {
  assert.match(L.friendlyErr('Sign in to confirm you’re not a bot'), /cookies/);
  assert.match(L.friendlyErr('ERROR: Private video'), /خاص/);
});

/* ---------- الخط الكامل بأدوات مزيّفة (ffmpeg حقيقي) ---------- */
async function mk() {
  const work = await mkdtemp(path.join(os.tmpdir(), 'yt-'));
  const info = { title: 'يا سبع الدجيل | باسم الكربلائي (Official Audio)', duration: 6, channel: 'باسم الكربلائي', channel_id: 'UCx', upload_date: '20251101', description: 'كلمات: السيد فلان\nاشترك', subtitles: { ar: [{}] }, automatic_captions: {}, live_status: 'not_live' };
  const store = new Map(), up = [];
  const ctx = {
    work, hasCookies: false, retryMs: 0, pauseMs: 0, info,
    exec: run,
    store: { get: async (p) => store.get(p) || null, set: async (p, o) => { store.set(p, o); } },
    upload: async (k, f, t) => { up.push([k, t]); return 1; },
    async ytdlp(args) {
      if (args.includes('-J')) return JSON.stringify(ctx.info);
      const o = args[args.indexOf('-o') + 1], d = path.dirname(o);
      if (args.includes('--skip-download')) { await writeFile(path.join(d, 's.ar.json3'), JSON.stringify({ events: [{ tStartMs: 500, dDurationMs: 1500, segs: [{ utf8: 'يا سبع الدجيل' }] }] })); return ''; }
      await run('ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=' + (ctx.audioDur || 6), '-c:a', 'aac', path.join(d, 'a.m4a')]);
      await run('ffmpeg', ['-y', '-v', 'error', '-f', 'lavfi', '-i', 'color=c=red:s=1280x720:d=1', '-frames:v', '1', path.join(d, 'a.jpg')]);
      return '';
    },
  };
  return { ctx, store, up, work };
}

test('importOne: مسودة كاملة (صوت + غلاف مربّع + ترجمة)', async () => {
  const { ctx, store, up, work } = await mk();
  const r = await L.importOne(ctx, 'dQw4w9WgXcQ', { reciter: 'باسم الكربلائي', cat: 'لطميات', pl: [{ id: 'PLabcdefghijklmn', t: 'إصدار' }], job: 'j1' });
  assert.equal(r.st, 'ok');
  const d = store.get('ytDrafts/dQw4w9WgXcQ');
  assert.equal(d.status, 'draft'); assert.equal(d.g.title, 'يا سبع الدجيل'); assert.equal(d.g.poet, 'السيد فلان'); assert.equal(d.g.reciter, 'باسم الكربلائي');
  assert.equal(d.audio, 'media/u/a/ytdQw4w9WgXcQ.m4a'); assert.equal(d.cover, 'media/u/c/ytdQw4w9WgXcQ.jpg');
  assert.equal(d.sk, 'manual'); assert.equal(d.subs.length, 1); assert.equal(d.pl[0].t, 'إصدار'); assert.ok(d.dur >= 5 && d.dur <= 7);
  assert.deepEqual(up.map((x) => x[0]), ['a/ytdQw4w9WgXcQ.m4a', 'c/ytdQw4w9WgXcQ.jpg']);
  assert.deepEqual(await readdir(work), []);                      // نُظّف مجلد العمل
  assert.match(up[0][0], /^(a|c)\/[A-Za-z0-9_-]{3,64}\.(m4a|jpg)$/);   // مطابق لقاعدة دالة الرفع
});

test('importOne: يتخطى المكرر والبث وغير الصالح ويفشل عند التنزيل الناقص', async () => {
  let m = await mk();
  await L.importOne(m.ctx, 'dQw4w9WgXcQ', {});
  assert.equal((await L.importOne(m.ctx, 'dQw4w9WgXcQ', {})).st, 'skip');                                   // مسودة موجودة
  m.store.set('ytDrafts/aaaaaaaaaaa', { status: 'rejected' });
  assert.equal((await L.importOne(m.ctx, 'aaaaaaaaaaa', {})).st, 'skip');                                   // مرفوضة سابقاً
  assert.equal((await L.importOne(m.ctx, 'aaaaaaaaaaa', { force: true })).st, 'ok');                         // يختارها المالك يدوياً
  m.store.set('ytDrafts/bbbbbbbbbbb', { status: 'published' });
  assert.equal((await L.importOne(m.ctx, 'bbbbbbbbbbb', { force: true })).st, 'skip');                       // المنشورة لا تُعاد حتى مع force
  m = await mk(); m.ctx.info.live_status = 'is_live'; assert.equal((await L.importOne(m.ctx, 'cccccccccc1', {})).st, 'skip');
  m = await mk(); m.ctx.info.duration = 4 * 3600; assert.equal((await L.importOne(m.ctx, 'cccccccccc2', {})).st, 'skip');
  m = await mk(); m.ctx.audioDur = 2; await assert.rejects(() => L.importOne(m.ctx, 'cccccccccc3', {}), /تنزيل ناقص/);   // مدة الصوت لا تطابق
  assert.equal(m.store.size, 0); assert.equal(m.up.length, 0);                                               // لا مسودة ولا رفع عند الفشل
  await assert.rejects(() => L.importOne(m.ctx, 'bad', {}), /غير صالح/);
});

test('importOne: فشل جلب الترجمة لا يُفشل الاستيراد', async () => {
  const m = await mk(); const orig = m.ctx.ytdlp;
  m.ctx.ytdlp = async (a, o) => { if (a.includes('--skip-download')) throw new Error('HTTP Error 429'); return orig(a, o); };
  const r = await L.importOne(m.ctx, 'dQw4w9WgXcQ', {});
  assert.equal(r.st, 'ok'); assert.equal(m.store.get('ytDrafts/dQw4w9WgXcQ').subs.length, 0); assert.match(r.msg, /الترجمة/);
});

test('runBatch: فشل واحد لا يوقف الباقي، وcookies فقط عند الحظر', async () => {
  const m = await mk(); m.ctx.hasCookies = true; const seen = []; const orig = m.ctx.ytdlp;
  m.ctx.ytdlp = async (a, o) => { seen.push(!!(o && o.cookies)); if (a.includes('-J') && a[a.length - 1].endsWith('bbbbbbbbbb1')) throw new Error('Sign in to confirm you’re not a bot'); return orig(a, o); };
  const res = await L.runBatch(m.ctx, ['aaaaaaaaaa1', 'bbbbbbbbbb1', 'cccccccccc1'], {}, null);
  assert.equal(res.aaaaaaaaaa1.st, 'ok'); assert.equal(res.bbbbbbbbbb1.st, 'fail'); assert.match(res.bbbbbbbbbb1.msg, /cookies/); assert.equal(res.cccccccccc1.st, 'ok');
  assert.ok(seen.includes(true));
});

test('قراءة القوائم المسطّحة', () => {
  const txt = [JSON.stringify({ id: 'dQw4w9WgXcQ', title: 'أ', duration: 300 }), 'تحذير', JSON.stringify({ id: 'dQw4w9WgXcQ', title: 'مكرر' }), JSON.stringify({ id: 'eeeeeeeeeee', title: 'ب', live_status: 'is_live' }), JSON.stringify({ id: 'PLabcdefghijklmnopqrstuv', title: 'قائمة', _type: 'url' })].join('\n');
  const l = L.parseFlat(txt);
  assert.equal(L.videoEntries(l).length, 2); assert.equal(L.videoEntries(l)[1].x, 'بث مباشر');
  assert.deepEqual(L.playlistEntries(l), [{ id: 'PLabcdefghijklmnopqrstuv', t: 'قائمة' }]);
});
