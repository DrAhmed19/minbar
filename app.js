const ICONS = {"trim": "<circle cx=\"6\" cy=\"6\" r=\"3\" /> <path d=\"M8.12 8.12 12 12\" /> <path d=\"M20 4 8.12 15.88\" /> <circle cx=\"6\" cy=\"18\" r=\"3\" /> <path d=\"M14.8 14.8 20 20\" />", "home": "<path d=\"m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z\" /> <path d=\"M9 22V12h6v10\" />", "gear": "<path d=\"M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z\" /> <circle cx=\"12\" cy=\"12\" r=\"3\" />", "back": "<path d=\"m9 18 6-6-6-6\" />", "chevl": "<path d=\"m15 18-6-6 6-6\" />", "lyrics": "<path d=\"M3 6h18\" /> <path d=\"M3 12h18\" /> <path d=\"M3 18h12\" />", "media": "<path d=\"m12.296 3.464 3.02 3.956\" /> <path d=\"M20.2 6 3 11l-.9-2.4c-.3-1.1.3-2.2 1.3-2.5l13.5-4c1.1-.3 2.2.3 2.5 1.3z\" /> <path d=\"M3 11h18v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z\" /> <path d=\"m6.18 5.276 3.1 3.899\" />", "text": "<path d=\"M13 21h8\" /> <path d=\"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z\" />", "design": "<rect width=\"18\" height=\"7\" x=\"3\" y=\"3\" rx=\"1\" /> <rect width=\"9\" height=\"7\" x=\"3\" y=\"14\" rx=\"1\" /> <rect width=\"5\" height=\"7\" x=\"16\" y=\"14\" rx=\"1\" />", "color": "<path d=\"M12 22a1 1 0 0 1 0-20 10 9 0 0 1 10 9 5 5 0 0 1-5 5h-2.25a1.75 1.75 0 0 0-1.4 2.8l.3.4a1.75 1.75 0 0 1-1.4 2.8z\" /> <circle cx=\"13.5\" cy=\"6.5\" r=\".5\" fill=\"currentColor\" /> <circle cx=\"17.5\" cy=\"10.5\" r=\".5\" fill=\"currentColor\" /> <circle cx=\"6.5\" cy=\"12.5\" r=\".5\" fill=\"currentColor\" /> <circle cx=\"8.5\" cy=\"7.5\" r=\".5\" fill=\"currentColor\" />", "font": "<path d=\"m15 16 2.536-7.328a1.02 1.02 1 0 1 1.928 0L22 16\" /> <path d=\"M15.697 14h5.606\" /> <path d=\"m2 16 4.039-9.69a.5.5 0 0 1 .923 0L11 16\" /> <path d=\"M3.304 13h6.392\" />", "frame": "<line x1=\"22\" x2=\"2\" y1=\"6\" y2=\"6\" /> <line x1=\"22\" x2=\"2\" y1=\"18\" y2=\"18\" /> <line x1=\"6\" x2=\"6\" y1=\"2\" y2=\"22\" /> <line x1=\"18\" x2=\"18\" y1=\"2\" y2=\"22\" />", "filter": "<path d=\"m21.64 3.64-1.28-1.28a1.21 1.21 0 0 0-1.72 0L2.36 18.64a1.21 1.21 0 0 0 0 1.72l1.28 1.28a1.2 1.2 0 0 0 1.72 0L21.64 5.36a1.2 1.2 0 0 0 0-1.72\" /> <path d=\"m14 7 3 3\" /> <path d=\"M5 6v4\" /> <path d=\"M19 14v4\" /> <path d=\"M10 2v2\" /> <path d=\"M7 8H3\" /> <path d=\"M21 16h-4\" /> <path d=\"M11 3H9\" />", "logo": "<path d=\"M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z\" />", "tpl": "<path d=\"M12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83z\" /> <path d=\"M2 12a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 12\" /> <path d=\"M2 17a1 1 0 0 0 .58.91l8.6 3.91a2 2 0 0 0 1.65 0l8.58-3.9A1 1 0 0 0 22 17\" />", "set": "<path d=\"M14 17H5\" /> <path d=\"M19 7h-9\" /> <circle cx=\"17\" cy=\"17\" r=\"3\" /> <circle cx=\"7\" cy=\"7\" r=\"3\" />", "undo": "<path d=\"M9 14 4 9l5-5\" /> <path d=\"M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11\" />", "redo": "<path d=\"m15 14 5-5-5-5\" /> <path d=\"M20 9H9.5A5.5 5.5 0 0 0 4 14.5A5.5 5.5 0 0 0 9.5 20H13\" />", "play": "<path d=\"M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z\" />", "pause": "<rect x=\"14\" y=\"3\" width=\"5\" height=\"18\" rx=\"1\" /> <rect x=\"5\" y=\"3\" width=\"5\" height=\"18\" rx=\"1\" />", "chev": "<path d=\"m6 9 6 6 6-6\" />", "close": "<path d=\"M18 6 6 18\" /> <path d=\"m6 6 12 12\" />", "download": "<path d=\"M12 15V3\" /> <path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\" /> <path d=\"m7 10 5 5 5-5\" />", "share": "<circle cx=\"18\" cy=\"5\" r=\"3\" /> <circle cx=\"6\" cy=\"12\" r=\"3\" /> <circle cx=\"18\" cy=\"19\" r=\"3\" /> <line x1=\"8.59\" x2=\"15.42\" y1=\"13.51\" y2=\"17.49\" /> <line x1=\"15.41\" x2=\"8.59\" y1=\"6.51\" y2=\"10.49\" />", "audio": "<path d=\"M2 10v3\" /> <path d=\"M6 6v11\" /> <path d=\"M10 3v18\" /> <path d=\"M14 8v7\" /> <path d=\"M18 5v13\" /> <path d=\"M22 10v3\" />", "user": "<path d=\"M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2\" /> <circle cx=\"12\" cy=\"7\" r=\"4\" />", "logout": "<path d=\"m16 17 5-5-5-5\" /> <path d=\"M21 12H9\" /> <path d=\"M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4\" />", "mail": "<path d=\"m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7\" /> <rect x=\"2\" y=\"4\" width=\"20\" height=\"16\" rx=\"2\" />", "lock": "<rect width=\"18\" height=\"11\" x=\"3\" y=\"11\" rx=\"2\" ry=\"2\" /> <path d=\"M7 11V7a5 5 0 0 1 10 0v4\" />", "eye": "<path d=\"M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0\" /> <circle cx=\"12\" cy=\"12\" r=\"3\" />", "eyeoff": "<path d=\"M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49\" /> <path d=\"M14.084 14.158a3 3 0 0 1-4.242-4.242\" /> <path d=\"M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143\" /> <path d=\"m2 2 20 20\" />", "spark": "<path d=\"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z\" /> <path d=\"M20 2v4\" /> <path d=\"M22 4h-4\" /> <circle cx=\"4\" cy=\"20\" r=\"2\" />", "upload": "<path d=\"M12 3v12\" /> <path d=\"m17 8-5-5-5 5\" /> <path d=\"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4\" />", "trash": "<path d=\"M10 11v6\" /> <path d=\"M14 11v6\" /> <path d=\"M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6\" /> <path d=\"M3 6h18\" /> <path d=\"M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2\" />", "check": "<path d=\"M20 6 9 17l-5-5\" />", "image": "<rect width=\"18\" height=\"18\" x=\"3\" y=\"3\" rx=\"2\" ry=\"2\" /> <circle cx=\"9\" cy=\"9\" r=\"2\" /> <path d=\"m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21\" />", "music": "<path d=\"M21 16V3a1 1 0 0 0-1.28-.96l-10 2.917a1 1 0 0 0-.72.96V19\" /> <circle cx=\"18\" cy=\"16\" r=\"3\" /> <circle cx=\"6\" cy=\"19\" r=\"3\" />"};
const ic = (n) => `<svg class="ico" viewBox="0 0 24 24" aria-hidden="true">${ICONS[n]||""}</svg>`;
(function () {
'use strict';
const $ = (id) => document.getElementById(id);
const FONTS = [['F0','كايرو',700],['F1','تجوّل',700],['F2','أميري',700],['F3','عارف رقعة',700],['F4','ريم كوفي',700],['F5','المسيري',700],['F6','لالزار',400],['F7','كاتبة',400],['F8','نسخ',700],['F9','رقاص',400],['F10','عارف رقعة حبر',700],['F11','فايبس',400],['F12','ميرزا',700],['F13','شهرزاد',700],['F14','نوتو كوفي',700],['F15','ريم كوفي حبر',400],['F16','بلاكا',400],['F17','لطيف',700]];
const THEMES = [['#2BB583','#1A7A5A','#0F4F3B'],['#8B5CF6','#5B35B0','#32197A'],['#3B82F6','#1E4FA8','#0F2C66'],['#C2303A','#7F1620','#3D0A10'],['#4B4B4B','#262626','#0E0E0E'],['#B8862B','#6E4A12','#2A1B05'],['#14B8A6','#0F766E','#06332F'],['#2E4A8F','#1B2D5E','#0A1230'],['#8A8F98','#4B5360','#1C222B']];
const TCOLS = [['silver','فضي'],['gold','ذهبي'],['white','أبيض'],['custom','مخصص']];
const ACCS = [['gold','ذهبي'],['silver','فضي'],['white','أبيض'],['custom','مخصص']];
const ANIMS = [['slide','انزلاق'],['fade','تلاشي'],['zoom','تكبير'],['none','بدون حركة']];
const WAVES = [['bars','أعمدة'],['thin','أعمدة رفيعة'],['wave','موجة ناعمة']];
const FITS = [['orig','كما هو'],['45','4:5 (قص)'],['sq','مربع 1:1 (قص)']];
const QUAL = [['uhd','فائقة 1440p (أجهزة قوية)'],['max','أعلى جودة 1080p'],['hi','عالية 1080p'],['mid','متوسطة 720p']];
const FRAMES = [['double','مزدوج'],['line','خط واحد'],['corners','زوايا'],['glow','متوهج'],['none','بدون']];
const COVERSH = [['round','مستدير'],['square','مربع'],['circle','دائري']];
const BGMODES = [['grad','تدرج'],['solid','سادة'],['image','صورة']];
const PATS = [['stars','نجوم'],['dots','نقاط'],['lines','خطوط'],['none','بدون']];
const VLAYS = [['classic','كلاسيك'],['card','بطاقة'],['blur','خلفية ضبابية']];
const ALAYS = [['vinyl','أسطوانة'],['pulse','نبض'],['starpulse','نجمة نابضة'],['mirror','طيف مرآة'],['particles','جسيمات'],['ring','حلقة'],['sphere','كرة'],['neon','نيون'],['ridges','تلال'],['vu','عدادات'],['card','مشغل'],['poster','ملصق'],['cassette','كاسيت']];
const BRAND = { name: 'منبر', tag: 'قصائد ومراثي' };
const LFRAMES = [['none','بدون'],['circle','دائرة'],['seal','ختم'],['octa','نجمة 8'],['octagon','مثمن'],['arch','محراب'],['square','مربع']];
const LEMBS = [['none','بدون'],['dome','قبة'],['dome_line','قبة خطية'],['crescent','هلال'],['crescent_star','هلال ونجمة']];
const FILTERS = {
  none: { n: 'بدون' },
  warm: { n: 'دافئ', f: { sepia: .25, sat: 1.15, hue: -8, bri: 1.03 } },
  cool: { n: 'بارد', f: { hue: 12, sat: 1.05, bri: 1.02, con: 1.03 } },
  cine: { n: 'سينمائي', f: { con: 1.18, sat: .85, bri: .97, sepia: .12 } },
  bw: { n: 'أبيض وأسود', f: { gray: 1, con: 1.1 } },
  vintage: { n: 'عتيق', f: { sepia: .55, con: 1.05, bri: 1.03, sat: 1.1 } },
  vivid: { n: 'زاهي', f: { sat: 1.45, con: 1.08 } },
  fade: { n: 'باهت', f: { con: .88, bri: 1.08, sat: .82 } },
  drama: { n: 'درامي', f: { con: 1.3, bri: .92, sat: .9 } },
  mourn: { n: 'حزين', f: { sat: .6, bri: .9, con: 1.15, hue: 6 } },
  gold: { n: 'ذهبي', f: { sepia: .4, sat: 1.3, hue: -12, bri: 1.02 } },
  night: { n: 'ليلي', f: { bri: .85, con: 1.2, sat: .8, hue: 18 } }
};
ICONS.move = '<path d="M5 9l-3 3 3 3M9 5l3-3 3 3M15 19l-3 3-3-3M19 9l3 3-3 3M2 12h20M12 2v20"/>';
const VTF0 = { z: 1, x: 0, y: 0, r: 0, sx: 1, sy: 1, kx: 0, ky: 0, fh: 0, fv: 0 }; const LASTV = { dw: 1000, dh: 1000, cx: 0, cy: 0 };
const TOOLS = [['media','المصدر'],['trim','القص'],['move','تحريك'],['filter','الفلاتر'],['audio','الصوت'],['lyrics','الكلمات'],['font','الخط'],['text','التفاصيل'],['design','التصميم'],['color','الألوان'],['frame','الإطار'],['logo','الشعار'],['tpl','القوالب']];
const LOGO0 = { frame: 'octa', emblem: 'none', text: 'منبر', font: 4, tsize: 1, tcol: 'gold', tcustom: '#E8C468', fcol: 'gold', fcustom: '#E8C468', ecol: 'gold', ecustom: '#E8C468', thick: 1, deco: false };
const LOGO_PRESETS = [
  { frame: 'seal' }, { frame: 'none', emblem: 'dome_line' }, { frame: 'octa' }, { frame: 'none', deco: true, tsize: 1.45 },
  { frame: 'octa', emblem: 'dome', text: '' }, { frame: 'octagon', emblem: 'dome' }, { frame: 'arch', emblem: 'crescent' }, { frame: 'none', emblem: 'crescent_star' }
].map((p) => Object.assign({}, LOGO0, p));
const DEF = {
  theme: 0, custom: '#1f6f8b', bgMode: 'grad', bgBlur: 40, bgDim: 35, pat: 'stars', patA: 75,
  font: 3, tcol: 'silver', tcustom: '#FFD76A', tscale: 1, nscale: 1, tout: true, tglow: 30, tshadow: 60, lblCol: '#F3DE9C', valCol: '#FFFFFF', anim: 'slide',
  vlay: 'classic', alay: 'vinyl', vscale: 1, vfit: 'orig', vtf: { z: 1, x: 0, y: 0, r: 0, sx: 1, sy: 1, kx: 0, ky: 0, fh: 0, fv: 0 }, vrad: 36, safe: true,
  acc: 'gold', accC: '#E8C468', frameStyle: 'double', fthick: 1, cshape: 'round', cborder: true,
  filter: 'none', fint: 1, fbri: 0, fcon: 0, fsat: 0, fwarm: 0, fvig: 0, fx: { blur: 0, glow: 0, shake: 0, pulse: 0, grain: 0 },
  logo: true, logoOrn: true, logoSize: 1, logoMode: 'builder', logoP: Object.assign({}, LOGO0), logoData: null,
  wave: 'bars', dspeed: 1, q: 'hi', lyrOn: false, lyrY: 78, lyrSize: 1, vreact: { glow: true, bars: false, logo: true, bg: false },
  tp: { thr: 0, inv: false, clean: 40, smooth: 50, up: 2, fill: 'silver', fcustom: '#FFD76A', outline: true, glow: true, shadow: true, bevel: true }
};
const TPL_KEYS = ['theme','custom','bgMode','bgBlur','bgDim','pat','patA','font','tcol','tcustom','tscale','nscale','tout','tglow','tshadow','lblCol','valCol','anim','vlay','alay','vscale','vfit','vrad','safe','acc','accC','frameStyle','fthick','cshape','cborder','filter','fint','fbri','fcon','fsat','fwarm','fvig','logo','logoOrn','logoSize','logoMode','logoP','wave','dspeed','vreact'];

const LS = {
  get(k, d) { try { const v = JSON.parse(localStorage.getItem(k)); return v == null ? d : v; } catch (e) { return d; } },
  set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} }
};
const clone = (o) => JSON.parse(JSON.stringify(o));
let cfg = Object.assign(clone(DEF), LS.get('basim.cfg', {}));
cfg.logoP = Object.assign({}, LOGO0, cfg.logoP || {}); cfg.tp = Object.assign({}, DEF.tp, cfg.tp || {}); cfg.vreact = Object.assign({}, DEF.vreact, cfg.vreact || {});
let lib = Object.assign({ reciters: [], poets: [] }, LS.get('basim.lib', {}));
let onSave = null;
let TRIAL = false, NS = '', PID = '', PROJ = { status: 'draft', created: 0, expName: '' };
let scT = 0;
const saveCfg = () => { if (!TRIAL) { clearTimeout(scT); scT = setTimeout(() => LS.set('basim.cfg', cfg), 300); touchProject(); } if (onSave) onSave(); };
const saveLib = () => { if (!TRIAL) LS.set('basim.lib', lib); };

const S = { vspec: null, mode: 'video', url: null, file: null, dur: 0, titleSrc: null, titleFx: null, bgImg: null, img: null, abuf: null, spec: null, busy: false, cancel: false, resBlob: null, resName: '' };
let vUrl = null, vFile = null, aUrl = null, aFile = null;
let needs = true;
const dirty = () => { needs = true; };

function toast(m) { const t = $('toast'); t.textContent = m; t.hidden = false; clearTimeout(toast.h); toast.h = setTimeout(() => { t.hidden = true; }, 2800); }
const fmt = (s) => { s = Math.max(0, s || 0); return Math.floor(s / 60) + ':' + String(Math.floor(s % 60)).padStart(2, '0'); };
const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
const ease = (x) => 1 - Math.pow(1 - x, 3);
const buzz = () => { try { if (UI.haptic !== false) navigator.vibrate && navigator.vibrate(8); } catch (e) {} };

/* ---------- ألوان ---------- */
function hex2rgb(h) { h = h.replace('#', ''); if (h.length === 3) h = h.split('').map((c) => c + c).join(''); return [parseInt(h.slice(0,2),16), parseInt(h.slice(2,4),16), parseInt(h.slice(4,6),16)]; }
function mix(a, b, t) { const A = hex2rgb(a), B = hex2rgb(b); return '#' + A.map((v,i) => Math.round(v + (B[i]-v)*t).toString(16).padStart(2,'0')).join(''); }
function rgba(h, a) { const c = hex2rgb(h); return `rgba(${c[0]},${c[1]},${c[2]},${a})`; }
function themeColors() {
  if (cfg.theme < THEMES.length) return THEMES[cfg.theme];
  const c = cfg.custom; return [mix(c,'#ffffff',.2), c, mix(c,'#000000',.5)];
}
function shades(kind, custom) {
  if (kind === 'gold') return ['#FFF4B8', '#F4CF55', '#B8841A'];
  if (kind === 'silver') return ['#FFFFFF', '#D5DAE3', '#8C96A6'];
  if (kind === 'white') return ['#FFFFFF', '#F4F4F4', '#C8C8C8'];
  const c = custom || '#E8C468'; return [mix(c, '#ffffff', .55), c, mix(c, '#000000', .42)];
}
function paint(ctx, kind, custom, y0, y1) {
  const g = ctx.createLinearGradient(0, y0, 0, y1), s = shades(kind, custom);
  if (kind === 'white') { g.addColorStop(0, '#fff'); g.addColorStop(1, '#fff'); return g; }
  g.addColorStop(0, s[0]); g.addColorStop(.45, s[1]); g.addColorStop(.58, s[2]); g.addColorStop(1, mix(s[1], '#ffffff', .25));
  return g;
}
function accent() { return cfg.acc === 'gold' ? '#E8C468' : cfg.acc === 'silver' ? '#D5DAE3' : cfg.acc === 'white' ? '#FFFFFF' : cfg.accC; }

/* ---------- رسم أساسي ---------- */
function rr(ctx, x, y, w, h, r) {
  r = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
}
function setFont(ctx, size, weightOverride) { const f = FONTS[cfg.font]; ctx.font = `${weightOverride || f[2]} ${size}px "${f[0]}", "F0", sans-serif`; }
function setBase(ctx, size, w) { ctx.font = `${w || 700} ${size}px "F0", sans-serif`; }
function octaPath(cx, cy, R) {
  const ri = R * 0.7654; let p = '';
  for (let i = 0; i < 16; i++) { const a = -Math.PI / 2 + i * Math.PI / 8, r = i % 2 ? ri : R; p += (i ? 'L' : 'M') + (cx + Math.cos(a) * r).toFixed(1) + ' ' + (cy + Math.sin(a) * r).toFixed(1); }
  return p + 'Z';
}
function poly8Path(cx, cy, R) { let p = ''; for (let i = 0; i < 8; i++) { const a = -Math.PI / 2 + Math.PI / 8 + i * Math.PI / 4; p += (i ? 'L' : 'M') + (cx + Math.cos(a) * R).toFixed(1) + ' ' + (cy + Math.sin(a) * R).toFixed(1); } return p + 'Z'; }
function diamond(ctx, cx, cy, r, fill) { ctx.beginPath(); ctx.moveTo(cx, cy - r); ctx.lineTo(cx + r, cy); ctx.lineTo(cx, cy + r); ctx.lineTo(cx - r, cy); ctx.closePath(); ctx.fillStyle = fill; ctx.fill(); }
function accLine(ctx, x1, x2, y, w, col) {
  const g = ctx.createLinearGradient(x1, 0, x2, 0), a = x1 < x2;
  g.addColorStop(0, rgba(col, a ? 0 : .95)); g.addColorStop(1, rgba(col, a ? .95 : 0));
  ctx.strokeStyle = g; ctx.lineWidth = w; ctx.beginPath(); ctx.moveTo(x1, y); ctx.lineTo(x2, y); ctx.stroke();
}

/* ---------- باني الشعار ---------- */
const logoCache = {};
function renderLogo(p) {
  const key = JSON.stringify(p) + '|' + (document.fonts && document.fonts.size);
  if (logoCache[key]) return logoCache[key];
  const cv = document.createElement('canvas'); cv.width = cv.height = 512; const x = cv.getContext('2d');
  x.direction = 'rtl'; x.textBaseline = 'middle'; x.lineJoin = 'miter';
  const th = p.thick;
  const fs = (kind, cust, y0, y1) => paint(x, kind, cust, y0, y1);
  const strokeP = (path, w, a) => { x.save(); x.strokeStyle = fs(p.fcol, p.fcustom, 0, 512); x.lineWidth = w * th; if (a) x.globalAlpha = a; x.stroke(path); x.restore(); };
  switch (p.frame) {
    case 'circle': { const c1 = new Path2D(); c1.arc(256, 256, 224, 0, 7); strokeP(c1, 11); const c2 = new Path2D(); c2.arc(256, 256, 198, 0, 7); strokeP(c2, 3.5, .85); break; }
    case 'seal': {
      const c1 = new Path2D(); c1.arc(256, 256, 224, 0, 7); strokeP(c1, 11); const c2 = new Path2D(); c2.arc(256, 256, 198, 0, 7); strokeP(c2, 3.5);
      for (let i = 0; i < 8; i++) { const a = i * Math.PI / 4; diamond(x, 256 + Math.cos(a) * 211, 256 + Math.sin(a) * 211, 13, fs(p.fcol, p.fcustom, 0, 512)); }
      break; }
    case 'octa': strokeP(new Path2D(octaPath(256, 256, 244)), 11); strokeP(new Path2D(octaPath(256, 256, 208)), 3.5, .85); break;
    case 'octagon': strokeP(new Path2D(poly8Path(256, 256, 244)), 11); strokeP(new Path2D(poly8Path(256, 256, 212)), 3.5, .85); break;
    case 'arch': strokeP(new Path2D('M64 484V232C64 132 150 70 256 36C362 70 448 132 448 232V484Z'), 11); strokeP(new Path2D('M92 484V238C92 150 164 94 256 66C348 94 420 150 420 238V484Z'), 3.5, .85); break;
    case 'square': { const a = new Path2D(); a.roundRect ? a.roundRect(24, 24, 464, 464, 44) : a.rect(24, 24, 464, 464); strokeP(a, 11); const b = new Path2D(); b.roundRect ? b.roundRect(50, 50, 412, 412, 28) : b.rect(50, 50, 412, 412); strokeP(b, 3.5, .85); break; }
  }
  const hasT = !!(p.text && p.text.trim());
  const eC = shades(p.ecol, p.ecustom);
  const fillL = () => { const g = x.createLinearGradient(-90, -90, 90, 90); g.addColorStop(0, eC[0]); g.addColorStop(1, eC[1]); return g; };
  const fillD = () => { const g = x.createLinearGradient(-90, -90, 90, 90); g.addColorStop(0, eC[1]); g.addColorStop(1, eC[2]); return g; };
  const crescent = (s) => { x.fillStyle = fillL(); x.fill(new Path2D(`M${6 * s} ${-14 * s}a${22 * s} ${22 * s} 0 1 0 ${8 * s} ${38 * s}a${17 * s} ${17 * s} 0 1 1 ${-8 * s} ${-38 * s}z`)); };
  if (p.emblem !== 'none') {
    x.save();
    const ey = hasT ? 176 : 256, es = hasT ? .92 : 1.45;
    x.translate(256, ey); x.scale(es, es);
    if (p.emblem === 'dome') {
      const w = 140, top = -40, l = -w / 2, r = w / 2, bd = top + w * .62;
      x.translate(0, 22);
      x.fillStyle = fillL(); x.fill(new Path2D(`M0 ${top}C${-w * .12} ${top + w * .3} ${l} ${top + w * .36} ${l} ${top + w * .66}L${l} ${bd}L0 ${bd}Z`));
      x.fillStyle = fillD(); x.fill(new Path2D(`M0 ${top}C${w * .12} ${top + w * .3} ${r} ${top + w * .36} ${r} ${top + w * .66}L${r} ${bd}L0 ${bd}Z`));
      x.fillStyle = fillL(); x.fillRect(-3, top - w * .2, 6, w * .2 + 2);
      x.save(); x.translate(3, top - w * .2); crescent(.9); x.restore();
      x.fillStyle = fillL(); x.fillRect(l - 8, bd, w / 2 + 8, w * .09); x.fillStyle = fillD(); x.fillRect(0, bd, w / 2 + 8, w * .09);
    } else if (p.emblem === 'dome_line') {
      x.translate(-256, -166); x.strokeStyle = fs(p.ecol, p.ecustom, 0, 300); x.lineWidth = 9; x.lineCap = 'round'; x.lineJoin = 'round';
      x.stroke(new Path2D('M256 70C232 128 178 150 178 214L178 262L334 262L334 214C334 150 280 128 256 70Z')); x.globalAlpha = .7; x.lineWidth = 5; x.stroke(new Path2D('M256 70L256 262')); x.globalAlpha = 1; x.lineWidth = 9;
      x.stroke(new Path2D('M160 262L352 262M172 282L340 282')); x.save(); x.translate(272, 50); crescent(1.2); x.restore();
    } else if (p.emblem === 'crescent') {
      x.translate(-4, 0); crescent(3.1);
    } else if (p.emblem === 'crescent_star') {
      x.fillStyle = fillL(); x.fill(new Path2D('M60 -150a118 118 0 1 0 0 232a96 96 0 1 1 0-232z')); x.fillStyle = fillD(); x.fill(new Path2D(octaPath(86, -52, 36)));
    }
    x.restore();
  }
  if (hasT) {
    let size = 128 * p.tsize; const f = FONTS[p.font] || FONTS[4];
    const fy = p.emblem !== 'none' ? 372 : 262;
    x.font = `${f[2]} ${size}px "${f[0]}", "F4", sans-serif`;
    const maxW = p.frame === 'none' ? 470 : 360; const w = x.measureText(p.text).width; if (w > maxW) { size *= maxW / w; x.font = `${f[2]} ${size}px "${f[0]}", "F4", sans-serif`; }
    x.textAlign = 'center'; x.save(); x.shadowColor = 'rgba(0,0,0,.45)'; x.shadowBlur = 9; x.shadowOffsetY = 5;
    x.fillStyle = fs(p.tcol, p.tcustom, fy - size * .6, fy + size * .6); x.fillText(p.text, 256, fy); x.restore();
    if (p.deco) { x.fillStyle = fs(p.tcol, p.tcustom, 0, 512); x.globalAlpha = .85; x.fillRect(100, fy + size * .52 + 14, 312, 5); x.globalAlpha = 1; diamond(x, 256, fy + size * .52 + 16, 14, fs(p.tcol, p.tcustom, 0, 512)); }
  }
  logoCache[key] = cv; return cv;
}
const logoImgEl = new Image();
let logoUser = null;
function currentLogo() { return cfg.logoMode === 'image' && logoUser && logoUser.naturalWidth ? logoUser : renderLogo(cfg.logoP); }
function loadLogo() {
  if (cfg.logoMode === 'image' && cfg.logoData) { logoUser = new Image(); logoUser.onload = () => { dirty(); refreshLogoUI(); }; logoUser.src = cfg.logoData; }
  dirty();
}
let refreshLogoUI = () => {};
/* ---------- معالجة صورة العنوان ---------- */
function otsu(hist, total) {
  let sum = 0; for (let i = 0; i < 256; i++) sum += i * hist[i];
  let sB = 0, wB = 0, best = 0, thr = 128;
  for (let i = 0; i < 256; i++) { wB += hist[i]; if (!wB) continue; const wF = total - wB; if (!wF) break; sB += i * hist[i]; const mB = sB / wB, mF = (sum - sB) / wF, v = wB * wF * (mB - mF) * (mB - mF); if (v > best) { best = v; thr = i; } }
  return thr;
}
function boxBlurAlpha(a, w, h, r) {
  if (r < 1) return a;
  const tmp = new Float32Array(a.length), out = new Float32Array(a.length), n = 2 * r + 1;
  for (let y = 0; y < h; y++) { let s = 0; const o = y * w; for (let x = -r; x <= r; x++) s += a[o + clamp(x, 0, w - 1)]; for (let x = 0; x < w; x++) { tmp[o + x] = s / n; s += a[o + clamp(x + r + 1, 0, w - 1)] - a[o + clamp(x - r, 0, w - 1)]; } }
  for (let x = 0; x < w; x++) { let s = 0; for (let y = -r; y <= r; y++) s += tmp[clamp(y, 0, h - 1) * w + x]; for (let y = 0; y < h; y++) { out[y * w + x] = s / n; s += tmp[clamp(y + r + 1, 0, h - 1) * w + x] - tmp[clamp(y - r, 0, h - 1) * w + x]; } }
  return out;
}
function segmentTitle(img, tp) {
  const k = Math.min(1, 1600 / Math.max(img.naturalWidth, img.naturalHeight));
  const w = Math.max(8, Math.round(img.naturalWidth * k)), h = Math.max(8, Math.round(img.naturalHeight * k)), n = w * h;
  const c = document.createElement('canvas'); c.width = w; c.height = h; const x = c.getContext('2d', { willReadFrequently: true }); x.drawImage(img, 0, 0, w, h);
  const id = x.getImageData(0, 0, w, h), d = id.data;
  let transp = 0; for (let i = 3; i < d.length; i += 4) if (d[i] < 200) transp++;
  const A = new Uint8Array(n);
  let info = '';
  if (transp > n * .05) { for (let i = 0; i < n; i++) A[i] = d[i * 4 + 3]; info = 'الصورة شفافة أصلاً، تم استخدام شفافيتها.'; }
  else {
    const L = new Uint8Array(n), hist = new Float64Array(256);
    for (let i = 0; i < n; i++) { const v = Math.round(.299 * d[i * 4] + .587 * d[i * 4 + 1] + .114 * d[i * 4 + 2]); L[i] = v; hist[v]++; }
    const thr = clamp(otsu(hist, n) + tp.thr, 4, 251);
    let hi = 0; for (let v = thr + 1; v < 256; v++) hi += hist[v];
    let bright = hi < n - hi; if (tp.inv) bright = !bright;
    for (let i = 0; i < n; i++) { const v = (L[i] - thr) / 30; A[i] = Math.round(clamp((bright ? v : -v) + .5, 0, 1) * 255); }
    info = bright ? 'تم اعتبار النص أفتح من الخلفية.' : 'تم اعتبار النص أغمق من الخلفية.';
  }
  // تنظيف الشوائب بالمكونات المتصلة
  const lab = new Int32Array(n), stack = new Int32Array(n), areas = [0]; let nl = 0;
  for (let i = 0; i < n; i++) {
    if (A[i] < 128 || lab[i]) continue;
    nl++; let sp = 0, ar = 0; stack[sp++] = i; lab[i] = nl;
    while (sp) { const p = stack[--sp]; ar++; const px = p % w, py = (p / w) | 0;
      if (px > 0 && A[p - 1] >= 128 && !lab[p - 1]) { lab[p - 1] = nl; stack[sp++] = p - 1; }
      if (px < w - 1 && A[p + 1] >= 128 && !lab[p + 1]) { lab[p + 1] = nl; stack[sp++] = p + 1; }
      if (py > 0 && A[p - w] >= 128 && !lab[p - w]) { lab[p - w] = nl; stack[sp++] = p - w; }
      if (py < h - 1 && A[p + w] >= 128 && !lab[p + w]) { lab[p + w] = nl; stack[sp++] = p + w; } }
    areas.push(ar);
  }
  if (!nl) return null;
  let maxA = 0; for (let i = 1; i <= nl; i++) maxA = Math.max(maxA, areas[i]);
  const minA = Math.max(10, tp.clean / 100 * .012 * maxA), keepL = new Uint8Array(nl + 1); let kept = 0;
  for (let i = 1; i <= nl; i++) if (areas[i] >= minA) { keepL[i] = 1; kept++; }
  let x0 = w, y0 = h, x1 = -1, y1 = -1;
  const A2 = new Uint8Array(n);
  for (let y = 0; y < h; y++) for (let xx = 0; xx < w; xx++) {
    const i = y * w + xx; if (!A[i]) continue;
    let ok = lab[i] ? keepL[lab[i]] : 0;
    if (!ok) { for (let dy = -2; dy <= 2 && !ok; dy++) for (let dx = -2; dx <= 2; dx++) { const yy = y + dy, xq = xx + dx; if (yy < 0 || yy >= h || xq < 0 || xq >= w) continue; const l = lab[yy * w + xq]; if (l && keepL[l]) { ok = 1; break; } } }
    if (ok) { A2[i] = A[i]; if (A[i] > 60) { if (xx < x0) x0 = xx; if (xx > x1) x1 = xx; if (y < y0) y0 = y; if (y > y1) y1 = y; } }
  }
  if (x1 < 0) return null;
  const pad = Math.round(Math.max(x1 - x0, y1 - y0) * .04) + 4;
  x0 = Math.max(0, x0 - pad); y0 = Math.max(0, y0 - pad); x1 = Math.min(w - 1, x1 + pad); y1 = Math.min(h - 1, y1 + pad);
  const cw = x1 - x0 + 1, ch = y1 - y0 + 1;
  const crop = document.createElement('canvas'); crop.width = cw; crop.height = ch; const cx = crop.getContext('2d'); const cd = cx.createImageData(cw, ch);
  for (let y = 0; y < ch; y++) for (let xx = 0; xx < cw; xx++) { const si = (y + y0) * w + xx + x0, di = (y * cw + xx) * 4; cd.data[di] = d[si * 4]; cd.data[di + 1] = d[si * 4 + 1]; cd.data[di + 2] = d[si * 4 + 2]; cd.data[di + 3] = A2[si]; }
  cx.putImageData(cd, 0, 0);
  // رفع الجودة + تنعيم الحواف
  let s = clamp(tp.up, 1, 4); if (ch * s < 420) s = 420 / ch; s = Math.min(s, 4);
  const ow = Math.round(cw * s), oh = Math.round(ch * s);
  const big = document.createElement('canvas'); big.width = ow; big.height = oh; const bx = big.getContext('2d', { willReadFrequently: true }); bx.imageSmoothingEnabled = true; bx.imageSmoothingQuality = 'high'; bx.drawImage(crop, 0, 0, ow, oh);
  const bd = bx.getImageData(0, 0, ow, oh), al = new Float32Array(ow * oh); for (let i = 0; i < al.length; i++) al[i] = bd.data[i * 4 + 3] / 255;
  const bl = boxBlurAlpha(al, ow, oh, Math.max(1, Math.round(tp.smooth / 100 * 1.3 * s)));
  for (let i = 0; i < bl.length; i++) { const v = clamp((bl[i] - .32) / .36, 0, 1); bd.data[i * 4 + 3] = Math.round(v * v * (3 - 2 * v) * 255); }
  bx.putImageData(bd, 0, 0);
  return { canvas: big, info: info + ` (${kept} قطعة، ${ow}×${oh})` };
}
let titleSeq = 0;
function applyTitleFx(m, tp) {
  const sc = m.height / 260, pad = Math.round(m.height * .08 + (tp.glow ? 30 * sc : 0) + (tp.shadow ? 16 * sc : 0));
  const W = m.width + pad * 2, H = m.height + pad * 2;
  const mk = () => { const c = document.createElement('canvas'); c.width = W; c.height = H; return c; };
  const T = mk(), tx = T.getContext('2d'); tx.drawImage(m, pad, pad);
  if (tp.fill !== 'orig') { tx.globalCompositeOperation = 'source-in'; tx.fillStyle = paint(tx, tp.fill, tp.fcustom, pad, pad + m.height); tx.fillRect(0, 0, W, H); tx.globalCompositeOperation = 'source-over'; }
  if (tp.bevel) {
    const edge = (col, dx, dy, alpha) => { const e = mk(), ex = e.getContext('2d'); ex.drawImage(m, pad, pad); ex.globalCompositeOperation = 'source-in'; ex.fillStyle = col; ex.fillRect(0, 0, W, H); ex.globalCompositeOperation = 'destination-out'; ex.drawImage(m, pad + dx, pad + dy); tx.save(); tx.globalCompositeOperation = 'source-atop'; tx.globalAlpha = alpha; tx.drawImage(e, 0, 0); tx.restore(); };
    const o = Math.max(2, Math.round(3 * sc)); edge('#ffffff', o, o, .6); edge('#000000', -o, -o, .35);
  }
  const out = mk(), ox = out.getContext('2d');
  const glowC = tp.fill === 'gold' ? 'rgba(244,207,85,.75)' : tp.fill === 'custom' ? rgba(tp.fcustom, .75) : 'rgba(255,255,255,.6)';
  if (tp.outline) {
    const sil = mk(), sx = sil.getContext('2d'); sx.drawImage(m, pad, pad); sx.globalCompositeOperation = 'source-in'; sx.fillStyle = 'rgba(0,0,0,.6)'; sx.fillRect(0, 0, W, H);
    const r = Math.max(2, 3.5 * sc); for (let a = 0; a < 16; a++) ox.drawImage(sil, Math.cos(a * Math.PI / 8) * r, Math.sin(a * Math.PI / 8) * r);
  }
  if (tp.shadow) { ox.save(); ox.shadowColor = 'rgba(0,0,0,.65)'; ox.shadowBlur = 14 * sc; ox.shadowOffsetY = 8 * sc; ox.drawImage(T, 0, 0); ox.restore(); }
  if (tp.glow) { ox.save(); ox.shadowColor = glowC; ox.shadowBlur = 30 * sc; ox.drawImage(T, 0, 0); ox.restore(); }
  ox.drawImage(T, 0, 0);
  out._id = ++titleSeq;
  return out;
}
let titleTimer = null, titleMask = null;
function rebuildTitle(full) {
  clearTimeout(titleTimer);
  titleTimer = setTimeout(() => {
    if (!S.titleSrc) { S.titleFx = null; titleMask = null; dirty(); return; }
    $('tpMsg').textContent = 'جاري معالجة الصورة...';
    setTimeout(() => {
      try {
        if (full !== false || !titleMask) { const r = segmentTitle(S.titleSrc, cfg.tp); if (!r) { $('tpMsg').textContent = 'ما لقيت نص بالصورة. جرّب تغيّر الحساسية أو تضغط عكس.'; S.titleFx = null; dirty(); return; } titleMask = r; }
        S.titleFx = applyTitleFx(titleMask.canvas, cfg.tp);
        $('tpMsg').textContent = titleMask.info;
        const pv2 = $('tpPrev'), px = pv2.getContext('2d'); px.clearRect(0, 0, pv2.width, pv2.height);
        const k = Math.min(pv2.width / S.titleFx.width, pv2.height / S.titleFx.height); px.drawImage(S.titleFx, (pv2.width - S.titleFx.width * k) / 2, (pv2.height - S.titleFx.height * k) / 2, S.titleFx.width * k, S.titleFx.height * k);
      } catch (e) { $('tpMsg').textContent = 'تعذّرت المعالجة: ' + e.message; }
      dirty();
    }, 30);
  }, 140);
}
/* ---------- الفلاتر ---------- */
let CURF = 'none';
function buildFilter(key, k, adj) {
  const f = (FILTERS[key] || FILTERS.none).f || {};
  const p = Object.assign({ bri: 1, con: 1, sat: 1, sepia: 0, gray: 0, hue: 0 }, f);
  const m = (d, v) => d + (v - d) * k;
  let bri = m(1, p.bri), con = m(1, p.con), sat = m(1, p.sat), sep = m(0, p.sepia), gray = m(0, p.gray), hue = m(0, p.hue);
  if (adj) {
    bri *= 1 + cfg.fbri / 100; con *= 1 + cfg.fcon / 100; sat *= 1 + cfg.fsat / 100;
    const w = cfg.fwarm / 100; if (w > 0) { sep += w * .3; hue -= w * 10; } else { hue += -w * 14; }
  }
  const o = [];
  if (Math.abs(bri - 1) > .005) o.push(`brightness(${bri.toFixed(3)})`);
  if (Math.abs(con - 1) > .005) o.push(`contrast(${con.toFixed(3)})`);
  if (Math.abs(sat - 1) > .005) o.push(`saturate(${sat.toFixed(3)})`);
  if (sep > .005) o.push(`sepia(${Math.min(1, sep).toFixed(3)})`);
  if (gray > .005) o.push(`grayscale(${Math.min(1, gray).toFixed(3)})`);
  if (Math.abs(hue) > .3) o.push(`hue-rotate(${hue.toFixed(1)}deg)`);
  return o.length ? o.join(' ') : 'none';
}
const filterCSS = () => buildFilter(cfg.filter, cfg.fint, true);
const FXK = ['blur', 'glow', 'shake', 'pulse', 'grain'];
const fxOf = () => { const f = cfg.fx || {}; return f; };
let GRN = null;
const __scC = new WeakMap();
function hqScaled(src, sx, sy, sw, sh, tw, th) {
  const q = Math.pow(2, Math.ceil(Math.log2(Math.max(tw, th, 16)) * 4) / 4) / Math.max(tw, th); tw = Math.max(8, Math.round(tw * q)); th = Math.max(8, Math.round(th * q));
  let m = __scC.get(src); if (!m) { m = new Map(); __scC.set(src, m); } const key = [sx | 0, sy | 0, sw | 0, sh | 0, tw, th].join(','); let c = m.get(key); if (c) return c;
  let cw = sw, ch = sh, cur = document.createElement('canvas'); cur.width = Math.round(sw); cur.height = Math.round(sh); let x = cur.getContext('2d'); x.drawImage(src, sx, sy, sw, sh, 0, 0, cur.width, cur.height);
  while (cw / 2 >= tw && ch / 2 >= th) { cw /= 2; ch /= 2; const n2 = document.createElement('canvas'); n2.width = Math.round(cw); n2.height = Math.round(ch); const y = n2.getContext('2d'); y.imageSmoothingQuality = 'high'; y.drawImage(cur, 0, 0, n2.width, n2.height); cur = n2; }
  c = document.createElement('canvas'); c.width = tw; c.height = th; x = c.getContext('2d'); x.imageSmoothingQuality = 'high'; x.drawImage(cur, 0, 0, tw, th);
  if (m.size > 24) m.clear(); m.set(key, c); return c;
}
function drawMedia(ctx, src, sx, sy, sw, sh, dx, dy, dw, dh) {
  if (window.__plrDrawing) { const tr = ctx.getTransform(), sc = Math.hypot(tr.a, tr.b) || 1, tw = dw * sc, th = dh * sc; ctx.imageSmoothingQuality = 'high';
    if (src.naturalWidth && (sw > tw * 1.4 || sh > th * 1.4)) { try { ctx.drawImage(hqScaled(src, sx, sy, sw, sh, tw, th), dx, dy, dw, dh); return; } catch (e) {} }
    ctx.drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh); return; }
  const f = fxOf(), sc = Math.abs(ctx.getTransform().a) || 1, bl = f.blur ? ` blur(${(f.blur / 100 * 14 * sc).toFixed(1)}px)` : '';
  const fl = (CURF !== 'none' ? CURF : '') + bl;
  if (fl.trim()) { ctx.save(); ctx.filter = fl.trim(); ctx.drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh); ctx.restore(); }
  else ctx.drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh);
  if (f.glow) { ctx.save(); ctx.globalCompositeOperation = 'lighter'; ctx.globalAlpha = Math.min(1, ctx.globalAlpha) * f.glow / 100 * .55; ctx.filter = `blur(${(18 * sc).toFixed(1)}px) brightness(1.15)` + (CURF !== 'none' ? ' ' + CURF : ''); ctx.drawImage(src, sx, sy, sw, sh, dx, dy, dw, dh); ctx.restore(); }
}
function fxMove(t, FR) {
  const f = fxOf(); if (!f.shake && !f.pulse) return null;
  const sh = (f.shake || 0) / 100, pu = (f.pulse || 0) / 100, b = FR ? Math.min(1, FR.bass * 1.3 + FR.beat * .6) : (0.5 + 0.5 * Math.sin(t * 7));
  return { x: sh * 14 * (Math.sin(t * 43) + Math.sin(t * 71 + 1) * .6), y: sh * 14 * (Math.cos(t * 37) + Math.sin(t * 59) * .6), z: 1 + sh * .04 + pu * .09 * b };
}
function grainOver(ctx, x, y, w, h, t) {
  const f = fxOf(); if (!f.grain) return;
  if (!GRN) { GRN = document.createElement('canvas'); GRN.width = GRN.height = 256; const g = GRN.getContext('2d'), d = g.createImageData(256, 256); for (let i = 0; i < d.data.length; i += 4) { const v = Math.random() * 255; d.data[i] = d.data[i + 1] = d.data[i + 2] = v; d.data[i + 3] = 255; } g.putImageData(d, 0, 0); }
  ctx.save(); ctx.globalAlpha = f.grain / 100 * .35; ctx.globalCompositeOperation = 'overlay'; const ox = -((t * 997) % 256), oy = -((t * 613) % 256);
  ctx.beginPath(); ctx.rect(x, y, w, h); ctx.clip();
  for (let gx = x + ox; gx < x + w; gx += 256) for (let gy = y + oy; gy < y + h; gy += 256) ctx.drawImage(GRN, gx, gy);
  ctx.restore();
}
function vignette(ctx, x, y, w, h) {
  if (cfg.fvig <= 0) return;
  const cx = x + w / 2, cy = y + h / 2, g = ctx.createRadialGradient(cx, cy, Math.min(w, h) * .25, cx, cy, Math.max(w, h) * .72);
  g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, `rgba(0,0,0,${(cfg.fvig / 100 * .75).toFixed(3)})`);
  ctx.fillStyle = g; ctx.fillRect(x, y, w, h);
}
function drawCover(ctx, img, x, y, w, h) {
  const iw = img.naturalWidth || img.videoWidth || img.displayWidth || img.width, ih = img.naturalHeight || img.videoHeight || img.displayHeight || img.height;
  const ar = w / h, ir = iw / ih; let sx = 0, sy = 0, sw = iw, sh = ih;
  if (ir > ar) { sw = sh * ar; sx = (iw - sw) / 2; } else { sh = sw / ar; sy = (ih - sh) / 2; }
  drawMedia(ctx, img, sx, sy, sw, sh, x, y, w, h);
}
function srcDims(src) {
  if (!src) return null;
  if (src.videoWidth) return [src.videoWidth, src.videoHeight];
  if (src.displayWidth) return [src.displayWidth, src.displayHeight];
  if (src.naturalWidth) return [src.naturalWidth, src.naturalHeight];
  if (src.width && src.height) return [src.width, src.height];
  return null;
}

