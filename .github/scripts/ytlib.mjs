// منطق استيراد يوتيوب لمنبر — دوال نقية + خط الاستيراد (تُحقن إليه الأدوات حتى يمكن اختباره بدون إنترنت)
import { readFile, stat, mkdir, rm, readdir } from 'node:fs/promises';
import path from 'node:path';

export const RE_ID = /^[A-Za-z0-9_-]{11}$/;
export const MAX_BYTES = 85 * 1024 * 1024;     // حد R2 في دالة الرفع 90 م.ب
export const MAX_DUR = 3 * 3600;               // أطول من 3 ساعات لا يُستورد
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/* ---------- الروابط ---------- */
export function parseUrl(raw) {
  let s = String(raw || '').trim(); if (!s) return null;
  if (!/^https?:\/\//i.test(s)) s = 'https://' + s;
  let u; try { u = new URL(s); } catch (e) { return null; }
  const h = u.hostname.toLowerCase().replace(/^(www\.|m\.|music\.)/, '');
  const P = (u.pathname || '/').replace(/\/+$/, '') || '/';
  const seg = P.split('/').filter(Boolean);
  if (h === 'youtu.be') { const id = seg[0]; return RE_ID.test(id || '') ? { kind: 'video', id, url: 'https://www.youtube.com/watch?v=' + id } : null; }
  if (h !== 'youtube.com') return null;
  const v = u.searchParams.get('v'), list = u.searchParams.get('list');
  if (P === '/watch' && RE_ID.test(v || '')) return { kind: 'video', id: v, url: 'https://www.youtube.com/watch?v=' + v };
  if ((seg[0] === 'shorts' || seg[0] === 'live' || seg[0] === 'embed') && RE_ID.test(seg[1] || '')) return { kind: 'video', id: seg[1], url: 'https://www.youtube.com/watch?v=' + seg[1] };
  if (P === '/playlist' && /^[A-Za-z0-9_-]{10,60}$/.test(list || '')) return { kind: 'playlist', id: list, url: 'https://www.youtube.com/playlist?list=' + list };
  if (seg[0] && seg[0][0] === '@') return { kind: 'channel', url: 'https://www.youtube.com/' + seg[0] };
  if (['channel', 'c', 'user'].includes(seg[0]) && seg[1]) return { kind: 'channel', url: 'https://www.youtube.com/' + seg[0] + '/' + seg[1] };
  if (seg[0] === 'browse') return { kind: 'unsupported', msg: 'افتح الألبوم أو القائمة واضغط «مشاركة» لتحصل على رابط فيه playlist?list=' };
  return null;
}

/* ---------- نصوص عربية ---------- */
export const normAr = (s) => String(s || '').normalize('NFKD').replace(/[ً-ٰٟـ]/g, '')
  .replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه').replace(/ؤ/g, 'و').replace(/ئ/g, 'ي')
  .toLowerCase().replace(/[^\p{L}\p{N}]+/gu, '');

const NOISE = /(official|video|audio|lyrics?|lyric|\bhd\b|\bhq\b|4k|1080p|720p|clip|الرسمي|رسمي|رسمية|فيديو|كليب|حصري|حصريا|حصرياً|بجودة|صوتي|مكتوبة|نسخة|جديد)/i;
export function cleanTitle(raw, names = []) {
  let s = String(raw || '').normalize('NFC').replace(/[‎‏‪-‮]/g, '');
  s = s.replace(/[\(\[\{（【]([^\)\]\}）】]*)[\)\]\}）】]/g, (m, inner) => (NOISE.test(inner) || /^[\d\s\/\-.:]*$/.test(inner)) ? ' ' : ' ' + inner + ' ');
  const parts = s.split(/\s*[|｜•·–—]\s*|\s+-\s+/).map((x) => x.trim()).filter(Boolean);
  const nn = names.map(normAr).filter((x) => x.length > 2);
  const keep = parts.filter((p) => { const n = normAr(p); if (!n) return false; if (nn.some((x) => n === x || n.includes(x) || (n.length >= 6 && x.includes(n)))) return false; return !(NOISE.test(p) && p.split(/\s+/).length <= 3); });
  let t = (keep[0] || parts[0] || s).replace(/\b(HD|HQ|4K|Official|Audio|Video)\b/gi, ' ').replace(/\s+/g, ' ').trim();
  t = t.replace(/^[\-–—:،,.\s]+|[\-–—:،,.\s]+$/g, '');
  return t || String(raw || '').trim();
}
export function guessPoet(desc) {
  for (const ln of String(desc || '').split(/\r?\n/)) {
    const l = ln.replace(/^[^\p{L}\p{N}]+/u, '').trim();
    const m = /^(?:كلمات|الكلمات|شعر|الشاعر|نظم|من نظم|تأليف)\s*[:：\-–]\s*(.+)$/u.exec(l);
    if (m) { const p = m[1].replace(/[^\p{L}\p{N})\s]+$/u, '').trim(); if (p.length >= 2 && p.length <= 60) return p; }
  }
  return '';
}

