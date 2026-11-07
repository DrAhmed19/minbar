/* فلتر التعليقات: يكشف الألفاظ البذيئة حتى لو كانت مموّهة بمسافات أو نقاط أو رموز أو تكرار أحرف أو اختلاف الهمزات.
   النتيجة: { st: 'ok' | 'review' | 'block', hit } */
(function (root) {
  'use strict';
  /* توحيد الحروف العربية */
  const MAP = { 'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ئ': 'ي', 'ؤ': 'و', 'ة': 'ه', 'گ': 'ك', 'ڪ': 'ك', 'ک': 'ك', 'ی': 'ي', 'ي': 'ي', 'چ': 'ج', 'ڤ': 'ف', 'پ': 'ب', 'ژ': 'ز' };
  /* بدائل لاتينية وأرقام يستعملها البعض للتمويه (عربيزي) */
  const LAT = [[/kh/g, 'خ'], [/sh/g, 'ش'], [/th/g, 'ث'], [/ch/g, 'ج'], [/gh/g, 'غ'], [/3/g, 'ع'], [/7/g, 'ح'], [/5/g, 'خ'], [/2/g, 'ا'], [/9/g, 'ق'], [/6/g, 'ط'], [/8/g, 'غ'], [/k/g, 'ك'], [/s/g, 'س'], [/z/g, 'ز'], [/n/g, 'ن'], [/y/g, 'ي'], [/i/g, 'ي'], [/e/g, 'ي'], [/a/g, 'ا'], [/o/g, 'و'], [/u/g, 'و'], [/w/g, 'و'], [/r/g, 'ر'], [/b/g, 'ب'], [/m/g, 'م'], [/t/g, 'ت'], [/d/g, 'د'], [/q/g, 'ق'], [/f/g, 'ف'], [/l/g, 'ل'], [/h/g, 'ه'], [/j/g, 'ج'], [/g/g, 'ك'], [/p/g, 'ب'], [/v/g, 'ف'], [/c/g, 'ك']];
  function norm(s) {
    s = String(s || '').toLowerCase().replace(/[ً-ٰٟۖ-ۭـ]/g, ''); /* تشكيل وتطويل */
    let o = ''; for (const ch of s) o += MAP[ch] || ch;
    if (/[a-z0-9]/.test(o)) { let l = o; LAT.forEach(([r, v]) => { l = l.replace(r, v); }); o = l; }
    return o;
  }
  const ARL = /[ء-ي]/;
  /* يرجع الكلمات بعد التنظيف، مع دمج الأحرف المفرّقة (ك س م → كسم) وطيّ التكرار (كسسسس → كس) */
  function tokens(s) {
    const n = norm(s), raw = n.split(/[^ء-ي]+/).filter(Boolean), out = [];
    let run = '';
    raw.forEach((w) => { if (w.length <= 1) { run += w; return; } if (run) { out.push(run); run = ''; } out.push(w); });
    if (run) out.push(run);
    return out.map((w) => w.replace(/(.)\1+/g, '$1'));
  }
  /* كلمات تُحظر عند مطابقتها كلمةً كاملة (قصيرة، حتى لا نحظر كلمات سليمة مثل «عكس» و«انكسر») */
  const BW = [
    /^(و|يا|ف)?كس(م|ام|امك|مك|ك|ه|ها|هم|كم|خت|ختك|ختكم|امكم|اختك|اخت|ين)?$/, /^(و|يا)?كسخت(ك|كم|ه)?$/, /^(و|يا)?كسم(ك|كم)?$/,
    /^(و|يا)?اير(ي|ك|ه|كم|هم|نا)?$/, /^(و|يا)?عير(ي|ك|ه|كم)?$/, /^(و|يا)?زب(ي|ك|ه|كم|ر)?$/, /^(و|يا)?طيز(ك|ه|كم|ي)?$/,
    /^(ا|ن|ي|ت)?ني(ك|ج|ش|چ)(ك|ه|كم|ها|م|و)?$/, /^(ا|ن|ي|ت)?نيج(ك|ه|كم|ها)?$/, /^(ا|ن|ي)?نيش(ك|ه|كم|ها)?$/, /^(ا|و)?نيكو?$/,
    /^(و|يا)?(منيوك|منيوج|منيوش|منيكه|منيوكه|منيوكين)$/, /^(و|يا)?(قحب|قحبه|كحبه|قحاب|كحاب)$/, /^(و|يا)?(شرموط|شرموطه|شراميط)$/,
    /^(و|يا)?(عاهر|عاهره|عواهر)$/, /^(و|يا)?(ديوث|كواد|قواد|كوادين|قوادين)$/, /^(و|يا)?(لوطي|مخنث|مفعول)$/, /^(و|يا)?(نغل|نغول|فرخ|فروخ|زنيم)$/,
    /^(و|يا)?(خنيث|خنيثه)$/
  ];
  /* مقاطع طويلة تُحظر حتى لو التصقت بغيرها أو مُوّهت بالنقاط */
  const BS = ['كسامك', 'كساختك', 'كسختك', 'كسمك', 'منيوك', 'شرموط', 'قحبه', 'انيجك', 'انيكك', 'انيشك', 'انيكم', 'انيجكم', 'ايريب', 'ايرك', 'ديوث', 'عاهره', 'كوادين', 'ابنالقحبه', 'ابنالكلب', 'يلعنابوك', 'ابوكالكلب', 'نيجامك', 'نيكامك', 'نيشامك'];
  /* تحتاج مراجعة يدوية: إهانات خفيفة أو كلمات لها أكثر من معنى */
  const RW = [/^(و|يا)?(كلب|كلاب|جلب|جلاب|حمار|حمير|زمال|حيوان|حيوانات|بهيمه|غبي|اغبياء|تافه|تافهين|زباله|خرا|خره|منحط|واطي|سافل|سافله|حقير|وسخ|وسخين|جحش|ثور)$/, /^(و|يا)?(اخرس|انجب|انقلع|طز|عيب)$/];
  /* هيكل التمويه: حروف تُستبدل عمداً (كش امك، صب، جلب...) */
  const SK = { 'ش': 'س', 'ص': 'س', 'ث': 'س', 'ق': 'ك', 'ج': 'ك', 'ظ': 'ز', 'ض': 'ز', 'ذ': 'ز', 'ط': 'ت' };
  const skel = (w) => { let o = ''; for (const ch of w) o += SK[ch] || ch; return o.replace(/(.)\1+/g, '$1'); };
  const BSK = BS.map(skel), VOW = ['كسمك', 'كسختك', 'كسمكم'];
  let EXTRA = { block: [], review: [], allow: [] };
  function setExtra(o) { EXTRA = { block: (o && o.block) || [], review: (o && o.review) || [], allow: (o && o.allow) || [] }; }
  function check(s) {
    const tk = tokens(s); if (!tk.length) return { st: 'ok' };
    const allow = new Set(EXTRA.allow.map((w) => tokens(w).join('')));
    const comp = tk.join(''), compAll = norm(s).replace(/[^ء-ي]+/g, '').replace(/(.)\1+/g, '$1');
    for (const w of tk) { if (allow.has(w)) continue; for (const r of BW) if (r.test(w)) return { st: 'block', hit: w }; }
    for (const p of BS) if (comp.includes(p) || compAll.includes(p)) return { st: 'block', hit: p };
    const sc = skel(comp), sa = skel(compAll), sv = sa.replace(/[اوي]/g, '');
    for (let i = 0; i < BSK.length; i++) if (sc.includes(BSK[i]) || sa.includes(BSK[i])) return { st: 'block', hit: BS[i] };
    for (const p of VOW) if (sv.includes(p)) return { st: 'block', hit: p };
    for (const w of tk) { if (w.length < 3 || allow.has(w)) continue; const k = skel(w); if (k !== w) for (const r of BW) if (r.test(k)) return { st: 'block', hit: w }; }
    for (const e of EXTRA.block) { const p = tokens(e).join(''); if (p && (tk.includes(p) || (p.length >= 4 && compAll.includes(p)))) return { st: 'block', hit: p }; }
    for (const w of tk) { if (allow.has(w)) continue; for (const r of RW) if (r.test(w)) return { st: 'review', hit: w }; }
    for (const e of EXTRA.review) { const p = tokens(e).join(''); if (p && (tk.includes(p) || (p.length >= 4 && compAll.includes(p)))) return { st: 'review', hit: p }; }
    /* روابط، تكرار مزعج، أو كلام بلا أحرف عربية ولا معنى */
    if (/(https?:|www\.|\.com|\.net|t\.me|@\w)/i.test(s)) return { st: 'block', hit: 'رابط' };
    if (/(.)\1{7,}/.test(s)) return { st: 'review', hit: 'تكرار' };
    if (!ARL.test(norm(s)) && !/^[\p{Emoji}\s]+$/u.test(s)) return { st: 'review', hit: 'غير عربي' };
    return { st: 'ok' };
  }
  root.CMF = { check, norm, tokens, setExtra };
})(window);