/* ---------- الخلفية ---------- */
const tiny = document.createElement('canvas'), tinyB = document.createElement('canvas'), blurCache = new Map();
function blurRaw(ctx, src, W, H, amt) {
  const d = srcDims(src); if (!d) return;
  const tw = Math.max(16, Math.round(540 * Math.pow(24 / 540, amt / 100))), th = Math.max(16, Math.round(tw * H / W));
  if (tiny.width !== tw || tiny.height !== th) { tiny.width = tw; tiny.height = th; tinyB.width = tw * 4; tinyB.height = th * 4; }
  const x = tiny.getContext('2d'); x.imageSmoothingQuality = 'high';
  const ar = tw / th, ir = d[0] / d[1]; let sx = 0, sy = 0, w = d[0], h = d[1]; if (ir > ar) { w = h * ar; sx = (d[0] - w) / 2; } else { h = w / ar; sy = (d[1] - h) / 2; }
  x.drawImage(src, sx, sy, w, h, 0, 0, tw, th);
  const y = tinyB.getContext('2d'); y.imageSmoothingQuality = 'high'; y.drawImage(tiny, 0, 0, tw * 4, th * 4);
  ctx.drawImage(tinyB, 0, 0, tinyB.width, tinyB.height, 0, 0, W, H);
}
function blurFill(ctx, src, W, H, amt, key) {
  if (!key) { blurRaw(ctx, src, W, H, amt); return; }
  const k = key + '|' + W + '|' + amt; let c = blurCache.get(k);
  if (!c) { c = document.createElement('canvas'); c.width = W; c.height = H; blurRaw(c.getContext('2d'), src, W, H, amt); blurCache.set(k, c); if (blurCache.size > 6) blurCache.delete(blurCache.keys().next().value); }
  ctx.drawImage(c, 0, 0, W, H);
}
const imgKey = (im) => (im.src || 'img') + '#' + (im.naturalWidth || 0);
const bgCache = {};
function getBg(W) {
  const cols = themeColors(); const key = [cols.join(), W, cfg.bgMode, cfg.pat, cfg.patA].join('|');
  if (bgCache[key]) return bgCache[key];
  const H = Math.round(W * 16 / 9); const cv = document.createElement('canvas'); cv.width = W; cv.height = H; const x = cv.getContext('2d');
  x.scale(W / 1080, W / 1080);
  if (cfg.bgMode === 'solid') { x.fillStyle = cols[1]; x.fillRect(0, 0, 1080, 1920); }
  else { const g = x.createLinearGradient(0, 0, 0, 1920); g.addColorStop(0, cols[0]); g.addColorStop(.5, cols[1]); g.addColorStop(1, cols[2]); x.fillStyle = g; x.fillRect(0, 0, 1080, 1920); }
  const pa = .075 * cfg.patA / 75; x.strokeStyle = `rgba(255,255,255,${pa})`; x.fillStyle = `rgba(255,255,255,${pa * 1.4})`; x.lineWidth = 2.5;
  if (cfg.pat === 'stars') {
    for (let gx = 0; gx <= 10; gx++) for (let gy = 0; gy <= 18; gy++) {
      x.stroke(new Path2D(octaPath(gx * 112 + 56, gy * 112 + 56, 56)));
      const dx = gx * 112 + 112, dy = gy * 112 + 112; x.beginPath(); x.moveTo(dx, dy - 17); x.lineTo(dx + 17, dy); x.lineTo(dx, dy + 17); x.lineTo(dx - 17, dy); x.closePath(); x.stroke();
    }
  } else if (cfg.pat === 'dots') {
    for (let gx = 0; gx <= 20; gx++) for (let gy = 0; gy <= 36; gy++) { x.beginPath(); x.arc(gx * 54 + (gy % 2 ? 27 : 0), gy * 54, 3, 0, 7); x.fill(); }
  } else if (cfg.pat === 'lines') {
    x.lineWidth = 3; for (let i = -1920; i < 1080; i += 64) { x.beginPath(); x.moveTo(i, 1920); x.lineTo(i + 1920, 0); x.stroke(); }
  }
  const g = x.createRadialGradient(540, 860, 200, 540, 960, 1250); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.55)');
  x.fillStyle = g; x.fillRect(0, 0, 1080, 1920);
  bgCache[key] = cv; return cv;
}
function drawBackground(ctx, W, H, src, o) {
  const dark = (a) => { ctx.fillStyle = `rgba(0,0,0,${a})`; ctx.fillRect(0, 0, W, H); };
  const RL = o.mode === 'audio' ? NEW_AL[cfg.alay] : null;
  if (RL && RL.bg === 'blur' && o.img) { blurFill(ctx, o.img, W, H, 55, imgKey(o.img)); dark(.55); return; }
  if (RL && RL.bg === 'dark') {
    const cols = themeColors(); ctx.fillStyle = mix(cols[2], '#000000', .55); ctx.fillRect(0, 0, W, H);
    const g = ctx.createRadialGradient(W / 2, H * .4, W * .1, W / 2, H * .45, W * 1.1); g.addColorStop(0, rgba(cols[1], .38)); g.addColorStop(1, rgba(cols[2], 0)); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H); return;
  }
  if (o.mode === 'audio' && cfg.alay === 'poster' && o.img) { blurFill(ctx, o.img, W, H, 55, imgKey(o.img)); dark(.5); return; }
  if (o.mode !== 'audio' && cfg.vlay === 'blur' && srcDims(src)) { blurFill(ctx, src, W, H, 60); dark(.5); return; }
  if (cfg.bgMode === 'image' && o.bgImg) { blurFill(ctx, o.bgImg, W, H, cfg.bgBlur, 'bg' + imgKey(o.bgImg)); dark(cfg.bgDim / 100); return; }
  ctx.drawImage(getBg(W), 0, 0, W, H);
}

/* ---------- النص ---------- */
function metal(ctx, y0, y1) { return paint(ctx, cfg.tcol, cfg.tcustom, y0, y1); }
function layoutTitle(ctx, text) {
  const maxW = 940;
  for (let size = Math.round(124 * cfg.tscale); size >= 56; size -= 4) { setFont(ctx, size); if (ctx.measureText(text).width <= maxW) return { lines: [text], size }; }
  const words = text.split(/\s+/);
  if (words.length < 2) { setFont(ctx, 64); return { lines: [text], size: Math.max(36, Math.floor(64 * maxW / ctx.measureText(text).width)) }; }
  let best = null;
  for (let size = Math.round(112 * cfg.tscale); size >= 48; size -= 4) {
    setFont(ctx, size); let bi = 1, bw = 1e9;
    for (let i = 1; i < words.length; i++) { const w = Math.max(ctx.measureText(words.slice(0, i).join(' ')).width, ctx.measureText(words.slice(i).join(' ')).width); if (w < bw) { bw = w; bi = i; } }
    best = { lines: [words.slice(0, bi).join(' '), words.slice(bi).join(' ')], size }; if (bw <= maxW) return best;
  }
  return best;
}
function buildItems(ctx, o, ACC) {
  const ph = (v, d) => v || (o.preview ? d : '');
  const title = ph(o.title, 'اسم القصيدة'), occ = o.occ || '', rec = ph(o.reciter, 'اسم الرادود'), poet = ph(o.poet, 'اسم الشاعر');
  const items = [];
  if (o.titleFx && o.titleFx.width) {
    const k = Math.min(960 / o.titleFx.width, 290 * cfg.tscale / o.titleFx.height);
    items.push({ h: o.titleFx.height * k + 22, delay: .9, fn: (y) => ctx.drawImage(o.titleFx, 540 - o.titleFx.width * k / 2, y + 11, o.titleFx.width * k, o.titleFx.height * k) });
  } else if (title) {
    const lay = layoutTitle(ctx, title); const lh = lay.size * 1.3;
    items.push({ h: lh * lay.lines.length + 12, delay: .9, fn: (y) => {
      setFont(ctx, lay.size); ctx.textAlign = 'center'; ctx.lineJoin = 'round';
      const glowC = cfg.tcol === 'gold' ? 'rgba(244,207,85,.6)' : cfg.tcol === 'custom' ? rgba(cfg.tcustom, .6) : 'rgba(255,255,255,.5)';
      lay.lines.forEach((ln, i) => {
        const cy = y + lh * i + lh / 2 + 6;
        if (cfg.tglow > 0) { ctx.save(); ctx.shadowColor = glowC; ctx.shadowBlur = cfg.tglow * .9; ctx.fillStyle = 'rgba(255,255,255,.01)'; ctx.fillText(ln, 540, cy); ctx.restore(); }
        ctx.save();
        if (cfg.tshadow > 0) { ctx.shadowColor = `rgba(0,0,0,${(cfg.tshadow / 100 * .8).toFixed(2)})`; ctx.shadowBlur = 8 + cfg.tshadow / 8; ctx.shadowOffsetY = 6; }
        if (cfg.tout) { ctx.strokeStyle = 'rgba(0,0,0,.4)'; ctx.lineWidth = 7; ctx.strokeText(ln, 540, cy); }
        ctx.shadowColor = 'transparent'; ctx.fillStyle = metal(ctx, cy - lay.size * .6, cy + lay.size * .6); ctx.fillText(ln, 540, cy);
        ctx.restore();
      });
    } });
  }
  if (title || o.titleFx) items.push({ h: 44, delay: 1.1, fn: (y) => { const cy = y + 22; accLine(ctx, 540 - 8 - 220, 540 - 24, cy, 3, ACC); accLine(ctx, 540 + 8 + 220, 540 + 24, cy, 3, ACC); diamond(ctx, 540, cy, 9, ACC); } });
  const nsz = Math.round(38 * cfg.nscale);
  const two = (label, val, delay) => { if (val) items.push({ h: nsz * 1.5, delay, fn: (y) => {
    setBase(ctx, nsz, 700); const wl = ctx.measureText(label).width, wv = ctx.measureText(val).width, gap = 14, tot = wl + gap + wv, xr = 540 + tot / 2;
    ctx.textAlign = 'right'; ctx.fillStyle = cfg.lblCol; ctx.fillText(label, xr, y + nsz * .75);
    ctx.fillStyle = cfg.valCol; ctx.fillText(val, xr - wl - gap, y + nsz * .75);
  } }); };
  two('الرادود:', rec, 1.3); two('الشاعر:', poet, 1.5);
  if (occ) {
    let sz = Math.round(30 * cfg.nscale); setBase(ctx, sz, 700); while (sz > 20 && ctx.measureText(occ).width > 880) { sz -= 2; setBase(ctx, sz, 700); }
    const pw = ctx.measureText(occ).width + 64;
    items.push({ h: 86, delay: 1.7, fn: (y) => {
      rr(ctx, 540 - pw / 2, y + 14, pw, 56, 28); ctx.fillStyle = 'rgba(0,0,0,.2)'; ctx.fill(); ctx.strokeStyle = rgba(ACC, .85); ctx.lineWidth = 2.5; ctx.stroke();
      setBase(ctx, sz, 700); ctx.textAlign = 'center'; ctx.fillStyle = cfg.lblCol; ctx.fillText(occ, 540, y + 43);
    } });
  }
  return { items, T: items.reduce((a, b) => a + b.h, 0) };
}

/* ---------- عناصر المشغل ---------- */
function barsAt(o, t) {
  const n = 22; if (o && o.live) return o.live.vals;
  if (o.spec) { const f = Math.min(o.spec.frames - 1, Math.max(0, Math.floor(t * o.spec.fps))); return o.spec.data.subarray(f * n, f * n + n); }
  const a = []; for (let i = 0; i < n; i++) a.push(.2 + .5 * Math.abs(Math.sin(t * 3.1 + i * .6)) * (1 - i / n * .5)); return a;
}
function drawWave(ctx, cy, vals, maxH, ACC, W) {
  W = W || 900; const style = cfg.wave, x0 = 540 - W / 2;
  const n = style === 'thin' ? 66 : style === 'wave' ? 90 : 44;
  const hs = []; for (let i = 0; i < n; i++) { const k = Math.min(vals.length - 1, Math.floor(Math.abs(i - (n - 1) / 2) / (n / 2) * vals.length)); hs.push(Math.max(8, vals[k] * maxH)); }
  ctx.fillStyle = rgba(ACC, .35); ctx.fillRect(x0, cy - 1.5, W, 3);
  ctx.fillStyle = ACC; ctx.strokeStyle = ACC;
  if (style === 'wave') {
    const px = (i) => x0 + i * W / (n - 1);
    ctx.beginPath(); ctx.moveTo(px(0), cy - hs[0] / 2);
    for (let i = 1; i < n; i++) { const mx = (px(i - 1) + px(i)) / 2, my = (cy - hs[i - 1] / 2 + cy - hs[i] / 2) / 2; ctx.quadraticCurveTo(px(i - 1), cy - hs[i - 1] / 2, mx, my); }
    ctx.lineTo(px(n - 1), cy - hs[n - 1] / 2); ctx.lineTo(px(n - 1), cy + hs[n - 1] / 2);
    for (let i = n - 2; i >= 0; i--) { const mx = (px(i + 1) + px(i)) / 2, my = (cy + hs[i + 1] / 2 + cy + hs[i] / 2) / 2; ctx.quadraticCurveTo(px(i + 1), cy + hs[i + 1] / 2, mx, my); }
    ctx.lineTo(px(0), cy + hs[0] / 2); ctx.closePath();
    ctx.save(); ctx.globalAlpha = .3; ctx.fill(); ctx.restore(); ctx.lineWidth = 5; ctx.lineJoin = 'round'; ctx.stroke(); return;
  }
  const bw = style === 'thin' ? Math.round(6 * W / 900) : Math.round(12 * W / 900), gap = (W - n * bw) / (n - 1);
  for (let i = 0; i < n; i++) { rr(ctx, x0 + i * (bw + gap), cy - hs[i] / 2, bw, hs[i], bw / 2); ctx.fill(); }
}
function drawProgress(ctx, py, t, dur, ACC) {
  const p = dur ? clamp(t / dur, 0, 1) : 0;
  ctx.fillStyle = 'rgba(255,255,255,.25)'; rr(ctx, 100, py, 880, 7, 3.5); ctx.fill();
  ctx.fillStyle = ACC; rr(ctx, 100, py, Math.max(7, 880 * p), 7, 3.5); ctx.fill();
  ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.arc(100 + 880 * p, py + 3.5, 13, 0, 7); ctx.fill();
  ctx.direction = 'ltr'; ctx.textAlign = 'left'; setBase(ctx, 28, 700); ctx.fillStyle = 'rgba(255,255,255,.85)'; ctx.fillText(fmt(t), 100, py + 42);
  ctx.textAlign = 'right'; ctx.fillText(fmt(dur), 980, py + 42); ctx.direction = 'rtl';
}
function drawControls(ctx, cy, ACC, paused) {
  ctx.fillStyle = '#fff';
  const tri = (cx, dir) => { ctx.beginPath(); ctx.moveTo(cx + dir * 22, cy - 24); ctx.lineTo(cx - dir * 14, cy); ctx.lineTo(cx + dir * 22, cy + 24); ctx.closePath(); ctx.fill(); ctx.fillRect(cx - dir * 24 - 4, cy - 24, 8, 48); };
  tri(300, 1); tri(780, -1);
  ctx.fillStyle = ACC; ctx.beginPath(); ctx.arc(540, cy, 52, 0, 7); ctx.fill();
  ctx.fillStyle = '#1b1b1b';
  if (paused) { ctx.beginPath(); ctx.moveTo(526, cy - 24); ctx.lineTo(560, cy); ctx.lineTo(526, cy + 24); ctx.closePath(); ctx.fill(); }
  else { ctx.fillRect(522, cy - 24, 12, 48); ctx.fillRect(546, cy - 24, 12, 48); }
}
function coverShape(ctx, img, x, y, w, h, ACC) {
  const shape = cfg.cshape, r = shape === 'circle' ? Math.min(w, h) / 2 : shape === 'square' ? 0 : Math.min(w, h) * .05;
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.6)'; ctx.shadowBlur = 44; ctx.shadowOffsetY = 16; ctx.fillStyle = '#111'; rr(ctx, x, y, w, h, r); ctx.fill(); ctx.restore();
  ctx.save(); rr(ctx, x, y, w, h, r); ctx.clip();
  if (img && img.naturalWidth) drawCover(ctx, img, x, y, w, h); else { ctx.fillStyle = 'rgba(255,255,255,.12)'; ctx.fillRect(x, y, w, h); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.textAlign = 'center'; setBase(ctx, 44, 700); ctx.fillText('الصورة هنا', x + w / 2, y + h / 2); }
  ctx.restore();
  if (cfg.cborder) { ctx.strokeStyle = rgba(ACC, .9); ctx.lineWidth = 4; rr(ctx, x, y, w, h, r); ctx.stroke(); }
}
let CURSC = 1;
const discCache = new Map();
function renderDiscBase(ctx, R, img, ACC) {
  let g = ctx.createRadialGradient(0, 0, R * .2, 0, 0, R); g.addColorStop(0, '#1d1d1d'); g.addColorStop(1, '#040404');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, R, 0, 7); ctx.fill();
  ctx.strokeStyle = 'rgba(255,255,255,.055)'; ctx.lineWidth = 1.5;
  for (let r = R * .38; r < R * .97; r += R * .034) { ctx.beginPath(); ctx.arc(0, 0, r, 0, 7); ctx.stroke(); }
  ctx.save(); ctx.strokeStyle = rgba(ACC, .45); ctx.lineWidth = 4; ctx.lineCap = 'round';
  [[.62, .15, .55], [.62, Math.PI + .15, Math.PI + .55], [.82, 1.4, 1.75], [.82, Math.PI + 1.4, Math.PI + 1.75]].forEach((a) => { ctx.beginPath(); ctx.arc(0, 0, R * a[0], a[1], a[2]); ctx.stroke(); });
  ctx.beginPath(); ctx.arc(0, 0, R * .34, 0, 7); ctx.clip();
  if (img && img.naturalWidth) drawCover(ctx, img, -R * .34, -R * .34, R * .68, R * .68); else { ctx.fillStyle = ACC; ctx.fillRect(-R, -R, 2 * R, 2 * R); }
  ctx.restore();
  ctx.strokeStyle = ACC; ctx.lineWidth = 4; ctx.beginPath(); ctx.arc(0, 0, R * .34, 0, 7); ctx.stroke();
  ctx.fillStyle = '#0b0b0b'; ctx.beginPath(); ctx.arc(0, 0, R * .05, 0, 7); ctx.fill(); ctx.stroke();
}
function drawDisc(ctx, cx, cy, R, ang, img, ACC) {
  const key = [Math.round(R), img && img.src, img && img.naturalWidth, ACC, CURF, CURSC.toFixed(3)].join('|');
  let c = discCache.get(key);
  if (!c) {
    const pad = 3, sz = Math.ceil((2 * R + 2 * pad) * CURSC); c = document.createElement('canvas'); c.width = c.height = sz; const x = c.getContext('2d');
    x.scale(CURSC, CURSC); x.translate(R + pad, R + pad); renderDiscBase(x, R, img, ACC); c._pad = pad; discCache.set(key, c); if (discCache.size > 6) discCache.delete(discCache.keys().next().value);
  }
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(ang); ctx.drawImage(c, -R - c._pad, -R - c._pad, 2 * R + 2 * c._pad, 2 * R + 2 * c._pad); ctx.restore();
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(-.7);
  const g = ctx.createLinearGradient(0, -R, 0, R); g.addColorStop(0, 'rgba(255,255,255,0)'); g.addColorStop(.5, 'rgba(255,255,255,.08)'); g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g; ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, R, -.3, .3); ctx.closePath(); ctx.fill();
  ctx.beginPath(); ctx.moveTo(0, 0); ctx.arc(0, 0, R, Math.PI - .3, Math.PI + .3); ctx.closePath(); ctx.fill();
  ctx.restore();
}
function drawRingViz(ctx, cx, cy, Rc, vals, ang, img, ACC) {
  const n = 72, r0 = Rc + 30, maxL = 120;
  ctx.save(); ctx.strokeStyle = ACC; ctx.lineWidth = 9; ctx.lineCap = 'round';
  for (let i = 0; i < n; i++) {
    const a = Math.PI / 2 + i * 2 * Math.PI / n, k = Math.min(vals.length - 1, Math.floor(Math.abs(i - n / 2) / (n / 2) * vals.length)), len = 14 + vals[k] * maxL;
    ctx.beginPath(); ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); ctx.lineTo(cx + Math.cos(a) * (r0 + len), cy + Math.sin(a) * (r0 + len)); ctx.stroke();
  }
  ctx.restore();
  ctx.strokeStyle = rgba(ACC, .5); ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(cx, cy, Rc + 14, 0, 7); ctx.stroke();
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.55)'; ctx.shadowBlur = 40; ctx.shadowOffsetY = 14; ctx.fillStyle = '#111'; ctx.beginPath(); ctx.arc(cx, cy, Rc, 0, 7); ctx.fill(); ctx.restore();
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(ang); ctx.beginPath(); ctx.arc(0, 0, Rc, 0, 7); ctx.clip();
  if (img && img.naturalWidth) drawCover(ctx, img, -Rc, -Rc, 2 * Rc, 2 * Rc); else { ctx.fillStyle = 'rgba(255,255,255,.14)'; ctx.fillRect(-Rc, -Rc, 2 * Rc, 2 * Rc); ctx.rotate(-ang); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.textAlign = 'center'; setBase(ctx, 40, 700); ctx.fillText('الصورة هنا', 0, 0); }
  ctx.restore();
  ctx.strokeStyle = ACC; ctx.lineWidth = 6; ctx.beginPath(); ctx.arc(cx, cy, Rc, 0, 7); ctx.stroke();
}
function drawCassette(ctx, cx, y, w, t, img, ACC) {
  const h = w * .64, x = cx - w / 2, rot = t * Math.PI * 2 * .6 * cfg.dspeed;
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.55)'; ctx.shadowBlur = 40; ctx.shadowOffsetY = 16;
  let g = ctx.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, '#2b3037'); g.addColorStop(1, '#14171b'); ctx.fillStyle = g; rr(ctx, x, y, w, h, 34); ctx.fill(); ctx.restore();
  ctx.strokeStyle = 'rgba(255,255,255,.12)'; ctx.lineWidth = 3; rr(ctx, x, y, w, h, 34); ctx.stroke();
  [[.05, .07], [.95, .07], [.05, .93], [.95, .93]].forEach((p) => { ctx.fillStyle = '#0c0e10'; ctx.beginPath(); ctx.arc(x + w * p[0], y + h * p[1], 9, 0, 7); ctx.fill(); });
  const lx = x + w * .07, ly = y + h * .07, lw = w * .86, lh = h * .46;
  ctx.fillStyle = '#e8e0cc'; rr(ctx, lx, ly, lw, lh, 16); ctx.fill();
  ctx.save(); rr(ctx, lx, ly, lw, lh, 16); ctx.clip();
  if (img && img.naturalWidth) drawCover(ctx, img, lx, ly, lw, lh); else { ctx.fillStyle = rgba(ACC, .25); ctx.fillRect(lx, ly, lw, lh); ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.textAlign = 'center'; setBase(ctx, 40, 700); ctx.fillText('الصورة هنا', lx + lw / 2, ly + lh / 2); }
  ctx.restore();
  ctx.fillStyle = ACC; ctx.fillRect(lx, ly + lh - 8, lw, 8);
  const wy = y + h * .6, wh = h * .27, wx = x + w * .2, ww = w * .6;
  ctx.fillStyle = '#0b0d0f'; rr(ctx, wx, wy, ww, wh, wh / 2); ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.18)'; ctx.lineWidth = 3; ctx.stroke();
  const rx = [cx - ww * .24, cx + ww * .24], rcy = wy + wh / 2, rR = wh * .36;
  rx.forEach((px, i) => {
    ctx.fillStyle = '#3a2d22'; ctx.beginPath(); ctx.arc(px, rcy, rR * (i ? .86 : 1.08), 0, 7); ctx.fill();
    ctx.save(); ctx.translate(px, rcy); ctx.rotate(rot); ctx.strokeStyle = '#e9e9e9'; ctx.lineWidth = 5; ctx.beginPath(); ctx.arc(0, 0, rR * .62, 0, 7); ctx.stroke();
    for (let k = 0; k < 6; k++) { ctx.rotate(Math.PI / 3); ctx.beginPath(); ctx.moveTo(rR * .22, 0); ctx.lineTo(rR * .62, 0); ctx.stroke(); }
    ctx.restore();
  });
  ctx.strokeStyle = '#4a3a2c'; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(rx[0] + rR, rcy + rR * .7); ctx.lineTo(rx[1] - rR, rcy + rR * .7); ctx.stroke();
  ctx.fillStyle = '#0c0e10'; ctx.beginPath(); ctx.moveTo(x + w * .3, y + h); ctx.lineTo(x + w * .34, y + h * .9); ctx.lineTo(x + w * .66, y + h * .9); ctx.lineTo(x + w * .7, y + h); ctx.closePath(); ctx.fill();
  return h;
}