/* ---------- الترجمة ---------- */
export function pickSubLang(info) {
  const sub = Object.keys((info && info.subtitles) || {}).filter((k) => /^ar(-|$)/.test(k) && k !== 'live_chat');
  if (sub.length) return { kind: 'manual', lang: sub.includes('ar') ? 'ar' : sub[0] };
  const au = Object.keys((info && info.automatic_captions) || {});
  if (au.includes('ar-orig')) return { kind: 'auto', lang: 'ar-orig' };   // الأصلية فقط، أما ar فقد تكون ترجمة آلية
  return null;
}
export function parseJson3(j) {
  const out = [];
  for (const ev of (j && j.events) || []) {
    if (!ev.segs) continue;
    const text = ev.segs.map((s) => s.utf8 || '').join('').replace(/\s*\n\s*/g, ' ').replace(/\s+/g, ' ').trim();
    if (!text) continue;
    const t = (ev.tStartMs || 0) / 1000, e = t + (ev.dDurationMs || 0) / 1000;
    out.push({ t: +t.toFixed(2), e: +e.toFixed(2), l: text });
  }
  return out;
}
export function cuesToLines(cues, kind) {
  const out = [], recent = [];
  for (const c of cues) {
    const n = normAr(c.l); if (!n) continue;
    if (kind === 'auto' && recent.some((r) => r === n || r.includes(n))) continue;   // التسميات الآلية تتكرر بالتدرّج
    if (out.length && normAr(out[out.length - 1].l) === n) { out[out.length - 1].e = c.e; continue; }
    out.push({ t: c.t, e: c.e, l: c.l }); recent.push(n); if (recent.length > 4) recent.shift();
  }
  return out.slice(0, 600);
}

/* ---------- أخطاء مفهومة ---------- */
export function friendlyErr(msg) {
  const m = String(msg || '');
  if (/COOKIES_EXPIRED/.test(m)) return 'cookies منتهية أو مرفوضة: جدّد السر YT_COOKIES';
  if (/confirm you.?re not a bot|sign in to confirm/i.test(m)) return 'يوتيوب حظر سيرفر GitHub (أضف السر YT_COOKIES أو شغّل من جهازك)';
  if (/private video|video unavailable|has been removed|account.*terminated|not available/i.test(m)) return 'الفيديو خاص أو محذوف أو غير متاح';
  if (/members-only|join this channel|subscriber/i.test(m)) return 'الفيديو لأعضاء القناة فقط';
  if (/HTTP Error 429|too many requests/i.test(m)) return 'يوتيوب حدّ الطلبات مؤقتاً';
  if (/live event|is live|premiere|upcoming/i.test(m)) return 'بث مباشر أو لم يبدأ بعد';
  if (/ffmpeg|ffprobe/i.test(m)) return 'تعذّر تحويل الصوت (ffmpeg)';
  return m.replace(/\s+/g, ' ').slice(-220) || 'خطأ غير معروف';
}

/* ---------- Firestore (تحويل القيم) ---------- */
export function toFs(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.filter((x) => x !== undefined).map(toFs) } };
  if (typeof v === 'object') return { mapValue: { fields: toFields(v) } };
  return { stringValue: String(v) };
}
export function toFields(o) { const f = {}; for (const k of Object.keys(o)) if (o[k] !== undefined) f[k] = toFs(o[k]); return f; }
export function fromFs(f) {
  if (!f) return null;
  if ('stringValue' in f) return f.stringValue; if ('integerValue' in f) return Number(f.integerValue); if ('doubleValue' in f) return f.doubleValue;
  if ('booleanValue' in f) return f.booleanValue; if ('nullValue' in f) return null; if ('timestampValue' in f) return f.timestampValue;
  if ('arrayValue' in f) return (f.arrayValue.values || []).map(fromFs);
  if ('mapValue' in f) { const o = {}, m = f.mapValue.fields || {}; for (const k of Object.keys(m)) o[k] = fromFs(m[k]); return o; }
  return null;
}

