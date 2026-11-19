/* منبر — صفحة «التخزين» للمالك: بيانات حقيقية من R2 و KV عبر /api/store، مع ربط الملفات بالقصائد وحذف آمن */
(function () {
  const isAdmin = () => !!(window.MinbarAuth && MinbarAuth.admin);
  const LIMIT = 10e9; /* الحد المجاني لـ R2: 10 GB لكل حساب Cloudflare */
  const TYPES = { a: ['صوت', '#1b7f5c', '♪'], c: ['أغلفة', '#c9a84c', '▣'], u: ['ملفات المستخدمين', '#3b82c4', '☺'], n: ['تحليل الصوت', '#a35cc4', '≋'] };
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const f0 = (n) => Math.round(+n || 0).toLocaleString('en-US');
  const sz = (n) => { n = +n || 0; if (n >= 1e9) return (n / 1e9).toFixed(2) + ' GB'; if (n >= 1e6) return (n / 1e6).toFixed(1) + ' MB'; if (n >= 1e3) return Math.round(n / 1e3) + ' KB'; return n + ' B'; };
  const dt = (t) => t ? new Date(t).toLocaleDateString('en-GB') : '—';
  const KRX = /media\/u\/((?:a|c|u|n)\/[^"\s?\\]+)/g;

  let root = null, S = null, sheet = null;
  const fresh = () => ({ r2: [], kv: [], loading: false, msg: '', err: '', f: 'all', tool: '', sort: 'big', q: '', shown: 60, sel: new Set(), scan: null, ref: new Map(), kvNone: false });

  /* ---------- الربط بالقصائد: من كاش المكتبة (بدون قراءات) + فحص كامل عند الطلب ---------- */
  function addRefs(map, obj, label) {
    let js; try { js = JSON.stringify(obj); } catch (e) { return; }
    let m; KRX.lastIndex = 0; while ((m = KRX.exec(js))) { if (!map.has(m[1])) map.set(m[1], label); }
  }
  function cacheRefs() {
    const map = new Map();
    try { (JSON.parse(localStorage.getItem('minbar.tracks.fs') || '[]') || []).forEach((t) => addRefs(map, { a: t.audio, c: t.ownCover || t.cover, i: t.img, x: t.image }, { t: t.title || '', r: t.reciter || '' })); } catch (e) {}
    try { const al = JSON.parse(localStorage.getItem('minbar.tracks.fs.alb') || '{}'); Object.keys(al).forEach((k) => addRefs(map, al[k], { t: al[k].name || '', r: 'إصدار' })); } catch (e) {}
    return map;
  }
  const refOf = (k) => (S.scan && S.scan.map.get(k)) || S.ref.get(k) || null;

  /* ---------- الاتصال بالسيرفر ---------- */
  async function tok() { const u = firebase.auth().currentUser; if (!u) throw new Error('سجّل الدخول'); return u.getIdToken(); }
  async function api(path, opt) {
    const r = await fetch(path, Object.assign({}, opt, { headers: Object.assign({ authorization: 'Bearer ' + await tok() }, (opt && opt.headers) || {}) }));
    let d = {}; try { d = await r.json(); } catch (e) {} if (!r.ok) throw new Error(d.error || 'تعذّر الاتصال (' + r.status + ')'); return d;
  }
  async function loadAll() {
    S.loading = true; S.err = ''; S.r2 = []; S.kv = []; S.sel.clear(); draw();
    try {
      for (const st of ['r2', 'kv']) {
        let c = '', a = '', seen = new Map();
        for (let i = 0; i < 80; i++) {
          S.msg = (st === 'r2' ? 'جارٍ قراءة ملفات R2… ' : 'جارٍ قراءة ملفات KV… ') + f0(seen.size); head();
          const d = await api('api/store?s=' + st + (st === 'r2' ? (a ? '&a=' + encodeURIComponent(a) : '') : (c ? '&c=' + encodeURIComponent(c) : '')));
          if (d.none) { if (st === 'kv') S.kvNone = true; break; }
          let add = 0; d.items.forEach((x) => { if (!seen.has(x[0])) { seen.set(x[0], { k: x[0], n: x[1], t: x[2], e: x[3], st, p: x[0].charAt(0) }); add++; } });
          if (d.done || !add) break;
          if (st === 'r2') { if (!d.last || d.last === a) break; a = d.last; } else { if (!d.cursor || d.cursor === c) break; c = d.cursor; }
        }
        S[st] = [...seen.values()];
      }
      S.ref = cacheRefs();
    } catch (e) { S.err = e.message || String(e); }
    S.loading = false; S.msg = ''; draw();
  }
  async function scanLinks() {
    const db = firebase.firestore(); S.loading = true; S.msg = 'جارٍ فحص روابط القصائد…'; draw();
    try {
      const map = new Map(); let reads = 0;
      const rd = async (col, lab, must) => { try { const s = await db.collection(col).get(); s.forEach((d) => { reads++; const x = d.data() || {}; addRefs(map, x, lab(x, d)); }); } catch (e) { if (must) throw e; } };
      await rd('tracks', (x) => ({ t: x.title || (x.g && x.g.title) || '', r: x.reciter || '' }), true);
      await rd('albums', (x) => ({ t: x.name || '', r: 'إصدار' }), true);
      await rd('ytDrafts', (x) => ({ t: (x.g && x.g.title) || x.ti || '', r: 'مسودة استيراد' }), false);
      S.scan = { map, at: Date.now(), reads };
    } catch (e) { S.err = 'تعذّر فحص الروابط: ' + (e.message || e); }
    S.loading = false; S.msg = ''; draw();
  }

  /* ---------- التحليل ---------- */
  function calc() {
    const r2 = S.r2, kvSet = new Set(S.kv.map((x) => x.k)), r2Set = new Set(r2.map((x) => x.k));
    const tot = r2.reduce((a, x) => a + x.n, 0), by = { a: [0, 0], c: [0, 0], u: [0, 0], n: [0, 0] };
    r2.forEach((x) => { const b = by[x.p] || (by[x.p] = [0, 0]); b[0] += x.n; b[1]++; });
    /* مكرر: نفس المحتوى (etag + الحجم) بمفاتيح مختلفة. المحتفَظ به = المربوط أولاً ثم الأقدم */
    const g = new Map(); r2.forEach((x) => { if (x.e && x.n > 0) { const id = x.e + ':' + x.n; (g.get(id) || g.set(id, []).get(id)).push(x); } });
    const dup = new Set(), dupSafe = new Set(); let dupSize = 0;
    g.forEach((L) => { if (L.length < 2) return; L.sort((a, b) => (refOf(b.k) ? 1 : 0) - (refOf(a.k) ? 1 : 0) || (a.t || 0) - (b.t || 0)); L.slice(1).forEach((x) => { dup.add(x.k); if (!refOf(x.k) && S.scan) { dupSafe.add(x.k); dupSize += x.n; } }); L.__g = 1; });
    const grp = [...g.values()].filter((L) => L.length > 1);
    const orph = new Set(); let orphSize = 0;
    if (S.scan) r2.forEach((x) => { if ((x.p === 'a' || x.p === 'c') && !S.scan.map.has(x.k)) { orph.add(x.k); orphSize += x.n; } });
    const kvDup = S.kv.filter((x) => r2Set.has(x.k)), kvDupSize = kvDup.reduce((a, x) => a + x.n, 0);
    return { tot, by, grp, dup, dupSafe, dupSize, orph, orphSize, kvDup: new Set(kvDup.map((x) => x.k)), kvDupSize, kvTot: S.kv.reduce((a, x) => a + x.n, 0), kvSet };
  }

  /* ---------- الرسم ---------- */
  function ring(pct, col) {
    const R = 52, C = 2 * Math.PI * R, v = Math.min(1, pct);
    return '<svg viewBox="0 0 130 130" class="stoRing"><circle cx="65" cy="65" r="' + R + '" fill="none" stroke="#ffffff26" stroke-width="12"/><circle id="stoArc" cx="65" cy="65" r="' + R + '" fill="none" stroke="' + col + '" stroke-width="12" stroke-linecap="round" stroke-dasharray="' + C + '" stroke-dashoffset="' + (S.anim ? C * (1 - v) : C) + '" data-to="' + (C * (1 - v)) + '" transform="rotate(-90 65 65)"/><text x="65" y="63" text-anchor="middle" font-size="26" font-weight="800" fill="#fff">' + Math.round(pct * 100) + '%</text><text x="65" y="81" text-anchor="middle" font-size="9.5" fill="#ffffffb0">من الحد المجاني</text></svg>';
  }
  function growth(C) {
    const L = S.r2.filter((x) => x.t > 0).sort((a, b) => a.t - b.t); if (L.length < 2) return '';
    const days = []; let cum = 0, last = '';
    L.forEach((x) => { cum += x.n; const d = new Date(x.t).toISOString().slice(0, 10); if (d === last) days[days.length - 1].v = cum; else { days.push({ d, v: cum }); last = d; } });
    if (days.length < 2) return '';
    S.gp = days; const W = 340, H = 150, pl = 34, pb = 20, pt = 10, mx = Math.max(LIMIT * 1.05, days[days.length - 1].v * 1.05);
    const t0 = +new Date(days[0].d), t1 = +new Date(days[days.length - 1].d) || t0 + 1, X = (d) => pl + ((+new Date(d) - t0) / Math.max(1, t1 - t0)) * (W - pl - 8), Y = (v) => pt + (H - pt - pb) * (1 - v / mx);
    let p = ''; days.forEach((x, i) => { p += (i ? ' L' : 'M') + X(x.d).toFixed(1) + ',' + Y(x.v).toFixed(1); });
    const area = p + ' L' + X(days[days.length - 1].d) + ',' + (H - pb) + ' L' + X(days[0].d) + ',' + (H - pb) + ' Z';
    const yl = [0, 0.5, 1].map((r) => '<text x="' + (pl - 4) + '" y="' + (Y(mx * r / 1.05 * 1) + 3) + '" text-anchor="end" font-size="8" fill="#888">' + Math.round((mx / 1.05) * r / 1e9) + 'GB</text>').join('');
    return '<div class="stoGr"><svg viewBox="0 0 ' + W + ' ' + H + '" direction="ltr" id="stoG"><path d="' + area + '" fill="#1b7f5c" opacity=".14"/><path d="' + p + '" fill="none" stroke="#1b7f5c" stroke-width="2.6" stroke-linejoin="round"/><line x1="' + pl + '" x2="' + (W - 8) + '" y1="' + Y(LIMIT) + '" y2="' + Y(LIMIT) + '" stroke="#c0392b" stroke-dasharray="4 3"/><text x="' + (W - 10) + '" y="' + (Y(LIMIT) - 3) + '" text-anchor="end" font-size="8" fill="#c0392b">الحد المجاني</text>' + yl + '<line id="stoGl" y1="' + pt + '" y2="' + (H - pb) + '" stroke="#0f5a43" stroke-opacity=".5" display="none"/><circle id="stoGd" r="4.5" fill="#fff" stroke="#0f5a43" stroke-width="2" display="none"/></svg><div class="stoGt" id="stoGt">المس الرسم لتشوف التخزين بكل يوم</div></div>';
  }
  function bindGrowth() {
    const sv = root.querySelector('#stoG'); if (!sv || !S.gp) return; const days = S.gp, W = 340, H = 150, pl = 34, pb = 20, pt = 10, mx = Math.max(LIMIT * 1.05, days[days.length - 1].v * 1.05), t0 = +new Date(days[0].d), t1 = +new Date(days[days.length - 1].d) || t0 + 1;
    const X = (d) => pl + ((+new Date(d) - t0) / Math.max(1, t1 - t0)) * (W - pl - 8), Y = (v) => pt + (H - pt - pb) * (1 - v / mx);
    const mv = (ev) => { const r = sv.getBoundingClientRect(), x = ((ev.clientX - r.left) / r.width) * W; let b = days[0], bd = 1e9; days.forEach((d) => { const q = Math.abs(X(d.d) - x); if (q < bd) { bd = q; b = d; } }); const l = root.querySelector('#stoGl'), c = root.querySelector('#stoGd'); l.setAttribute('x1', X(b.d)); l.setAttribute('x2', X(b.d)); l.removeAttribute('display'); c.setAttribute('cx', X(b.d)); c.setAttribute('cy', Y(b.v)); c.removeAttribute('display'); root.querySelector('#stoGt').textContent = b.d.split('-').reverse().join('/') + ' — ' + sz(b.v); };
    sv.addEventListener('pointerdown', mv); sv.addEventListener('pointermove', (e) => { if (e.buttons || e.pointerType === 'mouse') mv(e); });
  }
  function head() { const m = root && root.querySelector('.stoMsg'); if (m) m.textContent = S.msg; }

  function view() {
    const C = calc(), pct = C.tot / LIMIT, over = C.tot > LIMIT, col = over ? '#ff8a7a' : pct > 0.8 ? '#ffd36b' : '#4cff9a';
    const left = LIMIT - C.tot;
    const parts = Object.keys(TYPES).map((p) => ({ p, n: (C.by[p] || [0])[0], c: (C.by[p] || [0, 0])[1] })).filter((x) => x.n > 0);
    const stack = parts.map((x) => '<i style="width:' + Math.max(1.5, (x.n / (C.tot || 1)) * 100) + '%;background:' + TYPES[x.p][1] + '"></i>').join('');
    const leg = parts.map((x) => '<button type="button" class="stoLg" data-f="' + x.p + '"><i style="background:' + TYPES[x.p][1] + '"></i><span>' + TYPES[x.p][0] + '</span><b>' + sz(x.n) + '</b><small>' + f0(x.c) + ' ملف</small></button>').join('');
    const scanTxt = S.scan ? 'آخر فحص ' + new Date(S.scan.at).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }) + ' · قرأ ' + f0(S.scan.reads) + ' وثيقة' : 'لم يُفحص بعد';
    const tools = '<div class="stoTools">'
      + '<button type="button" data-t="big"><b>الأكبر حجماً</b><small>' + (S.r2[0] ? 'ترتيب الملفات من الأكبر' : '—') + '</small></button>'
      + '<button type="button" data-t="dup" class="' + (C.grp.length ? 'hot' : '') + '"><b>مكررة</b><small>' + f0(C.dup.size) + ' نسخة' + (S.scan ? ' · يوفّر ' + sz(C.dupSize) : '') + '</small></button>'
      + '<button type="button" data-t="orph" class="' + (C.orph.size ? 'hot' : '') + '"><b>بدون قصيدة</b><small>' + (S.scan ? f0(C.orph.size) + ' ملف · ' + sz(C.orphSize) : 'افحص الربط أولاً') + '</small></button>'
      + '<button type="button" data-t="kvdup"><b>نسخ قديمة بـ KV</b><small>' + (S.kvNone ? 'غير مربوط' : f0(C.kvDup.size) + ' ملف · ' + sz(C.kvDupSize)) + '</small></button></div>'
      + '<button type="button" class="stoScan" id="stoScan">' + (S.scan ? 'إعادة فحص الربط' : 'فحص ربط الملفات بالقصائد') + '<small>' + scanTxt + '</small></button>';
    /* قائمة الملفات */
    let L = visible(C);
    const so = { big: (a, b) => b.n - a.n, new: (a, b) => (b.t || 0) - (a.t || 0), old: (a, b) => (a.t || 0) - (b.t || 0), name: (a, b) => a.k.localeCompare(b.k) }[S.sort];
    L = L.slice().sort(so);
    const rows = L.slice(0, S.shown).map((x) => {
      const r = refOf(x.k), ty = TYPES[x.p] || ['أخرى', '#888', '•'], id = x.st + '|' + x.k, on = S.sel.has(id);
      const th = x.p === 'c' ? '<img loading="lazy" src="media/u/' + esc(x.k) + '" alt="">' : '<span style="color:' + ty[1] + '">' + ty[2] + '</span>';
      const bd = (x.st === 'kv' ? '<em class="k">KV</em>' : '') + (C.dup.has(x.k) && x.st === 'r2' ? '<em class="d">مكرر</em>' : '') + (C.orph.has(x.k) ? '<em class="o">بدون قصيدة</em>' : '') + (r ? '<em class="l">مربوط</em>' : '');
      return '<div class="stoRow' + (on ? ' on' : '') + '" data-id="' + esc(id) + '"><button type="button" class="stoCk" data-ck="' + esc(id) + '" aria-label="تحديد">' + (on ? '✓' : '') + '</button><div class="stoTh">' + th + '</div><div class="stoTx"><b>' + esc(r && r.t ? r.t : x.k.split('/').pop()) + '</b><small>' + esc(r && r.t ? (r.r ? r.r + ' · ' : '') + x.k.split('/').pop() : x.k) + '</small><div>' + bd + '</div></div><div class="stoSz"><b>' + sz(x.n) + '</b><small>' + dt(x.t) + '</small></div></div>';
    }).join('');
    const selAll = L.length ? '<button type="button" id="stoSelAll">' + (L.every((x) => S.sel.has(x.st + '|' + x.k)) ? 'إلغاء تحديد الكل' : 'تحديد الكل (' + f0(L.length) + ')') + '</button>' : '';
    const chips = [['all', 'الكل'], ['a', 'صوت'], ['c', 'أغلفة'], ['u', 'مستخدمون'], ['n', 'تحليل'], ['kv', 'KV']].map((c) => '<button type="button" data-f="' + c[0] + '" class="' + (S.f === c[0] && !S.tool ? 'on' : '') + '">' + c[1] + '</button>').join('');
    const toolName = { dup: 'المكررة', orph: 'بدون قصيدة', kvdup: 'نسخ KV القديمة', big: '' }[S.tool] || '';
    return '<div class="stoHero"><div class="stoHr">' + ring(pct, col) + '<div class="stoHt"><small>مستهلك في R2</small><b>' + sz(C.tot) + '</b><span class="stoPill ' + (over ? 'bad' : pct > 0.8 ? 'warn' : 'ok') + '">' + (over ? 'فوق الحد بـ ' + sz(-left) : 'متبقي ' + sz(left)) + '</span><small>' + f0(S.r2.length) + ' ملف · الحد ' + sz(LIMIT) + '</small></div></div>'
      + '<div class="stoNote">الحد المجاني يُحسب على حساب Cloudflare كله (كل الـ buckets) وبمتوسط الشهر. هذا الرقم لـ bucket المنبر فقط.</div></div>'
      + (C.kvTot || S.kv.length ? '<div class="stoKv">ملفات قديمة بـ KV: <b>' + f0(S.kv.length) + '</b> ملف · <b>' + sz(C.kvTot) + '</b> (الحد المجاني 1 GB)</div>' : '')
      + '<div class="stsec">التوزيع</div><div class="stbox"><div class="stoStack">' + stack + '</div><div class="stoLgs">' + leg + '</div></div>'
      + (growth(C) ? '<div class="stsec">الملفات الحالية حسب تاريخ رفعها (تراكمي)</div><div class="stbox">' + growth(C) + '</div>' : '')
      + '<div class="stsec">أدوات التنظيف</div>' + tools
      + '<div class="stsec" id="stoList">الملفات' + (toolName ? ' — ' + toolName : '') + '</div>'
      + '<div class="stoBar"><input id="stoQ" type="search" placeholder="ابحث باسم القصيدة أو الملف" value="' + esc(S.q) + '"><select id="stoSort"><option value="big"' + (S.sort === 'big' ? ' selected' : '') + '>الأكبر</option><option value="new"' + (S.sort === 'new' ? ' selected' : '') + '>الأحدث</option><option value="old"' + (S.sort === 'old' ? ' selected' : '') + '>الأقدم</option><option value="name"' + (S.sort === 'name' ? ' selected' : '') + '>الاسم</option></select></div>'
      + '<div class="sttabs sm stoChips">' + chips + '</div><div class="stoLh"><span>' + f0(L.length) + ' ملف · ' + sz(L.reduce((a, x) => a + x.n, 0)) + '</span>' + selAll + (S.tool ? '<button type="button" id="stoNoTool">إلغاء الفلتر</button>' : '') + '</div>'
      + '<div class="stoRows">' + (rows || '<div class="tthint">لا ملفات</div>') + '</div>' + (L.length > S.shown ? '<button type="button" class="stoMore" id="stoMore">عرض المزيد (' + f0(L.length - S.shown) + ')</button>' : '');
  }

  function draw() {
    if (!root) return; const bd = root.querySelector('.ttbody'), top = bd.scrollTop;
    if (S.err) { bd.innerHTML = '<div class="tthint">' + esc(S.err) + '</div>'; return; }
    if (S.loading && !S.r2.length) { bd.innerHTML = '<div class="tthint stoMsg">' + esc(S.msg || 'جارٍ التحميل…') + '</div>'; return; }
    bd.innerHTML = view() + (S.loading ? '<div class="stoBusy"><span class="stoMsg">' + esc(S.msg) + '</span></div>' : '') + bulk();
    bd.scrollTop = top; bind(bd);
    const a = bd.querySelector('#stoArc'); if (a && !S.anim) { S.anim = true; requestAnimationFrame(() => requestAnimationFrame(() => a.setAttribute('stroke-dashoffset', a.dataset.to))); }
    bindGrowth();
  }
  function bulk() {
    if (!S.sel.size) return ''; const it = selItems(), s = it.reduce((a, x) => a + x.n, 0);
    return '<div class="stoSel"><span><b>' + f0(it.length) + '</b> محدد · يوفّر ' + sz(s) + '</span><button type="button" id="stoClr">إلغاء</button><button type="button" id="stoDel" class="del">حذف</button></div>';
  }
  const selItems = () => { const m = new Map(S.r2.concat(S.kv).map((x) => [x.st + '|' + x.k, x])); return [...S.sel].map((id) => m.get(id)).filter(Boolean); };

  function bind(bd) {
    bd.querySelectorAll('[data-f]').forEach((b) => { b.onclick = () => { S.f = b.dataset.f; S.tool = ''; S.shown = 60; draw(); }; });
    bd.querySelectorAll('[data-t]').forEach((b) => { b.onclick = () => { const t = b.dataset.t; if (t === 'orph' && !S.scan) { scanLinks(); return; } S.tool = t === 'big' ? '' : t; if (t === 'big') S.sort = 'big'; S.f = 'all'; S.shown = 60; draw(); const l = root.querySelector('#stoList'); if (l) l.scrollIntoView({ behavior: 'smooth', block: 'start' }); }; });
    const q = bd.querySelector('#stoQ'); if (q) q.oninput = () => { S.q = q.value; S.shown = 60; clearTimeout(S.qt); S.qt = setTimeout(() => { draw(); const n = root.querySelector('#stoQ'); if (n) { n.focus(); n.setSelectionRange(n.value.length, n.value.length); } }, 250); };
    const so = bd.querySelector('#stoSort'); if (so) so.onchange = () => { S.sort = so.value; draw(); };
    const sc = bd.querySelector('#stoScan'); if (sc) sc.onclick = scanLinks;
    const mo = bd.querySelector('#stoMore'); if (mo) mo.onclick = () => { S.shown += 80; draw(); };
    const nt = bd.querySelector('#stoNoTool'); if (nt) nt.onclick = () => { S.tool = ''; draw(); };
    bd.querySelectorAll('.stoRow').forEach((r) => { r.onclick = (e) => { const ck = e.target.closest('[data-ck]'); if (ck) { const id = ck.dataset.ck; S.sel.has(id) ? S.sel.delete(id) : S.sel.add(id); draw(); return; } openSheet(r.dataset.id); }; });
    const sa = bd.querySelector('#stoSelAll'); if (sa) sa.onclick = () => { const ids = [...bd.querySelectorAll('.stoRow')]; const C = calc(); const lst = visible(C); const every = lst.every((x) => S.sel.has(x.st + '|' + x.k)); lst.forEach((x) => { const id = x.st + '|' + x.k; every ? S.sel.delete(id) : S.sel.add(id); }); draw(); };
    const cl = bd.querySelector('#stoClr'); if (cl) cl.onclick = () => { S.sel.clear(); draw(); };
    const dl = bd.querySelector('#stoDel'); if (dl) dl.onclick = () => confirmDel(selItems());
  }
  function visible(C) {
    let L = (S.f === 'kv' ? S.kv : S.r2).filter((x) => S.f === 'all' || S.f === 'kv' || x.p === S.f);
    if (S.tool === 'dup') L = S.r2.filter((x) => C.dup.has(x.k)); else if (S.tool === 'orph') L = S.r2.filter((x) => C.orph.has(x.k)); else if (S.tool === 'kvdup') L = S.kv.filter((x) => C.kvDup.has(x.k));
    const q = S.q.trim().toLowerCase(); if (q) L = L.filter((x) => { const r = refOf(x.k); return x.k.toLowerCase().includes(q) || (r && ((r.t + ' ' + r.r).toLowerCase().includes(q))); });
    return L;
  }

  /* ---------- نافذة تفاصيل الملف ---------- */
  function openSheet(id) {
    const [st, ...kk] = id.split('|'), k = kk.join('|'), x = (S[st] || []).find((y) => y.k === k); if (!x) return; closeSheet();
    const r = refOf(k), C = calc(), url = location.origin + location.pathname.replace(/[^/]*$/, '') + 'media/u/' + k, isImg = x.p === 'c', isAud = x.p === 'a';
    const el = document.createElement('div'); el.className = 'stoSh'; el.innerHTML = '<div class="stoShBg"></div><div class="stoShC"><div class="stoGrip"></div><b>' + esc(r && r.t ? r.t : k.split('/').pop()) + '</b><small>' + esc(r ? (r.r || '') : 'غير مربوط بقصيدة معروفة') + '</small>'
      + (isImg ? '<img class="stoPv" src="media/u/' + esc(k) + '" alt="">' : '') + (isAud ? '<audio controls preload="none" src="media/u/' + esc(k) + '"></audio>' : '')
      + '<div class="stoKvs"><p><span>المسار</span><b dir="ltr">' + esc(k) + '</b></p><p><span>الحجم</span><b>' + sz(x.n) + ' (' + f0(x.n) + ' بايت)</b></p><p><span>المخزن</span><b>' + (st === 'r2' ? 'R2' : 'KV (قديم)') + '</b></p>' + (x.t ? '<p><span>تاريخ الرفع</span><b>' + new Date(x.t).toLocaleString('en-GB') + '</b></p>' : '') + (C.dup.has(k) ? '<p><span>الحالة</span><b>نسخة مكررة لملف آخر</b></p>' : '') + (C.kvDup.has(k) ? '<p><span>الحالة</span><b>موجود أيضاً في R2 (النسخة هنا زائدة)</b></p>' : '') + '</div>'
      + '<div class="stoAct"><button type="button" id="shCp">نسخ الرابط</button><a href="media/u/' + esc(k) + '" target="_blank" rel="noopener">فتح</a><button type="button" id="shDl" class="del">حذف</button></div></div>';
    document.body.appendChild(el); sheet = el; requestAnimationFrame(() => el.classList.add('on'));
    el.querySelector('.stoShBg').onclick = closeSheet;
    el.querySelector('#shCp').onclick = () => { try { navigator.clipboard.writeText(url); toast('تم نسخ الرابط'); } catch (e) { toast('تعذّر النسخ'); } };
    el.querySelector('#shDl').onclick = () => { closeSheet(); confirmDel([x]); };
  }
  function closeSheet() { if (sheet) { const s = sheet; sheet = null; s.classList.remove('on'); setTimeout(() => s.remove(), 220); } }
  function toast(t) { const e = document.createElement('div'); e.className = 'stoToast'; e.textContent = t; document.body.appendChild(e); setTimeout(() => e.classList.add('on'), 10); setTimeout(() => { e.classList.remove('on'); setTimeout(() => e.remove(), 300); }, 2600); }

  /* ---------- الحذف ---------- */
  function confirmDel(items) {
    if (!items.length) return; const linked = items.filter((x) => refOf(x.k)), size = items.reduce((a, x) => a + x.n, 0), r2n = items.filter((x) => x.st === 'r2').length;
    const el = document.createElement('div'); el.className = 'stoSh on stoDlg';
    el.innerHTML = '<div class="stoShBg"></div><div class="stoShC"><b>تأكيد الحذف</b><p>سيتم حذف <b>' + f0(items.length) + '</b> ملف (' + sz(size) + ') نهائياً' + (r2n ? ' من R2' : '') + '. لا يمكن التراجع.</p>'
      + (linked.length ? '<div class="stoWarn">⚠ ' + f0(linked.length) + ' منها مربوط بقصائد، وراح تتوقف عن التشغيل بعد الحذف:<br>' + linked.slice(0, 4).map((x) => esc((refOf(x.k) || {}).t || x.k)).join('، ') + (linked.length > 4 ? ' …' : '') + '<label><input type="checkbox" id="dlOk"> أفهم ذلك وأريد الحذف</label></div>' : '')
      + (!S.scan && items.some((x) => x.p === 'a' || x.p === 'c') ? '<div class="stoWarn soft">لم تفحص ربط الملفات بالقصائد، فقد يكون بعضها مستعملاً. الأفضل تعمل «فحص الربط» أولاً.</div>' : '')
      + '<div class="stoAct"><button type="button" id="dlNo">إلغاء</button><button type="button" id="dlGo" class="del"' + (linked.length ? ' disabled' : '') + '>حذف نهائي</button></div><div class="stoProg" id="dlPr"></div></div>';
    document.body.appendChild(el);
    const ok = el.querySelector('#dlOk'), go = el.querySelector('#dlGo'); if (ok) ok.onchange = () => { go.disabled = !ok.checked; };
    el.querySelector('#dlNo').onclick = () => el.remove(); el.querySelector('.stoShBg').onclick = () => { if (!go.dataset.busy) el.remove(); };
    go.onclick = async () => {
      go.dataset.busy = 1; go.disabled = true; el.querySelector('#dlNo').disabled = true; const pr = el.querySelector('#dlPr'); let done = 0, fail = 0; const bad = [];
      for (const st of ['r2', 'kv']) {
        const ks = items.filter((x) => x.st === st).map((x) => x.k), step = st === 'r2' ? 200 : 40;
        for (let i = 0; i < ks.length; i += step) {
          const ch = ks.slice(i, i + step); pr.textContent = 'جارٍ الحذف… ' + f0(done) + ' / ' + f0(items.length);
          try { const d = await api('api/store', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ del: ch, store: st }) }); const f = new Set(d.failed || []); ch.forEach((k) => { if (f.has(k)) { fail++; bad.push(k); } else { done++; S[st] = S[st].filter((x) => x.k !== k); S.sel.delete(st + '|' + k); } }); }
          catch (e) { fail += ch.length; bad.push(...ch); pr.textContent = e.message; }
        }
      }
      el.remove(); toast(fail ? 'حُذف ' + f0(done) + ' وفشل ' + f0(fail) : 'تم حذف ' + f0(done) + ' ملف'); draw();
    };
  }

  function open() {
    if (root) return; S = fresh();
    root = document.createElement('div'); root.className = 'ttpg stpg stoPg';
    root.innerHTML = '<div class="tth"><button class="ttb" type="button" aria-label="رجوع">‹</button><b>التخزين</b><button class="ttb" type="button" id="stoRf" aria-label="تحديث">⟳</button></div><div class="ttbody"></div>';
    document.body.appendChild(root);
    root.querySelector('.ttb').onclick = () => { closeSheet(); root.remove(); root = null; };
    root.querySelector('#stoRf').onclick = () => { if (!S.loading) loadAll(); };
    loadAll();
  }
  /* صفّ «التخزين» بقائمة الحساب بعد صفّ الإحصائيات */
  const inject = () => {
    if (!isAdmin()) return; const st = document.getElementById('stRow'); if (!st || !st.parentNode || document.getElementById('stoRow')) return;
    const c = st.cloneNode(true); c.id = 'stoRow'; c.onclick = (e) => { e.stopPropagation(); open(); };
    const w = document.createTreeWalker(c, NodeFilter.SHOW_TEXT); let t; while ((t = w.nextNode())) { if (/الإحصائيات/.test(t.nodeValue)) t.nodeValue = 'التخزين'; else if (/المستخدمون النشطون/.test(t.nodeValue)) t.nodeValue = 'المساحة والملفات والتنظيف'; }
    st.parentNode.insertBefore(c, st.nextSibling);
  };
  new MutationObserver(inject).observe(document.body, { childList: true, subtree: true }); inject();
  window.MinbarStore = { open };
})();