/* ---------- الرسم الرئيسي ---------- */
const layerCache = new Map();
function resetCtx(ctx, W, H) {
  if (ctx.reset) ctx.reset();
  else { ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over'; ctx.filter = 'none'; ctx.shadowColor = 'transparent'; ctx.shadowBlur = 0; ctx.shadowOffsetX = 0; ctx.shadowOffsetY = 0; ctx.lineWidth = 1; ctx.setLineDash([]); ctx.beginPath(); ctx.clearRect(0, 0, W, H); }
}
function draw(ctx, W, H, t, dur, src, o) {
  o = o || {};
  resetCtx(ctx, W, H); ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
  try { drawInner(ctx, W, H, t, dur, src, o); }
  catch (e) { if (!draw.warned) { draw.warned = 1; console.error('draw error', e && e.stack || e); } }
  try { drawLyrics(ctx, W, H, (o && o.srcT != null) ? o.srcT : t, (o && o.srcDur) || dur); } catch (e) {}
  try { drawTrialMark(ctx, W, H); } catch (e) {}
}
function drawInner(ctx, W, H, t, dur, src, o) {
  const audio = o.mode === 'audio', ACC = accent(); CURF = filterCSS(); CURSC = W / 1080;
  const VR = cfg.vreact || {}; const FR = (!audio && (VR.glow || VR.bars || VR.logo || VR.bg) && (o.spec || o.demo)) ? featAt(o, t) : null;
  drawBackground(ctx, W, H, src, o);
  if (FR && VR.bg) { ctx.fillStyle = rgba(ACC, clamp(.1 * FR.bass + .12 * FR.beat, 0, .3)); ctx.fillRect(0, 0, W, H); }
  ctx.setTransform(W / 1080, 0, 0, W / 1080, 0, 0);
  ctx.direction = 'rtl'; ctx.textBaseline = 'middle'; if (o.yShift) ctx.translate(0, o.yShift);
  const still = !!o.still, { items, T } = buildItems(ctx, o, ACC);
  const rt = cfg.safe ? 150 : 90, rb = cfg.safe ? 1560 : 1860, Rh = rb - rt;
  const logoH = 152 * cfg.logoSize, headH = cfg.logo ? logoH + 28 : 0, gap = 44;
  let textY = 0, post = null;
  const logoAt = (ly, k) => {
    k = (k || 1) * (FR && VR.logo ? 1 + .12 * FR.bass + .06 * FR.beat : 1); const lh = logoH * k, lw = lh / 2 + 26;
    if (cfg.logoOrn) { accLine(ctx, 540 - lw, 540 - 340, ly, 3, ACC); accLine(ctx, 540 + lw, 540 + 340, ly, 3, ACC); diamond(ctx, 540 - lw, ly, 8, ACC); diamond(ctx, 540 + lw, ly, 8, ACC); }
    const lg = currentLogo(), iw = lg.width || lg.naturalWidth, ih = lg.height || lg.naturalHeight;
    if (iw) { const ar = iw / ih; ctx.drawImage(lg, 540 - lh * ar / 2, ly - lh / 2, lh * ar, lh); }
  };

  if (audio) {
    const vals = barsAt(o, t), paused = !!o.still, spd = Math.PI * 2 / 5 * cfg.dspeed;
    const L = cfg.alay;
    if (NEW_AL[L]) {
      const RL = NEW_AL[L], F = featAt(o, t), G = headH + RL.h + gap + T + 120, y0 = rt + Math.max(0, (Rh - G) * .4), by = y0 + headH;
      if (cfg.logo) logoAt(y0 + logoH / 2);
      RL.draw(ctx, by, t, dur, o, F, ACC);
      textY = by + RL.h + gap; post = (yb) => drawProgress(ctx, yb + 30, t, dur, ACC);
    } else if (L === 'poster') {
      const cols = themeColors();
      if (o.img && o.img.naturalWidth) drawCover(ctx, o.img, 0, 0, 1080, 1040); else { ctx.fillStyle = 'rgba(255,255,255,.12)'; ctx.fillRect(0, 0, 1080, 1040); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.textAlign = 'center'; setBase(ctx, 44, 700); ctx.fillText('الصورة هنا', 540, 500); }
      const fc = mix(cols[1], cols[2], .18), g = ctx.createLinearGradient(0, 560, 0, 1090); g.addColorStop(0, rgba('#000000', 0)); g.addColorStop(1, 'rgba(0,0,0,.0)');
      const g2 = ctx.createLinearGradient(0, 520, 0, 1090); g2.addColorStop(0, rgba(fc, 0)); g2.addColorStop(.7, rgba(fc, .92)); g2.addColorStop(1, fc); ctx.fillStyle = g2; ctx.fillRect(0, 520, 1080, 580);
      ctx.fillStyle = fc; ctx.fillRect(0, 1090, 1080, 830);
      if (cfg.logo) logoAt(120, .72);
      textY = 790; post = (yb) => { drawWave(ctx, yb + 34 + 85, vals, 170, ACC); drawProgress(ctx, yb + 34 + 170 + 40, t, dur, ACC); };
    } else {
      const waveH = 150, progH = 90, gp = 34;
      let C, extra = 0;
      if (L === 'vinyl') { const rest = headH + gap + T + gp + waveH + gp + progH; C = Math.min(640, Math.max(340, Rh - rest)); extra = C; }
      else if (L === 'ring') { const rest = headH + gap + T + gp + progH + 190; C = Math.min(480, Math.max(300, Rh - rest - 150)); extra = C + 2 * 160; }
      else if (L === 'card') { const rest = headH + gap + T + gp + 90 + gp + 130 + 30; C = Math.min(760, Math.max(340, Rh - rest)); extra = C; }
      else { C = 860; extra = C * .64; }
      const G = headH + extra + gap + T + (L === 'vinyl' ? gp + waveH + gp + progH : L === 'ring' ? gp + progH + 20 : L === 'card' ? gp + 90 + gp + 130 : gp + progH + 40);
      const y0 = rt + Math.max(0, (Rh - G) * .4), by = y0 + headH;
      if (cfg.logo) logoAt(y0 + logoH / 2);
      if (L === 'vinyl') {
        const D = C * .93, coverX = (1080 - (C + D * .42)) / 2;
        drawDisc(ctx, coverX + C - D * .08, by + C / 2, D / 2, t * spd, o.img, ACC); coverShape(ctx, o.img, coverX, by, C, C, ACC);
        textY = by + C + gp; post = (yb) => { drawWave(ctx, yb + gp + waveH / 2, vals, waveH, ACC); drawProgress(ctx, yb + gp + waveH + gp, t, dur, ACC); };
      } else if (L === 'ring') {
        const cy = by + C / 2 + 160; drawRingViz(ctx, 540, cy, C / 2, vals, t * spd * .5, o.img, ACC);
        textY = cy + C / 2 + 160 + 14; post = (yb) => drawProgress(ctx, yb + gp, t, dur, ACC);
      } else if (L === 'card') {
        coverShape(ctx, o.img, 540 - C / 2, by, C, C, ACC);
        const wy = by + C + 34; drawWave(ctx, wy + 40, vals, 80, ACC, 700);
        textY = wy + 90; post = (yb) => { drawProgress(ctx, yb + gp - 6, t, dur, ACC); drawControls(ctx, yb + gp + 112, ACC, paused); };
      } else {
        const ch = drawCassette(ctx, 540, by, C, t, o.img, ACC);
        textY = by + ch + gap; post = (yb) => { drawWave(ctx, yb + gp + 60, vals, 120, ACC); drawProgress(ctx, yb + gp + 150, t, dur, ACC); };
      }
    }
  } else {
    const dims = srcDims(src); const hasV = !!dims; const aspect = hasV ? dims[0] / dims[1] : 16 / 9;
    const wAsp = cfg.vfit === 'sq' ? 1 : cfg.vfit === '45' ? .8 : aspect;
    const V = cfg.vlay;
    const availH = Math.max(320, Rh - headH - T - gap);
    const bw = V === 'blur' ? 1080 : V === 'card' ? 1010 : (cfg.frameStyle === 'none' ? 1080 : 1020);
    let dw = Math.min(bw, availH * wAsp), dh = dw / wAsp; dw *= cfg.vscale; dh *= cfg.vscale;
    const barsH = (FR && VR.bars) ? 120 : 0;
    const G = headH + dh + gap + T + barsH, y0 = rt + Math.max(0, (Rh - G) * .42), vy = y0 + headH, dx = (1080 - dw) / 2;
    if (cfg.logo) logoAt(y0 + logoH / 2);
    const rad = V === 'card' ? cfg.vrad : 0;
    if (V === 'card') { ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.55)'; ctx.shadowBlur = 50; ctx.shadowOffsetY = 18; ctx.fillStyle = '#000'; rr(ctx, dx, vy, dw, dh, rad); ctx.fill(); ctx.restore(); }
    if (hasV) {
      ctx.save(); if (o && o.vAlpha != null && o.vAlpha < 1) ctx.globalAlpha = o.vAlpha; rr(ctx, dx, vy, dw, dh, rad); ctx.clip(); ctx.fillStyle = '#000'; ctx.fillRect(dx, vy, dw, dh);
      let sw = dims[0], sh = dims[1], sx = 0, sy = 0;
      if (Math.abs(wAsp - aspect) >= .001) { if (aspect > wAsp) { sw = sh * wAsp; sx = (dims[0] - sw) / 2; } else { sh = sw / wAsp; sy = (dims[1] - sh) / 2; } }
      LASTV.dw = dw; LASTV.dh = dh; LASTV.cx = dx + dw / 2; LASTV.cy = vy + dh / 2; const T2 = cfg.vtf; const FXM = fxMove((o && o.srcT != null) ? o.srcT : t, FR); ctx.save(); if (FXM) { ctx.translate(dx + dw / 2 + FXM.x, vy + dh / 2 + FXM.y); ctx.scale(FXM.z, FXM.z); ctx.translate(-(dx + dw / 2), -(vy + dh / 2)); }
      if (T2 && (T2.z !== 1 || T2.x || T2.y || T2.r || T2.sx !== 1 || T2.sy !== 1 || T2.kx || T2.ky || T2.fh || T2.fv)) {
        ctx.save(); ctx.translate(dx + dw / 2 + T2.x / 100 * dw, vy + dh / 2 + T2.y / 100 * dh); ctx.rotate(T2.r * Math.PI / 180);
        if (T2.kx || T2.ky) ctx.transform(1, Math.tan((T2.ky || 0) * Math.PI / 180), Math.tan((T2.kx || 0) * Math.PI / 180), 1, 0, 0);
        ctx.scale(T2.z * T2.sx * (T2.fh ? -1 : 1), T2.z * T2.sy * (T2.fv ? -1 : 1));
        drawMedia(ctx, src, sx, sy, sw, sh, -dw / 2, -dh / 2, dw, dh); ctx.restore();
      } else drawMedia(ctx, src, sx, sy, sw, sh, dx, vy, dw, dh);
      ctx.restore(); vignette(ctx, dx, vy, dw, dh); grainOver(ctx, dx, vy, dw, dh, (o && o.srcT != null) ? o.srcT : t); ctx.restore();
    } else { ctx.fillStyle = 'rgba(0,0,0,.4)'; rr(ctx, dx, vy, dw, dh, rad); ctx.fill(); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.textAlign = 'center'; setBase(ctx, 44, 700); ctx.fillText('الفيديو هنا', 540, vy + dh / 2); }
    const th = cfg.fthick;
    ctx.save();
    if (FR && VR.glow && V === 'classic') { ctx.shadowColor = ACC; ctx.shadowBlur = 12 + 60 * FR.bass + 30 * FR.beat; }
    if (V === 'card' && FR && VR.glow) { ctx.save(); ctx.shadowColor = ACC; ctx.shadowBlur = 20 + 60 * FR.bass; ctx.strokeStyle = rgba(ACC, .5 + .4 * FR.bass); ctx.lineWidth = 5; rr(ctx, dx, vy, dw, dh, rad); ctx.stroke(); ctx.restore(); }
    if (V === 'blur') { ctx.fillStyle = ACC; ctx.fillRect(0, vy - 3 * th, 1080, 3 * th); ctx.fillRect(0, vy + dh, 1080, 3 * th); }
    else if (V === 'classic') {
      const fs = cfg.frameStyle;
      if (fs === 'double') {
        ctx.strokeStyle = ACC; ctx.lineWidth = 4 * th; ctx.strokeRect(dx - 12, vy - 12, dw + 24, dh + 24);
        ctx.strokeStyle = rgba(ACC, .55); ctx.lineWidth = 2 * th; ctx.strokeRect(dx - 5, vy - 5, dw + 10, dh + 10);
        [[dx - 12, vy - 12], [dx + dw + 12, vy - 12], [dx - 12, vy + dh + 12], [dx + dw + 12, vy + dh + 12]].forEach((p) => diamond(ctx, p[0], p[1], 11, ACC));
      } else if (fs === 'line') { ctx.strokeStyle = ACC; ctx.lineWidth = 4 * th; ctx.strokeRect(dx - 8, vy - 8, dw + 16, dh + 16); }
      else if (fs === 'glow') { ctx.save(); ctx.shadowColor = ACC; ctx.shadowBlur = 30; ctx.strokeStyle = ACC; ctx.lineWidth = 4 * th; ctx.strokeRect(dx - 6, vy - 6, dw + 12, dh + 12); ctx.restore(); }
      else if (fs === 'corners') {
        ctx.strokeStyle = ACC; ctx.lineWidth = 7 * th; ctx.lineCap = 'square'; const L = 80, o2 = 12;
        [[dx - o2, vy - o2, 1, 1], [dx + dw + o2, vy - o2, -1, 1], [dx - o2, vy + dh + o2, 1, -1], [dx + dw + o2, vy + dh + o2, -1, -1]].forEach((c) => { ctx.beginPath(); ctx.moveTo(c[0] + c[2] * L, c[1]); ctx.lineTo(c[0], c[1]); ctx.lineTo(c[0], c[1] + c[3] * L); ctx.stroke(); });
      }
    }
    ctx.restore();
    if (barsH) {
      const n = 44, W2 = 920, x0 = 540 - W2 / 2, bw = 14, gp = (W2 - n * bw) / (n - 1), base = vy + dh + 30 + barsH - 30, v = interpVals(FR.vals, n, true);
      ctx.fillStyle = ACC; for (let i = 0; i < n; i++) { const h = Math.max(5, v[i] * 80); rr(ctx, x0 + i * (bw + gp), base - h, bw, h, 7); ctx.fill(); }
    }
    textY = vy + dh + gap + barsH + (V === 'classic' && cfg.frameStyle !== 'none' ? 12 : 0);
  }
  const outStart = audio ? 1e9 : Math.max(dur - 1.0, 1.8);
  const settled = still || cfg.anim === 'none' || (t > 2.6 && t < outStart - 0.01);
  if (settled) {
    const sc = W / 1080, ly0 = Math.max(0, Math.floor(textY - 30)), lhh = Math.max(40, Math.min(1920 - ly0, Math.ceil(T + 90)));
    const key = JSON.stringify([W, ly0, lhh, o.preview ? 1 : 0, o.title, o.occ, o.reciter, o.poet, o.titleFx && o.titleFx._id, cfg.font, cfg.tcol, cfg.tcustom, cfg.tscale, cfg.nscale, cfg.tout, cfg.tglow, cfg.tshadow, cfg.lblCol, cfg.valCol, ACC]);
    let lay = layerCache.get(key);
    if (!lay) {
      lay = document.createElement('canvas'); lay.width = W; lay.height = Math.ceil(lhh * sc); const lx = lay.getContext('2d'); lx.setTransform(sc, 0, 0, sc, 0, -ly0 * sc); lx.direction = 'rtl'; lx.textBaseline = 'middle';
      const bi = buildItems(lx, o, ACC); let yy = textY; bi.items.forEach((it) => { it.fn(yy); yy += it.h; });
      layerCache.set(key, lay); if (layerCache.size > 8) layerCache.delete(layerCache.keys().next().value);
    }
    ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.drawImage(lay, 0, Math.round(ly0 * sc)); ctx.restore();
  } else {
    let y = textY;
    items.forEach((it) => {
      let a = 1;
      if (!still && cfg.anim !== 'none') a = ease(clamp((t - it.delay) / .6, 0, 1)) * (1 - ease(clamp((t - outStart) / .6, 0, 1)));
      if (a > 0.003) {
        ctx.save(); ctx.globalAlpha = a;
        if (cfg.anim === 'slide') ctx.translate(0, (1 - a) * 28);
        else if (cfg.anim === 'zoom') { const cy = y + it.h / 2, sc = .88 + .12 * a; ctx.translate(540, cy); ctx.scale(sc, sc); ctx.translate(-540, -cy); }
        it.fn(y); ctx.restore();
      }
      y += it.h;
    });
  }
  const y = textY + T;
  if (post && !o.promo) post(y);
  if (o.guide) {
    ctx.fillStyle = 'rgba(255,40,40,.28)'; ctx.fillRect(0, 0, 1080, 150); ctx.fillRect(0, 1560, 1080, 360); ctx.fillRect(950, 760, 130, 800);
    ctx.fillStyle = '#fff'; ctx.textAlign = 'center'; setBase(ctx, 30, 700); ctx.fillText('واجهة تيك توك', 540, 1740);
  }
}
function withCfg(over, fn) { const keep = {}; Object.keys(over).forEach((k) => { keep[k] = cfg[k]; cfg[k] = over[k]; }); try { return fn(); } finally { Object.keys(keep).forEach((k) => { cfg[k] = keep[k]; }); } }
/* ---------- ميزات الصوت للحركة ---------- */
const rnd = (i, k) => { const x = Math.sin(i * 127.1 + k * 311.7) * 43758.5453; return x - Math.floor(x); };
function featAt(o, t) {
  if (o.srcT != null) t = o.srcT;
  const sp = o.spec;
  if (sp && sp.vol) {
    const f = clamp(Math.floor(t * sp.fps), 0, sp.frames - 1);
    return { f, vals: sp.data.subarray(f * 22, f * 22 + 22), vol: sp.vol[f], bass: sp.bass[f], mid: sp.mid[f], hi: sp.hi[f], beat: sp.beat[f], cum: sp.cum[f], sp };
  }
  const b = Math.max(0, Math.sin(t * 6.3));
  return { f: Math.floor(t * 30), vals: barsAt(o, t), vol: .45 + .2 * Math.sin(t * 2.1), bass: .35 + .4 * b, mid: .4 + .2 * Math.sin(t * 3.7), hi: .35 + .2 * Math.sin(t * 5), beat: Math.pow(b, 4), cum: t * .5, sp: null };
}
function valsBack(F, o, t, k) {
  if (F.hist && F.hist.length) return F.hist[Math.min(k, F.hist.length - 1)];
  if (F.sp) { const f = Math.max(0, F.f - k); return F.sp.data.subarray(f * 22, f * 22 + 22); }
  return barsAt(o, Math.max(0, t - k / 30));
}
function interpVals(vals, n, mirror) {
  const out = new Array(n), m = vals.length - 1;
  for (let i = 0; i < n; i++) {
    const u = mirror ? Math.abs(i - (n - 1) / 2) / ((n - 1) / 2) : i / (n - 1), p = u * m, a = Math.floor(p), b = Math.min(m, a + 1), w = p - a;
    out[i] = vals[a] * (1 - w) + vals[b] * w;
  }
  return out;
}
function coverAny(ctx, img, x, y, w, h, shape, ACC, bw) {
  const r = shape === 'circle' ? Math.min(w, h) / 2 : shape === 'square' ? 0 : Math.min(w, h) * .06;
  ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.6)'; ctx.shadowBlur = 40; ctx.shadowOffsetY = 14; ctx.fillStyle = '#111'; rr(ctx, x, y, w, h, r); ctx.fill(); ctx.restore();
  ctx.save(); rr(ctx, x, y, w, h, r); ctx.clip();
  if (img && img.naturalWidth) drawCover(ctx, img, x, y, w, h); else { ctx.fillStyle = 'rgba(255,255,255,.14)'; ctx.fillRect(x, y, w, h); ctx.fillStyle = 'rgba(255,255,255,.7)'; ctx.textAlign = 'center'; setBase(ctx, 38, 700); ctx.fillText('الصورة هنا', x + w / 2, y + h / 2); }
  ctx.restore();
  if (cfg.cborder) { ctx.strokeStyle = rgba(ACC, .95); ctx.lineWidth = bw || 5; rr(ctx, x, y, w, h, r); ctx.stroke(); }
}

const __dots = {}; function dotSprite(c) { if (__dots[c]) return __dots[c]; const s = document.createElement('canvas'); s.width = s.height = 32; const x = s.getContext('2d'); x.fillStyle = c; x.beginPath(); x.arc(16, 16, 15, 0, 7); x.fill(); return (__dots[c] = s); }
const NEW_AL = {
  pulse: { h: 700, bg: null, draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, cy = by + 350, R = 200;
    let g = ctx.createRadialGradient(cx, cy, R * .5, cx, cy, R * 2.3); g.addColorStop(0, rgba(ACC, .12 + .5 * F.bass)); g.addColorStop(1, rgba(ACC, 0)); ctx.fillStyle = g; ctx.fillRect(cx - 520, cy - 360, 1040, 720);
    for (let k = 0; k < 5; k++) { const ph = (F.cum * .5 + k / 5) % 1, r = R * 1.1 + ph * R * 1.45; ctx.strokeStyle = rgba(ACC, (1 - ph) * (.2 + .7 * F.vol)); ctx.lineWidth = 3 + (1 - ph) * 6 * (.4 + F.beat); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 7); ctx.stroke(); }
    const s = 1 + .07 * F.bass + .08 * F.beat; ctx.save(); ctx.translate(cx, cy); ctx.scale(s, s); coverAny(ctx, o.img, -R, -R, 2 * R, 2 * R, 'circle', ACC, 6 + 4 * F.beat); ctx.restore();
  } },
  particles: { h: 700, bg: null, draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, cy = by + 350;
    for (let i = 0; i < 190; i++) {
      const ang = rnd(i, 1) * Math.PI * 2, spd = .4 + rnd(i, 2) * 1.3, off = rnd(i, 3), sz = 1.6 + rnd(i, 4) * 4.6, ph = (F.cum * spd * .9 + off) % 1, r = 170 + ph * 360;
      const a = (1 - ph) * Math.min(1, .3 + F.vol * 1.1 + F.beat * .6), rd = sz * (1 + F.beat * .8) * (1 - ph * .45);
      if (window.__plrDrawing) { const sp = dotSprite(i % 3 ? ACC : '#ffffff'); ctx.globalAlpha = a; ctx.drawImage(sp, cx + Math.cos(ang) * r - rd, cy + Math.sin(ang) * r * .94 - rd, rd * 2, rd * 2); ctx.globalAlpha = 1; continue; }
      ctx.fillStyle = i % 3 ? rgba(ACC, a) : `rgba(255,255,255,${a})`; ctx.beginPath(); ctx.arc(cx + Math.cos(ang) * r, cy + Math.sin(ang) * r * .94, rd, 0, 7); ctx.fill();
    }
    const s = 1 + .03 * F.bass + .04 * F.beat; ctx.save(); ctx.translate(cx, cy); ctx.scale(s, s); coverAny(ctx, o.img, -170, -170, 340, 340, cfg.cshape, ACC, 5); ctx.restore();
  } },
  mirror: { h: 720, bg: 'blur', draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, cy = by + 150, R = 130, s = 1 + .04 * F.bass + .05 * F.beat;
    ctx.save(); ctx.translate(cx, cy); ctx.scale(s, s); coverAny(ctx, o.img, -R, -R, 2 * R, 2 * R, 'circle', ACC, 5); ctx.restore();
    const n = 40, W = 960, x0 = 540 - W / 2, bw = 16, gap = (W - n * bw) / (n - 1), base = by + 560, H = 250;
    const v = interpVals(F.vals, n, true), peaks = new Array(n).fill(0);
    for (let j = 0; j < 12; j++) { const vv = interpVals(valsBack(F, o, t, j), n, true); for (let i = 0; i < n; i++) peaks[i] = Math.max(peaks[i], vv[i] - j * .035); }
    const g = ctx.createLinearGradient(0, base - H, 0, base); g.addColorStop(0, '#fff'); g.addColorStop(1, ACC);
    ctx.fillStyle = g; for (let i = 0; i < n; i++) { const h = Math.max(6, v[i] * H); rr(ctx, x0 + i * (bw + gap), base - h, bw, h, 6); ctx.fill(); }
    ctx.fillStyle = ACC; for (let i = 0; i < n; i++) ctx.fillRect(x0 + i * (bw + gap), base - Math.max(Math.max(6, v[i] * H) + 6, peaks[i] * H) - 8, bw, 5);
    ctx.fillStyle = rgba(ACC, .2); for (let i = 0; i < n; i++) { rr(ctx, x0 + i * (bw + gap), base + 6, bw, Math.max(6, v[i] * H) * .5, 6); ctx.fill(); }
    ctx.fillStyle = rgba(ACC, .5); ctx.fillRect(x0, base, W, 3);
  } },
  neon: { h: 700, bg: 'dark', draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, S = 430, x = cx - S / 2, y = by + 30, glow = 18 + 70 * F.vol + 40 * F.beat, fl = .88 + .12 * Math.sin(t * 41) * (1 - F.vol * .5);
    let g = ctx.createRadialGradient(cx, y + S / 2, 40, cx, y + S / 2, 460); g.addColorStop(0, rgba(ACC, .08 + .25 * F.bass)); g.addColorStop(1, rgba(ACC, 0)); ctx.fillStyle = g; ctx.fillRect(cx - 540, y - 120, 1080, 760);
    coverAny(ctx, o.img, x, y, S, S, 'round', ACC, 0);
    ctx.save(); ctx.strokeStyle = ACC; ctx.lineJoin = 'round';
    [[44, .07], [28, .12], [16, .22]].forEach((e) => { ctx.globalAlpha = Math.min(1, e[1] * (1 + glow / 60)) * fl; ctx.lineWidth = e[0]; rr(ctx, x - 14, y - 14, S + 28, S + 28, 38); ctx.stroke(); });
    ctx.globalAlpha = fl; ctx.lineWidth = 6; rr(ctx, x - 14, y - 14, S + 28, S + 28, 38); ctx.stroke();
    ctx.restore();
    const n = 30, W = 900, x0 = 540 - W / 2, bw = 14, gp = (W - n * bw) / (n - 1), base = y + S + 210, v = interpVals(F.vals, n, true);
    ctx.save(); ctx.fillStyle = ACC;
    ctx.globalAlpha = .18 * fl; for (let i = 0; i < n; i++) { const h = Math.max(8, v[i] * 170); rr(ctx, x0 + i * (bw + gp) - 8, base - h - 8, bw + 16, h + 16, 12); ctx.fill(); }
    ctx.globalAlpha = fl; for (let i = 0; i < n; i++) { const h = Math.max(8, v[i] * 170); rr(ctx, x0 + i * (bw + gp), base - h, bw, h, 7); ctx.fill(); }
    ctx.restore();
  } },
  vu: { h: 690, bg: null, draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, C = 330; coverAny(ctx, o.img, cx - C / 2, by + 6, C, C, 'round', ACC, 5);
    const gauge = (gx, gy, val, lbl) => {
      const w = 440, h = 300; ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.5)'; ctx.shadowBlur = 28; ctx.shadowOffsetY = 10; ctx.fillStyle = mix('#efe6cf', ACC, .12); rr(ctx, gx, gy, w, h, 26); ctx.fill(); ctx.restore();
      ctx.strokeStyle = 'rgba(0,0,0,.35)'; ctx.lineWidth = 3; rr(ctx, gx, gy, w, h, 26); ctx.stroke();
      const px = gx + w / 2, py = gy + h - 36, R = 205, a0 = -145 * Math.PI / 180, a1 = -35 * Math.PI / 180;
      for (let i = 0; i <= 20; i++) { const a = a0 + (a1 - a0) * i / 20, big = i % 5 === 0, r1 = R - (big ? 30 : 16); ctx.strokeStyle = i >= 16 ? '#c0392b' : '#1b1b1b'; ctx.lineWidth = big ? 5 : 3; ctx.beginPath(); ctx.moveTo(px + Math.cos(a) * r1, py + Math.sin(a) * r1); ctx.lineTo(px + Math.cos(a) * R, py + Math.sin(a) * R); ctx.stroke(); }
      ctx.strokeStyle = '#c0392b'; ctx.lineWidth = 8; ctx.beginPath(); ctx.arc(px, py, R + 10, a0 + (a1 - a0) * .8, a1); ctx.stroke();
      ctx.fillStyle = '#222'; ctx.textAlign = 'center'; setBase(ctx, 30, 700); ctx.fillText('VU', px, gy + 78); setBase(ctx, 24, 700); ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fillText(lbl, px, gy + h - 12);
      const a = a0 + (a1 - a0) * clamp(val, 0, 1); ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.4)'; ctx.shadowBlur = 6; ctx.shadowOffsetX = 4; ctx.strokeStyle = '#111'; ctx.lineWidth = 4; ctx.lineCap = 'round'; ctx.beginPath(); ctx.moveTo(px, py); ctx.lineTo(px + Math.cos(a) * (R - 10), py + Math.sin(a) * (R - 10)); ctx.stroke(); ctx.restore();
      ctx.fillStyle = '#111'; ctx.beginPath(); ctx.arc(px, py, 16, 0, 7); ctx.fill(); ctx.fillStyle = ACC; ctx.beginPath(); ctx.arc(px, py, 7, 0, 7); ctx.fill();
    };
    let l = 0, r = 0; for (let j = 0; j < 4; j++) { const vv = valsBack(F, o, t, j); let a = 0, b = 0; for (let k = 0; k < 22; k++) { if (k < 11) a += vv[k]; else b += vv[k]; } l += a / 11; r += b / 11; }
    gauge(70, by + 380, clamp(l / 4 * .95 + F.beat * .1, 0, 1), 'LOW'); gauge(570, by + 380, clamp(r / 4 * 1.15, 0, 1), 'HIGH');
  } },
  starpulse: { h: 740, bg: null, draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, cy = by + 370, st = (R, rot, lw, a) => { ctx.save(); ctx.translate(cx, cy); ctx.rotate(rot); ctx.strokeStyle = rgba(ACC, a); ctx.lineWidth = lw; ctx.lineJoin = 'miter'; ctx.stroke(new Path2D(octaPath(0, 0, R))); ctx.restore(); };
    let g = ctx.createRadialGradient(cx, cy, 80, cx, cy, 400); g.addColorStop(0, rgba(ACC, .1 + .3 * F.bass)); g.addColorStop(1, rgba(ACC, 0)); ctx.fillStyle = g; ctx.fillRect(cx - 520, cy - 400, 1040, 800);
    for (let k = 0; k < 3; k++) { const ph = (F.cum * .35 + k / 3) % 1; st(250 + ph * 150, F.cum * .2, 3 + (1 - ph) * 4, (1 - ph) * (.25 + .6 * F.vol)); }
    st(335 * (1 + .05 * F.bass), F.cum * .25, 6, .95); st(285 * (1 + .04 * F.mid), -F.cum * .3, 3, .6);
    for (let i = 0; i < 8; i++) { const a = -Math.PI / 2 + i * Math.PI / 4 + F.cum * .25, R = 335 * (1 + .05 * F.bass); diamond(ctx, cx + Math.cos(a) * R, cy + Math.sin(a) * R, 10 + 8 * F.beat, ACC); }
    const s = 1 + .05 * F.bass + .05 * F.beat; ctx.save(); ctx.translate(cx, cy); ctx.scale(s, s);
    ctx.save(); ctx.shadowColor = 'rgba(0,0,0,.6)'; ctx.shadowBlur = 40; ctx.fillStyle = '#111'; ctx.fill(new Path2D(octaPath(0, 0, 215))); ctx.restore();
    ctx.save(); ctx.clip(new Path2D(octaPath(0, 0, 215))); if (o.img && o.img.naturalWidth) drawCover(ctx, o.img, -215, -215, 430, 430); else { ctx.fillStyle = 'rgba(255,255,255,.14)'; ctx.fillRect(-215, -215, 430, 430); } ctx.restore();
    ctx.strokeStyle = ACC; ctx.lineWidth = 6; ctx.stroke(new Path2D(octaPath(0, 0, 215))); ctx.restore();
  } },
  ridges: { h: 700, bg: 'dark', draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, R = 100; ctx.save(); ctx.translate(cx, by + 110); const s = 1 + .04 * F.beat; ctx.scale(s, s); coverAny(ctx, o.img, -R, -R, 2 * R, 2 * R, 'circle', ACC, 5); ctx.restore();
    const x0 = 90, W = 900, py = by + 250, ph = 440; ctx.fillStyle = '#071210'; rr(ctx, x0 - 24, py, W + 48, ph, 26); ctx.fill(); ctx.strokeStyle = rgba(ACC, .3); ctx.lineWidth = 2; ctx.stroke();
    const rows = 17, base = py + ph - 34, np = 64;
    for (let j = rows - 1; j >= 0; j--) {
      const v = interpVals(valsBack(F, o, t, j * 2), np, true), y = base - j * 21;
      ctx.beginPath(); ctx.moveTo(x0, y);
      for (let i = 0; i < np; i++) { const u = (i / (np - 1)) * 2 - 1, env = Math.exp(-u * u * 2.2), x = x0 + i * W / (np - 1); ctx.lineTo(x, y - v[i] * env * 120 * (1 - j * .02)); }
      ctx.lineTo(x0 + W, y); ctx.lineTo(x0 + W, y + 40); ctx.lineTo(x0, y + 40); ctx.closePath(); ctx.fillStyle = '#071210'; ctx.fill();
      ctx.beginPath(); ctx.moveTo(x0, y); for (let i = 0; i < np; i++) { const u = (i / (np - 1)) * 2 - 1, env = Math.exp(-u * u * 2.2); ctx.lineTo(x0 + i * W / (np - 1), y - v[i] * env * 120 * (1 - j * .02)); }
      ctx.strokeStyle = rgba(ACC, .95 - j * .045); ctx.lineWidth = 3; ctx.lineJoin = 'round'; ctx.stroke();
    }
  } },
  sphere: { h: 720, bg: null, draw(ctx, by, t, dur, o, F, ACC) {
    const cx = 540, cy = by + 360, N = 380, R0 = 235, rot = F.cum * .6, tilt = .38, ca = Math.cos(rot), sa = Math.sin(rot), ct = Math.cos(tilt), st = Math.sin(tilt), pts = [];
    for (let i = 0; i < N; i++) {
      const y = 1 - 2 * (i + .5) / N, r = Math.sqrt(1 - y * y), th = i * 2.399963, x = Math.cos(th) * r, z = Math.sin(th) * r;
      const band = Math.min(21, Math.floor((y + 1) / 2 * 22)), rf = 1 + .34 * F.vals[band] + .2 * F.beat;
      let x1 = x * ca + z * sa, z1 = -x * sa + z * ca, y1 = y * ct - z1 * st, z2 = y * st + z1 * ct;
      pts.push([cx + x1 * R0 * rf, cy + y1 * R0 * rf, z2, F.vals[band]]);
    }
    const dot = (p) => { const a = .22 + .78 * (p[2] + 1) / 2, s = 2 + (p[2] + 1) * 2.4 + p[3] * 3; ctx.fillStyle = p[3] > .7 ? `rgba(255,255,255,${a})` : rgba(ACC, a); ctx.beginPath(); ctx.arc(p[0], p[1], s, 0, 7); ctx.fill(); };
    pts.filter((p) => p[2] < 0).forEach(dot);
    const sc = 1 + .04 * F.beat; ctx.save(); ctx.translate(cx, cy); ctx.scale(sc, sc); coverAny(ctx, o.img, -120, -120, 240, 240, 'circle', ACC, 5); ctx.restore();
    pts.filter((p) => p[2] >= 0).forEach(dot);
  } }
};
function formState() { return { title: $('fTitle').value.trim(), occ: [$('fOcc').value.trim(), $('fPlace').value.trim()].filter(Boolean).join(' • '), reciter: $('fReciter').value.trim(), poet: $('fPoet').value.trim(), titleFx: S.titleFx, bgImg: S.bgImg }; }