/* ---------- محاولات yt-dlp ---------- */
export async function ytTry(ctx, args) {
  /* الترتيب: بدون cookies أولاً؛ إذا حظر يوتيوب السيرفر وكانت cookies مضبوطة نستعملها لبقية الطلبات (يُحفظ ذلك في ctx.needCookies) */
  const BOT = /not a bot|sign in to confirm|confirm you/i;
  let last;
  for (let i = 0; i < 2; i++) {
    try { return await ctx.ytdlp(args, { cookies: !!(ctx.hasCookies && ctx.needCookies) }); } catch (e) {
      last = e;
      if (ctx.hasCookies && !ctx.needCookies && BOT.test(e.message)) {
        ctx.needCookies = true;
        try { return await ctx.ytdlp(args, { cookies: true }); } catch (e2) { last = e2; }
      }
      if (ctx.needCookies && BOT.test(last.message)) throw new Error('COOKIES_EXPIRED');   // cookies مرفوضة: لا نكرر الطلب حتى لا نضرّ الحساب
      if (/private|unavailable|removed|members-only|live event|premiere/i.test(e.message)) break;   // لا فائدة من الإعادة
      await sleep(ctx.retryMs == null ? 6000 : ctx.retryMs);
    }
  }
  throw last;
}

/* ---------- استيراد فيديو واحد كمسودة ---------- */
export async function importOne(ctx, vid, o = {}) {
  if (!RE_ID.test(vid)) throw new Error('معرّف فيديو غير صالح');
  const prev = await ctx.store.get('ytDrafts/' + vid);
  /* المسودة/المنشورة لا تُعاد أبداً؛ المرفوضة والمتخطّاة تُعاد فقط إذا اختارها المالك يدوياً (force) */
  if (prev && ['draft', 'published', 'rejected', 'skipped'].includes(prev.status) && !(o.force && ['rejected', 'skipped'].includes(prev.status))) return { st: 'skip', msg: prev.status === 'published' ? 'منشورة سابقاً' : prev.status === 'rejected' ? 'مرفوضة سابقاً' : 'موجودة سابقاً' };
  const dir = path.join(ctx.work, vid); await rm(dir, { recursive: true, force: true }); await mkdir(dir, { recursive: true });
  const url = 'https://www.youtube.com/watch?v=' + vid;
  try {
    /* 1) المعلومات أولاً: حتى لا نحمّل بثاً مباشراً أو فيديو طويلاً جداً */
    if (ctx.stage) await ctx.stage('قراءة المعلومات');
    const info = JSON.parse(await ytTry(ctx, ['-J', '--no-playlist', url]));
    if (['is_live', 'is_upcoming', 'post_live'].includes(info.live_status)) return { st: 'skip', msg: 'بث مباشر أو لم يبدأ بعد' };
    if (!(info.duration > 5)) return { st: 'skip', msg: 'مدة غير صالحة' };
    if (info.duration > MAX_DUR) return { st: 'skip', msg: 'أطول من 3 ساعات' };
    /* 2) الصوت + الغلاف */
    if (ctx.stage) await ctx.stage('تنزيل الصوت');
    /* ملاحظة للمعاينة الحية */
    if (ctx.meta) await ctx.meta({ t: String(info.title || '').slice(0, 120), d: Math.round(info.duration || 0) });
    await ytTry(ctx, ['-f', 'bestaudio[ext=m4a]/bestaudio/best', '-x', '--audio-format', 'm4a', '--audio-quality', '0', '--no-playlist', '--write-thumbnail', '--convert-thumbnails', 'jpg', '-o', path.join(dir, 'a.%(ext)s'), url]);
    const audio = path.join(dir, 'a.m4a'); let sz; try { sz = (await stat(audio)).size; } catch (e) { throw new Error('لم يُنتج ملف الصوت'); }
    if (sz < 30 * 1024) throw new Error('ملف الصوت صغير جداً (تنزيل ناقص)');
    if (sz > MAX_BYTES) return { st: 'skip', msg: 'حجم الصوت أكبر من 85 م.ب' };
    const dur = Math.round(parseFloat((await ctx.exec('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', audio])).trim()));
    if (!(dur > 0)) throw new Error('تعذّر قراءة مدة الصوت');
    if (Math.abs(dur - info.duration) > Math.max(5, info.duration * 0.05)) throw new Error('مدة الصوت (' + dur + 'ث) لا تطابق الفيديو (' + info.duration + 'ث) — تنزيل ناقص');
    /* 3) الغلاف مربّعاً (قصّ المنتصف) */
    let coverFile = '';
    const th = path.join(dir, 'a.jpg');
    try { await stat(th); coverFile = path.join(dir, 'cover.jpg'); await ctx.exec('ffmpeg', ['-y', '-v', 'error', '-i', th, '-vf', "crop='min(iw,ih)':'min(iw,ih)',scale=1000:1000:flags=lanczos", '-q:v', '3', coverFile]); await stat(coverFile); } catch (e) { coverFile = ''; }
    /* 4) الترجمة الأصلية (اختيارية، فشلها لا يُفشل الاستيراد) */
    if (ctx.stage) await ctx.stage('الترجمة الأصلية');
    let subs = null, warn = '';
    const sl = o.subs === false ? null : pickSubLang(info);
    if (sl) {
      try {
        await ytTry(ctx, ['--skip-download', sl.kind === 'manual' ? '--write-subs' : '--write-auto-subs', '--sub-langs', sl.lang, '--sub-format', 'json3', '--no-playlist', '-o', path.join(dir, 's.%(ext)s'), url]);
        const f = (await readdir(dir)).find((x) => /^s\..+\.json3$/.test(x));
        if (f) { const lines = cuesToLines(parseJson3(JSON.parse(await readFile(path.join(dir, f), 'utf8'))), sl.kind); if (lines.length) subs = { kind: sl.kind, lang: sl.lang, lines }; }
      } catch (e) { warn = 'تعذّر جلب الترجمة'; }
    }
    /* 5) الرفع والتحقق */
    if (ctx.stage) await ctx.stage('رفع الصوت والغلاف');
    const akey = 'a/yt' + vid + '.m4a', ckey = 'c/yt' + vid + '.jpg';
    await ctx.upload(akey, audio, 'audio/mp4');
    if (coverFile) await ctx.upload(ckey, coverFile, 'image/jpeg');
    /* 6) المسودة */
    const names = [o.reciter, info.channel, info.uploader, ...(o.names || [])].filter(Boolean);
    const draft = {
      vid, status: 'draft', url, ti: String(info.title || ''), at: Date.now(), job: o.job || '',
      g: { title: cleanTitle(info.title, names), reciter: o.reciter || info.channel || info.uploader || '', poet: guessPoet(info.description), cat: o.cat || 'لطميات' },
      desc: String(info.description || '').slice(0, 3000), ud: String(info.upload_date || ''), dur, size: sz,
      audio: 'media/u/' + akey, cover: coverFile ? 'media/u/' + ckey : '', ch: String(info.channel || ''), chId: String(info.channel_id || ''),
      pl: o.pl || [], sk: subs ? subs.kind : '', sl: subs ? subs.lang : '', subs: subs ? subs.lines : [],
    };
    await ctx.store.set('ytDrafts/' + vid, draft);
    return { st: 'ok', msg: warn || (subs ? (subs.kind === 'manual' ? 'مع ترجمة أصلية' : 'مع ترجمة آلية') : ''), title: draft.g.title };
  } finally { await rm(dir, { recursive: true, force: true }).catch(() => {}); }
}

