/* منبر — صفحة «الإحصائيات» للأدمن (Google Analytics عبر /api/stats) */
(function () {
  const isAdmin = () => !!(window.MinbarAuth && MinbarAuth.admin);
  let root = null, D = null, per = 'w', met = 'u';
  const f = (n) => Math.round(+n || 0).toLocaleString('en-US');
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const dur = (s) => { s = Math.round(s || 0); return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0'); };
  const EV = { session_start: 'بدء جلسة', first_open: 'أول فتح للتطبيق', first_visit: 'أول زيارة', screen_view: 'عرض شاشة', page_view: 'عرض صفحة', user_engagement: 'تفاعل المستخدم', app_open: 'فتح التطبيق', scroll: 'تمرير', click: 'نقرة' };
  const PL = { Android: 'أندرويد', web: 'الموقع', iOS: 'آيفون' };
  const KP = { t: 'y', w: 'pw', m: 'pm' }, KL = { t: 'اليوم', w: '7 أيام', m: '30 يوم' };
  const MT = { u: ['المستخدمون', '#1b7f5c'], n: ['مستخدمون جدد', '#c9a84c'], s: ['الجلسات', '#3b82c4'], v: ['المشاهدات', '#a35cc4'] };

  function delta(a, b) { if (!b) return a ? '<em class="up">جديد</em>' : ''; const p = Math.round(((a - b) / b) * 100); return '<em class="' + (p >= 0 ? 'up' : 'dn') + '">' + (p >= 0 ? '▲ ' : '▼ ') + Math.abs(p) + '%</em>'; }
  function days(n) {
    const m = {}; (D.series || []).forEach((x) => { m[x.d] = x; }); const out = [], t = new Date();
    for (let i = n - 1; i >= 0; i--) { const d = new Date(t.getTime() - i * 864e5), k = d.getFullYear() + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0'); out.push(Object.assign({ d: k, u: 0, n: 0, s: 0, v: 0, e: 0 }, m[k] || {})); }
    return out;
  }
  function chart() {
    const n = per === 'm' ? 30 : 7, s = days(n), W = 340, H = 150, pl = 26, pb = 22, pt = 12, col = MT[met][1];
    const mx = Math.max(3, ...s.map((x) => x[met])), X = (i) => pl + (i * (W - pl - 8)) / Math.max(1, n - 1), Y = (v) => pt + (H - pt - pb) * (1 - v / mx);
    let p = '', a = '';
    s.forEach((x, i) => { const px = X(i), py = Y(x[met]); if (!i) p = 'M' + px + ',' + py; else { const qx = X(i - 1), qy = Y(s[i - 1][met]), cx = (qx + px) / 2; p += ' C' + cx + ',' + qy + ' ' + cx + ',' + py + ' ' + px + ',' + py; } });
    a = p + ' L' + X(n - 1) + ',' + (H - pb) + ' L' + X(0) + ',' + (H - pb) + ' Z';
    const g = [0, 0.5, 1].map((r) => '<line x1="' + pl + '" x2="' + (W - 8) + '" y1="' + Y(mx * r) + '" y2="' + Y(mx * r) + '" stroke="#0001"/><text x="' + (pl - 4) + '" y="' + (Y(mx * r) + 3) + '" text-anchor="end" font-size="8" fill="#888">' + f(mx * r) + '</text>').join('');
    const lb = s.map((x, i) => (n <= 7 || i % 5 === 0 || i === n - 1) ? '<text x="' + X(i) + '" y="' + (H - 6) + '" text-anchor="middle" font-size="8" fill="#888">' + x.d.slice(6) + '/' + x.d.slice(4, 6) + '</text>' : '').join('');
    const dots = s.map((x, i) => '<circle cx="' + X(i) + '" cy="' + Y(x[met]) + '" r="' + (n <= 7 ? 4 : 2.2) + '" fill="#fff" stroke="' + col + '" stroke-width="2"><title>' + x.d.slice(6) + '/' + x.d.slice(4, 6) + ' — ' + f(x[met]) + '</title></circle>').join('');
    return '<svg viewBox="0 0 ' + W + ' ' + H + '" class="stsvg" direction="ltr">' + g + '<path d="' + a + '" fill="' + col + '" opacity=".14"/><path d="' + p + '" fill="none" stroke="' + col + '" stroke-width="2.6" stroke-linecap="round"/>' + dots + lb + '</svg>';
  }
  function list(arr, fmt, col) {
    arr = (arr || []).filter((x) => x[1] > 0); if (!arr.length) return '<div class="tthint">لا بيانات بعد</div>';
    const mx = Math.max(...arr.map((x) => x[1])), tot = arr.reduce((a, x) => a + x[1], 0);
    return arr.map((x) => '<div class="stl"><div class="stl1"><span>' + esc(fmt ? fmt(x[0]) : x[0]) + '</span><b>' + f(x[1]) + '<small>' + Math.round((x[1] / tot) * 100) + '%</small></b></div><div class="stl2"><i style="width:' + Math.max(3, (x[1] / mx) * 100) + '%;background:' + (col || '#1b7f5c') + '"></i></div></div>').join('');
  }
  function donut(parts) {
    const tot = parts.reduce((a, x) => a + x.v, 0) || 1, cols = ['#1b7f5c', '#c9a84c', '#3b82c4', '#a35cc4'], R = 38, C = 2 * Math.PI * R; let off = 0;
    const seg = parts.map((x, i) => { const l = (x.v / tot) * C, s = '<circle r="' + R + '" cx="50" cy="50" fill="none" stroke="' + cols[i % 4] + '" stroke-width="16" stroke-dasharray="' + l + ' ' + (C - l) + '" stroke-dashoffset="' + -off + '" transform="rotate(-90 50 50)"/>'; off += l; return s; }).join('');
    return '<div class="stdn"><svg viewBox="0 0 100 100">' + (parts.length ? seg : '<circle r="38" cx="50" cy="50" fill="none" stroke="#0001" stroke-width="16"/>') + '<text x="50" y="55" text-anchor="middle" font-size="16" font-weight="800" fill="#0f5a43">' + f(tot === 1 && !parts.length ? 0 : tot) + '</text></svg><div>' + parts.map((x, i) => '<p><i style="background:' + cols[i % 4] + '"></i>' + esc(x.n) + ' <b>' + f(x.v) + '</b> <small>' + Math.round((x.v / tot) * 100) + '%</small></p>').join('') + '</div></div>';
  }
  function hours() {
    const h = D.hour || [], mx = Math.max(1, ...h);
    return '<div class="sthr">' + h.map((v, i) => '<div title="' + i + ':00 — ' + f(v) + '"><i style="height:' + Math.max(2, (v / mx) * 70) + 'px;opacity:' + (v ? 1 : 0.25) + '"></i><small>' + (i % 3 === 0 ? i : '') + '</small></div>').join('') + '</div>';
  }
  function draw() {
    const bd = root.querySelector('.ttbody'), k = (D.kpi || {})[per] || {}, p = (D.kpi || {})[KP[per]] || {}, nw = D.now || {};
    const pl = (nw.platforms || []).map((x) => '<span>' + esc(PL[x[0]] || x[0]) + ' ' + f(x[1]) + '</span>').join('');
    const cards = [['المستخدمون', 'u', f(k.u)], ['مستخدمون جدد', 'n', f(k.n)], ['الجلسات (مرات الفتح)', 's', f(k.s)], ['مشاهدات الشاشات', 'v', f(k.v)]].map((c) => '<div class="stk"><small>' + c[0] + '</small><b>' + c[2] + '</b>' + delta(k[c[1]] || 0, p[c[1]] || 0) + '</div>').join('')
      + '<div class="stk"><small>متوسط وقت المستخدم</small><b>' + dur(k.u ? k.e / k.u : 0) + '</b><em class="nt">دقيقة:ثانية</em></div><div class="stk"><small>جلسات لكل مستخدم</small><b>' + (k.u ? (k.s / k.u).toFixed(1) : '0') + '</b><em class="nt">كلما زاد = ولاء أكثر</em></div>';
    const nvT = (D.nvr.n + D.nvr.r) || 1, pf = (D.platform || []).map((x) => ({ n: PL[x[0]] || x[0], v: x[1] }));
    bd.innerHTML = '<div class="stnow"><div><span class="stlive"></span><b>' + f(nw.total) + '</b><small>نشط الآن (آخر 30 دقيقة)</small></div><div class="stpl">' + (pl || '<span>لا أحد الآن</span>') + '</div>' + ((nw.cities || []).length ? '<div class="stct">' + nw.cities.filter((x) => x[1]).map((x) => esc(x[0]) + ' · ' + f(x[1])).join('  |  ') + '</div>' : '') + '</div>'
      + '<div class="sttabs">' + ['t', 'w', 'm'].map((x) => '<button type="button" data-p="' + x + '" class="' + (x === per ? 'on' : '') + '">' + KL[x] + '</button>').join('') + '</div>'
      + '<div class="stkg">' + cards + '</div><div class="stnote">المقارنة بالفترة السابقة المماثلة</div>'
      + '<div class="stbox"><div class="sttabs sm">' + Object.keys(MT).map((x) => '<button type="button" data-m="' + x + '" class="' + (x === met ? 'on' : '') + '">' + MT[x][0] + '</button>').join('') + '</div>' + chart() + '</div>'
      + '<div class="stsec">المنصّات</div><div class="stbox">' + donut(pf) + '</div>'
      + '<div class="stsec">جدد مقابل عائدين (30 يوم)</div><div class="stbox"><div class="stnv"><i style="width:' + Math.max(3, (D.nvr.n / nvT) * 100) + '%"></i></div><div class="stnvl"><span>جدد ' + f(D.nvr.n) + ' (' + Math.round((D.nvr.n / nvT) * 100) + '%)</span><span>عائدون ' + f(D.nvr.r) + ' (' + Math.round((D.nvr.r / nvT) * 100) + '%)</span></div></div>'
      + '<div class="stsec">أوقات النشاط خلال اليوم (بتوقيت بغداد)</div><div class="stbox">' + hours() + '</div>'
      + '<div class="stsec">أكثر القصائد استماعاً</div><div class="stbox">' + (D.top && D.top.length ? D.top.map((x, i) => '<div class="stt"><span class="stn">' + (i + 1) + '</span><div><b>' + esc(x.title) + '</b><small>' + esc(x.reciter) + '</small></div><em>' + f(x.plays) + '</em></div>').join('') : '<div class="tthint">لا بيانات</div>') + '</div>'
      + '<div class="stsec">الدول</div><div class="stbox">' + list(D.country) + '</div><div class="stsec">المدن</div><div class="stbox">' + list(D.city, null, '#c9a84c') + '</div>'
      + '<div class="stsec">الشاشات الأكثر زيارة</div><div class="stbox">' + list(D.screens, null, '#3b82c4') + '</div>'
      + '<div class="stsec">الأجهزة</div><div class="stbox">' + list(D.device, (x) => ({ mobile: 'جوال', desktop: 'كمبيوتر', tablet: 'تابلت' }[x] || x)) + '</div>'
      + '<div class="stsec">موديلات الجوال</div><div class="stbox">' + list(D.model, null, '#a35cc4') + '</div>'
      + '<div class="stsec">نظام التشغيل</div><div class="stbox">' + list(D.os, null, '#3b82c4') + '</div>'
      + '<div class="stsec">إصدارات التطبيق</div><div class="stbox">' + list(D.appv, null, '#c9a84c') + '</div>'
      + '<div class="stsec">اللغات</div><div class="stbox">' + list(D.lang) + '</div>'
      + '<div class="stsec">أكثر الأحداث</div><div class="stbox">' + list(D.events, (x) => EV[x] || x, '#a35cc4') + '</div>'
      + '<div class="tthint">آخر تحديث ' + new Date(D.at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }) + ' · الأرقام تتأخر قليلاً وتُحفظ دقيقتين</div>';
    bd.querySelectorAll('[data-p]').forEach((b) => { b.onclick = () => { per = b.dataset.p; draw(); }; });
    bd.querySelectorAll('[data-m]').forEach((b) => { b.onclick = () => { met = b.dataset.m; draw(); }; });
  }
  async function load(fresh) {
    const bd = root.querySelector('.ttbody'); if (!D) bd.innerHTML = '<div class="tthint">جارٍ التحميل…</div>';
    try {
      const u = firebase.auth().currentUser; if (!u) throw new Error('سجّل الدخول');
      const r = await fetch('api/stats' + (fresh ? '?fresh=1' : ''), { headers: { authorization: 'Bearer ' + await u.getIdToken() } }), d = await r.json();
      if (!r.ok) throw new Error(d.error || 'تعذّر التحميل'); D = d; if (root) draw();
    } catch (e) { if (root) bd.innerHTML = '<div class="tthint">' + esc(e.message || e) + '</div>'; }
  }
  function open() {
    if (root) return; D = null;
    root = document.createElement('div'); root.className = 'ttpg stpg';
    root.innerHTML = '<div class="tth"><button class="ttb" type="button" aria-label="رجوع">‹</button><b>الإحصائيات</b><button class="ttb" type="button" id="stRf" aria-label="تحديث">⟳</button></div><div class="ttbody"></div>';
    document.body.appendChild(root); root.querySelector('.ttb').onclick = () => { root.remove(); root = null; }; root.querySelector('#stRf').onclick = () => load(true); load(false);
  }
  /* صفّ «الإحصائيات» للأدمن بقائمة الحساب بجانب صفّ التيك توك بدون لمس مشغّل الصفحة */
  new MutationObserver(() => {
    if (!isAdmin()) return;
    document.querySelectorAll('*').forEach((el) => {
      if (el.children.length > 4 || el.dataset.stDone || el.id === 'stRow') return;
      if (!/مقاطعنا على تيك توك/.test(el.textContent) || el.textContent.length > 60) return;
      const row = el.closest('button,a,[role=button],li,div'); if (!row || !row.parentNode || row.parentNode.querySelector('#stRow')) return;
      el.dataset.stDone = 1;
      const c = row.cloneNode(true); c.id = 'stRow'; c.onclick = (e) => { e.stopPropagation(); open(); };
      const w = document.createTreeWalker(c, NodeFilter.SHOW_TEXT); let t; while ((t = w.nextNode())) { if (/مقاطعنا على تيك توك/.test(t.nodeValue)) t.nodeValue = 'الإحصائيات'; else if (/مقاطع مختارة/.test(t.nodeValue)) t.nodeValue = 'المستخدمون النشطون والمشاهدات'; }
      row.parentNode.insertBefore(c, row.nextSibling);
    });
  }).observe(document.body, { childList: true, subtree: true });
  window.MinbarStats = { open };
})();