/* ---------- المعاينة ---------- */
const pc = $('pc'), pctx = pc.getContext('2d'), pv = $('pv');
let lastW = 0;
function fitCanvas() {
  const w = $('pc').parentElement.clientWidth || 360, dpr = Math.min(window.devicePixelRatio || 1, 3);
  let tw = Math.round(Math.min(prevCap(), Math.max(360, w * dpr)) / 2) * 2; if (S.url && !pv.paused) tw = Math.min(tw, 720);
  const th = Math.round(tw * 16 / 9 / 2) * 2;
  if (pc.width !== tw || pc.height !== th) { pc.width = tw; pc.height = th; dirty(); }
}
window.addEventListener('resize', fitCanvas);
if (window.ResizeObserver) new ResizeObserver(fitCanvas).observe($('pc').parentElement);
function render() {
  const demo = !S.url;
  let t = demo ? (performance.now() / 1000) % 9 : pv.currentTime;
  let dur = demo ? 9 : (pv.duration || S.dur || 9), srcT = null, vA = 1; const srcDur = dur;
  if (!demo && trimActive()) { const rs = keepRanges(dur), ci = segSync(t, rs), to = srcToOut(t, rs, ci); srcT = t; t = to < 0 ? 0 : to; dur = rangesLen(rs) || dur; vA = fadeA(segList(srcDur)[ci] || { a: 0, b: srcDur, fi: 0, fo: 0 }, srcT); }
  draw(pctx, pc.width, pc.height, t, dur, (demo || S.mode === 'audio') ? null : pv, Object.assign(formState(), { vAlpha: vA, preview: true, demo, srcT, srcDur, still: !demo && pv.paused, guide: $('guideOn').checked, mode: S.mode, img: S.img, spec: S.mode === 'audio' ? S.spec : S.vspec }));
  if (typeof vtfOverlay === 'function') { try { vtfOverlay(); } catch (x) {} }
}
let tkL = 0;
function tick(ts) {
  if (document.hidden || (window.PLR && PLR.visible && PLR.visible())) { requestAnimationFrame(tick); return; }
  if (!S.url && pv.paused && !needs && ts - tkL < 33) { requestAnimationFrame(tick); return; } tkL = ts || 0;
  trimGuard(); if (openP === 'trim' && !pv.paused) tlPh();
  if (!S.url || !pv.paused || needs) { try { render(); } catch (e) {} needs = false; }
  requestAnimationFrame(tick);
}
['seeked', 'loadeddata'].forEach((e) => pv.addEventListener(e, dirty));
['pause', 'play'].forEach((e) => pv.addEventListener(e, () => { fitCanvas(); dirty(); }));
pv.addEventListener('timeupdate', () => { if (S.url) { const od = outDur(), on = outNow(); $('seek').value = od ? Math.round(on / od * 1000) : 0; $('tcur').textContent = fmt(on); } });
pv.addEventListener('ended', () => { $('playBtn').textContent = '▶'; dirty(); });
function togglePlay() {
  if (!S.url) return;
  if (pv.paused) { if (pv.ended || pv.currentTime >= pv.duration - 0.05) pv.currentTime = 0; pv.muted = !!afxOut; pv.play().catch(() => {}); $('playBtn').textContent = '⏸'; }
  else { pv.pause(); $('playBtn').textContent = '▶'; }
  dirty();
}
$('playBtn').addEventListener('click', (e) => { e.stopPropagation(); togglePlay(); });
pc.addEventListener('click', togglePlay);
$('seek').addEventListener('input', () => { if (!S.url || !pv.duration) return; pv.pause(); $('playBtn').textContent = '▶'; seekOut($('seek').value / 1000 * outDur()); dirty(); });

function setMode(m) {
  S.mode = m; touchProject(); pv.pause(); $('playBtn').textContent = '▶';
  S.url = m === 'video' ? vUrl : aUrl; S.file = m === 'video' ? vFile : aFile;
  if (S.url) { pv.src = S.url; pv.load(); } else { pv.removeAttribute('src'); pv.load(); }
  $('vidPick').hidden = m !== 'video'; $('audPick').hidden = m !== 'audio'; $('playBtn').hidden = !S.url;
  document.querySelectorAll('[data-m]').forEach((e) => { e.hidden = e.dataset.m !== m; });
  $('vinfo').textContent = S.url ? '' : (m === 'video' ? 'لحد الآن ما اخترت فيديو، هذا عرض تجريبي للقالب' : 'اختر صورة وصوت. هذا عرض تجريبي لقالب القرص والموجة');
  buildChips('modeChips', MODES, (i, it) => S.mode === it[0], (i, it) => setMode(it[0]));
  dirty(); refreshDesign();
}
const MODES = [['video', 'فيديو'], ['audio', 'صورة + صوت']];
pv.addEventListener('loadedmetadata', () => {
  S.dur = pv.duration; $('tdur').textContent = fmt(S.dur); $('playBtn').hidden = false; $('playBtn').textContent = '▶';
  if (S.mode === 'video') { $('vinfo').textContent = `الفيديو: ${pv.videoWidth}×${pv.videoHeight} · ${fmt(S.dur)}` + (S.dur > 200 ? ' · طويل، التصدير ياخذ وقت' : ''); pv.currentTime = Math.min(0.1, S.dur / 2); }
  else { pv.currentTime = 0; }
  dirty(); setTimeout(refreshDesign, 300);
});
pv.addEventListener('error', () => { if (pv.getAttribute('src')) toast('هذا الملف ما يشتغل بالمتصفح'); });
$('fileIn').addEventListener('change', (e) => {
  const f = e.target.files[0]; if (!f) return;
  if (vUrl) URL.revokeObjectURL(vUrl); vFile = f; vUrl = URL.createObjectURL(f); S.vspec = null; setMode('video');
  (async () => { try { const b = await decodeAudio(f); if (b && vFile === f) { S.vspec = await computeSpectrum(b); $('vinfo').textContent += ' · تم تحليل الصوت'; dirty(); } } catch (e) {} })();
});
$('imgIn').addEventListener('change', (e) => {
  const f = e.target.files[0]; if (!f) return;
  S.imgFile = f; const im = new Image(); im.onload = () => { S.img = im; dirty(); toast('تم اختيار الصورة'); refreshDesign(); }; im.src = URL.createObjectURL(f);
});
$('audIn').addEventListener('change', async (e) => {
  const f = e.target.files[0]; if (!f) return;
  if (aUrl) URL.revokeObjectURL(aUrl); aFile = f; aUrl = URL.createObjectURL(f); S.abuf = null; S.spec = null; setMode('audio');
  $('vinfo').textContent = 'جاري تحليل الصوت...';
  const buf = await decodeAudio(f);
  if (!buf) { $('vinfo').textContent = 'ما قدرت أقرأ هذا الصوت'; return; }
  S.abuf = buf; S.spec = await computeSpectrum(buf, (p) => { $('vinfo').textContent = 'جاري تحليل الصوت ' + Math.round(p * 100) + '%'; });
  $('vinfo').textContent = `الصوت: ${fmt(buf.duration)}` + (buf.duration > 300 ? ' · طويل' : ''); dirty();
});
['fTitle', 'fOcc', 'fPlace', 'fReciter', 'fPoet'].forEach((id) => $(id).addEventListener('input', dirty));


/* ---------- الواجهة ---------- */
function buildChips(id, list, cur, onPick, fontFn) {
  const box = $(id); box.innerHTML = '';
  list.forEach((it, i) => { const b = document.createElement('button'); b.className = 'chip' + (cur(i, it) ? ' on' : ''); b.textContent = it[1]; if (fontFn) { b.style.fontFamily = `"${it[0]}","F0"`; b.style.fontWeight = it[2]; } b.onclick = () => { onPick(i, it); buildChips(id, list, cur, onPick, fontFn); dirty(); }; box.appendChild(b); });
}
function loadFont() { const f = FONTS[cfg.font]; return Promise.all([document.fonts.load(`${f[2]} 40px "${f[0]}"`, 'قصيدة'), document.fonts.load('700 40px "F0"', 'قصيدة')]).then(dirty).catch(() => {}); }
const slFmt = (v, m, u) => u === 'x' ? v.toFixed(1) + 'x' : Math.round(v * m) + u;
const shows = [], checks = [];
function bindSlider(id, vid, get, set, mult, unit, after) {
  const el = $(id), show = () => { el.value = Math.round(get() * mult); $(vid).textContent = slFmt(get(), mult, unit); };
  el.addEventListener('input', () => { set(+el.value / mult); $(vid).textContent = slFmt(get(), mult, unit); saveCfg(); dirty(); if (after) after(); });
  shows.push(show);
}
function bindCheck(id, get, set, after) {
  const el = $(id); el.addEventListener('change', () => { set(el.checked); saveCfg(); dirty(); if (after) after(); }); checks.push(() => { el.checked = !!get(); });
}
const tpAfterFull = () => rebuildTitle(true), tpAfterFx = () => rebuildTitle(false);
const logoAfter = () => { cfg.logoMode = 'builder'; loadLogo(); drawLogoPreview(); };
[['vsize', 'vsizeVal', 'vscale', 100, '%'], ['dspeed', 'dspeedV', 'dspeed', 100, 'x'], ['patA', 'patAV', 'patA', 1, '%'], ['bgBlur', 'bgBlurV', 'bgBlur', 1, ''], ['bgDim', 'bgDimV', 'bgDim', 1, ''],
  ['tscale', 'tscaleV', 'tscale', 100, '%'], ['nscale', 'nscaleV', 'nscale', 100, '%'], ['tglow', 'tglowV', 'tglow', 1, ''], ['tshadow', 'tshadowV', 'tshadow', 1, ''],
  ['fthick', 'fthickV', 'fthick', 100, '%'], ['vrad', 'vradV', 'vrad', 1, ''], ['fint', 'fintV', 'fint', 100, '%'], ['fbri', 'fbriV', 'fbri', 1, ''], ['fcon', 'fconV', 'fcon', 1, ''],
  ['fsat', 'fsatV', 'fsat', 1, ''], ['fwarm', 'fwarmV', 'fwarm', 1, ''], ['fvig', 'fvigV', 'fvig', 1, ''], ['logoSize', 'logoSizeV', 'logoSize', 100, '%']
].forEach(([id, vid, key, m, u]) => bindSlider(id, vid, () => cfg[key], (v) => { cfg[key] = v; }, m, u));
bindSlider('lgThick', 'lgThickV', () => cfg.logoP.thick, (v) => { cfg.logoP.thick = v; }, 100, '%', logoAfter);
bindSlider('lgTsize', 'lgTsizeV', () => cfg.logoP.tsize, (v) => { cfg.logoP.tsize = v; }, 100, '%', logoAfter);
bindSlider('tpThr', 'tpThrV', () => cfg.tp.thr, (v) => { cfg.tp.thr = v; }, 1, '', tpAfterFull);
bindSlider('tpClean', 'tpCleanV', () => cfg.tp.clean, (v) => { cfg.tp.clean = v; }, 1, '', tpAfterFull);
bindSlider('tpSmooth', 'tpSmoothV', () => cfg.tp.smooth, (v) => { cfg.tp.smooth = v; }, 1, '', tpAfterFull);
bindSlider('tpUp', 'tpUpV', () => cfg.tp.up, (v) => { cfg.tp.up = v; }, 1, 'x', tpAfterFull);
bindCheck('safeOn', () => cfg.safe, (v) => { cfg.safe = v; }); bindCheck('cborder', () => cfg.cborder, (v) => { cfg.cborder = v; });
bindCheck('logoOn', () => cfg.logo, (v) => { cfg.logo = v; }); bindCheck('logoOrn', () => cfg.logoOrn, (v) => { cfg.logoOrn = v; });
bindCheck('toutOn', () => cfg.tout, (v) => { cfg.tout = v; });
bindCheck('lgDeco', () => cfg.logoP.deco, (v) => { cfg.logoP.deco = v; }, logoAfter);
bindCheck('tpInv', () => cfg.tp.inv, (v) => { cfg.tp.inv = v; }, tpAfterFull);
$('guideOn').addEventListener('change', dirty);
[['lblCol', 'lblCol'], ['valCol', 'valCol']].forEach(([id, key]) => $(id).addEventListener('input', () => { cfg[key] = $(id).value; saveCfg(); dirty(); }));

function colorRow(id, obj, kk, ck, after, kinds) {
  const box = $(id); box.innerHTML = ''; kinds = kinds || ['gold', 'silver', 'white'];
  const bg = { gold: 'linear-gradient(135deg,#FFF4B8,#F4CF55,#B8841A)', silver: 'linear-gradient(135deg,#fff,#D5DAE3,#8C96A6)', white: '#fff' };
  kinds.forEach((k) => { const b = document.createElement('button'); b.className = 'cdot' + (obj[kk] === k ? ' on' : ''); b.style.background = bg[k]; b.setAttribute('aria-label', k); b.onclick = () => { obj[kk] = k; saveCfg(); after(); colorRow(id, obj, kk, ck, after, kinds); }; box.appendChild(b); });
  const inp = document.createElement('input'); inp.type = 'color'; inp.value = obj[ck]; inp.className = 'cinp' + (obj[kk] === 'custom' ? ' on' : '');
  inp.oninput = () => { obj[ck] = inp.value; obj[kk] = 'custom'; saveCfg(); after(); }; inp.onchange = () => colorRow(id, obj, kk, ck, after, kinds); box.appendChild(inp);
}
function buildSwatches() {
  const box = $('swatches'); box.innerHTML = '';
  THEMES.forEach((c, i) => { const b = document.createElement('button'); b.className = 'sw' + (cfg.theme === i ? ' on' : ''); b.style.background = `linear-gradient(135deg,${c[0]},${c[1]} 55%,${c[2]})`; b.setAttribute('aria-label', 'لون ' + (i + 1)); b.onclick = () => { cfg.theme = i; saveCfg(); buildSwatches(); dirty(); refreshDesign(); }; box.appendChild(b); });
  const inp = document.createElement('input'); inp.type = 'color'; inp.value = cfg.custom; inp.className = 'cinp' + (cfg.theme >= THEMES.length ? ' on' : ''); inp.setAttribute('aria-label', 'لون مخصص');
  inp.oninput = () => { cfg.custom = inp.value; cfg.theme = THEMES.length; saveCfg(); dirty(); }; inp.onchange = () => { buildSwatches(); refreshDesign(); }; box.appendChild(inp);
}

/* ---------- صور مصغرة ---------- */
function thumbSrc() { return (S.mode === 'video' && S.url && pv.videoWidth) ? pv : null; }
function thumbOpts(extra) { return Object.assign(formState(), { preview: true, still: true, mode: S.mode, img: S.img, spec: null }, extra || {}); }
function buildLayouts() {
  const box = $('layoutGal'); box.innerHTML = ''; const list = S.mode === 'audio' ? ALAYS : VLAYS, key = S.mode === 'audio' ? 'alay' : 'vlay';
  list.forEach(([k, name]) => {
    const b = document.createElement('button'); b.className = 'gtile' + (cfg[key] === k ? ' on' : ''); const c = document.createElement('canvas'); c.width = 108; c.height = 192; b.appendChild(c);
    const sp = document.createElement('span'); sp.textContent = name; b.appendChild(sp); b.onclick = () => { cfg[key] = k; saveCfg(); buildLayouts(); dirty(); }; box.appendChild(b);
    withCfg({ [key]: k }, () => draw(c.getContext('2d'), 108, 192, 3.2, 9, thumbSrc(), thumbOpts()));
  });
}
const TPL_CATS = [['all','الكل'],['muharram','محرم'],['aza','عزاء ورثاء'],['mawlid','مواليد وأفراح'],['general','عام']];
const TX = (title, occ) => ({ title, reciter: 'اسم الرادود', poet: 'اسم الشاعر', occ: occ || '' });
const BUILTIN_TPLS = [
  { name: 'ملكي ذهبي', cat: 'muharram', txt: TX('لبيك يا حسين', 'ليلة العاشر'), cfg: { theme: 4, acc: 'gold', tcol: 'gold', font: 3, pat: 'stars', alay: 'vinyl', vlay: 'classic', frameStyle: 'double', logoP: 2 } },
  { name: 'حسيني', cat: 'muharram', txt: TX('السلام عليك يا أبا عبد الله', 'محرم الحرام'), cfg: { theme: 3, acc: 'silver', tcol: 'silver', font: 10, pat: 'lines', alay: 'ring', vlay: 'blur', frameStyle: 'corners', logoP: 0, anim: 'fade', tscale: 1.1 } },
  { name: 'كربلاء ليلاً', cat: 'muharram', txt: TX('يا كربلاء', 'ليلة الحادي عشر'), cfg: { theme: 3, acc: 'silver', tcol: 'white', font: 10, pat: 'lines', alay: 'ridges', vlay: 'blur', frameStyle: 'glow', filter: 'mourn', logoP: 6, tscale: 1.15 } },
  { name: 'راية حمراء', cat: 'muharram', txt: TX('حسين مني وأنا من حسين', 'عاشوراء'), cfg: { theme: 3, acc: 'gold', tcol: 'gold', font: 5, pat: 'stars', alay: 'poster', vlay: 'card', frameStyle: 'double', logoP: 5, anim: 'zoom' } },
  { name: 'عزاء أسود', cat: 'aza', txt: TX('رحيل', 'مجلس عزاء'), cfg: { theme: 4, acc: 'silver', tcol: 'white', font: 13, pat: 'none', alay: 'ring', vlay: 'classic', frameStyle: 'line', filter: 'bw', logoP: 3, anim: 'fade' } },
  { name: 'وداع هادئ', cat: 'aza', txt: TX('وداعاً', 'ذكرى الأربعين'), cfg: { theme: 8, acc: 'silver', tcol: 'silver', font: 2, pat: 'none', alay: 'pulse', vlay: 'blur', frameStyle: 'none', filter: 'fade', logoP: 1, anim: 'fade' } },
  { name: 'رمادي هادئ', cat: 'aza', txt: TX('مرثية', 'ذكرى الوفاة'), cfg: { theme: 8, acc: 'silver', tcol: 'silver', font: 13, pat: 'stars', alay: 'ring', vlay: 'classic', filter: 'fade', logoP: 3 } },
  { name: 'ليلي أزرق', cat: 'aza', txt: TX('ليلة وداع', 'ليلة الجمعة'), cfg: { theme: 7, acc: 'silver', tcol: 'white', font: 14, pat: 'dots', alay: 'poster', vlay: 'blur', filter: 'cine', logoP: 5 } },
  { name: 'مولد نور', cat: 'mawlid', txt: TX('يا مولد النور', 'ذكرى المولد'), cfg: { theme: 6, acc: 'gold', tcol: 'gold', font: 12, pat: 'stars', alay: 'starpulse', vlay: 'classic', frameStyle: 'glow', filter: 'gold', logoP: 7 } },
  { name: 'زمرد', cat: 'mawlid', txt: TX('أنوار الولادة', 'مولد الإمام'), cfg: { theme: 0, acc: 'gold', tcol: 'silver', font: 3, pat: 'stars', alay: 'card', vlay: 'card', frameStyle: 'double', logoP: 2 } },
  { name: 'بنفسجي ملكي', cat: 'mawlid', txt: TX('فرحة الزهراء', 'ليلة الفرح'), cfg: { theme: 1, acc: 'gold', tcol: 'gold', font: 12, pat: 'stars', alay: 'cassette', vlay: 'classic', frameStyle: 'glow', logoP: 6 } },
  { name: 'فرح أخضر', cat: 'mawlid', txt: TX('بشرى وفرح', 'احتفال'), cfg: { theme: 0, acc: 'white', tcol: 'white', font: 6, pat: 'dots', alay: 'particles', vlay: 'blur', frameStyle: 'none', filter: 'vivid', logoP: 4, anim: 'zoom' } },
  { name: 'فيروزي', cat: 'general', txt: TX('عنوان القصيدة'), cfg: { theme: 6, acc: 'white', tcol: 'white', font: 0, pat: 'none', alay: 'card', vlay: 'card', frameStyle: 'line', logoP: 1 } },
  { name: 'ذهبي بني', cat: 'general', txt: TX('عنوان القصيدة'), cfg: { theme: 5, acc: 'gold', tcol: 'gold', font: 5, pat: 'stars', alay: 'vinyl', vlay: 'classic', frameStyle: 'double', logoP: 7 } },
  { name: 'نيون', cat: 'general', txt: TX('عنوان القصيدة'), cfg: { theme: 2, acc: 'silver', tcol: 'white', font: 14, pat: 'dots', alay: 'neon', vlay: 'blur', wave: 'thin', frameStyle: 'glow', logoP: 5 } },
  { name: 'كاسيت قديم', cat: 'general', txt: TX('عنوان القصيدة'), cfg: { theme: 5, acc: 'gold', tcol: 'gold', font: 7, pat: 'lines', alay: 'cassette', vlay: 'card', filter: 'vintage', frameStyle: 'line', logoP: 3 } },
  { name: 'بسيط أبيض', cat: 'general', txt: TX('عنوان القصيدة'), cfg: { theme: 8, acc: 'white', tcol: 'white', font: 0, pat: 'none', alay: 'mirror', vlay: 'classic', frameStyle: 'none', logoP: 1, tscale: 0.95 } }
];
function tplToCfg(t) { const o = clone(t.cfg); if (typeof o.logoP === 'number') { o.logoP = clone(LOGO_PRESETS[o.logoP]); o.logoMode = 'builder'; } return o; }
function fillSample(t) {
  [['fTitle', t.txt.title], ['fReciter', t.txt.reciter], ['fPoet', t.txt.poet], ['fOcc', t.txt.occ]].forEach(([id, v]) => { const el = $(id); if (el && v && !el.value.trim()) { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); } });
}
let tovMode = 'edit', tovCat = 'all';
function buildTplGal(boxId, cat, big) {
  const box = $(boxId || 'tplGal'); box.innerHTML = '';
  const W = big ? 162 : 108, H = big ? 288 : 192;
  BUILTIN_TPLS.filter((t) => !cat || cat === 'all' || t.cat === cat).forEach((t) => {
    const b = document.createElement('button'); b.className = 'gtile'; const c = document.createElement('canvas'); c.width = W; c.height = H; b.appendChild(c);
    const sp = document.createElement('span'); sp.textContent = t.name; b.appendChild(sp);
    b.onclick = () => pickTpl(t); box.appendChild(b);
    try { withCfg(tplToCfg(t), () => draw(c.getContext('2d'), W, H, 3.2, 9, thumbSrc(), thumbOpts({ title: t.txt.title, reciter: t.txt.reciter, poet: t.txt.poet, occ: t.txt.occ, titleFx: null, bgImg: null }))); } catch (e) {}
  });
}
function pickTpl(t) {
  const go = () => { applyCfg(tplToCfg(t)); fillSample(t); $('tplOv').hidden = true; toast('تم تطبيق: ' + t.name); };
  if (tovMode === 'new') { $('tplOv').hidden = true; newProject(t.name === '' ? '' : 'minbar - ' + t.name); go(); } else go();
}
function openTplOv(mode) {
  tovMode = mode; tovCat = 'all'; $('tplOv').hidden = false;
  const cb = $('tovCats'); cb.innerHTML = '';
  TPL_CATS.forEach(([k, n]) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'chip' + (k === tovCat ? ' on' : ''); b.textContent = n; b.onclick = () => { tovCat = k; cb.querySelectorAll('.chip').forEach((x) => x.classList.toggle('on', x === b)); buildTplGal('tovGal', k, true); }; cb.appendChild(b); });
  buildTplGal('tovGal', 'all', true); $('tovGal').parentElement.scrollTop = 0;
}
$('homeTpl').addEventListener('click', () => openTplOv('new'));
$('tplOpenAll').addEventListener('click', () => openTplOv('edit'));
$('tovBack').addEventListener('click', () => { $('tplOv').hidden = true; });
function sceneCanvas(w, h) {
  const c = document.createElement('canvas'); c.width = w; c.height = h; const x = c.getContext('2d');
  let g = x.createLinearGradient(0, 0, 0, h); g.addColorStop(0, '#3d6fb0'); g.addColorStop(.5, '#f0b46a'); g.addColorStop(.62, '#d8683b'); g.addColorStop(1, '#2d3e2c'); x.fillStyle = g; x.fillRect(0, 0, w, h);
  x.fillStyle = '#fff4c8'; x.beginPath(); x.arc(w * .68, h * .5, h * .11, 0, 7); x.fill();
  x.fillStyle = 'rgba(255,255,255,.5)'; [[.2, .28, .22], [.55, .2, .26], [.8, .33, .18]].forEach((p) => { x.beginPath(); x.ellipse(w * p[0], h * p[1], w * p[2], h * .06, 0, 0, 7); x.fill(); });
  x.fillStyle = '#1f2c25'; x.beginPath(); x.moveTo(0, h); x.lineTo(0, h * .72); x.lineTo(w * .22, h * .6); x.lineTo(w * .4, h * .74); x.lineTo(w * .62, h * .66); x.lineTo(w * .85, h * .78); x.lineTo(w, h * .7); x.lineTo(w, h); x.closePath(); x.fill();
  return c;
}
function buildFilters() {
  const box = $('filterTiles'); box.innerHTML = '';
  const base = document.createElement('canvas'); base.width = 112; base.height = 84; const bx = base.getContext('2d');
  const s = thumbSrc() || (S.mode === 'audio' && S.img && S.img.naturalWidth ? S.img : null);
  if (s) { const d = srcDims(s); const ar = 112 / 84, ir = d[0] / d[1]; let sw = d[0], sh = d[1], sx = 0, sy = 0; if (ir > ar) { sw = sh * ar; sx = (d[0] - sw) / 2; } else { sh = sw / ar; sy = (d[1] - sh) / 2; } try { bx.drawImage(s, sx, sy, sw, sh, 0, 0, 112, 84); } catch (e) { bx.drawImage(sceneCanvas(112, 84), 0, 0); } }
  else bx.drawImage(sceneCanvas(112, 84), 0, 0);
  Object.keys(FILTERS).forEach((k) => {
    const b = document.createElement('button'); b.className = 'ftile' + (cfg.filter === k ? ' on' : '');
    const c = document.createElement('canvas'); c.width = 112; c.height = 84; c.getContext('2d').drawImage(base, 0, 0); const f = buildFilter(k, 1, false); if (f !== 'none') c.style.filter = f;
    const sp = document.createElement('span'); sp.textContent = FILTERS[k].n; b.append(c, sp);
    b.onclick = () => { cfg.filter = k; saveCfg(); buildFilters(); dirty(); }; box.appendChild(b);
  });
}
$('fReset').addEventListener('click', () => { Object.assign(cfg, { filter: 'none', fint: 1, fbri: 0, fcon: 0, fsat: 0, fwarm: 0, fvig: 0, fx: { blur: 0, glow: 0, shake: 0, pulse: 0, grain: 0 } }); saveCfg(); rebuildAll(); });
function refreshDesign() { buildLayouts(); buildFilters(); if (openP === 'tpl') buildTplGal('tplGal', 'all', false); }

/* ---------- الشعار ---------- */
function drawLogoPreview() {
  const c = $('lgPrev'), x = c.getContext('2d'); x.clearRect(0, 0, c.width, c.height);
  const cols = themeColors(); const g = x.createLinearGradient(0, 0, 0, c.height); g.addColorStop(0, cols[0]); g.addColorStop(1, cols[2]); x.fillStyle = g; x.fillRect(0, 0, c.width, c.height);
  const lg = currentLogo(), iw = lg.width || lg.naturalWidth, ih = lg.height || lg.naturalHeight; if (iw) { const k = Math.min(c.width / iw, c.height / ih) * .92; x.drawImage(lg, (c.width - iw * k) / 2, (c.height - ih * k) / 2, iw * k, ih * k); }
}
function buildLogoUI() {
  drawLogoPreview();
  const box = $('logoGrid'); box.innerHTML = '';
  LOGO_PRESETS.forEach((p) => {
    const b = document.createElement('button'); b.className = 'lg' + (cfg.logoMode === 'builder' && JSON.stringify(cfg.logoP) === JSON.stringify(p) ? ' on' : ''); const c = document.createElement('canvas'); c.width = c.height = 120;
    c.getContext('2d').drawImage(renderLogo(p), 0, 0, 120, 120); b.appendChild(c);
    b.onclick = () => { cfg.logoP = clone(p); cfg.logoMode = 'builder'; saveCfg(); loadLogo(); rebuildAll(); }; box.appendChild(b);
  });
  if (cfg.logoData) { const b = document.createElement('button'); b.className = 'lg' + (cfg.logoMode === 'image' ? ' on' : ''); const im = document.createElement('img'); im.src = cfg.logoData; b.appendChild(im); b.onclick = () => { cfg.logoMode = 'image'; saveCfg(); loadLogo(); rebuildAll(); }; box.appendChild(b); }
  const cg = () => { cfg.logoMode = 'builder'; saveCfg(); loadLogo(); drawLogoPreview(); buildLogoUI2(); };
  $('logoBack').hidden = cfg.logoMode !== 'image';
  buildLogoUI2 = () => {
    buildChips('lgFrame', LFRAMES, (i, it) => cfg.logoP.frame === it[0], (i, it) => { cfg.logoP.frame = it[0]; cg(); });
    buildChips('lgEmb', LEMBS, (i, it) => cfg.logoP.emblem === it[0], (i, it) => { cfg.logoP.emblem = it[0]; cg(); });
    buildChips('lgFont', FONTS, (i) => cfg.logoP.font === i, (i) => { cfg.logoP.font = i; const f = FONTS[i]; cg(); document.fonts.load(`${f[2]} 40px "${f[0]}"`, 'باسم').then(() => { loadLogo(); drawLogoPreview(); }); }, true);
    colorRow('lgFcol', cfg.logoP, 'fcol', 'fcustom', () => { cfg.logoMode = 'builder'; loadLogo(); drawLogoPreview(); });
    colorRow('lgEcol', cfg.logoP, 'ecol', 'ecustom', () => { cfg.logoMode = 'builder'; loadLogo(); drawLogoPreview(); });
    colorRow('lgTcol', cfg.logoP, 'tcol', 'tcustom', () => { cfg.logoMode = 'builder'; loadLogo(); drawLogoPreview(); });
    $('lgText').value = cfg.logoP.text;
  };
  buildLogoUI2();
}
let buildLogoUI2 = () => {};
refreshLogoUI = () => { drawLogoPreview(); };
$('lgText').addEventListener('input', () => { cfg.logoP.text = $('lgText').value; cfg.logoMode = 'builder'; saveCfg(); loadLogo(); drawLogoPreview(); });
$('logoIn').addEventListener('change', (e) => {
  const f = e.target.files[0]; if (!f) return;
  const im = new Image(); im.onload = () => {
    const k = Math.min(1, 512 / Math.max(im.width, im.height)), c = document.createElement('canvas'); c.width = Math.round(im.width * k); c.height = Math.round(im.height * k);
    c.getContext('2d').drawImage(im, 0, 0, c.width, c.height); cfg.logoData = c.toDataURL('image/png'); cfg.logoMode = 'image'; saveCfg(); loadLogo(); buildLogoUI(); toast('تم رفع الشعار');
  }; im.src = URL.createObjectURL(f);
});
$('logoBack').addEventListener('click', () => { cfg.logoMode = 'builder'; saveCfg(); loadLogo(); buildLogoUI(); });

/* ---------- العنوان بصورة ---------- */
$('titleImgIn').addEventListener('change', (e) => {
  const f = e.target.files[0]; if (!f) return;
  const im = new Image(); im.onload = () => { S.titleSrc = im; $('tpBox').hidden = false; $('titleImgClear').hidden = false; rebuildTitle(true); }; im.src = URL.createObjectURL(f);
});
$('titleImgClear').addEventListener('click', () => { S.titleSrc = null; S.titleFx = null; titleMask = null; $('tpBox').hidden = true; $('titleImgClear').hidden = true; $('titleImgIn').value = ''; dirty(); });
function buildTitleUI() {
  buildChips('tpFillChips', [['silver', 'فضي'], ['gold', 'ذهبي'], ['white', 'أبيض'], ['orig', 'لون الصورة'], ['custom', 'مخصص']], (i, it) => cfg.tp.fill === it[0], (i, it) => { cfg.tp.fill = it[0]; saveCfg(); tpAfterFx(); });
  if (cfg.tp.fill === 'custom') { const inp = document.createElement('input'); inp.type = 'color'; inp.className = 'cinp on'; inp.value = cfg.tp.fcustom; inp.oninput = () => { cfg.tp.fcustom = inp.value; saveCfg(); tpAfterFx(); }; $('tpFillChips').appendChild(inp); }
  buildChips('tpFx', [['outline', 'حدّ'], ['glow', 'توهج'], ['shadow', 'ظل'], ['bevel', 'نقش']], (i, it) => cfg.tp[it[0]], (i, it) => { cfg.tp[it[0]] = !cfg.tp[it[0]]; saveCfg(); tpAfterFx(); });
}

/* ---------- القوالب والإعدادات ---------- */
function applyCfg(over) {
  Object.assign(cfg, over); cfg.logoP = Object.assign({}, LOGO0, cfg.logoP); if (cfg.logoMode === 'image' && !cfg.logoData) cfg.logoMode = 'builder';
  saveCfg(); rebuildAll(); loadLogo(); loadFont();
}
let tpls = LS.get('basim.tpls', []);
function buildTpls() {
  const box = $('tplList'); box.innerHTML = '';
  if (!tpls.length) { box.innerHTML = '<div class="hint">ما عندك قوالب محفوظة بعد.</div>'; return; }
  tpls.forEach((t, i) => {
    const d = document.createElement('div'); d.className = 'tpl'; d.innerHTML = '<b></b>'; d.firstChild.textContent = t.name;
    const ap = document.createElement('button'); ap.className = 'btn small primary'; ap.textContent = 'تطبيق'; ap.onclick = () => { applyCfg(clone(t.cfg)); toast('تم تطبيق القالب'); };
    const rm = document.createElement('button'); rm.className = 'btn small'; rm.textContent = 'حذف'; rm.onclick = () => { tpls.splice(i, 1); LS.set('basim.tpls', tpls); buildTpls(); };
    d.append(ap, rm); box.appendChild(d);
  });
}
$('tplSave').addEventListener('click', () => {
  const name = $('tplName').value.trim() || ('قالب ' + (tpls.length + 1)); const sub = {}; TPL_KEYS.forEach((k) => { sub[k] = clone(cfg[k]); });
  tpls.push({ name, cfg: sub }); LS.set('basim.tpls', tpls); $('tplName').value = ''; buildTpls(); toast('تم حفظ القالب');
});
function buildLib() {
  const box = $('libList'); box.innerHTML = '';
  const add = (arr, lbl) => arr.forEach((n, i) => { const b = document.createElement('button'); b.className = 'chip'; b.style.fontSize = '14px'; b.textContent = lbl + ': ' + n + '  ✕'; b.onclick = () => { arr.splice(i, 1); saveLib(); buildLib(); fillLists(); }; box.appendChild(b); });
  add(lib.reciters, 'رادود'); add(lib.poets, 'شاعر');
  if (!lib.reciters.length && !lib.poets.length) box.innerHTML = '<span class="hint">فارغة، تنحفظ الأسماء تلقائياً بعد كل تصدير.</span>';
}
function fillLists() {
  $('dlReciters').innerHTML = lib.reciters.map((n) => `<option value="${n.replace(/"/g, '&quot;')}">`).join('');
  $('dlPoets').innerHTML = lib.poets.map((n) => `<option value="${n.replace(/"/g, '&quot;')}">`).join('');
}
function remember(kind, v) { v = (v || '').trim(); if (!v) return; const a = lib[kind]; const i = a.indexOf(v); if (i >= 0) a.splice(i, 1); a.unshift(v); if (a.length > 200) a.length = 200; }
let deferred = null;
window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); deferred = e; $('btnInstall').hidden = false; });
$('btnInstall').addEventListener('click', async () => { if (deferred) { deferred.prompt(); deferred = null; $('btnInstall').hidden = true; } });
if (/iphone|ipad/i.test(navigator.userAgent) && !window.navigator.standalone) $('iosHint').hidden = false;
$('btnReset').addEventListener('click', () => { cfg = clone(DEF); saveCfg(); rebuildAll(); loadLogo(); loadFont(); toast('تمت إعادة الضبط'); });
$('bgImgIn').addEventListener('change', (e) => { const f = e.target.files[0]; if (!f) return; const im = new Image(); im.onload = () => { S.bgImg = im; dirty(); }; im.src = URL.createObjectURL(f); });