/* ---------- تشغيل دفعة ---------- */
export async function runBatch(ctx, ids, o, onProgress) {
  const res = {}; let i = 0; ctx.stopped = false;
  for (const vid of ids) {
    if (o.shouldStop && await o.shouldStop()) { ctx.stopped = true; break; }
    i++;
    if (o.onStart) await o.onStart(vid, i, ids.length);
    try { res[vid] = await importOne(ctx, vid, Object.assign({}, o, { pl: (o.plOf && o.plOf[vid]) || [] })); }
    catch (e) { res[vid] = { st: 'fail', msg: friendlyErr(e.message) }; }
    if (onProgress) await onProgress(res, i, ids.length, vid);
    if (i < ids.length) await sleep(ctx.pauseMs == null ? 4000 : ctx.pauseMs);
  }
  return res;
}

/* ---------- قراءة قوائم yt-dlp المسطّحة ---------- */
export function parseFlat(text) {
  const out = [];
  for (const ln of String(text || '').split(/\r?\n/)) { const s = ln.trim(); if (s[0] !== '{') continue; try { out.push(JSON.parse(s)); } catch (e) {} }
  return out;
}
export function videoEntries(list) {
  const seen = new Set(), out = [];
  for (const e of list) {
    if (!e || !RE_ID.test(e.id || '') || seen.has(e.id)) continue; seen.add(e.id);
    const bad = e.availability && !['public', 'unlisted'].includes(e.availability) ? 'للأعضاء أو خاص' : (['is_live', 'is_upcoming'].includes(e.live_status) ? 'بث مباشر' : '');
    out.push({ id: e.id, t: String(e.title || ''), d: Math.round(e.duration || 0), x: bad });
  }
  return out;
}
export function playlistEntries(list) {
  const out = [];
  for (const e of list) { const id = e && (e.id || ''); if (id && !RE_ID.test(id) && id.length >= 12 && e.title) out.push({ id, t: String(e.title) }); }
  return out;
}