/* ---------- التجربة المحدودة ---------- */
const TRIAL_MIN = 10, TRIAL_LOCK = new Set(['trim', 'lyrics', 'color', 'font', 'frame', 'filter', 'logo', 'tpl']); let trialTimer = 0;
function trialUI() { buildDock(); if (TRIAL && !unlocked() && TRIAL_LOCK.has(openP)) openP = 'media'; paintPanels(0); }
const brandImg = new Image(); brandImg.src = 'icons/brand-mark.png';
if (/[?&]resettrial/.test(location.search)) { LS.set('minbar.trial2', null); history.replaceState(null, '', location.pathname); }
const TRIAL_EPOCH = 2;
const DEVID = (() => { let d = LS.get('minbar.devid', ''); if (!d) { d = (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : (Date.now().toString(36) + Math.random().toString(36).slice(2, 12)); LS.set('minbar.devid', d); } return d; })();
const grant = () => LS.get('minbar.grant', {}) || {}, unlocked = () => (grant().unlockUntil || 0) > Date.now(), trialMs = () => (TRIAL_MIN + (grant().extMin || 0)) * 60000;
function trialLeft() { const o = LS.get('minbar.trial2', null); const s = (o && o.e === TRIAL_EPOCH) ? o.s : 0; return s ? Math.max(0, s + trialMs() - Date.now()) : trialMs(); }
function trialLabel() { const l = trialLeft(); return l <= 0 ? 'انتهت فترة التجربة' : (() => { const n = Math.ceil(l / 60000); return `تجربة محدودة (${n === 1 ? 'دقيقة واحدة' : n === 2 ? 'دقيقتان' : n <= 10 ? n + ' دقائق' : n + ' دقيقة'})`; })(); }
function refreshTrialBtns() { const t = trialLabel(); if ($('gTrial')) $('gTrial').textContent = t; $('lGuest').textContent = t; }
async function startTrial() {
  if (window.MAINT && await window.MAINT.on()) return window.MAINT.show();
  if (trialLeft() <= 0) { refreshTrialBtns(); return toast('انتهت فترة التجربة المحدودة على هذا الجهاز'); }
  { const o = LS.get('minbar.trial2', null); if (!(o && o.e === TRIAL_EPOCH)) LS.set('minbar.trial2', { s: Date.now(), e: TRIAL_EPOCH }); }
  if (AUTH && AUTH.logTrial) AUTH.logTrial(DEVID, 'start');
  finishLogin({ name: 'تجربة', chan: '', email: '', guest: true, trial: true });
}
function stopTrial() { const was = TRIAL; TRIAL = false; clearInterval(trialTimer); $('trialChip').hidden = true; dirty(); if (was) trialUI(); }
function trialCfg() { cfg = clone(DEF); cfg.logoP = Object.assign({}, LOGO0, cfg.logoP || {}); cfg.tp = Object.assign({}, DEF.tp); cfg.vreact = Object.assign({}, DEF.vreact); rebuildAll(); loadLogo(); }
function runTrial() {
  TRIAL = true; trialCfg(); clearInterval(trialTimer); dirty(); trialUI();
  const tick = () => {
    const l = trialLeft(); const m = Math.floor(l / 60000), s = Math.floor(l % 60000 / 1000);
    $('trialChip').hidden = false; $('trialChip').textContent = 'تجربة · ' + String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
    if (l <= 0) { stopTrial(); S.cancel = true; pv.pause(); user = null; LS.set('basim.user', null); refreshTrialBtns(); showLogin(); if (AUTH && AUTH.logTrial) AUTH.logTrial(DEVID, 'end'); trialEnded(); }
  };
  tick(); trialTimer = setInterval(tick, 1000);
}
function drawTrialMark(ctx, W, H) {
  if (!TRIAL) return;
  ctx.save(); ctx.setTransform(W / 1080, 0, 0, W / 1080, 0, 0);
  ctx.globalAlpha = .07; ctx.fillStyle = '#fff'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.direction = 'rtl'; setBase(ctx, 64, 700);
  ctx.translate(540, 960); ctx.rotate(-Math.PI / 7); ctx.fillText('منبر • قيد التطوير', 0, 0); ctx.setTransform(W / 1080, 0, 0, W / 1080, 0, 0);
  ctx.globalAlpha = 1; rr(ctx, 290, 1796, 500, 66, 33); ctx.fillStyle = 'rgba(0,0,0,.55)'; ctx.fill(); ctx.strokeStyle = 'rgba(232,196,104,.6)'; ctx.lineWidth = 2; ctx.stroke();
  if (brandImg.complete && brandImg.naturalWidth) ctx.drawImage(brandImg, 302, 1803, 52, 52);
  ctx.textAlign = 'right'; ctx.fillStyle = '#E8C468'; setBase(ctx, 24, 700); ctx.fillText('منبر', 774, 1815);
  ctx.fillStyle = '#fff'; setBase(ctx, 20, 700); ctx.fillText('هذا التطبيق قيد التطوير ولم يصدر بعد', 774, 1843);
  ctx.restore();
}

/* ---------- الكلمات ---------- */
const LY = { text: '', t: [] };
function lyrLines() { return LY.text.split('\n').map((s) => s.trim()).filter(Boolean); }
function lyrTimes(n, dur) {
  if (LY.t.length === n && LY.t.every(Number.isFinite)) return LY.t;
  const a = []; for (let i = 0; i < n; i++) a.push(dur * i / n); return a;
}
function drawLyrics(ctx, W, H, t, dur) {
  if (!cfg.lyrOn || TRIAL) return; const L = lyrLines(); if (!L.length) return;
  dur = dur || 9; const T = lyrTimes(L.length, dur); let i = -1;
  for (let k = 0; k < L.length; k++) if (T[k] <= t) i = k;
  if (i < 0) return;
  let a = Math.min(1, (t - T[i]) / .25);
  if (i === L.length - 1) a = Math.min(a, (T[i] + Math.max(3, dur - T[i]) - t) / .3);
  if (a <= 0) return;
  ctx.save(); ctx.setTransform(W / 1080, 0, 0, W / 1080, 0, 0); ctx.globalAlpha = clamp(a, 0, 1);
  ctx.direction = 'rtl'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  const size = Math.round(58 * cfg.lyrSize); setBase(ctx, size, 700);
  const words = L[i].split(/\s+/), lines = []; let cur = '';
  words.forEach((w) => { const tt = cur ? cur + ' ' + w : w; if (ctx.measureText(tt).width > 900 && cur) { lines.push(cur); cur = w; } else cur = tt; });
  if (cur) lines.push(cur);
  const lh = size * 1.5, h = lines.length * lh + 36, cy = cfg.lyrY / 100 * 1920;
  const mw = Math.max.apply(null, lines.map((s) => ctx.measureText(s).width));
  rr(ctx, 540 - mw / 2 - 40, cy - h / 2, mw + 80, h, 36); ctx.fillStyle = 'rgba(0,0,0,.45)'; ctx.fill();
  ctx.fillStyle = '#fff'; ctx.shadowColor = 'rgba(0,0,0,.6)'; ctx.shadowBlur = 8;
  lines.forEach((s, k) => ctx.fillText(s, 540, cy - h / 2 + 18 + lh * (k + .5)));
  ctx.restore();
}
bindCheck('lyrOn', () => cfg.lyrOn, (v) => { cfg.lyrOn = v; });
bindSlider('lyrY', 'lyrYV', () => cfg.lyrY, (v) => { cfg.lyrY = v; }, 1, '%');
bindSlider('lyrSize', 'lyrSizeV', () => cfg.lyrSize, (v) => { cfg.lyrSize = v; }, 100, '%');
function lyrSave() { touchProject(); }
function lyrInfo() { const n = lyrLines().length; $('lyrInfo').textContent = n ? `${n} سطر · ` + (LY.t.length === n && LY.t.every(Number.isFinite) ? 'التوقيت مضبوط' : 'التوقيت تلقائي (موزّع بالتساوي)') : 'اكتب الكلمات سطر بسطر'; }
$('lyrText').value = LY.text; lyrInfo();
$('lyrText').addEventListener('input', () => { LY.text = $('lyrText').value; if (LY.t.length !== lyrLines().length) LY.t = []; lyrSave(); lyrInfo(); renderLyrList(); dirty(); });
function lyrOnNow() { cfg.lyrOn = true; $('lyrOn').checked = true; saveCfg(); dirty(); }
$('lyrAuto').addEventListener('click', () => {
  const n = lyrLines().length; if (!n) return toast('اكتب الكلمات أولاً'); if (!S.dur) return toast('اختر الفيديو أو الصوت أولاً');
  LY.t = []; lyrSave(); lyrInfo(); renderLyrList(); lyrOnNow(); toast('تم توزيع الأسطر بالتساوي');
});
let tapI = -1;
function tapLabel() { const L = lyrLines(); $('lyrTap').textContent = tapI < 0 ? 'مزامنة بالنقر مع الصوت' : `اضغط عند بداية السطر ${tapI + 1} من ${L.length}`; $('lyrNext').textContent = tapI < 0 ? '' : L[tapI]; }
$('lyrTap').addEventListener('click', () => {
  const L = lyrLines(); if (!L.length) return toast('اكتب الكلمات أولاً'); if (!S.url) return toast('اختر الفيديو أو الصوت أولاً');
  if (tapI < 0) { LY.t = []; tapI = 0; pv.currentTime = 0; pv.muted = !!afxOut; pv.play().catch(() => {}); $('playBtn').textContent = '⏸'; tapLabel(); return; }
  LY.t[tapI] = Math.max(0, +(pv.currentTime - 0.1).toFixed(2)); tapI++;
  if (tapI >= L.length) { tapI = -1; lyrSave(); lyrInfo(); renderLyrList(); lyrOnNow(); toast('تمت المزامنة'); }
  tapLabel(); dirty();
});

/* ---------- وصف تيك توك ---------- */
$('btnCap').addEventListener('click', async () => {
  const g = (id) => $(id).value.trim(), tg = (s) => s ? '#' + s.replace(/[\s\-_.،,]+/g, '_') : '';
  const rows = [['🎙️ القصيدة', g('fTitle')], ['🗓️ المناسبة', g('fOcc')], ['🎤 الرادود', g('fReciter')], ['✍️ الشاعر', g('fPoet')], ['📍 المكان', g('fPlace')]].filter((x) => x[1]).map((x) => x[0] + ': ' + x[1]);
  if (!rows.length) return toast('اكتب تفاصيل القصيدة أولاً');
  const txt = rows.join('\n') + '\n\n' + [tg(g('fReciter')), tg(g('fPoet')), '#قصائد', '#رادود', '#مراثي'].filter(Boolean).join(' ');
  try { await navigator.clipboard.writeText(txt); }
  catch (e) { const ta = document.createElement('textarea'); ta.value = txt; document.body.appendChild(ta); ta.select(); try { document.execCommand('copy'); } catch (e2) {} ta.remove(); }
  toast('تم نسخ الوصف');
});

let allowUnload = false;
function reloadNow() { allowUnload = true; location.reload(); }
/* ---------- المشاريع ---------- */
const idb = (() => {
  let p; const open = () => p || (p = new Promise((res, rej) => { const r = indexedDB.open('minbar', 1); r.onupgradeneeded = () => r.result.createObjectStore('d'); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); }));
  const tx = (m, fn) => open().then((db) => new Promise((res, rej) => { const t = db.transaction('d', m); const rq = fn(t.objectStore('d')); t.oncomplete = () => res(rq && rq.result); t.onerror = () => rej(t.error); }));
  return { put: (k, v) => tx('readwrite', (s) => s.put(v, k)).catch(() => {}), get: (k) => tx('readonly', (s) => s.get(k)).catch(() => null), del: (k) => tx('readwrite', (s) => s.delete(k)).catch(() => {}), keys: () => tx('readonly', (s) => s.getAllKeys()).catch(() => []) };
})();
const DRAFT = [['fileIn', 'video'], ['imgIn', 'image'], ['audIn', 'audio'], ['titleImgIn', 'title'], ['bgImgIn', 'bg']];
DRAFT.forEach(([id, k]) => $(id).addEventListener('change', () => { const f = $(id).files[0]; if (f && NS && PID) { idb.put(NS + ':' + PID + ':' + k, f); touchProject(); } }));
let spT = 0;
function touchProject() { if (!NS || !PID) return; clearTimeout(spT); spT = setTimeout(saveProject, 800); }
function hasContent() { return !!(S.file || S.img || S.titleSrc || FIELDS.some((id) => id !== 'fProj' && $(id).value.trim()) || LY.text.trim()); }
function makeThumb() { try { const c = document.createElement('canvas'); c.width = 108; c.height = 192; c.getContext('2d').drawImage(pc, 0, 0, 108, 192); return c.toDataURL('image/jpeg', .6); } catch (e) { return ''; } }
async function saveProject() {
  if (!NS || !PID || !hasContent()) return;
  const f = {}; FIELDS.forEach((id) => { f[id] = $(id).value; });
  const now = Date.now(); if (!PROJ.created) PROJ.created = now;
  const meta = { id: PID, name: $('fProj').value.trim() || $('fTitle').value.trim() || 'مشروع بدون عنوان', status: PROJ.status, seg: clone(SEG), mode: S.mode, fields: f, lyr: { text: LY.text, t: LY.t }, cfg: clone(cfg), created: PROJ.created, updated: now, thumb: makeThumb(), expName: PROJ.expName || '' };
  await idb.put(NS + ':' + PID + ':meta', meta);
  const idx = (await idb.get(NS + ':index')) || [];
  const row = { id: PID, name: meta.name, status: meta.status, updated: now, thumb: meta.thumb, mode: meta.mode, hasExp: !!PROJ.expName, expName: PROJ.expName || '' };
  const k = idx.findIndex((x) => x.id === PID); if (k >= 0) idx[k] = row; else idx.push(row);
  await idb.put(NS + ':index', idx);
}
window.addEventListener('pagehide', () => { LS.set('basim.cfg', cfg); saveProject(); });
document.addEventListener('visibilitychange', () => { if (document.hidden) { clearTimeout(spT); saveProject(); } });
function loadSpace(u) { NS = (u && !u.trial) ? (u.uid || 'local') : ''; PID = ''; }
function enterEditor() { $('btnHome').hidden = false; $('btnHome').innerHTML = ic(TRIAL ? 'gear' : 'home'); fitCanvas(); dirty(); }
function showHome() { $('home').hidden = false; renderHome(); if (window.PLR && !showHome.once) { showHome.once = 1; window.PLR.open(); } }
function hideHome() { $('home').hidden = true; }
function newProject(nm) { PID = Date.now().toString(36); PROJ = { status: 'draft', created: 0, expName: '' }; $('fProj').value = nm || ''; hideHome(); enterEditor(); touchProject(); }
async function openProject(id) {
  const meta = await idb.get(NS + ':' + id + ':meta'); if (!meta) return toast('تعذّر فتح المشروع');
  PID = id; PROJ = { status: meta.status || 'draft', created: meta.created || 0, expName: meta.expName || '' };
  cfg = Object.assign(clone(DEF), clone(meta.cfg || {})); cfg.logoP = Object.assign({}, LOGO0, cfg.logoP || {}); cfg.tp = Object.assign({}, DEF.tp, cfg.tp || {}); cfg.vreact = Object.assign({}, DEF.vreact, cfg.vreact || {});
  Object.keys(meta.fields || {}).forEach((k) => { if ($(k)) $(k).value = meta.fields[k]; });
  LY.text = (meta.lyr && meta.lyr.text) || ''; LY.t = (meta.lyr && meta.lyr.t) || []; $('lyrText').value = LY.text; lyrInfo(); renderLyrList();
  rebuildAll(); loadLogo(); loadFont();
  for (const [inp, k] of DRAFT) { const f = await idb.get(NS + ':' + id + ':' + k); if (!f) continue; try { const dt = new DataTransfer(); dt.items.add(f); $(inp).files = dt.files; $(inp).dispatchEvent(new Event('change')); } catch (e) {} }
  SEG = meta.seg ? clone(meta.seg) : legacySeg(meta.trim, 0); SELI = 0; curSeg = 0; segFix(); trRefresh();
  if (meta.mode) setMode(meta.mode);
  hist.a = [snap()]; hist.i = 0; updUndo(); hideHome(); enterEditor();
}
async function delProject(id) {
  if (!confirm('حذف هذا المشروع نهائياً؟')) return;
  await Promise.all(DRAFT.map(([, k]) => idb.del(NS + ':' + id + ':' + k)).concat([idb.del(NS + ':' + id + ':meta'), idb.del(NS + ':' + id + ':exp')]));
  await idb.put(NS + ':index', ((await idb.get(NS + ':index')) || []).filter((x) => x.id !== id)); renderHome();
}
async function renderHome() {
  $('homeHello').textContent = 'مرحباً ' + ((user && user.name) ? user.name.split(' ')[0] : '');
  const idx = ((await idb.get(NS + ':index')) || []).sort((x, y) => y.updated - x.updated);
  const box = $('projList'); box.textContent = '';
  if (!idx.length) { const d = document.createElement('div'); d.className = 'hint'; d.textContent = 'لا توجد مشاريع بعد. ابدأ بمشروع جديد، وسيتم حفظ عملك تلقائياً.'; box.appendChild(d); return; }
  idx.forEach((p) => {
    const c = document.createElement('div'); c.className = 'projc'; c.onclick = () => openProject(p.id);
    if (p.thumb) { const im = document.createElement('img'); im.src = p.thumb; im.alt = ''; c.appendChild(im); } else { const ph = document.createElement('div'); ph.className = 'ph'; c.appendChild(ph); }
    const m = document.createElement('div'); m.className = 'pm'; const b = document.createElement('b'); b.textContent = p.name; m.appendChild(b);
    const s = document.createElement('small'); s.textContent = new Date(p.updated).toLocaleDateString('ar-IQ') + ' · ' + (p.mode === 'audio' ? 'صورة + صوت' : 'فيديو'); m.appendChild(s);
    const ch = document.createElement('span'); ch.className = 'chip2' + (p.status === 'exported' ? ' ok' : ''); ch.textContent = p.status === 'exported' ? 'تم التصدير' : 'مسودة'; ch.style.alignSelf = 'flex-start'; m.appendChild(ch); c.appendChild(m);
    const pa = document.createElement('div'); pa.className = 'pa';
    if (p.hasExp) { const d = document.createElement('button'); d.type = 'button'; d.innerHTML = ic('download'); d.onclick = async (e) => { e.stopPropagation(); const bl = await idb.get(NS + ':' + p.id + ':exp'); if (!bl) return toast('الملف غير متوفر'); const u = URL.createObjectURL(bl); const a = document.createElement('a'); a.href = u; a.download = p.expName || 'منبر.mp4'; document.body.appendChild(a); a.click(); a.remove(); setTimeout(() => URL.revokeObjectURL(u), 4000); }; pa.appendChild(d); }
    const rn = document.createElement('button'); rn.type = 'button'; rn.innerHTML = ic('text'); rn.onclick = async (e) => { e.stopPropagation(); const nm = prompt('اسم المشروع', p.name); if (nm === null || !nm.trim()) return; const meta = await idb.get(NS + ':' + p.id + ':meta'); if (!meta) return; meta.fields = meta.fields || {}; meta.fields.fProj = nm.trim(); meta.name = nm.trim(); await idb.put(NS + ':' + p.id + ':meta', meta); const idx = (await idb.get(NS + ':index')) || []; const k = idx.findIndex((y) => y.id === p.id); if (k >= 0) { idx[k].name = nm.trim(); await idb.put(NS + ':index', idx); } renderHome(); }; pa.appendChild(rn);
    const x = document.createElement('button'); x.type = 'button'; x.innerHTML = ic('trash'); x.onclick = (e) => { e.stopPropagation(); delProject(p.id); }; pa.appendChild(x); c.appendChild(pa);
    box.appendChild(c);
  });
}
$('homeNew').addEventListener('click', async () => {
  const idx = (await idb.get(NS + ':index')) || []; let mx = 0;
  idx.forEach((p) => { const m = /^minbar - (\d+)$/.exec(p.name || ''); if (m) mx = Math.max(mx, +m[1]); });
  newProject('minbar - ' + (Math.max(mx, idx.length) + 1));
});
window.__plrDesign = async (audioFile, coverFile, meta, a, b) => {
  newProject('مقطع - ' + (meta.title || ''));
  $('fTitle').value = meta.title || ''; $('fReciter').value = meta.reciter || ''; $('fPoet').value = meta.poet || '';
  const put = (inp, f) => { const dt = new DataTransfer(); dt.items.add(f); $(inp).files = dt.files; $(inp).dispatchEvent(new Event('change')); };
  put('imgIn', coverFile); put('audIn', audioFile);
  for (let i = 0; i < 300 && !(S.abuf && S.spec); i++) await new Promise((r) => setTimeout(r, 100));
  const ls = (meta.lyrics || []).filter((x) => x.t >= a - 0.01 && x.t < b);
  if (ls.length) { LY.text = ls.map((x) => x.l).join('\n'); LY.t = ls.map((x) => x.t); $('lyrText').value = LY.text; cfg.lyrOn = true; lyrInfo(); renderLyrList(); }
  SEG = [segNew(a, b)]; SELI = 0; curSeg = 0; segFix(); trRefresh(); pv.currentTime = a; pushHist(); dirty();
};
async function goHome() { clearTimeout(spT); await saveProject(); reloadNow(); }
$('btnHome').addEventListener('click', () => { if (TRIAL) return openSettings(); goHome(); });
$('btnWipe').addEventListener('click', async () => {
  if (!confirm('حذف كل المشاريع المحفوظة على هذا الجهاز؟ لا يمكن التراجع.')) return;
  const ks = await idb.keys(); await Promise.all(ks.filter((k) => String(k).startsWith(NS + ':')).map((k) => idb.del(k))); reloadNow();
});

/* ---------- فحص الجهاز ---------- */
const DEVKEY = 'minbar.dev'; let DEV = LS.get(DEVKEY, null);
const TIERS = { high: 'عالٍ', mid: 'متوسط', low: 'محدود' };
async function probeDevice() {
  const info = { cores: navigator.hardwareConcurrency || 4, mem: navigator.deviceMemory || 0, dpr: +(window.devicePixelRatio || 1).toFixed(1) };
  info.hz = await new Promise((res) => { let n = 0, t0 = 0; const f = (t) => { if (!t0) t0 = t; n++; if (t - t0 >= 700) res(Math.round(n * 1000 / (t - t0) / 5) * 5); else requestAnimationFrame(f); }; requestAnimationFrame(f); });
  try { const gl = document.createElement('canvas').getContext('webgl'); const e = gl && gl.getExtension('WEBGL_debug_renderer_info'); info.gpu = e ? String(gl.getParameter(e.UNMASKED_RENDERER_WEBGL)).slice(0, 60) : ''; } catch (e) { info.gpu = ''; }
  const enc = async (codec, w, h, fps, br) => { try { const r = await VideoEncoder.isConfigSupported({ codec, width: w, height: h, framerate: fps, bitrate: br, avc: { format: 'avc' } }); return !!r.supported; } catch (e) { return false; } };
  info.webcodecs = !!(window.VideoEncoder && window.VideoDecoder);
  info.c30 = info.webcodecs && await enc('avc1.640032', 1080, 1920, 30, 16e6);
  info.c60 = info.webcodecs && await enc('avc1.640033', 1080, 1920, 60, 24e6);
  info.c120 = info.webcodecs && await enc('avc1.640034', 1080, 1920, 120, 40e6);
  let ms = 99;
  try { const cv = document.createElement('canvas'); cv.width = 1080; cv.height = 1920; const cx = cv.getContext('2d'); const o = Object.assign(formState(), { title: 'اسم القصيدة', reciter: 'الرادود', poet: 'الشاعر', demo: true, mode: 'video', still: false, img: null, spec: null });
    draw(cx, 1080, 1920, 0, 9, null, o); const t0 = performance.now(); for (let i = 1; i <= 6; i++) draw(cx, 1080, 1920, i * .12, 9, null, o); cx.getImageData(0, 0, 1, 1); ms = (performance.now() - t0) / 6; } catch (e) {}
  info.ms = Math.max(1, Math.round(ms));
  const strong = info.cores >= 6 && (!info.mem || info.mem >= 4);
  info.tier = (info.ms < 28 && strong) ? 'high' : (info.ms < 70 && info.cores >= 4) ? 'mid' : 'low';
  const rec = { high: { q: 'max', fps: info.c120 ? 120 : info.c60 ? 60 : 30, prev: 1080 }, mid: { q: 'hi', fps: info.c60 ? 60 : 30, prev: 720 }, low: { q: 'mid', fps: 30, prev: 540 } }[info.tier];
  return { info, rec, ov: { fps: 'auto', prev: 'auto' } };
}
function fpsCap() {
  if (TRIAL) return 30;
  let v = DEV && DEV.ov && DEV.ov.fps !== 'auto' ? +DEV.ov.fps : (DEV ? DEV.rec.fps : 60);
  if (DEV && DEV.info) { if (v >= 120 && !DEV.info.c120) v = 60; if (v >= 60 && !DEV.info.c60) v = 30; }
  return v;
}
function prevCap() { return DEV && DEV.ov && DEV.ov.prev !== 'auto' ? +DEV.ov.prev : (DEV ? DEV.rec.prev : 1080); }
function devRows(box) {
  box.textContent = ''; if (!DEV) { box.textContent = 'لم يُجرَ الفحص بعد'; return; }
  const i = DEV.info, ok = (b) => b ? 'مدعوم' : 'غير مدعوم';
  [['مستوى الأداء', TIERS[i.tier]], ['المعالج', i.cores + ' أنوية'], ['الذاكرة', i.mem ? i.mem + ' غيغابايت' : 'غير معروفة'], ['تحديث الشاشة', i.hz + ' هرتز'], ['ترميز 1080p بـ 30 إطار', ok(i.c30)], ['ترميز 1080p بـ 60 إطار', ok(i.c60)], ['ترميز 1080p بـ 120 إطار', ok(i.c120)], ['سرعة الرسم', i.ms + ' مللي/إطار'], ['الموصى به', 'جودة ' + { max: 'قصوى', hi: 'عالية', mid: 'متوسطة' }[DEV.rec.q] + ' · حتى ' + DEV.rec.fps + ' إطار · معاينة ' + DEV.rec.prev + 'p']].forEach(([k, v]) => {
    const r = document.createElement('div'); r.className = 'xrow'; const x = document.createElement('span'); x.textContent = k; const y = document.createElement('b'); y.textContent = v; r.appendChild(x); r.appendChild(y); box.appendChild(r); });
}
function deviceCheck(showUI) {
  return new Promise((resolve) => {
    if (showUI) { $('devchk').hidden = false; $('dvRes').hidden = true; $('dvBtns').hidden = true; $('dvSpin').hidden = false; $('dvMsg').textContent = 'جارٍ فحص إمكانيات جهازك لتحديد أنسب الإعدادات...'; }
    probeDevice().then((r) => {
      const keep = DEV && DEV.ov; DEV = r; if (keep) DEV.ov = keep; LS.set(DEVKEY, DEV); fitCanvas();
      if (!showUI) return resolve();
      $('dvSpin').hidden = true; $('dvMsg').textContent = 'اكتمل الفحص. هذه الإعدادات الأنسب لجهازك:'; devRows($('dvRes')); $('dvRes').hidden = false; $('dvBtns').hidden = false;
      $('dvApply').onclick = () => { if (!TRIAL) { cfg.q = DEV.rec.q; saveCfg(); } $('devchk').hidden = true; if ($('settings').hidden === false) renderDevice(); resolve(); };
      $('dvSkip').onclick = () => { $('devchk').hidden = true; resolve(); };
    }).catch(() => { $('devchk').hidden = true; resolve(); });
  });
}
const FPSL = [['auto', 'تلقائي'], [30, '30'], [60, '60'], [120, '120']];
function pickFps(v) { if (!DEV) return; DEV.ov.fps = v; LS.set(DEVKEY, DEV); if (v !== 'auto' && DEV.info && ((+v >= 120 && !DEV.info.c120) || (+v >= 60 && !DEV.info.c60))) toast('جهازك لا يدعم هذا المعدل، سيُستخدم الأقرب له'); }
function buildFpsChips() {
  if (!DEV) return;
  buildChips('fpsChips', FPSL, (i, it) => String(DEV.ov.fps) === String(it[0]), (i, it) => { pickFps(it[0]); exportSummary(); });
}
function renderDevice() {
  devRows($('devSum'));
  if (!DEV) return;
  buildChips('devPrev', [['auto', 'تلقائي'], [540, 'منخفضة'], [720, 'متوسطة'], [1080, 'عالية']], (i, it) => String(DEV.ov.prev) === String(it[0]), (i, it) => { DEV.ov.prev = it[0]; LS.set(DEVKEY, DEV); fitCanvas(); });
  buildChips('devFps', FPSL, (i, it) => String(DEV.ov.fps) === String(it[0]), (i, it) => pickFps(it[0]));
  $('devNote').textContent = 'في وضع الفيديو يتبع التصدير إطارات الفيديو الأصلي حتى هذا الحد. وفي وضع صورة + صوت يُستخدم المعدل المختار (التلقائي حتى 60).';
}
$('devRe').addEventListener('click', () => deviceCheck(true));
function afterLogin(u) {
  const go = () => { if (u.trial) { PID = ''; enterEditor(); } else showHome(); };
  go();
}

/* ---------- الإعدادات والمظهر ---------- */
const UI = Object.assign({ mode: 'dark', tint: 0, size: 1, haptic: true, calm: false }, LS.get('minbar.ui', {}));
const TINTS = [['أخضر', '#090e0c', '#121b17', '#1a2620', '#2BB583'], ['أزرق', '#080d14', '#101923', '#18242f', '#4A90E2'], ['بنفسجي', '#0d0b14', '#17121f', '#211a2c', '#9B7BE0'], ['أسود', '#000000', '#0c0c0c', '#161616', '#2BB583'], ['بني', '#100b08', '#1c1410', '#271d17', '#C28A4A']];
function applyUI() {
  const dark = UI.mode === 'dark' || (UI.mode === 'auto' && window.matchMedia && matchMedia('(prefers-color-scheme: dark)').matches);
  document.body.classList.toggle('light', !dark); document.body.classList.toggle('calm', !!UI.calm);
  const r = document.documentElement.style, t = TINTS[UI.tint] || TINTS[0];
  const keys = { '--bg': t[1], '--card': t[2], '--card2': t[3], '--green': t[4], '--dock': rgba(t[1], .96), '--sheetA': t[2], '--sheetB': t[1], '--stageA': t[2], '--stageB': t[1] };
  Object.keys(keys).forEach((k) => { if (dark) r.setProperty(k, keys[k]); else r.removeProperty(k); });
  r.setProperty('--z', String(UI.size));
  const m = document.querySelector('meta[name=theme-color]'); if (m) m.content = dark ? t[1] : '#eef3f0';
}
function saveUI() { LS.set('minbar.ui', UI); applyUI(); }
applyUI(); if (window.matchMedia) { try { matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => { if (UI.mode === 'auto') applyUI(); }); } catch (e) {} }
function buildTints() {
  const box = $('uiTint'); box.innerHTML = '';
  TINTS.forEach((t, i) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'sw' + (UI.tint === i ? ' on' : ''); b.style.background = `linear-gradient(135deg,${t[1]} 50%,${t[4]} 50%)`; b.title = t[0]; b.onclick = () => { UI.tint = i; saveUI(); buildTints(); }; box.appendChild(b); });
}
function fillAccount() {
  const nm = user ? (user.name || (user.trial ? 'تجربة محدودة' : 'مستخدم')) : '', mail = (user && user.email) || '';
  ['acctName', 'acctName2'].forEach((id) => { $(id).textContent = nm; }); ['acctMail', 'acctMail2'].forEach((id) => { $(id).textContent = mail; });
  ['avMain', 'avBig'].forEach((id) => { const e = $(id); e.textContent = ''; if (user && user.photo) { const im = new Image(); im.referrerPolicy = 'no-referrer'; im.alt = ''; im.src = user.photo; e.appendChild(im); } else e.textContent = (nm || 'م').trim().charAt(0); });
}
const SPT = { main: 'الإعدادات', account: 'الحساب', appearance: 'المظهر', touch: 'اللمس والحركة', device: 'أداء الجهاز', data: 'البيانات والإعدادات', about: 'حول التطبيق والشروط' };
let spCur = 'main';
function spShow(p) { spCur = p; document.querySelectorAll('.spage').forEach((e) => { e.hidden = e.dataset.sp !== p; }); $('setTitle').textContent = SPT[p]; if (p === 'device') renderDevice(); if (p === 'account') fillAccount(); $('settings').querySelector('.ovb').scrollTop = 0; }
function openSettings(p) { fillAccount(); spShow(p || 'main'); $('settings').hidden = false; }
$('setBack').addEventListener('click', () => { if (spCur === 'main') $('settings').hidden = true; else spShow('main'); });
document.querySelectorAll('[data-go]').forEach((b) => { b.onclick = () => spShow(b.dataset.go); });
$('homeSet').addEventListener('click', () => openSettings());
buildChips('uiMode', [['dark', 'داكن'], ['light', 'فاتح'], ['auto', 'تلقائي']], (i, it) => UI.mode === it[0], (i, it) => { UI.mode = it[0]; saveUI(); });
buildChips('uiSize', [[.92, 'صغير'], [1, 'متوسط'], [1.1, 'كبير']], (i, it) => UI.size === it[0], (i, it) => { UI.size = it[0]; saveUI(); });
buildTints();
$('uiHaptic').checked = UI.haptic !== false; $('uiHaptic').addEventListener('change', () => { UI.haptic = $('uiHaptic').checked; saveUI(); });
$('uiMotion').checked = !!UI.calm; $('uiMotion').addEventListener('change', () => { UI.calm = $('uiMotion').checked; saveUI(); });

/* ---------- الكلمات: تصحيح ومزامنة ذكية واستخراج ---------- */
const fmtT = (t) => Math.floor(t / 60) + ':' + (t % 60).toFixed(1).padStart(4, '0');
function renderLyrList() {
  const box = $('lyrList'); if (!box) return; box.textContent = '';
  const L = lyrLines(); if (!L.length) return;
  const T = lyrTimes(L.length, S.dur || 9);
  const mat = () => { const t = lyrTimes(L.length, S.dur || 9).slice(); LY.t = t; return t; };
  const mk = (cls, txt, fn) => { const b = document.createElement('button'); b.type = 'button'; b.className = cls; b.textContent = txt; b.onclick = fn; return b; };
  const after = (t, i) => { lyrSave(); lyrInfo(); renderLyrList(); if (S.url) pv.currentTime = t[i]; dirty(); };
  L.forEach((ln, i) => {
    const r = document.createElement('div'); r.className = 'lrw';
    const tx = document.createElement('input'); tx.className = 'ltx'; tx.value = ln;
    tx.addEventListener('change', () => { const arr = lyrLines(); if (!tx.value.trim()) { tx.value = arr[i]; return; } arr[i] = tx.value.trim(); LY.text = arr.join('\n'); $('lyrText').value = LY.text; lyrSave(); dirty(); });
    r.append(mk('ltb', fmtT(T[i]), () => { if (S.url) { pv.currentTime = T[i]; dirty(); } }), tx,
      mk('lnb', '−', () => { const t = mat(); t[i] = Math.max(0, +(t[i] - .1).toFixed(2)); after(t, i); }),
      mk('lnb', '+', () => { const t = mat(); t[i] = +(t[i] + .1).toFixed(2); after(t, i); }),
      mk('lnb', '⏱', () => { const t = mat(); t[i] = +(pv.currentTime || 0).toFixed(2); after(t, i); }));
    box.appendChild(r);
  });
}
function pauseSync(L, spec) {
  const n = L.length, fps = spec.fps, vol = spec.vol, F = spec.frames;
  const sm = new Float32Array(F); for (let f = 0; f < F; f++) { let s = 0, c = 0; for (let k = Math.max(0, f - 2); k <= Math.min(F - 1, f + 2); k++) { s += vol[k]; c++; } sm[f] = s / c; }
  const sorted = Float32Array.from(sm).sort(), p20 = sorted[Math.floor(F * .2)], p80 = sorted[Math.floor(F * .8)], thr = p20 + (p80 - p20) * .3;
  const segs = []; let st = -1;
  for (let f = 0; f <= F; f++) { const on = f < F && sm[f] >= thr; if (on && st < 0) st = f; if (!on && st >= 0) { segs.push([st, f]); st = -1; } }
  const ph = []; segs.forEach((s) => { const l = ph[ph.length - 1]; if (l && s[0] - l[1] < 4) l[1] = s[1]; else ph.push([s[0], s[1]]); });
  const phr = ph.filter((p) => p[1] - p[0] >= 5); if (!phr.length) return null;
  let starts;
  if (phr.length >= n) {
    const gaps = phr.slice(1).map((p, i) => ({ i: i + 1, len: p[0] - phr[i][1] }));
    const keep = gaps.sort((x, y) => y.len - x.len).slice(0, n - 1).map((g) => g.i).sort((x, y) => x - y);
    starts = [phr[0][0]].concat(keep.map((i) => phr[i][0]));
  } else {
    const dsum = phr.reduce((s, p) => s + (p[1] - p[0]), 0), cnt = phr.map((p) => Math.max(1, Math.round(n * (p[1] - p[0]) / dsum)));
    let tot = cnt.reduce((x, y) => x + y, 0);
    while (tot > n) { const k = cnt.indexOf(Math.max.apply(null, cnt)); if (cnt[k] <= 1) break; cnt[k]--; tot--; }
    while (tot < n) { let bi = 0, bv = -1; phr.forEach((p, i) => { const v = (p[1] - p[0]) / cnt[i]; if (v > bv) { bv = v; bi = i; } }); cnt[bi]++; tot++; }
    starts = []; let li = 0;
    phr.forEach((p, i) => { const k = cnt[i], ch = []; for (let j = 0; j < k; j++) ch.push(Math.max(2, (L[li + j] || '').length)); const cs = ch.reduce((x, y) => x + y, 0); let acc = 0; for (let j = 0; j < k; j++) { starts.push(p[0] + (p[1] - p[0]) * acc / cs); acc += ch[j]; } li += k; });
  }
  if (starts.length !== n) return null;
  return starts.map((f) => +Math.max(0, f / fps - .15).toFixed(2));
}
$('lyrSmart').addEventListener('click', () => {
  const L = lyrLines(); if (!L.length) return toast('اكتب الكلمات أولاً');
  const spec = S.mode === 'audio' ? S.spec : S.vspec; if (!spec || !spec.vol) return toast('انتظر انتهاء تحليل الصوت أو اختر ملفاً أولاً');
  const t = pauseSync(L, spec); if (!t) return toast('تعذّرت المزامنة الذكية، جرّب المزامنة بالنقر');
  LY.t = t; lyrSave(); lyrInfo(); renderLyrList(); lyrOnNow(); toast('تمت المزامنة. راجع التوقيت وصحّحه إن لزم');
});
let asrBusy = false;
$('lyrAsr').addEventListener('click', async () => {
  if (asrBusy) return; if (!S.url) return toast('اختر الفيديو أو الصوت أولاً');
  if (!confirm('سيتم تحميل نموذج التعرّف على الكلام (حوالي 80 ميغابايت) عند أول استخدام، ويحتاج اتصالاً بالإنترنت. المتابعة؟')) return;
  asrBusy = true; const say = (m) => { $('lyrAsrMsg').textContent = m; };
  try {
    say('جارٍ تجهيز الصوت...');
    const buf = S.mode === 'audio' ? S.abuf : await decodeAudio(S.file); if (!buf) throw new Error('تعذّر قراءة الصوت');
    const off = new OfflineAudioContext(1, Math.ceil(buf.duration * 16000), 16000), src = off.createBufferSource(); src.buffer = buf; src.connect(off.destination); src.start();
    const pcm = (await off.startRendering()).getChannelData(0);
    say('جارٍ تحميل النموذج...');
    const tf = await import('https://cdn.jsdelivr.net/npm/@huggingface/transformers@3');
    const asr = await tf.pipeline('automatic-speech-recognition', 'Xenova/whisper-base', { dtype: 'q8', progress_callback: (p) => { if (p.status === 'progress' && p.total) say('تحميل النموذج ' + Math.round(p.loaded / p.total * 100) + '%'); } });
    say('جارٍ التعرّف على الكلمات، قد يستغرق دقائق...');
    const out = await asr(pcm, { language: 'arabic', task: 'transcribe', return_timestamps: true, chunk_length_s: 30, stride_length_s: 5 });
    const ch = (out.chunks || []).filter((c) => c.text && c.text.trim()); if (!ch.length) throw new Error('لم يتم التعرف على كلام واضح');
    LY.text = ch.map((c) => c.text.trim()).join('\n'); LY.t = ch.map((c) => +((c.timestamp && c.timestamp[0]) || 0).toFixed(2));
    $('lyrText').value = LY.text; lyrSave(); lyrInfo(); renderLyrList(); lyrOnNow();
    say('تم استخراج الكلمات. يرجى مراجعتها وتصحيحها من القائمة أدناه، فدقة الاستخراج تتفاوت مع الإنشاد.');
  } catch (e) { say('تعذّر الاستخراج التلقائي: ' + (e.message || e)); }
  asrBusy = false;
});



/* ---------- المتصفحات الداخلية (تيك توك وغيره) ---------- */
const INAPP = /TikTok|musical_ly|BytedanceWebview|Instagram|FBAN|FBAV|Snapchat|Line\//i.test(navigator.userAgent), IS_AND = /Android/i.test(navigator.userAgent), IS_TT = /TikTok|musical_ly|BytedanceWebview/i.test(navigator.userAgent);
function showInApp(force) {
  if (document.getElementById('inapp')) return;
  const m = document.createElement('div'); m.id = 'inapp'; m.className = 'svy'; const c = document.createElement('div'); c.className = 'svc'; m.appendChild(c);
  const h = (t, cls) => { const e = document.createElement('div'); e.className = cls; e.textContent = t; c.appendChild(e); };
  h(force ? 'تسجيل الدخول غير متاح هنا' : 'افتح منبر في المتصفح', 'svt');
  h('أنت تتصفح من داخل تطبيق آخر (مثل تيك توك). لا يسمح Google بتسجيل الدخول داخل هذه المتصفحات، وقد لا يعمل التصدير والحفظ بشكل سليم. يرجى فتح الرابط في المتصفح.', 'svs');
  const row = document.createElement('div'); row.className = 'row'; c.appendChild(row);
  const url = location.href.split('#')[0];
  if (IS_AND && !IS_TT) { const b = document.createElement('button'); b.type = 'button'; b.className = 'btn primary'; b.textContent = 'فتح في Chrome'; b.onclick = () => { location.href = 'intent://' + location.host + location.pathname + location.search + '#Intent;scheme=https;package=com.android.chrome;S.browser_fallback_url=' + encodeURIComponent(url) + ';end'; }; row.appendChild(b); }
  const cp = document.createElement('button'); cp.type = 'button'; cp.className = 'btn' + (IS_AND && !IS_TT ? '' : ' primary'); cp.textContent = 'نسخ الرابط'; cp.onclick = async () => { try { await navigator.clipboard.writeText(url); } catch (e) { const t = document.createElement('textarea'); t.value = url; document.body.appendChild(t); t.select(); try { document.execCommand('copy'); } catch (e2) {} t.remove(); } toast('تم نسخ الرابط، افتحه في المتصفح'); }; row.appendChild(cp);
  const ok = document.createElement('button'); ok.type = 'button'; ok.className = 'btn'; ok.textContent = 'متابعة هنا'; ok.onclick = () => m.remove(); row.appendChild(ok);
  h(IS_TT ? 'الطريقة: ١) اضغط على النقاط الثلاث ⋯ أعلى الصفحة. ٢) اختر «فتح في المتصفح». أو انسخ الرابط والصقه في Chrome.' : (IS_AND ? 'أو اضغط ⋯ أعلى الصفحة ثم «فتح في المتصفح».' : 'أو اضغط ⋯ ثم «فتح في Safari».'), 'svs');
  document.body.appendChild(m);
}
if (INAPP) { setTimeout(() => showInApp(false), 600); $('gBox').addEventListener('click', (e) => { if (e.target.closest && e.target.closest('#gBtn')) { e.stopPropagation(); e.preventDefault(); showInApp(true); } }, true); }

/* ---------- نهاية الفترة التجريبية وطلب التمديد ---------- */
function trialEnded() {
  const fin = () => { if (svAvail()) openSurvey('trial', () => reloadNow()); else reloadNow(); };
  if (!(AUTH && AUTH.enabled && AUTH.submitRequest)) { toast('انتهت فترة التجربة المحدودة'); setTimeout(reloadNow, 1500); return; }
  const m = document.createElement('div'); m.id = 'teEnd'; m.className = 'svy'; const c = document.createElement('div'); c.className = 'svc'; m.appendChild(c); document.body.appendChild(m);
  const h = (t, cls) => { const e = document.createElement('div'); e.className = cls; e.textContent = t; c.appendChild(e); return e; };
  const done = () => { m.remove(); fin(); };
  const intro = () => {
    c.textContent = ''; h('انتهت الفترة التجريبية', 'svt'); h('شكراً لتجربتك منبر. يمكنك تقديم طلب لتمديد الفترة أو فتح الميزات المتقدمة، أو التسجيل المسبق بحساب Google.', 'svs');
    const row = document.createElement('div'); row.className = 'row'; c.appendChild(row);
    const a1 = document.createElement('button'); a1.type = 'button'; a1.className = 'btn primary'; a1.textContent = 'تقديم طلب تمديد أو فتح ميزات'; a1.onclick = form; row.appendChild(a1);
    const a2 = document.createElement('button'); a2.type = 'button'; a2.className = 'btn'; a2.textContent = 'متابعة'; a2.onclick = done; row.appendChild(a2);
  };
  const form = () => {
    c.textContent = ''; h('طلب تمديد أو فتح ميزات', 'svt'); h('يرجى كتابة اسمك ومعرّفك ليتمكن المسؤول من التواصل معك.', 'svs');
    const inp = (ph, max) => { const i = document.createElement('input'); i.placeholder = ph; i.maxLength = max; i.autocomplete = 'off'; i.style.marginBottom = '10px'; c.appendChild(i); return i; };
    const nm = inp('الاسم (مطلوب)', 100), ct = inp('المعرّف: حساب تيك توك أو رقم واتساب أو بريد إلكتروني (مطلوب)', 120);
    h('نوع الطلب', 'svq'); let type = ''; const row = document.createElement('div'); row.className = 'svr'; c.appendChild(row);
    [['extend', 'تمديد الفترة التجريبية'], ['unlock', 'فتح الميزات المتقدمة']].forEach(([k, t]) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'svchip'; b.textContent = t; b.onclick = () => { type = k; [...row.children].forEach((x) => x.classList.toggle('on', x === b)); }; row.appendChild(b); });
    const ta = document.createElement('textarea'); ta.rows = 3; ta.maxLength = 500; ta.placeholder = 'ملاحظة (اختياري)'; ta.style.marginTop = '10px'; c.appendChild(ta);
    const r2 = document.createElement('div'); r2.className = 'row'; c.appendChild(r2);
    const go = document.createElement('button'); go.type = 'button'; go.className = 'btn primary'; go.textContent = 'إرسال الطلب'; r2.appendChild(go);
    const bk = document.createElement('button'); bk.type = 'button'; bk.className = 'btn'; bk.textContent = 'رجوع'; bk.onclick = intro; r2.appendChild(bk);
    go.onclick = async () => {
      if (nm.value.trim().length < 2) return toast('يرجى كتابة الاسم'); if (ct.value.trim().length < 3) return toast('يرجى كتابة المعرّف'); if (!type) return toast('يرجى اختيار نوع الطلب');
      go.disabled = true;
      try { await AUTH.submitRequest({ name: nm.value.trim(), contact: ct.value.trim(), type, note: ta.value.trim(), deviceId: DEVID, status: 'pending' }); toast('تم إرسال طلبك، وسيتم التواصل معك عبر المعرّف'); done(); }
      catch (e) { toast('تعذّر إرسال الطلب، يرجى المحاولة لاحقاً'); go.disabled = false; }
    };
  };
  intro();
}

/* ---------- الاستبيان ---------- */
const SVQ = {
  used: ['المصدر', 'التفاصيل', 'التصميم', 'الألوان', 'الخطوط', 'الإطار', 'الفلاتر', 'الشعار', 'القوالب', 'الكلمات', 'التصدير'],
  ease: ['سهل جداً', 'سهل', 'متوسط', 'صعب'],
  needs: ['قوالب إضافية', 'خطوط أكثر', 'مؤثرات صوتية بصرية', 'كلمات متزامنة', 'مقاطع أطول', 'أحجام تصدير أخرى', 'نشر مباشر على المنصات', 'أخرى'],
  issue: ['لا توجد مشكلة', 'بطء في الأداء', 'فشل التصدير', 'جودة منخفضة', 'خلل في العرض', 'أخرى'],
  willUse: ['نعم', 'ربما', 'لا']
};
const svKey = () => 'minbar.svy.' + (user && user.uid ? user.uid : 'trial');
function svAvail() { return !!(AUTH && AUTH.enabled && AUTH.submitSurvey && !AUTH.admin && !LS.get(svKey(), false)); }
function openSurvey(src, after) {
  if (!(AUTH && AUTH.enabled && AUTH.submitSurvey)) { if (after) after(); return; }
  const old = $('svy'); if (old) old.remove();
  const m = document.createElement('div'); m.id = 'svy'; m.className = 'svy';
  const c = document.createElement('div'); c.className = 'svc'; m.appendChild(c);
  const ans = { rating: 0, used: [], ease: '', needs: [], issue: '', willUse: '' };
  const h = (t, cls) => { const e = document.createElement('div'); e.className = cls; e.textContent = t; c.appendChild(e); return e; };
  const close = () => { m.remove(); if (after) after(); };
  h('استبيان رأي المستخدم', 'svt'); h('نشكر لك تجربتك للتطبيق. يرجى الإجابة عن الأسئلة التالية للمساهمة في تطويره.', 'svs');
  h('١. كيف تقيّم تجربتك العامة للتطبيق؟', 'svq');
  const sr = document.createElement('div'); sr.className = 'svstars'; c.appendChild(sr);
  for (let i = 1; i <= 5; i++) { const b = document.createElement('button'); b.type = 'button'; b.textContent = '★'; b.onclick = () => { ans.rating = i; [...sr.children].forEach((x, k) => x.classList.toggle('on', k < i)); }; sr.appendChild(b); }
  const group = (q, key, opts, multi) => {
    h(q, 'svq'); const row = document.createElement('div'); row.className = 'svr';
    opts.forEach((o) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'svchip'; b.textContent = o;
      b.onclick = () => { if (multi) { const i = ans[key].indexOf(o); if (i >= 0) ans[key].splice(i, 1); else ans[key].push(o); b.classList.toggle('on'); } else { ans[key] = ans[key] === o ? '' : o; [...row.children].forEach((x) => x.classList.toggle('on', x.textContent === ans[key])); } };
      row.appendChild(b); }); c.appendChild(row);
  };
  group('٢. ما الأقسام التي جرّبتها؟ (يمكن اختيار أكثر من قسم)', 'used', SVQ.used, true);
  group('٣. كيف تقيّم سهولة استخدام التطبيق؟', 'ease', SVQ.ease, false);
  group('٤. ما الميزات التي تحتاج إليها وغير متوفرة حالياً؟', 'needs', SVQ.needs, true);
  group('٥. هل واجهتك مشكلة أثناء الاستخدام؟', 'issue', SVQ.issue, false);
  group('٦. هل ستستخدم التطبيق عند إطلاقه رسمياً؟', 'willUse', SVQ.willUse, false);
  h('٧. ملاحظاتك واقتراحاتك', 'svq');
  const ta = document.createElement('textarea'); ta.rows = 4; ta.maxLength = 1500; ta.placeholder = 'يمكنك كتابة أي ملاحظة أو اقتراح هنا (اختياري)'; c.appendChild(ta);
  const row = document.createElement('div'); row.className = 'row'; c.appendChild(row);
  const go = document.createElement('button'); go.type = 'button'; go.className = 'btn primary'; go.textContent = 'إرسال'; row.appendChild(go);
  const sk = document.createElement('button'); sk.type = 'button'; sk.className = 'btn'; sk.textContent = 'تخطي'; sk.onclick = () => { LS.set(svKey(), true); close(); }; row.appendChild(sk);
  go.onclick = async () => {
    if (!ans.rating) return toast('يرجى اختيار التقييم العام أولاً');
    go.disabled = true;
    try {
      await AUTH.submitSurvey({ rating: ans.rating, used: ans.used.join('، ').slice(0, 300), ease: ans.ease, needs: ans.needs.join('، ').slice(0, 300), issue: ans.issue, willUse: ans.willUse, notes: ta.value.trim().slice(0, 1500), src, who: ((user && user.email) || 'تجربة محدودة').slice(0, 200) });
      LS.set(svKey(), true); toast('شكراً لمشاركتك'); close();
    } catch (e) { toast('تعذّر إرسال الاستبيان، يرجى المحاولة لاحقاً'); go.disabled = false; }
  };
  document.body.appendChild(m);
}
$('svOpen').addEventListener('click', () => openSurvey('export'));

/* ---------- صفحة التصدير ---------- */
function exportSummary() {
  buildFpsChips();
  const f = formState(), dur = S.dur || 0, Q = TRIAL ? 'mid' : cfg.q;
  const inf = { uhd: ['1440×2560', 45e6], max: ['1080×1920', 30e6], hi: ['1080×1920', 16e6], mid: ['720×1280', 8e6] }[Q];
  const rows = [['القصيدة', f.title || '—'], ['الرادود', $('fReciter').value.trim() || '—'], ['الشاعر', $('fPoet').value.trim() || '—'], ['النمط', S.mode === 'audio' ? 'صورة + صوت' : 'فيديو'], ['المدة', dur ? fmt(trimActive() ? rangesLen(keepRanges(dur)) : dur) : '—'], ['الدقة', inf[0] + ' · MP4'], ['الإطارات', S.mode === 'audio' ? Math.min(fpsCap(), (DEV && DEV.ov && DEV.ov.fps !== 'auto') ? 120 : 60) + ' إطار/ث' : 'حسب الفيديو (حتى ' + fpsCap() + ')']];
  const box = $('xsum'); box.textContent = '';
  rows.forEach(([k, v]) => { const r = document.createElement('div'); r.className = 'xrow'; const x = document.createElement('span'); x.textContent = k; const y = document.createElement('b'); y.textContent = v; r.appendChild(x); r.appendChild(y); box.appendChild(r); });
  const mb = dur ? Math.max(1, Math.round(inf[1] * dur / 8 / 1048576)) : 0;
  $('qInfo').textContent = (TRIAL ? 'التصدير في التجربة المحدودة بجودة 720p. ' : '') + (mb ? `الحجم التقريبي للملف: ${mb} ميغابايت` : 'اختر الفيديو أو الصوت لمعرفة الحجم التقريبي');
}
['btnSave', 'btnShare'].forEach((id) => $(id).addEventListener('click', () => { setTimeout(() => { if (svAvail()) openSurvey('export'); }, 1500); }));


/* ---------- القص وخط الزمن (مقاطع) ---------- */
let SEG = null, SELI = 0, curSeg = 0, tlZoom = 1, tlPPS = 60, cutIn = null, SID = 1;
const segNew = (a, b, o) => Object.assign({ id: SID++, a, b, fi: 0, fo: 0 }, o || {});
const segList = (dur) => (SEG && SEG.length) ? SEG : [{ a: 0, b: dur, fi: 0, fo: 0 }];
const trimActive = () => !!(S.dur && SEG && SEG.length);
function keepRanges(dur) { return segList(dur).map((s) => [Math.max(0, s.a), Math.min(dur, s.b)]).filter((r) => r[1] - r[0] > 0.02); }
const rangesLen = (rs) => rs.reduce((s, r) => s + r[1] - r[0], 0);
function segOffs(rs) { const o = []; let a = 0; rs.forEach((r) => { o.push(a); a += r[1] - r[0]; }); return o; }
function srcToOut(t, rs, hint) {
  let i = -1; const ok = (k) => rs[k] && t >= rs[k][0] - 1e-4 && t < rs[k][1] + 1e-4;
  if (hint != null && ok(hint)) i = hint;
  if (i < 0) for (let k = 0; k < rs.length; k++) if (t >= rs[k][0] - 1e-4 && t < rs[k][1]) { i = k; break; }
  if (i < 0) return -1;
  return segOffs(rs)[i] + Math.max(0, t - rs[i][0]);
}
function outSeg(t, rs) { let acc = 0; for (let i = 0; i < rs.length; i++) { const len = rs[i][1] - rs[i][0]; if (t < acc + len) return i; acc += len; } return rs.length - 1; }
function outToSrc(t, rs) { const i = outSeg(t, rs); return rs[i][0] + Math.min(Math.max(0, t - segOffs(rs)[i]), rs[i][1] - rs[i][0]); }
function fadeA(s, ts) { let a = 1; if (s.fi > 0) a = Math.min(a, (ts - s.a) / s.fi); if (s.fo > 0) a = Math.min(a, (s.b - ts) / s.fo); return Math.max(0, Math.min(1, a)); }
const segMono = (rs) => rs.every((r, i) => i === 0 || r[0] >= rs[i - 1][1] - 1e-3);
const segFades = () => !!(SEG && SEG.some((s) => s.fi > 0 || s.fo > 0));
function segSync(t, rs) {
  const ok = (i) => rs[i] && t >= rs[i][0] - 1e-3 && t <= rs[i][1] + 1e-3;
  if (ok(curSeg)) return curSeg; if (ok(SELI)) return (curSeg = SELI);
  const i = rs.findIndex((r) => t >= r[0] - 1e-3 && t < r[1]); if (i >= 0) curSeg = i; return curSeg;
}
function outNow() { if (!S.url) return 0; if (!trimActive()) return pv.currentTime || 0; const rs = keepRanges(S.dur), to = srcToOut(pv.currentTime, rs, segSync(pv.currentTime, rs)); return to < 0 ? 0 : to; }
function outDur() { return trimActive() ? rangesLen(keepRanges(S.dur)) : (pv.duration || 0); }
function seekOut(t) { t = Math.max(0, Math.min(t, outDur())); if (!trimActive()) { pv.currentTime = t; return; } const rs = keepRanges(S.dur); curSeg = outSeg(t, rs); pv.currentTime = outToSrc(t, rs); }
function trimGuard() {
  if (!S.url || !trimActive()) { if (pv.volume !== 1 && !afxOut) { try { pv.volume = 1; } catch (e) {} } return; }
  const d = pv.duration || S.dur, rs = keepRanges(d), t = pv.currentTime;
  if (curSeg >= rs.length) curSeg = 0;
  if (pv.paused) return;
  let r = rs[curSeg];
  if (t < r[0] - 0.3 || t > r[1] + 0.3) {
    const i = rs.findIndex((x) => t >= x[0] - 1e-3 && t < x[1]);
    if (i >= 0) curSeg = i; else { curSeg = Math.max(0, rs.findIndex((x) => x[0] > t)); pv.currentTime = rs[curSeg][0]; }
    r = rs[curSeg];
  }
  if (t >= r[1] - 0.025) {
    if (curSeg >= rs.length - 1) { pv.pause(); $('playBtn').textContent = '▶'; curSeg = 0; pv.currentTime = rs[0][0]; return; }
    const nx = rs[curSeg + 1]; curSeg++; if (Math.abs(nx[0] - r[1]) > 0.04) pv.currentTime = nx[0];
  }
  if (!afxOut) { try { pv.volume = segFades() ? fadeA(segList(d)[curSeg], pv.currentTime) : 1; } catch (e) {} }
}
function trNeed() { if (!S.url || !S.dur) { toast('اختر الفيديو أو الصوت أولاً'); return false; } return true; }
function segEnsure() { if (!SEG || !SEG.length) { SEG = [segNew(0, S.dur)]; SELI = 0; curSeg = 0; } }
function segFix() { if (!Array.isArray(SEG) || !SEG.length) { SEG = null; return; } SEG.forEach((s) => { if (!s.id) s.id = SID++; else SID = Math.max(SID, s.id + 1); s.fi = s.fi || 0; s.fo = s.fo || 0; if (S.dur) s.b = Math.min(s.b, S.dur); }); SEG = SEG.filter((s) => s.b - s.a > 0.05); if (!SEG.length) SEG = null; if (SELI >= (SEG ? SEG.length : 1)) SELI = 0; }
function legacySeg(t, dur) {
  if (!t) return null; const a = Math.max(0, t.a || 0), b = (t.b && t.b > 0) ? t.b : (dur || 1e6); let rs = [[a, b]];
  (t.cuts || []).slice().sort((x, y) => x[0] - y[0]).forEach(([c0, c1]) => { const nr = []; rs.forEach(([s, e]) => { if (c1 <= s || c0 >= e) nr.push([s, e]); else { if (c0 > s) nr.push([s, c0]); if (c1 < e) nr.push([c1, e]); } }); rs = nr; });
  rs = rs.filter((r) => r[1] - r[0] > 0.05); const id = rs.length === 1 && rs[0][0] <= 0.01 && !t.b && !(t.cuts || []).length;
  return (!rs.length || id) ? null : rs.map((r) => segNew(r[0], r[1]));
}
function segCommit(msg) { trRefresh(); pushHist(); if (msg) toast(msg); dirty(); }
function trRefresh() {
  if (SEG && S.dur && SEG.length === 1 && SEG[0].a < 0.01 && SEG[0].b >= S.dur - 0.01 && !SEG[0].fi && !SEG[0].fo) { SEG = null; SELI = 0; }
  if (SEG && SELI >= SEG.length) SELI = SEG.length - 1; if (SELI < 0) SELI = 0;
  const d = S.dur || 0, n = SEG ? SEG.length : 1;
  $('trInfo').textContent = d ? `${n} مقطع · المدة بعد التحرير ${fmt(outDur())} من ${fmt(d)}` : 'اختر فيديو أو صوتاً أولاً';
  if (S.url) { $('tdur').textContent = fmt(outDur()); const od = outDur(); $('seek').value = od ? Math.round(outNow() / od * 1000) : 0; }
  tlBuild(); touchProject(); dirty();
}
$('trReset').addEventListener('click', () => { if (!SEG) return; SEG = null; SELI = 0; curSeg = 0; segCommit('تم إلغاء كل التعديلات'); });
['fileIn', 'audIn'].forEach((id) => $(id).addEventListener('change', () => { SEG = null; SELI = 0; curSeg = 0; cutIn = null; }));
pv.addEventListener('loadedmetadata', () => { trPk = null; trPkSrc = null; segFix(); trRefresh(); if (openP === 'trim') trEnsurePeaks(); });
/* ---------- الموجة والتايم لاين ---------- */
let trPk = null, trPkSrc = null, trPkBusy = false;
async function trEnsurePeaks() {
  if (!S.url || trPkBusy) { tlBuild(); return; }
  const src = S.mode === 'audio' ? S.abuf : S.file;
  if (!src) { tlBuild(); return; }
  if (trPk && trPkSrc === src) { tlBuild(); return; }
  trPkBusy = true; $('tlSegInfo').textContent = 'جارٍ تحليل الموجة...';
  try {
    const buf = S.mode === 'audio' ? S.abuf : await decodeAudio(S.file);
    if (!buf) throw 0;
    const d = buf.getChannelData(0), sr = buf.sampleRate, N = 1800, step = Math.max(1, Math.floor(d.length / N)), pk = new Float32Array(N);
    for (let i = 0; i < N; i++) { let m = 0; const a = i * step, e = Math.min(d.length, a + step), st = Math.max(1, Math.floor((e - a) / 200)); for (let k = a; k < e; k += st) { const v = Math.abs(d[k]); if (v > m) m = v; } pk[i] = m; }
    const W = Math.max(1, Math.floor(sr * 0.05)), nw = Math.floor(d.length / W), rms = new Float32Array(nw);
    for (let i = 0; i < nw; i++) { let sum = 0, c = 0; const a = i * W, st = Math.max(1, Math.floor(W / 40)); for (let k = a; k < a + W; k += st) { sum += d[k] * d[k]; c++; } rms[i] = Math.sqrt(sum / c); }
    trPk = { pk, rms, win: W / sr }; trPkSrc = src;
  } catch (e) { trPk = null; }
  trPkBusy = false; trRefresh();
}
const TLH = 78;
function tlWave(cv, s, w) {
  const dpr = 1; cv.width = Math.max(1, Math.round(w)); cv.height = TLH; const x = cv.getContext('2d'); x.clearRect(0, 0, cv.width, TLH);
  const d = S.dur || 1;
  if (trPk) { const n = trPk.pk.length; x.fillStyle = 'rgba(255,255,255,.55)'; for (let px = 0; px < cv.width; px += 2) { const tt = s.a + px / cv.width * (s.b - s.a), i = Math.min(n - 1, Math.max(0, Math.floor(tt / d * n))), v = Math.min(1, trPk.pk[i] * 1.6), bh = Math.max(2, v * (TLH - 30)); x.fillRect(px, 22 + (TLH - 22 - bh) / 2, 1.4, bh); } }
  else { x.fillStyle = 'rgba(255,255,255,.18)'; x.fillRect(0, TLH / 2 + 10, cv.width, 2); }
}
function tlFill(blk, s, i) {
  const w = Math.max(30, (s.b - s.a) * tlPPS); blk.style.width = w + 'px';
  tlWave(blk.querySelector('canvas'), s, Math.min(w, 2400));
  blk.querySelector('.tlt').textContent = fmt(s.b - s.a);
  const fi = blk.querySelector('.tlfi'), fo = blk.querySelector('.tlfo'); fi.style.width = Math.min(w / 2, s.fi * tlPPS) + 'px'; fo.style.width = Math.min(w / 2, s.fo * tlPPS) + 'px';
}
function tlSegUi() {
  const rs = segList(S.dur || 0), s = rs[Math.min(SELI, rs.length - 1)]; if (!S.dur || !s) { $('tlSegInfo').textContent = 'اختر فيديو أو صوتاً أولاً'; return; }
  const len = s.b - s.a, mx = Math.max(0, Math.min(30, Math.floor(len / 2 * 10)));
  $('tlFi').max = mx; $('tlFo').max = mx; $('tlFi').value = Math.round(s.fi * 10); $('tlFo').value = Math.round(s.fo * 10);
  $('tlFiV').textContent = s.fi.toFixed(1) + ' ث'; $('tlFoV').textContent = s.fo.toFixed(1) + ' ث';
  if (!trPkBusy) $('tlSegInfo').textContent = `المقطع ${SELI + 1} من ${rs.length}: ${fmtT(s.a)} ← ${fmtT(s.b)}`;
}
function tlBuild() {
  const box = $('tlTrack'); if (!box) return; const wrap = $('tlScroll'), d = S.dur || 0;
  box.textContent = ''; if (!d || !wrap.clientWidth) { tlSegUi(); return; }
  tlPPS = Math.max(8, (wrap.clientWidth - 16) / d) * tlZoom;
  const rs = segList(d); box.style.width = '';
  rs.forEach((s, i) => {
    const b = document.createElement('div'); b.className = 'tlseg' + (i === SELI ? ' sel' : ''); b.dataset.i = i;
    b.innerHTML = '<canvas></canvas><div class="tlfi"></div><div class="tlfo"></div><div class="tlgrip"><span>⠿</span><b class="tlt"></b></div><div class="tlh l"></div><div class="tlh r"></div>';
    box.appendChild(b); tlFill(b, s, i); tlBind(b, i);
  });
  tlSegUi(); tlPh();
}
function tlPh() {
  const ph = $('tlPh'); if (!ph || !S.dur) return; const box = $('tlTrack'), rs = segList(S.dur), t = pv.currentTime || 0, ci = segSync(t, rs), b = box.children[ci];
  if (!b) { ph.style.display = 'none'; return; }
  const r = rs[ci], f = Math.max(0, Math.min(1, (t - r[0]) / Math.max(0.01, r[1] - r[0]))), x = b.offsetLeft + f * b.offsetWidth; ph.style.display = 'block'; ph.style.left = x + 'px';
  const w = $('tlScroll'); if (!pv.paused && (x < w.scrollLeft + 10 || x > w.scrollLeft + w.clientWidth - 10)) w.scrollLeft = x - w.clientWidth / 2;
  const od = outDur(); $('tlCur').textContent = fmtT(outNow()); $('tlTot').textContent = fmtT(od);
}
function tlBind(b, i) {
  const grip = b.querySelector('.tlgrip');
  b.addEventListener('click', (e) => {
    if (e.target.closest('.tlgrip') || e.target.closest('.tlh')) return; if (!trNeed()) return;
    const s = segList(S.dur)[i], r = b.getBoundingClientRect(), f = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width));
    SELI = i; curSeg = i; pv.pause(); $('playBtn').textContent = '▶'; pv.currentTime = s.a + f * (s.b - s.a);
    [...$('tlTrack').children].forEach((c, k) => c.classList.toggle('sel', k === i)); tlSegUi(); tlPh(); dirty();
  });
  grip.addEventListener('pointerdown', (e) => {
    if (!trNeed()) return; e.preventDefault(); e.stopPropagation(); segEnsure(); const rs = SEG, blocks = [...$('tlTrack').children], x0 = e.clientX, sc = $('tlScroll'), sl0 = sc.scrollLeft; let moved = false;
    try { grip.setPointerCapture(e.pointerId); } catch (x) {} SELI = i; curSeg = i; blocks.forEach((c, k) => c.classList.toggle('sel', k === i)); b.classList.add('drag');
    const mv = (ev) => { const dx = ev.clientX - x0 + (sc.scrollLeft - sl0); if (Math.abs(dx) > 4) moved = true; b.style.transform = `translateX(${dx}px)`; };
    const up = (ev) => {
      grip.removeEventListener('pointermove', mv); grip.removeEventListener('pointerup', up); grip.removeEventListener('pointercancel', up); b.classList.remove('drag'); b.style.transform = '';
      if (!moved) { tlSegUi(); return; }
      const dx = ev.clientX - x0 + (sc.scrollLeft - sl0), c = b.offsetLeft + b.offsetWidth / 2 + dx; let tg = 0;
      blocks.forEach((o, k) => { if (k !== i && o.offsetLeft + o.offsetWidth / 2 < c) tg++; });
      if (tg !== i) { const [s] = rs.splice(i, 1); rs.splice(tg, 0, s); SELI = tg; curSeg = tg; pv.pause(); $('playBtn').textContent = '▶'; pv.currentTime = s.a; segCommit('تم تغيير الترتيب'); } else tlBuild();
    };
    grip.addEventListener('pointermove', mv); grip.addEventListener('pointerup', up); grip.addEventListener('pointercancel', up);
  });
  b.querySelectorAll('.tlh').forEach((h) => h.addEventListener('pointerdown', (e) => {
    if (!trNeed()) return; e.preventDefault(); e.stopPropagation(); segEnsure(); const s = SEG[i], left = h.classList.contains('l'), x0 = e.clientX, a0 = s.a, b0 = s.b, sc = $('tlScroll'), sl0 = sc.scrollLeft;
    try { h.setPointerCapture(e.pointerId); } catch (x) {} SELI = i; curSeg = i; pv.pause(); $('playBtn').textContent = '▶';
    [...$('tlTrack').children].forEach((c, k) => c.classList.toggle('sel', k === i));
    const mv = (ev) => {
      const dt = (ev.clientX - x0 + (sc.scrollLeft - sl0)) / tlPPS;
      if (left) s.a = Math.max(0, Math.min(s.b - 0.2, a0 + dt)); else s.b = Math.min(S.dur, Math.max(s.a + 0.2, b0 + dt));
      s.fi = Math.min(s.fi, (s.b - s.a) / 2); s.fo = Math.min(s.fo, (s.b - s.a) / 2);
      tlFill(b, s, i); pv.currentTime = left ? s.a : Math.max(s.a, s.b - 0.05); tlSegUi(); tlPh(); dirty();
    };
    const up = () => { h.removeEventListener('pointermove', mv); h.removeEventListener('pointerup', up); h.removeEventListener('pointercancel', up); segCommit(); };
    h.addEventListener('pointermove', mv); h.addEventListener('pointerup', up); h.addEventListener('pointercancel', up);
  }));
}
(function () {
  const rule = $('tlRule'); let drag = false;
  const seek = (e) => {
    if (!S.dur) return; const box = $('tlTrack'), sc = $('tlScroll'), x = e.clientX - sc.getBoundingClientRect().left + sc.scrollLeft, rs = segList(S.dur); let k = 0;
    [...box.children].forEach((c, j) => { if (c.offsetLeft <= x) k = j; }); const c = box.children[k]; if (!c) return;
    const f = Math.max(0, Math.min(1, (x - c.offsetLeft) / Math.max(1, c.offsetWidth))); curSeg = k; pv.pause(); $('playBtn').textContent = '▶'; pv.currentTime = rs[k][0] + f * (rs[k][1] - rs[k][0]); tlPh(); dirty();
  };
  rule.addEventListener('pointerdown', (e) => { drag = true; try { rule.setPointerCapture(e.pointerId); } catch (x) {} seek(e); });
  rule.addEventListener('pointermove', (e) => { if (drag) seek(e); });
  ['pointerup', 'pointercancel'].forEach((ev) => rule.addEventListener(ev, () => { drag = false; }));
  ['timeupdate', 'seeked'].forEach((ev) => pv.addEventListener(ev, () => { if (openP === 'trim' && !collapsed) tlPh(); }));
  window.addEventListener('resize', () => { if (openP === 'trim') tlBuild(); });
  $('tlZin').addEventListener('click', () => { tlZoom = Math.min(12, tlZoom * 1.6); tlBuild(); });
  $('tlZout').addEventListener('click', () => { tlZoom = Math.max(1, tlZoom / 1.6); tlBuild(); });
  $('tlSplit').addEventListener('click', () => {
    if (!trNeed()) return; segEnsure(); const rs = keepRanges(S.dur), t = +pv.currentTime.toFixed(2), i = segSync(t, rs), s = SEG[i];
    if (!s || t < s.a + 0.15 || t > s.b - 0.15) return toast('حرّك المؤشر داخل المقطع');
    const R = segNew(t, s.b, { fo: s.fo }); s.b = t; s.fo = 0; SEG.splice(i + 1, 0, R); SELI = i + 1; curSeg = i + 1; segCommit('تم التقسيم');
  });
  $('tlDup').addEventListener('click', () => { if (!trNeed()) return; segEnsure(); const s = SEG[SELI]; if (!s) return; SEG.splice(SELI + 1, 0, segNew(s.a, s.b, { fi: s.fi, fo: s.fo })); SELI++; curSeg = SELI; segCommit('تم تكرار المقطع'); });
  $('tlDel').addEventListener('click', () => {
    if (!trNeed()) return; if (!SEG || SEG.length < 2) return toast('لا يمكن حذف المقطع الوحيد');
    SEG.splice(SELI, 1); SELI = Math.min(SELI, SEG.length - 1); curSeg = SELI; pv.pause(); $('playBtn').textContent = '▶'; pv.currentTime = SEG[SELI].a; segCommit('تم حذف المقطع');
  });
  const mvSeg = (d) => { if (!trNeed() || !SEG) return; const j = SELI + d; if (j < 0 || j >= SEG.length) return; const [s] = SEG.splice(SELI, 1); SEG.splice(j, 0, s); SELI = j; curSeg = j; segCommit(); };
  $('tlL').addEventListener('click', () => mvSeg(-1)); $('tlR').addEventListener('click', () => mvSeg(1));
  $('tlPlaySel').addEventListener('click', () => {
    if (!trNeed()) return; const s = segList(S.dur)[SELI]; if (!s) return; curSeg = SELI; pv.currentTime = s.a; pv.muted = !!afxOut; pv.play().catch(() => {}); $('playBtn').textContent = '⏸';
    const stop = () => { if (pv.paused) { pv.removeEventListener('pause', stop); return; } if (pv.currentTime >= s.b - 0.03) { pv.pause(); $('playBtn').textContent = '▶'; pv.removeEventListener('timeupdate', stop); } }; pv.addEventListener('timeupdate', stop);
  });
  const fade = (k) => () => { if (!trNeed()) return; segEnsure(); const s = SEG[SELI]; if (!s) return; const v = +$(k === 'fi' ? 'tlFi' : 'tlFo').value / 10, o = k === 'fi' ? s.fo : s.fi; s[k] = Math.max(0, Math.min(v, (s.b - s.a) - o)); const b = $('tlTrack').children[SELI]; if (b) tlFill(b, s, SELI); tlSegUi(); dirty(); pushHist(); touchProject(); };
  $('tlFi').addEventListener('input', fade('fi')); $('tlFo').addEventListener('input', fade('fo'));
  const sv = () => { $('trSilThrV').textContent = $('trSilThr').value + ' dB'; $('trSilMinV').textContent = ($('trSilMin').value / 10).toFixed(1) + ' ث'; };
  ['trSilThr', 'trSilMin'].forEach((id) => $(id).addEventListener('input', sv)); sv();
  $('trSilGo').addEventListener('click', async () => {
    if (!trNeed()) return; if (!trPk) { await trEnsurePeaks(); if (!trPk) return toast('تعذّر تحليل الصوت'); }
    const thr = Math.pow(10, +$('trSilThr').value / 20), minL = $('trSilMin').value / 10, rms = trPk.rms, win = trPk.win, pad = 0.15, found = [];
    let st = -1;
    for (let i = 0; i <= rms.length; i++) { const quiet = i < rms.length && rms[i] < thr; if (quiet && st < 0) st = i; if (!quiet && st >= 0) { const a = st * win, b = i * win; if (b - a >= minL) { const c0 = a + pad, c1 = b - pad; if (c1 - c0 > 0.1) found.push([c0, c1]); } st = -1; } }
    if (!found.length) return toast('ما لقيت صمت بهذي الحساسية');
    segEnsure(); const out = [];
    SEG.forEach((s) => {
      let ps = [[s.a, s.b]]; found.forEach(([c0, c1]) => { const nr = []; ps.forEach(([x, y]) => { if (c1 <= x || c0 >= y) nr.push([x, y]); else { if (c0 > x) nr.push([x, c0]); if (c1 < y) nr.push([c1, y]); } }); ps = nr; });
      ps = ps.filter((p) => p[1] - p[0] > 0.1); ps.forEach((p, k) => out.push(segNew(p[0], p[1], { fi: k === 0 ? s.fi : 0, fo: k === ps.length - 1 ? s.fo : 0 })));
    });
    if (!out.length) return toast('كل المقاطع صمت!'); SEG = out; SELI = 0; curSeg = 0; segCommit('تم حذف الصمت من ' + found.length + ' موضع');
  });
})();


/* ---------- صفحة التصدير الكاملة ---------- */
function estMB() { const d = S.dur ? outDur() : 0, Q = TRIAL ? 'mid' : cfg.q, br = { uhd: 45e6, max: 30e6, hi: 16e6, mid: 8e6 }[Q]; return d ? Math.max(1, Math.round(br * d / 8 / 1048576)) : 0; }
function openExport() {
  const nm = ($('fTitle').value.trim() || 'قصيدة').replace(/[\\/:*?"<>|]+/g, ' ').trim();
  $('expOv').hidden = false; $('eoTitle').textContent = 'جارٍ التصدير'; $('eoName').textContent = 'منبر - ' + nm + '.mp4'; $('eoPct').textContent = '0%'; $('eoBar').style.width = '0'; $('eoMsg').textContent = 'جارٍ التجهيز...';
  $('eoSize').textContent = estMB() ? '≈ ' + estMB() + ' ميغابايت (تقديري)' : '—'; $('eoCancel').hidden = false; $('eoClose').hidden = true; $('result').hidden = true;
}
$('eoCancel').addEventListener('click', () => { S.cancel = true; });
$('eoClose').addEventListener('click', () => { $('expOv').hidden = true; });

/* ---------- زر الرجوع وحماية الخروج ---------- */
let lastBack = 0;
const IOS = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
/* منع التكبير بالضغطتين أو بالإصبعين على كل الأجهزة */
['gesturestart', 'gesturechange', 'gestureend'].forEach((ev) => document.addEventListener(ev, (e) => e.preventDefault(), { passive: false }));
document.addEventListener('touchmove', (e) => { if (e.touches.length > 1 || (e.scale && e.scale !== 1)) e.preventDefault(); }, { passive: false });
document.addEventListener('dblclick', (e) => e.preventDefault(), { passive: false });
/* آيفون (التطبيق المثبّت لا يملك زر رجوع): سحب من حافة الشاشة للرجوع */
(function () { if (!IOS) return; let sx = 0, sy = 0, on = false, ind = null;
  const end = () => { on = false; if (ind) { const i = ind; ind = null; i.style.opacity = '0'; setTimeout(() => i.remove(), 200); } };
  document.addEventListener('touchstart', (e) => { if (e.touches.length !== 1) return end(); const t = e.touches[0]; if (t.clientX > 24 && t.clientX < innerWidth - 24) return; on = true; sx = t.clientX; sy = t.clientY; }, { passive: true, capture: true });
  document.addEventListener('touchmove', (e) => { if (!on) return; const t = e.touches[0], dx = Math.abs(t.clientX - sx), dy = Math.abs(t.clientY - sy); if (dy > 60 && dy > dx) return end();
    if (dx > 12 && !ind) { ind = document.createElement('div'); ind.className = 'edgeback' + (sx > innerWidth / 2 ? ' r' : ''); ind.innerHTML = '<svg viewBox="0 0 24 24"><path d="M15 6l-6 6 6 6"/></svg>'; ind.style.top = (t.clientY - 22) + 'px'; document.body.appendChild(ind); }
    if (ind) { const k = Math.min(1, dx / 80); ind.style.setProperty('--k', k); ind.classList.toggle('go', k >= 1); } }, { passive: true, capture: true });
  document.addEventListener('touchend', (e) => { if (!on) return; const t = e.changedTouches[0], dx = Math.abs(t.clientX - sx), dy = Math.abs(t.clientY - sy); end(); if (dx >= 80 && dy < 70) { try { if (navigator.vibrate) navigator.vibrate(8); } catch (x) {} layerClose(); } }, { passive: true, capture: true });
  document.addEventListener('touchcancel', end, { passive: true, capture: true }); })();
/* حماية الرجوع: مدخلان في السجل يُضافان عند لمسة حقيقية (pointerup/touchend) كي لا يتجاهلهما كروم، فيصير الخروج بضغطتين */
try { history.replaceState({ m: 'root', n: 0 }, ''); } catch (e) {}
const gdN = () => (history.state && history.state.n) || 0;
/* 6 مداخل تُعبّأ عند كل لمسة حقيقية: كروم يتجاهل المداخل المضافة بلا لمسة، فكانت ضغطات الرجوع المتتالية تُخرج من الموقع */
function armGuard() { try { let n = gdN(); while (n < 6) history.pushState({ m: 'app', n: ++n }, ''); } catch (e) {} }
['pointerup', 'touchend', 'click', 'keydown'].forEach((ev) => document.addEventListener(ev, armGuard, { passive: true, capture: true }));
function layerClose() {
  if (!$('tplOv').hidden) { $('tplOv').hidden = true; return true; }
  const adm = $('admModal'); if (adm && !adm.hidden) { adm.hidden = true; return true; }
  const sv = $('svy'); if (sv) { const b = sv.querySelector('.row .btn:not(.primary)'); if (b) b.click(); return true; }
  if (!$('expOv').hidden) { if (S.busy) toast('التصدير جارٍ. اضغط «إلغاء التصدير» للإيقاف'); else $('expOv').hidden = true; return true; }
  if (!$('devchk').hidden) return true;
  if (!$('settings').hidden) { if (spCur === 'main') $('settings').hidden = true; else spShow('main'); return true; }
  if ($('login').classList.contains('show')) return false;
  if (window.PLR && window.PLR.visible() && window.PLR.back()) return true;
  if ($('home').hidden && user && !TRIAL) { goHome(); if (window.PLR) window.PLR.open(); return true; }
  if (!$('home').hidden && window.PLR && !window.PLR.visible()) { window.PLR.open(); return true; }
  return false;
}
window.addEventListener('popstate', () => {
  /* الرجوع يغلق النافذة المفتوحة فقط ولا يُخرج من الموقع أبداً (للخروج: زر الرئيسية أو إغلاق التبويب) */
  layerClose();
  if (gdN() < 1) { try { history.pushState({ m: 'app', n: 1 }, ''); } catch (e) {} }
});
window.addEventListener('beforeunload', (e) => { if (allowUnload) return; if (S.busy || (TRIAL && hasContent())) { e.preventDefault(); e.returnValue = ''; } });
document.addEventListener('contextmenu', (e) => { if (!(e.target.closest && e.target.closest('input,textarea'))) e.preventDefault(); });

/* ---------- النوافذ والشريط ---------- */
let openP = 'media', collapsed = false;
const TIDX = (id) => TOOLS.findIndex((t) => t[0] === id);
function paintPanels(dir) {
  $('sheet').classList.toggle('open', !collapsed);
  $('sheet').style.setProperty('--dx', (dir || 0) * 26 + 'px');
  document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('on', p.dataset.p === openP));
  $('grabBtn').classList.toggle('flip', collapsed);
  if (!collapsed && openP === 'export') exportSummary();
  if (!collapsed) { if (openP === 'design' || openP === 'filter') refreshDesign(); if (openP === 'tpl') buildTplGal('tplGal', 'all', false); if (openP === 'trim') trEnsurePeaks(); if (openP === 'logo') buildLogoUI(); }
  updateDock(); dirty(); if (typeof vtfHook === 'function') vtfHook();
}
function openPanel(id) {
  if (TRIAL && !unlocked() && TRIAL_LOCK.has(id)) return toast('هذه الميزة متاحة بعد التسجيل بحساب Google');
  if (openP === id && !collapsed) return;
  const prev = TIDX(openP), nx = TIDX(id), dir = (prev >= 0 && nx >= 0 && prev !== nx) ? (nx > prev ? -1 : 1) : 0;
  openP = id; collapsed = false; paintPanels(dir);
}
$('grabBtn').addEventListener('click', () => { collapsed = !collapsed; paintPanels(0); });
function buildDock() {
  const d = $('dock'); d.innerHTML = '<span class="dind" id="dind"></span>';
  TOOLS.forEach((t) => { const b = document.createElement('button'); b.className = 'tool' + (TRIAL && !unlocked() && TRIAL_LOCK.has(t[0]) ? ' lock' : ''); b.dataset.t = t[0]; b.innerHTML = `${ic(t[0])}<span>${t[1]}</span>`; b.onclick = () => openPanel(t[0]); d.appendChild(b); });
}
function updateDock() {
  const d = $('dock'); let act = null;
  d.querySelectorAll('.tool').forEach((b) => { const on = b.dataset.t === openP; b.classList.toggle('on', on); if (on) act = b; });
  const ind = $('dind');
  if (act) { ind.style.opacity = 1; ind.style.width = act.offsetWidth + 'px'; ind.style.transform = `translateX(${act.offsetLeft}px)`; try { act.scrollIntoView({ inline: 'center', block: 'nearest', behavior: 'smooth' }); } catch (e) {} } else ind.style.opacity = 0;
}
$('topExport').addEventListener('click', () => openPanel('export'));
document.addEventListener('click', (e) => { if (e.target.closest && e.target.closest('button,.chip,.sw,.tool')) buzz(); });

/* ---------- تراجع وإعادة ---------- */
const hist = { a: [], i: -1, lock: false, timer: null };
const HK = TPL_KEYS.concat(['tp', 'q', 'lyrOn', 'lyrY', 'lyrSize', 'vtf', 'fx']);
const snap = () => { const o = {}; HK.forEach((k) => { o[k] = clone(cfg[k] === undefined ? null : cfg[k]); }); o.__seg = clone(SEG); return JSON.stringify(o); };
function updUndo() { $('btnUndo').disabled = hist.i <= 0; $('btnRedo').disabled = hist.i >= hist.a.length - 1; }
function pushHist() {
  if (hist.lock) return; clearTimeout(hist.timer);
  hist.timer = setTimeout(() => { const sn = snap(); if (hist.a[hist.i] === sn) return; hist.a = hist.a.slice(0, hist.i + 1); hist.a.push(sn); if (hist.a.length > 60) hist.a.shift(); hist.i = hist.a.length - 1; updUndo(); }, 350);
}
onSave = pushHist;
function histGo(d) {
  const ni = hist.i + d; if (ni < 0 || ni >= hist.a.length) return;
  hist.i = ni; hist.lock = true; const HJ = JSON.parse(hist.a[ni]); SEG = HJ.__seg || null; delete HJ.__seg; segFix(); Object.assign(cfg, HJ); cfg.logoP = Object.assign({}, LOGO0, cfg.logoP); if (cfg.logoMode === 'image' && !cfg.logoData) cfg.logoMode = 'builder';
  LS.set('basim.cfg', cfg); rebuildAll(); loadLogo(); loadFont(); hist.lock = false; updUndo(); trRefresh(); dirty();
}
$('btnUndo').addEventListener('click', () => histGo(-1)); $('btnRedo').addEventListener('click', () => histGo(1));

/* ---------- الحساب وشاشة الدخول ---------- */
const AUTH = window.MinbarAuth; let user = (AUTH && AUTH.enabled) ? null : LS.get('basim.user', null), loginRaf = 0, loginMode = 'in';
function applyUser() { fillAccount(); }
let lgL = 0;
function loginBg(ts) {
  loginRaf = requestAnimationFrame(loginBg); const lg = $('login'); if (document.hidden || !lg || !lg.classList.contains('show') || (window.PLR && PLR.visible && PLR.visible()) || (ts || 0) - lgL < 40) return; lgL = ts || 0;
  const c = $('lgBg'), x = c.getContext('2d'); if (c.width !== innerWidth || c.height !== innerHeight) { c.width = innerWidth; c.height = innerHeight; } const w = c.width, h = c.height; const t = performance.now() / 1000;
  const g = x.createLinearGradient(0, 0, 0, h); g.addColorStop(0, '#0f6a50'); g.addColorStop(.55, '#0a3c2e'); g.addColorStop(1, '#03140f'); x.fillStyle = g; x.fillRect(0, 0, w, h);
  x.strokeStyle = 'rgba(255,255,255,.06)'; x.lineWidth = 1.5; const sp = 90, off = (t * 12) % sp;
  for (let gx = -1; gx < w / sp + 1; gx++) for (let gy = -1; gy < h / sp + 1; gy++) x.stroke(new Path2D(octaPath(gx * sp + off, gy * sp + off, sp / 2)));
  const n = 34, bw = w / n; for (let i = 0; i < n; i++) { const hh = (Math.sin(t * 2.1 + i * .5) * .5 + .5) * (Math.sin(t * 1.3 + i * .21) * .5 + .5) * h * .18 + 8; const gg = x.createLinearGradient(0, h - hh, 0, h); gg.addColorStop(0, 'rgba(244,207,85,.55)'); gg.addColorStop(1, 'rgba(244,207,85,0)'); x.fillStyle = gg; x.fillRect(i * bw + bw * .2, h - hh, bw * .6, hh); }
  const rg = x.createRadialGradient(w / 2, h * .28, 10, w / 2, h * .28, h * .5); rg.addColorStop(0, 'rgba(43,181,131,.35)'); rg.addColorStop(1, 'rgba(43,181,131,0)'); x.fillStyle = rg; x.fillRect(0, 0, w, h);
}
function showLogin() { $('login').classList.add('show'); cancelAnimationFrame(loginRaf); loginBg(); }
function setLoginMode(m) {
  loginMode = m; $('ltIn').classList.toggle('on', m === 'in'); $('ltUp').classList.toggle('on', m === 'up');
  $('lfName').hidden = $('lfChan').hidden = m === 'in'; $('lGo').textContent = m === 'in' ? 'دخول' : 'إنشاء الحساب والدخول';
}
function finishLogin(u) {
  if (user && u.uid && user.uid === u.uid) return;
  user = u; loadSpace(u); if (u.trial) runTrial(); else stopTrial(); LS.set('basim.user', u); applyUser();
  if (u.chan && !u.guest && cfg.logoMode === 'builder' && (cfg.logoP.text === LOGO0.text || cfg.logoP.text === 'باسم')) { cfg.logoP.text = u.chan; saveCfg(); loadLogo(); buildLogoUI(); }
  $('login').classList.add('leave'); $('app').classList.add('enter');
  setTimeout(() => { $('login').classList.remove('show', 'leave'); cancelAnimationFrame(loginRaf); $('app').classList.remove('enter'); fitCanvas(); }, 520);
  afterLogin(u);
}
$('ltIn').addEventListener('click', () => setLoginMode('in')); $('ltUp').addEventListener('click', () => setLoginMode('up'));
$('lEye').addEventListener('click', () => { const p = $('lPass'); const sh = p.type === 'password'; p.type = sh ? 'text' : 'password'; $('lEye').innerHTML = ic(sh ? 'eyeoff' : 'eye'); });
$('lform').addEventListener('submit', (e) => { e.preventDefault(); finishLogin({ name: $('lName').value.trim(), chan: $('lChan').value.trim(), email: $('lMail').value.trim(), guest: false }); });
$('lGuest').addEventListener('click', () => startTrial());
$('btnLogout').addEventListener('click', () => { user = null; LS.set('basim.user', null); const go = () => reloadNow(); if (AUTH && AUTH.enabled) Promise.resolve(AUTH.signOut()).then(go, go); else go(); });

function fxSync() { FXK.forEach((k) => { const el = $('fx' + k[0].toUpperCase() + k.slice(1)); if (!el) return; const v = (cfg.fx && cfg.fx[k]) || 0; el.value = v; el.nextElementSibling.textContent = v; }); }
FXK.forEach((k) => { const el = $('fx' + k[0].toUpperCase() + k.slice(1)); el.addEventListener('input', () => { cfg.fx = Object.assign({ blur: 0, glow: 0, shake: 0, pulse: 0, grain: 0 }, cfg.fx); cfg.fx[k] = +el.value; el.nextElementSibling.textContent = el.value; saveCfg(); dirty(); }); });
function rebuildAll() { fxSync();
  buildSwatches();
  buildChips('bgModeChips', BGMODES, (i, it) => cfg.bgMode === it[0], (i, it) => { cfg.bgMode = it[0]; saveCfg(); $('bgColorBox').hidden = it[0] === 'image'; $('bgImgBox').hidden = it[0] !== 'image'; });
  $('bgColorBox').hidden = cfg.bgMode === 'image'; $('bgImgBox').hidden = cfg.bgMode !== 'image';
  buildChips('patChips', PATS, (i, it) => cfg.pat === it[0], (i, it) => { cfg.pat = it[0]; saveCfg(); });
  colorRow('accChips', cfg, 'acc', 'accC', () => { dirty(); }, ['gold', 'silver', 'white']);
  colorRow('tcolChips', cfg, 'tcol', 'tcustom', () => { dirty(); }, ['silver', 'gold', 'white']);
  buildChips('fontChips', FONTS, (i) => cfg.font === i, (i) => { cfg.font = i; saveCfg(); loadFont(); }, true);
  buildChips('animChips', ANIMS, (i, it) => cfg.anim === it[0], (i, it) => { cfg.anim = it[0]; saveCfg(); });
  buildChips('fitChips', FITS, (i, it) => cfg.vfit === it[0], (i, it) => { cfg.vfit = it[0]; saveCfg(); });
  buildChips('waveChips', WAVES, (i, it) => cfg.wave === it[0], (i, it) => { cfg.wave = it[0]; saveCfg(); });
  buildChips('frameChips', FRAMES, (i, it) => cfg.frameStyle === it[0], (i, it) => { cfg.frameStyle = it[0]; saveCfg(); });
  buildChips('coverChips', COVERSH, (i, it) => cfg.cshape === it[0], (i, it) => { cfg.cshape = it[0]; saveCfg(); });
  buildChips('qChips', QUAL, (i, it) => cfg.q === it[0], (i, it) => { cfg.q = it[0]; saveCfg(); exportSummary(); });
  shows.forEach((f) => f()); checks.forEach((f) => f());
  $('lblCol').value = cfg.lblCol; $('valCol').value = cfg.valCol;
  buildChips('reactChips', [['glow', 'توهج الإطار'], ['bars', 'شريط موجات'], ['logo', 'نبض الشعار'], ['bg', 'نبض الخلفية']], (i, it) => cfg.vreact[it[0]], (i, it) => { cfg.vreact[it[0]] = !cfg.vreact[it[0]]; saveCfg(); });
  buildTitleUI(); buildTpls(); buildLib(); fillLists(); buildLogoUI(); refreshDesign(); applyUser();
}

const FIELDS = ['fProj', 'fTitle', 'fOcc', 'fPlace', 'fReciter', 'fPoet'];
FIELDS.forEach((id) => { $(id).addEventListener('input', () => touchProject()); });

/* ---------- التصدير ---------- */
async function decodeAudio(file) {
  try {
    const ab = await file.arrayBuffer();
    const AC = window.AudioContext || window.webkitAudioContext; const ac = new AC();
    const buf = await ac.decodeAudioData(ab); ac.close && ac.close();
    const off = new OfflineAudioContext(2, Math.max(1, Math.ceil(buf.duration * 48000)), 48000);
    const src = off.createBufferSource(); src.buffer = buf; src.connect(off.destination); src.start();
    return await off.startRendering();
  } catch (e) { return null; }
}


function fftInPlace(re, im) {
  const n = re.length;
  for (let i = 1, j = 0; i < n; i++) { let bit = n >> 1; for (; j & bit; bit >>= 1) j ^= bit; j ^= bit; if (i < j) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
  for (let len = 2; len <= n; len <<= 1) {
    const ang = -2 * Math.PI / len, wr = Math.cos(ang), wi = Math.sin(ang), h = len >> 1;
    for (let i = 0; i < n; i += len) { let cr = 1, ci = 0;
      for (let j = 0; j < h; j++) {
        const a = i + j, b = a + h; const vr = re[b] * cr - im[b] * ci, vi = re[b] * ci + im[b] * cr;
        re[b] = re[a] - vr; im[b] = im[a] - vi; re[a] += vr; im[a] += vi;
        const nc = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = nc;
      } }
  }
}
async function computeSpectrum(buf, onProg) {
  const fps = 30, nb = 22, N = 2048, sr = buf.sampleRate;
  const L = buf.getChannelData(0), R = buf.numberOfChannels > 1 ? buf.getChannelData(1) : L;
  const frames = Math.ceil(buf.duration * fps) + 1; const raw = new Float32Array(frames * nb);
  const win = new Float32Array(N); for (let i = 0; i < N; i++) win[i] = .5 - .5 * Math.cos(2 * Math.PI * i / (N - 1));
  const bin = sr / N, be = []; for (let i = 0; i <= nb; i++) be.push(Math.max(1, Math.round(80 * Math.pow(9000 / 80, i / nb) / bin)));
  for (let i = 1; i <= nb; i++) if (be[i] <= be[i - 1]) be[i] = be[i - 1] + 1;
  const re = new Float32Array(N), im = new Float32Array(N);
  for (let f = 0; f < frames; f++) {
    const c = Math.floor(f / fps * sr) - N / 2;
    for (let i = 0; i < N; i++) { const k = c + i; re[i] = (k >= 0 && k < L.length ? (L[k] + R[k]) * .5 : 0) * win[i]; im[i] = 0; }
    fftInPlace(re, im);
    for (let b = 0; b < nb; b++) { let p = 0; for (let k = be[b]; k < be[b + 1]; k++) p += re[k] * re[k] + im[k] * im[k]; raw[f * nb + b] = 10 * Math.log10(p / (be[b + 1] - be[b]) + 1e-9); }
    if (f % 150 === 0) { if (onProg) onProg(f / frames); await new Promise((r) => setTimeout(r, 0)); }
  }
  const out = new Float32Array(frames * nb);
  for (let b = 0; b < nb; b++) {
    const col = new Float32Array(frames); for (let f = 0; f < frames; f++) col[f] = raw[f * nb + b];
    const sorted = Float32Array.from(col).sort(); const hi = sorted[Math.floor(frames * .96)], lo = hi - 36; let prev = 0;
    for (let f = 0; f < frames; f++) { let v = Math.min(1, Math.max(0, (col[f] - lo) / (hi - lo))); v = Math.pow(v, 1.35); v = Math.max(v, prev * .82); prev = v; out[f * nb + b] = .04 + v * .96; }
  }
  const vol = new Float32Array(frames), bass = new Float32Array(frames), mid = new Float32Array(frames), hi2 = new Float32Array(frames), beat = new Float32Array(frames), cum = new Float32Array(frames);
  let c0 = 0, pb = 0;
  for (let f = 0; f < frames; f++) {
    let a = 0, b = 0, m = 0, h = 0; for (let k = 0; k < nb; k++) { const v = out[f * nb + k]; a += v; if (k < 4) b += v; else if (k < 12) m += v; else h += v; }
    vol[f] = a / nb; bass[f] = b / 4; mid[f] = m / 8; hi2[f] = h / 10;
    let avg = 0, cnt = 0; for (let j = Math.max(0, f - 8); j < f; j++) { avg += bass[j]; cnt++; } avg = cnt ? avg / cnt : bass[f];
    const onset = Math.max(0, (bass[f] - avg) * 5); pb = Math.max(Math.min(1, onset), pb * .86); beat[f] = pb;
    c0 += vol[f] / fps; cum[f] = c0;
  }
  return { data: out, frames, fps, bars: nb, vol, bass, mid, hi: hi2, beat, cum };
}

async function probeMp4(file) {
  try {
    if (!window.MP4Box || !window.VideoDecoder || !window.DataStream) return null;
    const ab = await file.arrayBuffer(); ab.fileStart = 0;
    const mp4 = MP4Box.createFile();
    const info = await new Promise((res, rej) => { mp4.onReady = res; mp4.onError = rej; mp4.appendBuffer(ab); mp4.flush(); });
    const vt = info.videoTracks && info.videoTracks[0]; if (!vt) return null;
    const m = vt.matrix; let rot = 0;
    if (m) { const ma = m[0], mb = m[1], mc = m[3], md = m[4]; if (mb > 0 && mc < 0) rot = 90; else if (mb < 0 && mc > 0) rot = 270; else if (ma < 0 && md < 0) rot = 180; else if (ma < 0 || md < 0) return null; }
    const trak = mp4.getTrackById(vt.id); let desc = null;
    for (const e of trak.mdia.minf.stbl.stsd.entries) { const box = e.avcC || e.hvcC || e.vpcC || e.av1C; if (box) { const st = new DataStream(undefined, 0, DataStream.BIG_ENDIAN); box.write(st); desc = new Uint8Array(st.buffer, 8); break; } }
    const dc = { codec: vt.codec.startsWith('vp09') ? vt.codec : vt.codec, codedWidth: vt.video.width, codedHeight: vt.video.height };
    if (desc) dc.description = desc;
    const sup = await VideoDecoder.isConfigSupported(dc); if (!sup.supported) return null;
    const samples = [], asamples = [];
    const at = info.audioTracks && info.audioTracks[0]; let aacOk = false, asc = null;
    if (at && /^mp4a\.40\.(2|5|29)$/.test(at.codec)) {
      try { const atrak = mp4.getTrackById(at.id); const ent = atrak.mdia.minf.stbl.stsd.entries[0]; const d0 = ent.esds && ent.esds.esd && ent.esds.esd.descs && ent.esds.esd.descs[0]; const di = d0 && d0.descs && d0.descs[0]; if (di && di.data && di.data.length) { asc = new Uint8Array(di.data); aacOk = true; } } catch (e) {}
    }
    await new Promise((res, rej) => {
      const to = setTimeout(() => rej(new Error('samples timeout')), 20000);
      const need = vt.nb_samples + (aacOk ? at.nb_samples : 0);
      mp4.onSamples = (id, u, ss) => { for (const x of ss) (id === vt.id ? samples : asamples).push(x); if (samples.length + asamples.length >= need) { clearTimeout(to); res(); } };
      mp4.setExtractionOptions(vt.id, null, { nbSamples: 1000 }); if (aacOk) mp4.setExtractionOptions(at.id, null, { nbSamples: 1000 });
      mp4.start();
    });
    return { vt, dc, samples, rot, audio: aacOk ? { at, asc, samples: asamples } : null };
  } catch (e) { return null; }
}

async function runExport(setProg) {
  const QQ = TRIAL ? 'mid' : cfg.q; const q = QQ === 'uhd' ? { W: 1440, H: 2560, br: 45e6 } : QQ === 'max' ? { W: 1080, H: 1920, br: 30e6 } : QQ === 'hi' ? { W: 1080, H: 1920, br: 16e6 } : { W: 720, H: 1280, br: 8e6 };
  const form = formState();
  const cv = document.createElement('canvas'); cv.width = q.W; cv.height = q.H; const ctx = cv.getContext('2d'); ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
  const audioMode = S.mode === 'audio';
  const dopts = { title: form.title, occ: form.occ, reciter: form.reciter, poet: form.poet, titleFx: form.titleFx, bgImg: form.bgImg, still: false, mode: S.mode, img: S.img, spec: audioMode ? S.spec : S.vspec };

  setProg(0, 'قراءة الملف...');
  const mp = audioMode ? null : await probeMp4(S.file);
  let ev = null, dur, fps = 30;
  if (audioMode) { dur = S.abuf.duration; const ovf = DEV && DEV.ov && DEV.ov.fps !== 'auto'; fps = ovf ? fpsCap() : Math.min(fpsCap(), 60); }
  else if (mp) { dur = mp.vt.duration / mp.vt.timescale; fps = mp.samples.length / dur; }
  else {
    ev = document.createElement('video'); ev.muted = true; ev.playsInline = true; ev.preload = 'auto'; ev.src = S.url;
    await new Promise((res, rej) => { ev.onloadeddata = res; ev.onerror = () => rej(new Error('تعذّر قراءة الفيديو')); });
    dur = ev.duration;
  }
  const srcDur = dur;
  const SGL = segList(srcDur).map((x) => ({ a: Math.max(0, x.a), b: Math.min(srcDur, x.b), fi: x.fi || 0, fo: x.fo || 0 })).filter((x) => x.b - x.a > 0.02);
  if (!SGL.length) SGL.push({ a: 0, b: srcDur, fi: 0, fo: 0 });
  const RS = SGL.map((x) => [x.a, x.b]), OFFS = segOffs(RS), MONO = segMono(RS), HASFADE = SGL.some((x) => x.fi > 0 || x.fo > 0);
  dur = rangesLen(RS) || srcDur; dopts.srcDur = srcDur;
  let efps = fps > 90 ? 120 : fps > 45 ? 60 : 30; const cap = fpsCap();
  const step = (!audioMode && efps > cap) ? 1e6 / cap : 0; if (step) efps = cap >= 90 ? 120 : cap >= 45 ? 60 : 30;
  q.br = Math.round(q.br * (efps > 90 ? 2 : efps > 45 ? 1.5 : 1));

  let vc = null;
  const cands = efps > 90 ? [['avc1.640034', 'avc'], ['avc1.640033', 'avc'], ['vp09.00.51.08', 'vp9']] : efps > 30 ? [['avc1.640033', 'avc'], ['avc1.640032', 'avc'], ['vp09.00.50.08', 'vp9']] : [['avc1.640032', 'avc'], ['avc1.4d0032', 'avc'], ['avc1.42003e', 'avc'], ['vp09.00.40.08', 'vp9']];
  const pickVc = async () => {
    for (const c of cands) {
      const v = { codec: c[0], width: q.W, height: q.H, bitrate: q.br, framerate: efps, latencyMode: window.__lat || 'quality' };
      if (c[1] === 'avc') v.avc = { format: 'avc' };
      try { const r = await VideoEncoder.isConfigSupported(v); if (r.supported) return { cfg: v, mux: c[1] }; } catch (e) {}
    }
    return null;
  };
  vc = await pickVc();
  if (!vc && QQ === 'uhd') {
    q.W = 1080; q.H = 1920; q.br = Math.round(30e6 * (efps > 90 ? 2 : efps > 45 ? 1.5 : 1));
    cv.width = q.W; cv.height = q.H; ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
    toast('جهازك لا يدعم 1440p، تم التصدير بـ 1080p');
    vc = await pickVc();
  }
  if (!vc) throw new Error('المتصفح ما يدعم ترميز الفيديو. استخدم Chrome على أندرويد.');

  setProg(0, 'تجهيز الصوت...');
  const fxOn = window.AFX && afxOn();
  const pt = (!audioMode && mp && mp.audio && !fxOn && MONO && !HASFADE) ? mp.audio : null;
  let abuf = pt ? null : (audioMode ? S.abuf : (window.AudioEncoder ? await decodeAudio(S.file) : null));
  if (abuf && fxOn) { try { abuf = await window.AFX.process(abuf, afxParams(), (p) => setProg(0, 'معالجة الصوت ' + Math.round(p * 100) + '%')); } catch (e) { toast('تعذّرت معالجة الصوت، سيُستخدم الأصلي'); } }
  let ac = null;
  if (abuf) for (const c of [['mp4a.40.2', 'aac'], ['opus', 'opus']]) {
    const a = { codec: c[0], sampleRate: 48000, numberOfChannels: 2, bitrate: 256000 };
    try { const r = await AudioEncoder.isConfigSupported(a); if (r.supported) { ac = { cfg: a, mux: c[1] }; break; } } catch (e) {}
  }

  const muxer = new Mp4Muxer.Muxer({
    target: new Mp4Muxer.ArrayBufferTarget(),
    video: { codec: vc.mux, width: q.W, height: q.H },
    audio: pt ? { codec: 'aac', numberOfChannels: pt.at.audio.channel_count || 2, sampleRate: pt.at.audio.sample_rate || 48000 } : (ac ? { codec: ac.mux, numberOfChannels: 2, sampleRate: 48000 } : undefined),
    fastStart: 'in-memory', firstTimestampBehavior: 'cross-track-offset'
  });
  let vErr = null, aErr = null;
  const venc = new VideoEncoder({ output: (c, m) => muxer.addVideoChunk(c, m), error: (e) => { vErr = e; } });
  venc.configure(vc.cfg);
  let aenc = null, L, R, nA = 0, ai = 0;
  if (ac) {
    aenc = new AudioEncoder({ output: (c, m) => muxer.addAudioChunk(c, m), error: (e) => { aErr = e; } });
    aenc.configure(ac.cfg);
    L = abuf.getChannelData(0); R = abuf.numberOfChannels > 1 ? abuf.getChannelData(1) : L;
    const same0 = L === R;
    if (RS.length !== 1 || RS[0][0] > 0.001 || RS[0][1] < srcDur - 0.001) {
      const sr = abuf.sampleRate, tot = RS.reduce((s, r) => s + Math.floor((r[1] - r[0]) * sr), 0), nl = new Float32Array(tot), nr = new Float32Array(tot); let o2 = 0;
      RS.forEach((r) => { const a0 = Math.floor(r[0] * sr), len = Math.floor((r[1] - r[0]) * sr); nl.set(L.subarray(a0, a0 + len), o2); nr.set(R.subarray(a0, a0 + len), o2); o2 += len; });
      L = nl; R = same0 ? nl : nr;
    } else if (HASFADE) { L = Float32Array.from(L); R = same0 ? L : Float32Array.from(R); }
    if (HASFADE) {
      const sr = abuf.sampleRate; let o3 = 0;
      SGL.forEach((sg) => {
        const len = Math.floor((sg.b - sg.a) * sr), fiN = Math.floor(sg.fi * sr), foN = Math.floor(sg.fo * sr);
        for (let k = 0; k < Math.min(fiN, len); k++) { const g = k / fiN; L[o3 + k] *= g; if (R !== L) R[o3 + k] *= g; }
        for (let k = 0; k < Math.min(foN, len); k++) { const g = k / foN, ix = o3 + len - 1 - k; L[ix] *= g; if (R !== L) R[ix] *= g; }
        o3 += len;
      });
    }
    nA = Math.min(L.length, Math.ceil(dur * 48000));
  }
  const pump = (upto) => {
    while (aenc && ai < Math.min(nA, upto)) {
      const len = Math.min(4800, nA - ai); const d = new Float32Array(len * 2); d.set(L.subarray(ai, ai + len), 0); d.set(R.subarray(ai, ai + len), len);
      const ad = new AudioData({ format: 'f32-planar', sampleRate: 48000, numberOfFrames: len, numberOfChannels: 2, timestamp: Math.round(ai / 48000 * 1e6), data: d });
      aenc.encode(ad); ad.close(); ai += len;
    }
  };
  let pi = 0, firstA = true;
  const pumpRaw = (upto) => {
    while (pt && pi < pt.samples.length) {
      const x = pt.samples[pi], tsS = x.cts / x.timescale; if (tsS > upto) break;
      const to = srcToOut(tsS, RS);
      if (to >= 0) {
        muxer.addAudioChunkRaw(x.data, x.is_sync ? 'key' : 'delta', Math.round(to * 1e6), Math.round(x.duration * 1e6 / x.timescale),
          firstA ? { decoderConfig: { codec: pt.at.codec, numberOfChannels: pt.at.audio.channel_count || 2, sampleRate: pt.at.audio.sample_rate || 48000, description: pt.asc } } : undefined);
        firstA = false;
      }
      x.data = null; pi++;
    }
  };
  const pumpAt = (ts_, to_) => { if (pt) pumpRaw(ts_ + 0.6); else pump(Math.floor((to_ + 0.6) * 48000)); };
  const pumpAll = () => { if (pt) pumpRaw(1e9); else pump(nA); };
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const rc = document.createElement('canvas'), rx = rc.getContext('2d');
  const rotFrame = (f, r) => { const w = f.displayWidth, h = f.displayHeight, sw = r === 180 ? w : h, sh = r === 180 ? h : w; if (rc.width !== sw || rc.height !== sh) { rc.width = sw; rc.height = sh; } rx.setTransform(1, 0, 0, 1, 0, 0); rx.translate(sw / 2, sh / 2); rx.rotate(r * Math.PI / 180); rx.drawImage(f, -w / 2, -h / 2); return rc; };
  let n = 0, last = -1;
  const encodeCanvas = (tsUs, durUs) => {
    let ts = tsUs; if (ts <= last) ts = last + 1; last = ts;
    const fr = new VideoFrame(cv, durUs ? { timestamp: ts, duration: durUs } : { timestamp: ts });
    venc.encode(fr, { keyFrame: n % (efps * 3) === 0 }); fr.close(); n++;
  };

  if (audioMode) {
    const total = Math.ceil(dur * efps);
    for (let i = 0; i < total; i++) {
      while (venc.encodeQueueSize > 12 && !S.cancel && !vErr) await sleep(2);
      if (S.cancel) { try { venc.close(); } catch (e) {} throw new Error('cancel'); }
      if (vErr || aErr) throw (vErr || aErr);
      const t = i / efps; dopts.srcT = outToSrc(t, RS); draw(ctx, q.W, q.H, t, dur, null, dopts);
      encodeCanvas(Math.round(i * 1e6 / efps), Math.round(1e6 / efps)); pumpAt(0, t);
      if (i % 8 === 0) { setProg(i / total, 'جاري التصدير...'); await sleep(0); }
    }
  } else if (mp) {
    let derr = null, base = Infinity, nextTs = 0, CUR = [], lastOut = 0;
    for (const x of mp.samples) base = Math.min(base, x.cts * 1e6 / x.timescale);
    const dec = new VideoDecoder({
      output: (frame) => {
        try {
          const tsS = Math.max(0, frame.timestamp - base) / 1e6, cs = CUR.find((c) => tsS >= c.a - 1e-4 && tsS < c.b - 1e-4);
          if (!cs) return;
          const to = cs.off + (tsS - cs.a), ts = Math.round(to * 1e6);
          if (step) { if (ts + 500 < nextTs) return; nextTs = Math.max(nextTs, ts) + step; }
          dopts.srcT = tsS; dopts.vAlpha = HASFADE ? fadeA(cs, tsS) : null; lastOut = to;
          draw(ctx, q.W, q.H, to, dur, mp.rot ? rotFrame(frame, mp.rot) : frame, dopts);
          encodeCanvas(ts, frame.duration || 0);
          pumpAt(tsS, to);
        } finally { frame.close(); }
      },
      error: (e) => { derr = e; }
    });
    dec.configure(mp.dc);
    const total = mp.samples.length, bS = base / 1e6, runs = [];
    SGL.forEach((sg, k) => { sg.off = OFFS[k]; const l = runs[runs.length - 1]; if (l && Math.abs(sg.a - l[l.length - 1].b) < 0.04) l.push(sg); else runs.push([sg]); });
    const findI0 = (a) => { let i0 = 0; for (let k = 0; k < total; k++) { const sx = mp.samples[k]; if (sx.is_sync && sx.cts / sx.timescale - bS <= a + 1e-4) i0 = k; } return i0; };
    for (const run of runs) {
      CUR = run; const rb = run[run.length - 1].b, i0 = findI0(run[0].a);
      if (MONO) for (let k = 0; k < i0; k++) mp.samples[k].data = null;
      for (let i = i0; i < total; i++) {
        while ((dec.decodeQueueSize > 12 || venc.encodeQueueSize > 12) && !S.cancel && !derr && !vErr) await sleep(2);
        if (S.cancel) { try { dec.close(); venc.close(); } catch (e) {} throw new Error('cancel'); }
        if (derr || vErr || aErr) throw (derr || vErr || aErr);
        const x = mp.samples[i]; if (x.cts / x.timescale - bS > rb + 1.2) break;
        dec.decode(new EncodedVideoChunk({ type: x.is_sync ? 'key' : 'delta', timestamp: Math.round(x.cts * 1e6 / x.timescale), duration: Math.round(x.duration * 1e6 / x.timescale), data: x.data })); if (runs.length === 1) x.data = null;
        if (i % 15 === 0) setProg(Math.min(0.99, lastOut / Math.max(0.01, dur)), 'جاري التصدير...');
      }
      await dec.flush();
      if (derr) throw derr;
    }
    dec.close();
  } else {
    for (let si = 0; si < SGL.length; si++) {
      const cs = SGL[si], off = OFFS[si];
      if (Math.abs(ev.currentTime - cs.a) > 0.001) await new Promise((r) => { ev.onseeked = () => { ev.onseeked = null; r(); }; ev.currentTime = cs.a; });
      await new Promise((resolve, reject) => {
        let paused = false, fin = false;
        venc.ondequeue = () => { if (paused && venc.encodeQueueSize < 2) { paused = false; ev.play().catch(() => {}); } };
        const cb = (now, md) => {
          if (fin) return;
          if (S.cancel) { fin = true; ev.pause(); return reject(new Error('cancel')); }
          if (vErr || aErr) { fin = true; ev.pause(); return reject(vErr || aErr); }
          const mt = md.mediaTime;
          if (mt >= cs.b - 0.001) { fin = true; ev.pause(); return resolve(); }
          if (mt < cs.a - 0.05) { ev.requestVideoFrameCallback(cb); return; }
          const to = off + Math.max(0, mt - cs.a);
          dopts.srcT = mt; dopts.vAlpha = HASFADE ? fadeA(cs, mt) : null;
          draw(ctx, q.W, q.H, to, dur, ev, dopts);
          encodeCanvas(Math.round(to * 1e6), 0);
          pumpAt(mt, to);
          setProg(dur ? to / dur : 0, 'جاري التصدير...');
          if (venc.encodeQueueSize > 6) { paused = true; ev.pause(); }
          ev.requestVideoFrameCallback(cb);
        };
        ev.onended = () => { fin = true; resolve(); };
        ev.onerror = () => { fin = true; reject(new Error('خطأ بقراءة الفيديو')); };
        ev.requestVideoFrameCallback(cb); ev.play().catch(reject);
      });
    }
  }
  pumpAll();
  setProg(1, 'إنهاء الملف...');
  await venc.flush(); venc.close();
  if (aenc) { await aenc.flush(); aenc.close(); }
  if (vErr || aErr) throw (vErr || aErr);
  muxer.finalize();
  return { blob: new Blob([muxer.target.buffer], { type: 'video/mp4' }), codec: vc.mux, audio: !!ac || !!pt, passthru: !!pt, exact: !!mp || audioMode, frames: n };
}

let wake = null;
$('btnExport').addEventListener('click', async () => {
  if (S.busy) { S.cancel = true; return; }
  if (S.mode === 'video' && !S.file) { toast('اختر فيديو أولاً'); return; }
  if (S.mode === 'audio' && (!S.img || !S.abuf)) { toast('اختر الصورة والصوت أولاً'); return; }
  if (!$('fTitle').value.trim() && !S.titleFx) { toast('اكتب اسم القصيدة'); $('fTitle').focus(); return; }
  if (!window.VideoEncoder || !window.Mp4Muxer) { toast('المتصفح ما يدعم التصدير. استخدم Chrome على أندرويد'); return; }
  S.busy = true; S.cancel = false; pv.pause(); $('playBtn').textContent = '▶'; openExport();
  $('btnExport').textContent = 'إلغاء'; $('prog').hidden = false; $('result').hidden = true;
  try { if (navigator.wakeLock) wake = await navigator.wakeLock.request('screen'); } catch (e) {}
  const setProg = (p, m) => { $('eoPct').textContent = Math.round(p * 100) + '%'; $('eoBar').style.width = Math.round(p * 100) + '%'; $('eoMsg').textContent = m + ' · لا تطلع من التطبيق أثناء التصدير'; $('progBar').style.width = Math.round(p * 100) + '%'; $('expMsg').textContent = m + (p > 0 && p < 1 ? ' ' + Math.round(p * 100) + '%' : '') + ' · لا تطلع من التطبيق أثناء التصدير'; };
  try {
    const r = await runExport(setProg);
    S.resBlob = r.blob;
    const nm = ($('fTitle').value.trim() || 'قصيدة').replace(/[\\/:*?"<>|]+/g, ' ').trim();
    S.resName = 'منبر - ' + nm + '.mp4';
    const u = URL.createObjectURL(r.blob); const rv = $('resVideo'); if (rv.dataset.u) URL.revokeObjectURL(rv.dataset.u); rv.dataset.u = u; rv.src = u;
    $('result').hidden = false; $('progBar').style.width = '100%'; $('resMeta').textContent = S.resName + ' · ' + (r.blob.size / 1048576).toFixed(1) + ' ميغابايت'; $('svPrompt').hidden = !svAvail();
    if (NS && PID) { PROJ.status = 'exported'; PROJ.expName = S.resName; idb.put(NS + ':' + PID + ':exp', r.blob); saveProject(); }
    $('eoTitle').textContent = 'اكتمل التصدير'; $('eoPct').textContent = '100%'; $('eoBar').style.width = '100%'; $('eoMsg').textContent = ''; $('eoSize').textContent = (r.blob.size / 1048576).toFixed(1) + ' ميغابايت'; $('expRes').appendChild($('result')); $('result').hidden = false; $('eoCancel').hidden = true; $('eoClose').hidden = false;
    $('expMsg').textContent = `تم التصدير (${(r.blob.size / 1048576).toFixed(1)} ميغا)` + (r.codec === 'vp9' ? ' · ترميز VP9' : '') + (r.exact ? '' : ' · وضع التسجيل الحي') + (r.audio ? '' : ' · بدون صوت');
    remember('reciters', form_get('fReciter')); remember('poets', form_get('fPoet')); saveLib(); fillLists(); buildLib();
  } catch (e) {
    $('expMsg').textContent = e.message === 'cancel' ? 'تم الإلغاء' : (/memory|alloc|RangeError/i.test(String(e && (e.message || e.name))) ? 'الذاكرة ما كفت. جرّب جودة 720p أو سكّر التطبيقات الثانية' : 'فشل التصدير: ' + (e.message || e));
    $('prog').hidden = true;
    $('eoTitle').textContent = e.message === 'cancel' ? 'تم الإلغاء' : 'تعذّر التصدير'; $('eoMsg').textContent = $('expMsg').textContent; $('eoCancel').hidden = true; $('eoClose').hidden = false;
  } finally {
    S.busy = false; $('btnExport').textContent = 'تصدير الفيديو'; if (wake) { try { wake.release(); } catch (e) {} wake = null; }
  }
});
function form_get(id) { return $(id).value; }
$('btnSave').addEventListener('click', () => { if (!S.resBlob) return; const a = document.createElement('a'); a.href = URL.createObjectURL(S.resBlob); a.download = S.resName; document.body.appendChild(a); a.click(); a.remove(); });
$('btnShare').addEventListener('click', async () => {
  if (!S.resBlob) return;
  const f = new File([S.resBlob], S.resName, { type: 'video/mp4' });
  if (navigator.canShare && navigator.canShare({ files: [f] })) { try { await navigator.share({ files: [f], title: S.resName }); } catch (e) {} }
  else { toast('المشاركة غير مدعومة هنا، استخدم حفظ على الجهاز'); }
});

/* ---------- تشغيل ---------- */
buildDock(); rebuildAll(); loadLogo(); setMode('video'); fitCanvas(); paintPanels(0);
document.querySelectorAll('[data-ic]').forEach((e) => { e.innerHTML = ic(e.dataset.ic); });
hist.a = [snap()]; hist.i = 0; updUndo();
if (AUTH && AUTH.enabled && AUTH.fetchGrant) AUTH.fetchGrant(DEVID).then((g) => { if (!g) return; const o = grant(); if ((g.extMin || 0) !== (o.extMin || 0) || (g.unlockUntil || 0) !== (o.unlockUntil || 0)) { LS.set('minbar.grant', { extMin: g.extMin || 0, unlockUntil: g.unlockUntil || 0 }); refreshTrialBtns(); toast('تمت الموافقة على طلبك'); } }).catch(() => {});
if (AUTH && AUTH.enabled && AUTH.fetchPublic) AUTH.fetchPublic().then((c) => { const ep = (c && c.trialEpoch) || 0; if (ep > LS.get('minbar.trialRemote', 0)) { LS.set('minbar.trialRemote', ep); LS.set('minbar.trial2', null); refreshTrialBtns(); } }).catch(() => {});
refreshTrialBtns(); if ($('gTrial')) $('gTrial').addEventListener('click', startTrial);
if (user && user.trial) { if (trialLeft() > 0) runTrial(); else { user = null; LS.set('basim.user', null); } }
if (!(AUTH && AUTH.enabled) && user) { loadSpace(user); afterLogin(user); }
if (AUTH && AUTH.enabled) { document.body.classList.add('fbmode');
  const fast = user && user.uid && !user.trial && !user.guest;
  if (fast) { const u0 = user; user = null; finishLogin(u0); $('login').classList.remove('show', 'leave'); $('app').classList.remove('enter'); } else showLogin();
  AUTH.start({ onEnter: finishLogin, toast, onOut: () => { if (fast && user && user.uid) { user = null; LS.set('basim.user', null); showLogin(); } } }); }
else if (!user) { setLoginMode('in'); showLogin(); }
loadFont();
document.fonts.ready.then(() => { loadLogo(); dirty(); });
requestAnimationFrame(tick);
if ('serviceWorker' in navigator) {
  const had = !!navigator.serviceWorker.controller;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!had || document.getElementById('updBar')) return;
    const b = document.createElement('button'); b.id = 'updBar'; b.className = 'btn primary updbar'; b.textContent = 'نسخة جديدة جاهزة — اضغط للتحديث'; b.onclick = () => reloadNow(); document.body.appendChild(b);
  });
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}


/* ---------- تحريك وتحويل الفيديو (أسلوب Alight Motion) ---------- */
let vtMode = 'move', vtSnapUntil = 0, vtSnap = { x: false, y: false };
const vt = () => { if (!cfg.vtf) cfg.vtf = Object.assign({}, VTF0); return cfg.vtf; };
const r1 = (v) => Math.round(v * 10) / 10;
const VMODES = {
  move: { hint: 'اسحب هنا لتحريك الطبقة', f: [['X', 'x', 1, 1], ['Y', 'y', 1, 1]] },
  rot: { hint: 'اسحب يميناً ويساراً للتدوير', f: [['الزاوية °', 'r', 1, 1]] },
  scale: { hint: 'اسحب يميناً ويساراً للتكبير', f: [['التكبير %', 'z', 100, 1], ['العرض %', 'sx', 100, 1], ['الطول %', 'sy', 100, 1]] },
  skew: { hint: 'اسحب لميلان الطبقة', f: [['ميلان أفقي °', 'kx', 1, 1], ['ميلان عمودي °', 'ky', 1, 1]] }
};
function vtfSync() {
  const T = vt(), M = VMODES[vtMode];
  document.querySelectorAll('#mvModes button').forEach((b) => b.classList.toggle('on', b.dataset.m === vtMode));
  const box = $('mvFlds'); const need = M.f.map((f) => f[1]).join(',');
  if (box.dataset.k !== vtMode) {
    box.dataset.k = vtMode; box.innerHTML = '';
    M.f.forEach(([lb, k, sc]) => {
      const l = document.createElement('label'), s = document.createElement('span'), i = document.createElement('input'); s.textContent = lb; i.type = 'number'; i.step = '0.1'; i.inputMode = 'decimal'; i.dataset.k = k; i.dataset.sc = sc;
      i.addEventListener('change', () => { let v = parseFloat(i.value); if (!isFinite(v)) return; v /= sc; if (k === 'z' || k === 'sx' || k === 'sy') v = clamp(v, 0.1, 6); vt()[k] = v; vtfChanged(); vtfSync(); });
      l.appendChild(s); l.appendChild(i); box.appendChild(l);
    });
  }
  box.querySelectorAll('input').forEach((i) => { if (document.activeElement !== i) i.value = r1(T[i.dataset.k] * i.dataset.sc); });
  $('mvPadT').textContent = M.hint;
  $('mvFH').classList.toggle('primary', !!T.fh); $('mvFV').classList.toggle('primary', !!T.fv);
}
function vtfChanged() { saveCfg(); pushHist(); dirty(); }
document.querySelectorAll('#mvModes button').forEach((b) => b.addEventListener('click', () => { vtMode = b.dataset.m; vtfSync(); }));
$('mvFH').addEventListener('click', () => { vt().fh = vt().fh ? 0 : 1; vtfSync(); vtfChanged(); });
$('mvFV').addEventListener('click', () => { vt().fv = vt().fv ? 0 : 1; vtfSync(); vtfChanged(); });
$('mvR90').addEventListener('click', () => { const T = vt(); T.r = ((Math.round(T.r / 90) * 90 + 90 + 180) % 360) - 180; vtfSync(); vtfChanged(); });
$('mvReset').addEventListener('click', () => { cfg.vtf = Object.assign({}, VTF0); vtfSync(); vtfChanged(); });
function vtfHook() { const on = openP === 'move' && !collapsed; pc.style.touchAction = on ? 'none' : ''; if (on) vtfSync(); }
/* التقاط المنتصف: خطوط حمراء مثل Alight Motion */
function vtSnapPos(T) {
  vtSnap = { x: false, y: false };
  if (Math.abs(T.x) < 1.2) { T.x = 0; vtSnap.x = true; } if (Math.abs(T.y) < 1.2) { T.y = 0; vtSnap.y = true; }
  if (vtSnap.x || vtSnap.y) { vtSnapUntil = performance.now() + 600; setTimeout(dirty, 650); }
}
function vtSnapRot(T) { const n = Math.round(T.r / 45) * 45; if (Math.abs(T.r - n) < 2) { T.r = n === 180 ? 180 : n; vtSnapUntil = performance.now() + 600; setTimeout(dirty, 650); } }
/* لوحة السحب السفلية */
const vtPad = $('mvPad'); let vtPadG = null;
vtPad.addEventListener('pointerdown', (e) => { const T0 = vt(); vtPadG = { x: e.clientX, y: e.clientY, rx: T0.x, ry: T0.y, rr: T0.r }; try { vtPad.setPointerCapture(e.pointerId); } catch (x) {} vtPad.classList.add('act'); e.preventDefault(); });
vtPad.addEventListener('pointermove', (e) => {
  if (!vtPadG) return; const dx = e.clientX - vtPadG.x, dy = e.clientY - vtPadG.y; vtPadG.x = e.clientX; vtPadG.y = e.clientY; const T = vt();
  if (vtMode === 'move') { vtPadG.rx = clamp(vtPadG.rx + dx * 2 / (LASTV.dw || 1000) * 100, -150, 150); vtPadG.ry = clamp(vtPadG.ry + dy * 2 / (LASTV.dh || 1000) * 100, -150, 150); T.x = vtPadG.rx; T.y = vtPadG.ry; vtSnapPos(T); }
  else if (vtMode === 'rot') { vtPadG.rr += dx * 0.35; T.r = ((vtPadG.rr + 540) % 360) - 180; vtSnapRot(T); }
  else if (vtMode === 'scale') { const f = Math.exp(dx * 0.004); T.z = clamp(T.z * f, 0.1, 6); }
  else if (vtMode === 'skew') { T.kx = clamp(T.kx + dx * 0.15, -60, 60); T.ky = clamp(T.ky - dy * 0.15, -60, 60); }
  vtfSync(); saveCfg(); dirty();
});
const vtPadEnd = () => { if (vtPadG) { vtPadG = null; vtPad.classList.remove('act'); pushHist(); } };
vtPad.addEventListener('pointerup', vtPadEnd); vtPad.addEventListener('pointercancel', vtPadEnd);
/* السحب والقرص مباشرة على المعاينة (بدون تشغيل/إيقاف بالخطأ) */
const vtPtr = new Map(); let vtG = null;
const vtScale = () => { const r = pc.getBoundingClientRect(); return pc.width / (r.width || 1); };
function vtStart() {
  const T = vt(), p = [...vtPtr.values()];
  vtG = p.length >= 2 ? { two: true, d: Math.hypot(p[0].x - p[1].x, p[0].y - p[1].y) || 1, a: Math.atan2(p[1].y - p[0].y, p[1].x - p[0].x), z: T.z, r: T.r }
    : { two: false, x: p[0].x, y: p[0].y, tx: T.x, ty: T.y };
}
pc.addEventListener('click', (e) => { if (openP === 'move' && !collapsed) { e.stopImmediatePropagation(); e.preventDefault(); } }, true);
pc.addEventListener('pointerdown', (e) => { if (openP !== 'move' || collapsed) return; vtPtr.set(e.pointerId, { x: e.clientX, y: e.clientY }); try { pc.setPointerCapture(e.pointerId); } catch (x) {} vtStart(); e.preventDefault(); });
pc.addEventListener('pointermove', (e) => {
  if (!vtPtr.has(e.pointerId) || !vtG) return; vtPtr.set(e.pointerId, { x: e.clientX, y: e.clientY }); const T = vt(), p = [...vtPtr.values()], k = vtScale();
  if (vtG.two && p.length >= 2) {
    T.z = clamp(vtG.z * Math.hypot(p[0].x - p[1].x, p[0].y - p[1].y) / vtG.d, 0.1, 6);
    let r = vtG.r + (Math.atan2(p[1].y - p[0].y, p[1].x - p[0].x) - vtG.a) * 180 / Math.PI; r = ((r + 540) % 360) - 180; T.r = Math.round(r * 2) / 2; vtSnapRot(T);
  } else if (!vtG.two) {
    T.x = clamp(vtG.tx + (e.clientX - vtG.x) * k / (LASTV.dw || 1000) * 100, -150, 150); T.y = clamp(vtG.ty + (e.clientY - vtG.y) * k / (LASTV.dh || 1000) * 100, -150, 150); vtSnapPos(T);
  }
  vtfSync(); saveCfg(); dirty();
});
const vtEnd = (e) => { if (!vtPtr.delete(e.pointerId)) return; if (vtPtr.size) vtStart(); else { vtG = null; pushHist(); } };
pc.addEventListener('pointerup', vtEnd); pc.addEventListener('pointercancel', vtEnd);
/* إطار التحديد فوق الفيديو بالمعاينة فقط (لا يدخل التصدير) */
function vtfOverlay() {
  if (openP !== 'move' || collapsed || S.mode === 'audio' || !S.url || !LASTV.cx) return;
  const T = vt(), c = pctx; c.save(); c.setTransform(pc.width / 1080, 0, 0, pc.width / 1080, 0, 0); c.globalAlpha = 1; c.shadowColor = 'transparent'; c.filter = 'none';
  const dw = LASTV.dw, dh = LASTV.dh, z = Math.max(0.2, T.z);
  c.translate(LASTV.cx + T.x / 100 * dw, LASTV.cy + T.y / 100 * dh); c.rotate(T.r * Math.PI / 180);
  c.transform(1, Math.tan(T.ky * Math.PI / 180), Math.tan(T.kx * Math.PI / 180), 1, 0, 0); c.scale(T.z * T.sx, T.z * T.sy);
  const sx = Math.abs(T.z * T.sx) || 1, sy = Math.abs(T.z * T.sy) || 1;
  c.strokeStyle = '#fff'; c.lineWidth = 3 / Math.min(sx, sy); c.setLineDash([]); c.strokeRect(-dw / 2, -dh / 2, dw, dh);
  c.fillStyle = '#fff'; c.strokeStyle = '#2BB583'; c.lineWidth = 3 / Math.min(sx, sy);
  [[-1, -1], [1, -1], [-1, 1], [1, 1], [0, -1], [0, 1], [-1, 0], [1, 0]].forEach(([a, b]) => { const w = 16 / sx, hh = 16 / sy; c.beginPath(); c.rect(a * dw / 2 - w / 2, b * dh / 2 - hh / 2, w, hh); c.fill(); c.stroke(); });
  c.restore();
  if (performance.now() < vtSnapUntil) {
    c.save(); c.setTransform(pc.width / 1080, 0, 0, pc.width / 1080, 0, 0); c.globalAlpha = 1; c.shadowColor = 'transparent'; c.filter = 'none'; c.strokeStyle = '#ff2d2d'; c.lineWidth = 2;
    if (vtSnap.x) { c.beginPath(); c.moveTo(LASTV.cx, 0); c.lineTo(LASTV.cx, 1920); c.stroke(); }
    if (vtSnap.y) { c.beginPath(); c.moveTo(0, LASTV.cy); c.lineTo(1080, LASTV.cy); c.stroke(); }
    c.restore();
  }
}
['fileIn'].forEach((id) => $(id).addEventListener('change', () => { cfg.vtf = Object.assign({}, VTF0); vtfSync(); dirty(); }));
vtfSync();

/* ---------- فلاتر الصوت (تُطبَّق مباشرة) ---------- */
const AFXK = 'minbar_afx2', AFXNUM = ['gain', 'bass', 'mid', 'treb', 'rev', 'comp', 'den'];
let AFXS = { preset: 'orig', str: 1, m: null };
try { const sv = JSON.parse(localStorage.getItem(AFXK) || 'null'); if (sv && typeof sv === 'object') AFXS = Object.assign(AFXS, sv); } catch (e) {}
function afxParams() {
  if (AFXS.preset === 'custom' && AFXS.m) return Object.assign({}, window.AFX.DEF, AFXS.m);
  const pr = window.AFX.PRESETS.find((x) => x[0] === AFXS.preset), b = Object.assign({}, window.AFX.DEF, pr ? pr[2] : {}), s = AFXS.str;
  AFXNUM.forEach((k) => { b[k] = b[k] * s; }); b.norm = !!b.norm && s > 0.05; return b;
}
const afxOn = () => window.AFX.isOn(afxParams());
const AFXC = [['afxGain', 'gain', 1, 'db'], ['afxBass', 'bass', 1, 'db'], ['afxMid', 'mid', 1, 'db'], ['afxTreb', 'treb', 1, 'db'], ['afxRev', 'rev', 0.01, 'pc'], ['afxComp', 'comp', 0.01, 'pc'], ['afxDen', 'den', 0.01, 'pc']];
const afxInfo = (t) => { $('afxInfo').textContent = t || ''; };
function afxSave() { try { localStorage.setItem(AFXK, JSON.stringify(AFXS)); } catch (e) {} }
function afxSync() {
  const p = afxParams();
  AFXC.forEach(([id, k, sc, ty]) => { const v = Math.round((p[k] || 0) * 10) / 10; $(id).value = Math.round(v / sc * 100) / 100; $(id + 'V').textContent = ty === 'db' ? (v > 0 ? '+' : '') + v + ' dB' : Math.round(v * 100) + '%'; });
  $('afxNorm').checked = !!p.norm;
  $('afxStr').value = Math.round(AFXS.str * 100); $('afxStrV').textContent = Math.round(AFXS.str * 100) + '%';
  $('afxStr').disabled = AFXS.preset === 'orig' || AFXS.preset === 'custom'; $('afxStrRow').style.opacity = $('afxStr').disabled ? 0.55 : 1;
  buildChips('afxPre', window.AFX.PRESETS.map((q) => [q[0], q[1]]), (i, it) => AFXS.preset === it[0], (i, it) => { AFXS = { preset: it[0], str: 1, m: null }; afxSave(); afxSync(); afxApply(); });
}
/* محرك التشغيل: نُنتج نسخة معالجة بالخلفية ثم نشغّلها متزامنة مع الفيديو */
let afxCtx = null, afxNode = null, afxOut = null, afxSeq = 0, afxCache = null, afxBuf = null, afxFile = null, afxT0 = null, afxTm = 0;
async function afxSource() {
  if (S.mode === 'audio') return S.abuf;
  if (afxFile !== S.file || !afxBuf) { afxBuf = null; afxBuf = await decodeAudio(S.file); afxFile = S.file; afxCache = null; }
  return afxBuf;
}
function afxStopNode() { try { if (afxNode) { afxNode.onended = null; afxNode.stop(); } } catch (e) {} afxNode = null; }
function afxStart() {
  afxStopNode(); if (!afxOut || pv.paused || pv.seeking) return;
  try {
    if (!afxCtx) { const AC = window.AudioContext || window.webkitAudioContext; afxCtx = new AC(); }
    if (afxCtx.state === 'suspended') afxCtx.resume();
    const s = afxCtx.createBufferSource(); s.buffer = afxOut; s.playbackRate.value = pv.playbackRate || 1; s.connect(afxCtx.destination);
    s.start(0, Math.max(0, Math.min(pv.currentTime, afxOut.duration - 0.02))); afxNode = s; afxT0 = { c: afxCtx.currentTime, v: pv.currentTime, r: pv.playbackRate || 1 };
  } catch (e) {}
}
async function afxApply() {
  const seq = ++afxSeq;
  if (!afxOn()) { afxOut = null; afxStopNode(); pv.muted = false; afxInfo(''); return; }
  if (!S.url || !S.dur) { afxInfo('سيُطبَّق الفلتر عند اختيار الفيديو أو الصوت'); return; }
  afxInfo('جاري تطبيق الفلتر...');
  try {
    const src = await afxSource(); if (seq !== afxSeq) return;
    if (!src) { afxInfo(S.mode === 'audio' ? 'جاري تحليل الصوت...' : 'تعذّر قراءة الصوت'); if (S.mode === 'audio') setTimeout(() => { if (seq === afxSeq) afxApply(); }, 1500); return; }
    if (!afxCache || afxCache.src !== src) afxCache = { src, d: {} };
    const out = await window.AFX.process(src, afxParams(), (p) => { if (seq === afxSeq) afxInfo('جاري تطبيق الفلتر ' + Math.round(p * 100) + '%'); }, afxCache);
    if (seq !== afxSeq) return;
    afxOut = out; pv.muted = true; afxInfo('الفلتر مطبّق على المعاينة'); if (!pv.paused) afxStart();
  } catch (e) { if (seq === afxSeq) { afxOut = null; pv.muted = false; afxInfo('تعذّر تطبيق الفلتر'); } }
}
$('afxStr').addEventListener('input', () => { AFXS.str = +$('afxStr').value / 100; $('afxStrV').textContent = $('afxStr').value + '%'; afxSave(); clearTimeout(afxTm); afxTm = setTimeout(() => { afxSync(); afxApply(); }, 350); });
AFXC.forEach(([id, k, sc]) => $(id).addEventListener('input', () => {
  const m = Object.assign({}, afxParams()); m[k] = +$(id).value * sc; AFXS = { preset: 'custom', str: 1, m }; afxSave();
  $(id + 'V').textContent = AFXC.find((c) => c[0] === id)[3] === 'db' ? (m[k] > 0 ? '+' : '') + m[k] + ' dB' : Math.round(m[k] * 100) + '%';
  clearTimeout(afxTm); afxTm = setTimeout(() => { afxSync(); afxApply(); }, 350);
}));
$('afxNorm').addEventListener('change', () => { const m = Object.assign({}, afxParams()); m.norm = $('afxNorm').checked; AFXS = { preset: 'custom', str: 1, m }; afxSave(); afxSync(); afxApply(); });
$('afxAdvBtn').addEventListener('click', () => { const h = $('afxAdv').hidden = !$('afxAdv').hidden; $('afxAdvBtn').textContent = h ? 'ضبط متقدم ▾' : 'إخفاء الضبط المتقدم ▴'; });
pv.addEventListener('play', afxStart);
['pause', 'seeking', 'ended', 'waiting'].forEach((ev) => pv.addEventListener(ev, afxStopNode));
pv.addEventListener('seeked', afxStart); pv.addEventListener('ratechange', afxStart);
pv.addEventListener('timeupdate', () => { if (!afxNode || !afxT0 || !afxCtx) return; const exp = afxT0.v + (afxCtx.currentTime - afxT0.c) * afxT0.r; if (Math.abs(pv.currentTime - exp) > 0.25) afxStart(); });
pv.addEventListener('loadedmetadata', () => { afxSeq++; afxOut = null; afxStopNode(); pv.muted = false; afxBuf = null; afxFile = null; afxCache = null; if (afxOn()) afxApply(); });
afxSync();
if (afxOn()) afxApply();

window.__basim = { seg: () => SEG, afx: () => ({ on: afxOn(), out: !!afxOut, node: !!afxNode, muted: pv.muted, t: pv.currentTime, p: afxParams() }), S, cfg: () => cfg, draw, runExport, probeMp4, withCfg, applyCfg, BUILTIN_TPLS, LOGO_PRESETS, computeSpectrum, decodeAudio, FONTS, pauseSync, setTrim: (t) => { TR = t; }, getDEV: () => DEV, setFps: (v) => { DEV.ov.fps = v; } };
/* ---------- عرض المشغل: نفس مؤثرات قسم التصميم ---------- */
window.__plrViz = {
  list: [['vinyl', 'أسطوانة'], ['pulse', 'نبض'], ['starpulse', 'نجمة نابضة'], ['mirror', 'طيف مرآة'], ['particles', 'جسيمات'], ['ring', 'حلقة'], ['sphere', 'كرة'], ['neon', 'نيون'], ['ridges', 'تلال'], ['vu', 'عدادات']],
  draw(ctx, W, H, id, t, F, img, paused, cyf) {
    const ACC = '#E8C468', k = Math.min(W / 1080, H / 700), o = { img, live: F, still: !!paused, mode: 'audio', spec: null };
    if (!ctx.__noSh) { try { Object.defineProperty(ctx, 'shadowBlur', { get() { return 0; }, set() {}, configurable: true }); ctx.__noSh = 1; } catch (e) {} }
    window.__plrDrawing = true;
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, W, H);
    ctx.setTransform(k, 0, 0, k, (W - 1080 * k) / 2, H * (cyf || .5) - 350 * k);
    ctx.save(); ctx.beginPath(); ctx.rect(-400, -400, 1880, 1500); ctx.clip();
    try {
      if (id === 'vinyl') { const C = 520, D = C * .93, cx0 = (1080 - (C + D * .42)) / 2, by = 90; drawDisc(ctx, cx0 + C - D * .08, by + C / 2, D / 2, t * Math.PI * 2 / 5, img, ACC); coverShape(ctx, img, cx0, by, C, C, ACC); }
      else if (id === 'ring') drawRingViz(ctx, 540, 350, 190, F.vals, 0, img, ACC);
      else if (NEW_AL[id]) NEW_AL[id].draw(ctx, 0, t, 1, o, F, ACC);
    } catch (e) {}
    window.__plrDrawing = false; ctx.restore();
  }
};
})();
try { const t0 = Date.now(), chk = () => { const lg = $('login'), ld = $('gLoad'); const wait = lg.classList.contains('show') && ld && !ld.hidden; if (!wait || Date.now() - t0 > 5000) window.__splashOut && window.__splashOut(); else setTimeout(chk, 120); }; setTimeout(chk, 300); } catch (e) {}
