/* منبر — مرئيات المشغل (مستقلة تماماً عن قسم التصميم)
   كل قالب يُرسم حول «صندوق» محدد (مركز + نصف قطر) بدقة الجهاز، والغلاف يُجهَّز مرة واحدة بجودة عالية */
(function () {
  'use strict';
  const GOLD = '#E8C468', GOLD2 = '#F3D88A', MINT = '#7FE0B5', TAU = Math.PI * 2;
  const cl = (a) => (a > 0 ? (a < 1 ? +a.toFixed(3) : 1) : 0), ga = (a) => `rgba(232,196,104,${cl(a)})`, wa = (a) => `rgba(255,255,255,${cl(a)})`;
  /* ---------- الغلاف: نسخة مصغّرة عالية الجودة بشكل محدد ---------- */
  let cache = new WeakMap();
  function coverImg(img, px, shape) {
    if (!img || !img.naturalWidth) return null; px = Math.max(16, Math.round(Math.pow(2, Math.ceil(Math.log2(px) * 6) / 6)));
    let m = cache.get(img); if (!m) { m = new Map(); cache.set(img, m); } const k = px + shape; let c = m.get(k); if (c) return c;
    const iw = img.naturalWidth, ih = img.naturalHeight, s = Math.min(iw, ih); let src = document.createElement('canvas'); src.width = src.height = s; src.getContext('2d').drawImage(img, (iw - s) / 2, (ih - s) / 2, s, s, 0, 0, s, s);
    let cur = s; while (cur / 2 >= px) { cur = Math.round(cur / 2); const n = document.createElement('canvas'); n.width = n.height = cur; const x = n.getContext('2d'); x.imageSmoothingQuality = 'high'; x.drawImage(src, 0, 0, cur, cur); src = n; }
    c = document.createElement('canvas'); c.width = c.height = px; const x = c.getContext('2d'); x.imageSmoothingQuality = 'high';
    x.beginPath(); if (shape === 'c') x.arc(px / 2, px / 2, px / 2, 0, TAU); else rr(x, 0, 0, px, px, px * 0.08); x.clip(); x.drawImage(src, 0, 0, px, px);
    if (m.size > 16) m.clear(); m.set(k, c); return c;
  }
  function rr(x, a, b, w, h, r) { x.moveTo(a + r, b); x.arcTo(a + w, b, a + w, b + h, r); x.arcTo(a + w, b + h, a, b + h, r); x.arcTo(a, b + h, a, b, r); x.arcTo(a, b, a + w, b, r); x.closePath(); }
  /* غلاف مع ظل خفيف مرسوم (بلا shadowBlur) وإطار رفيع */
  function cover(x, S, R, shape, ring) {
    const c = coverImg(S.img, R * 2, shape); const { cx, cy } = S;
    const sh = x.createRadialGradient(cx, cy + R * 0.12, R * 0.7, cx, cy + R * 0.12, R * 1.25); sh.addColorStop(0, 'rgba(0,0,0,.45)'); sh.addColorStop(1, 'rgba(0,0,0,0)'); x.fillStyle = sh; x.fillRect(cx - R * 1.3, cy - R * 1.2, R * 2.6, R * 2.6);
    if (c) x.drawImage(c, cx - R, cy - R, R * 2, R * 2); else { x.fillStyle = '#0E5C46'; x.beginPath(); shape === 'c' ? x.arc(cx, cy, R, 0, TAU) : rr(x, cx - R, cy - R, 2 * R, 2 * R, R * 0.16); x.fill(); }
    if (ring !== false) { x.strokeStyle = ga(0.85); x.lineWidth = Math.max(1, R * 0.018); x.beginPath(); shape === 'c' ? x.arc(cx, cy, R, 0, TAU) : rr(x, cx - R, cy - R, 2 * R, 2 * R, R * 0.16); x.stroke(); }
  }
  /* قيم الطيف مُعاد توزيعها بشكل متناظر حول الدائرة */
  function sym(F, n) { const v = F.vals, m = v.length, o = new Float32Array(n); for (let i = 0; i < n; i++) { const p = i / n, q = p < 0.5 ? p * 2 : (1 - p) * 2, f = q * (m - 1), a = Math.floor(f), b = Math.min(m - 1, a + 1); o[i] = v[a] + (v[b] - v[a]) * (f - a); } return o; }
  function lin(F, n) { const v = F.vals, m = v.length, o = new Float32Array(n); for (let i = 0; i < n; i++) { const f = i / (n - 1) * (m - 1), a = Math.floor(f), b = Math.min(m - 1, a + 1); o[i] = v[a] + (v[b] - v[a]) * (f - a); } return o; }
  const glow = (x, cx, cy, r0, r1, a) => { const g = x.createRadialGradient(cx, cy, r0, cx, cy, r1); g.addColorStop(0, ga(a)); g.addColorStop(1, ga(0)); x.fillStyle = g; x.beginPath(); x.arc(cx, cy, r1, 0, TAU); x.fill(); };
  const bz = (a, b, c, d, q) => { const m = 1 - q; return m * m * m * a + 3 * m * m * q * b + 3 * m * q * q * c + q * q * q * d; };
  /* راية متموجة: تعيد دالة الإزاحة لاستعمالها في رسم الغلاف على القماش */
  function flagPath(x, px, py, L, H, wv, tail) { const N = 24; x.beginPath(); for (let i = 0; i <= N; i++) { const f = i / N; i ? x.lineTo(px + f * L, py + wv(f)) : x.moveTo(px, py + wv(0)); } if (tail) x.lineTo(px + L * 0.8, py + H / 2 + wv(0.8)); for (let i = N; i >= 0; i--) { const f = i / N; x.lineTo(px + f * L, py + H + wv(f)); } x.closePath(); }
  function flagShade(x, px, L, t, a) { const g = x.createLinearGradient(px, 0, px + L, 0); for (let i = 0; i <= 12; i++) { const f = i / 12, c = Math.cos(f * 4.2 - t * 5); g.addColorStop(f, c > 0 ? `rgba(255,255,255,${(c * a * 0.6).toFixed(3)})` : `rgba(0,0,0,${(-c * a * 1.4).toFixed(3)})`); } return g; }
  function flagDraw(x, px, py, L, H, t, amp, tail) { const wv = (f) => Math.sin(f * 4.2 - t * 5) * amp * H * (0.12 + f) * 0.5; flagPath(x, px, py, L, H, wv, tail); const g = x.createLinearGradient(0, py, 0, py + H); g.addColorStop(0, '#d8262b'); g.addColorStop(1, '#8a0e12'); x.fillStyle = g; x.fill(); x.fillStyle = flagShade(x, px, L, t, 0.3); x.fill(); return wv; }
  const st = {}; /* حالة دائمة لكل قالب */

  const V = {
    strings: ['الأوتار', (x, S) => {
      const { cx, cy, F, t } = S, R = S.R * 0.7; cover(x, Object.assign({}, S, { cy: cy - R * 0.45 }), R, 'r');
      const n = 7, top = cy + R * 0.75, gap = R * 0.13, W2 = Math.min(S.W * 0.92, R * 3.6), x0 = cx - W2 / 2, v2 = lin(F, n);
      x.fillStyle = ga(0.5); [x0, x0 + W2].forEach((bx) => { x.beginPath(); rr(x, bx - S.u * 3, top - gap * 0.6, S.u * 6, gap * (n - 1) + gap * 1.2, S.u * 3); x.fill(); });
      for (let s = 0; s < n; s++) { const y0 = top + s * gap, amp = v2[n - 1 - s] * gap * 0.75, k = 1 + (s % 3), ph = t * (18 + s * 3); x.strokeStyle = s % 2 ? ga(0.55 + v2[n - 1 - s] * 0.45) : `rgba(255,248,225,${0.45 + v2[n - 1 - s] * 0.5})`; x.lineWidth = S.u * (0.8 + (n - s) * 0.18);
        x.beginPath(); for (let i = 0; i <= 64; i++) { const f = i / 64, yy = y0 + Math.sin(f * Math.PI * k) * Math.sin(ph) * amp * Math.sin(f * Math.PI); i ? x.lineTo(x0 + f * W2, yy) : x.moveTo(x0, yy); } x.stroke(); }
    }],
    halo: ['هالة', (x, S) => { const { cx, cy, F } = S, R = S.R * (1 + F.bass * 0.03); glow(x, cx, cy, R * 0.6, R * (1.7 + F.bass * 0.5), 0.1 + F.vol * 0.35);
      x.strokeStyle = ga(0.25 + F.beat * 0.5); x.lineWidth = S.u * 2; x.beginPath(); rr(x, cx - R * 1.08, cy - R * 1.08, R * 2.16, R * 2.16, R * 0.2); x.stroke(); cover(x, Object.assign({}, S), R, 'r'); }],
    vinyl: ['أسطوانة', (x, S) => {
      const s = st.vinyl || (st.vinyl = { a: 0, w: 0, arm: 0, d: null, dr: 0 }), on = S.paused ? 0 : 1, { F } = S; if (s.hold) { s.w = 0; } else { s.w += (on * 1.15 - s.w) * Math.min(1, S.dt * 1.8); s.a += s.w * S.dt; } s.arm += ((s.hold ? 1 : on) - s.arm) * Math.min(1, S.dt * 2.6);
      const R = S.R * 1.18, cx = S.cx - R * 0.06, cy = S.cy + R * 0.04;
      if (!s.d || s.dr !== Math.round(R)) { const c = document.createElement('canvas'), p = Math.round(R * 2); c.width = c.height = p; const y = c.getContext('2d'), h = p / 2; y.translate(h, h);
        const bg = y.createRadialGradient(0, 0, h * 0.6, 0, 0, h); bg.addColorStop(0, '#141617'); bg.addColorStop(0.92, '#0b0c0d'); bg.addColorStop(1, '#202325'); y.fillStyle = bg; y.beginPath(); y.arc(0, 0, h, 0, TAU); y.fill();
        for (let r = h * 0.64; r < h * 0.97; r += Math.max(1.5, h / 90)) { y.strokeStyle = `rgba(255,255,255,${0.018 + 0.02 * Math.sin(r * 0.7) ** 2})`; y.lineWidth = 1; y.beginPath(); y.arc(0, 0, r, 0, TAU); y.stroke(); }
        y.strokeStyle = 'rgba(255,255,255,.08)'; y.lineWidth = Math.max(1, h * 0.012); y.beginPath(); y.arc(0, 0, h * 0.635, 0, TAU); y.stroke(); s.d = c; s.dr = Math.round(R); }
      glow(x, cx, cy, R * 0.9, R * 1.45, 0.05 + F.bass * 0.22);
      x.save(); x.translate(cx, cy); x.rotate(s.a); x.drawImage(s.d, -R, -R, 2 * R, 2 * R); const L = coverImg(S.img, R * 1.24, 'c'); if (L) x.drawImage(L, -R * 0.62, -R * 0.62, R * 1.24, R * 1.24); x.restore();
      x.save(); x.translate(cx, cy); [[-0.6, 0.11], [Math.PI - 0.6, 0.08]].forEach(([a, al]) => { const g = x.createRadialGradient(0, 0, R * 0.6, 0, 0, R); g.addColorStop(0, `rgba(255,255,255,0)`); g.addColorStop(0.6, `rgba(255,255,255,${al})`); g.addColorStop(1, 'rgba(255,255,255,0)'); x.fillStyle = g; x.beginPath(); x.moveTo(0, 0); x.arc(0, 0, R, a - 0.35, a + 0.35); x.closePath(); x.fill(); }); x.restore();
      const sp = x.createRadialGradient(cx - R * 0.01, cy - R * 0.01, 0, cx, cy, R * 0.05); sp.addColorStop(0, '#f4f4f4'); sp.addColorStop(1, '#8a8f93'); x.fillStyle = sp; x.beginPath(); x.arc(cx, cy, R * 0.045, 0, TAU); x.fill();
      /* الذراع */
      s.g = { cx, cy, R }; const u = R, px = cx + R * 1.0, py = cy - R * 1.08, th = (78 + (121 - 78) * s.arm) * Math.PI / 180, AL = R * 0.64;
      const met = (y0, y1, c) => { const m = x.createLinearGradient(0, y0, 0, y1); m.addColorStop(0, c[0]); m.addColorStop(0.45, c[1]); m.addColorStop(0.55, c[2]); m.addColorStop(1, c[3]); return m; };
      /* قاعدة الذراع */
      x.save(); x.translate(px, py); x.fillStyle = 'rgba(0,0,0,.35)'; x.beginPath(); rr(x, -u * 0.17 + u * 0.02, -u * 0.17 + u * 0.03, u * 0.34, u * 0.34, u * 0.08); x.fill();
      x.fillStyle = met(-u * 0.17, u * 0.17, ['#3a3e42', '#5b6166', '#4a4f53', '#25282b']); x.beginPath(); rr(x, -u * 0.17, -u * 0.17, u * 0.34, u * 0.34, u * 0.08); x.fill(); x.strokeStyle = 'rgba(255,255,255,.12)'; x.lineWidth = Math.max(1, u * 0.006); x.stroke();
      const ring = x.createRadialGradient(-u * 0.03, -u * 0.03, 0, 0, 0, u * 0.12); ring.addColorStop(0, '#9aa1a6'); ring.addColorStop(1, '#2d3134'); x.fillStyle = ring; x.beginPath(); x.arc(0, 0, u * 0.12, 0, TAU); x.fill(); x.restore();
      /* مسند الذراع */
      const ra = 78 * Math.PI / 180, rx = px + Math.cos(ra) * u * 0.5 + u * 0.06, ry = py + Math.sin(ra) * u * 0.5; x.fillStyle = '#2a2d30'; x.beginPath(); x.arc(rx, ry, u * 0.035, 0, TAU); x.fill(); x.fillStyle = '#8e959a'; x.beginPath(); x.arc(rx, ry, u * 0.02, 0, TAU); x.fill();
      const armPath = () => { x.beginPath(); x.moveTo(-u * 0.16, 0); x.lineTo(0, 0); x.bezierCurveTo(AL * 0.45, -u * 0.05, AL * 0.68, u * 0.09, AL * 0.93, u * 0.045); };
      const head = (sh) => { x.save(); x.translate(AL * 0.93, u * 0.045); x.rotate(0.38);
        if (sh) { x.fillStyle = 'rgba(0,0,0,.3)'; x.beginPath(); x.moveTo(0, -u * 0.035); x.lineTo(u * 0.19, -u * 0.05); x.lineTo(u * 0.205, u * 0.05); x.lineTo(0, u * 0.035); x.fill(); x.restore(); return; }
        x.fillStyle = met(-u * 0.05, u * 0.05, ['#c9ced2', '#f4f6f7', '#d4d8db', '#8a9095']); x.beginPath(); x.moveTo(0, -u * 0.032); x.lineTo(u * 0.19, -u * 0.048); x.quadraticCurveTo(u * 0.21, 0, u * 0.2, u * 0.05); x.lineTo(0, u * 0.032); x.closePath(); x.fill();
        x.strokeStyle = '#b9bfc3'; x.lineWidth = u * 0.012; x.lineCap = 'round'; x.beginPath(); x.moveTo(u * 0.06, -u * 0.04); x.quadraticCurveTo(u * 0.08, -u * 0.1, u * 0.13, -u * 0.12); x.stroke();
        x.fillStyle = '#141516'; x.beginPath(); rr(x, u * 0.07, -u * 0.03, u * 0.105, u * 0.06, u * 0.01); x.fill(); x.fillStyle = GOLD; x.fillRect(u * 0.07, -u * 0.03, u * 0.012, u * 0.06);
        x.fillStyle = '#d8c18a'; [[0.1, -0.02], [0.1, 0.02], [0.145, -0.02], [0.145, 0.02]].forEach(([a2, b2]) => { x.beginPath(); x.arc(u * a2, u * b2, u * 0.006, 0, TAU); x.fill(); }); x.restore(); };
      /* الظل */
      x.save(); x.translate(px + u * 0.035, py + u * 0.05); x.rotate(th); x.lineCap = 'round'; x.strokeStyle = 'rgba(0,0,0,.28)'; x.lineWidth = u * 0.035; armPath(); x.stroke(); head(true); x.restore();
      x.save(); x.translate(px, py); x.rotate(th); x.lineCap = 'round';
      /* الثقل الخلفي */
      x.fillStyle = met(-u * 0.085, u * 0.085, ['#55595d', '#e6e9eb', '#b9bec2', '#3f4346']); x.beginPath(); rr(x, -u * 0.36, -u * 0.085, u * 0.17, u * 0.17, u * 0.025); x.fill();
      x.strokeStyle = 'rgba(0,0,0,.25)'; x.lineWidth = Math.max(1, u * 0.005); [-0.32, -0.29, -0.26].forEach((q) => { x.beginPath(); x.moveTo(u * q, -u * 0.085); x.lineTo(u * q, u * 0.085); x.stroke(); });
      /* الأنبوب */
      x.strokeStyle = '#4b5155'; x.lineWidth = u * 0.034; armPath(); x.stroke(); x.strokeStyle = '#c3c8cc'; x.lineWidth = u * 0.024; armPath(); x.stroke();
      x.save(); x.translate(0, -u * 0.006); x.strokeStyle = 'rgba(255,255,255,.75)'; x.lineWidth = u * 0.006; armPath(); x.stroke(); x.restore();
      head(false);
      /* المفصل */
      const gm = x.createRadialGradient(-u * 0.02, -u * 0.025, 0, 0, 0, u * 0.075); gm.addColorStop(0, '#fbfbfb'); gm.addColorStop(0.6, '#a9afb3'); gm.addColorStop(1, '#585e62'); x.fillStyle = gm; x.beginPath(); x.arc(0, 0, u * 0.07, 0, TAU); x.fill();
      x.fillStyle = '#1d1f21'; x.beginPath(); x.arc(0, 0, u * 0.022, 0, TAU); x.fill(); x.restore();
    }],
    bars: ['حلقة الأعمدة', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.86, n = 72, v = sym(F, n); glow(x, cx, cy, R, R * 1.9, 0.06 + F.bass * 0.18);
      x.lineCap = 'round'; x.lineWidth = Math.max(2, R * 0.035); for (let i = 0; i < n; i++) { const a = -Math.PI / 2 + i * TAU / n, l = R * (0.06 + v[i] * 0.55), r0 = R * 1.12; x.strokeStyle = ga(0.45 + v[i] * 0.55); x.beginPath(); x.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); x.lineTo(cx + Math.cos(a) * (r0 + l), cy + Math.sin(a) * (r0 + l)); x.stroke(); }
      cover(x, S, R, 'c'); }],
    blob: ['موجة دائرية', (x, S) => { const { cx, cy, F, t } = S, R = S.R * 0.84, n = 48, v = sym(F, n), pts = [];
      for (let i = 0; i < n; i++) { const a = -Math.PI / 2 + i * TAU / n, r = R * (1.12 + v[i] * 0.42 + 0.03 * Math.sin(t * 1.3 + i * 0.5)); pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]); }
      const path = (k) => { x.beginPath(); for (let i = 0; i < n; i++) { const p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n]; if (!i) x.moveTo(p1[0], p1[1]); x.bezierCurveTo(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]); } x.closePath(); };
      const g = x.createRadialGradient(cx, cy, R, cx, cy, R * 1.6); g.addColorStop(0, ga(0.35)); g.addColorStop(1, 'rgba(127,224,181,.08)'); path(); x.fillStyle = g; x.fill(); x.strokeStyle = ga(0.9); x.lineWidth = S.u * 1.6; x.stroke(); cover(x, S, R, 'c'); }],
    wave: ['خط الصوت', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.78; cover(x, Object.assign({}, S, { cy: cy - R * 0.32 }), R, 'r');
      const w = F.wave, y0 = cy + R * 1.05, W2 = Math.min(S.W * 0.9, R * 3.4), hh = R * 0.42; if (!w) return; const n = 96; x.lineJoin = 'round';
      [[ga(0.25), S.u * 6], [GOLD2, S.u * 2]].forEach(([c, lw]) => { x.strokeStyle = c; x.lineWidth = lw; x.beginPath(); for (let i = 0; i < n; i++) { const f = i / (n - 1), v = w[Math.floor(f * (w.length - 1))] || 0, env = Math.sin(f * Math.PI); const px = cx - W2 / 2 + f * W2, py = y0 + v * hh * 2.2 * env; i ? x.lineTo(px, py) : x.moveTo(px, py); } x.stroke(); }); }],
    spectrum: ['أعمدة الطيف', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.72; cover(x, Object.assign({}, S, { cy: cy - R * 0.42 }), R, 'r');
      const n = 32, v = lin(F, n), W2 = Math.min(S.W * 0.88, R * 3.3), bw = W2 / n * 0.62, base = cy + R * 1.35, H = R * 0.85, s = st.sp || (st.sp = new Float32Array(n));
      for (let i = 0; i < n; i++) { const h = Math.max(S.u * 3, v[i] * H), px = cx - W2 / 2 + (i + 0.19) * (W2 / n); s[i] = Math.max(v[i], s[i] - S.dt * 0.6);
        const g = x.createLinearGradient(0, base - H, 0, base); g.addColorStop(0, GOLD2); g.addColorStop(1, ga(0.55)); x.fillStyle = g; x.beginPath(); rr(x, px, base - h, bw, h, bw / 2); x.fill();
        x.fillStyle = ga(0.13); x.beginPath(); rr(x, px, base + S.u * 3, bw, h * 0.35, bw / 2); x.fill(); x.fillStyle = wa(0.85); x.fillRect(px, base - s[i] * H - S.u * 5, bw, S.u * 2); } }],
    orbit: ['مدارات', (x, S) => { const { cx, cy, F, t } = S, R = S.R * 0.8; glow(x, cx, cy, R, R * 1.8, 0.05 + F.vol * 0.15);
      [[1.25, 0.4, 'bass', 7], [1.5, -0.27, 'mid', 11], [1.78, 0.19, 'hi', 16]].forEach(([k, sp, b, m], j) => { const rad = R * (k + F[b] * 0.08); x.strokeStyle = ga(0.12 + F[b] * 0.25); x.lineWidth = S.u; x.beginPath(); x.arc(cx, cy, rad, 0, TAU); x.stroke();
        for (let i = 0; i < m; i++) { const a = t * sp + i * TAU / m + j, sz = S.u * (2 + F[b] * 5) * (i % 3 ? 1 : 1.6); x.fillStyle = i % 4 ? ga(0.6 + F[b] * 0.4) : 'rgba(127,224,181,.85)'; x.beginPath(); x.arc(cx + Math.cos(a) * rad, cy + Math.sin(a) * rad, sz, 0, TAU); x.fill(); } });
      cover(x, S, R, 'c'); }],
    pulse: ['نبض', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.84, s = st.pu || (st.pu = { r: [], last: 0 }); const now = S.now;
      if (F.beat > 0.45 && now - s.last > 0.18) { s.r.push({ t: now, a: Math.min(1, F.beat) }); s.last = now; } s.r = s.r.filter((o) => now - o.t < 1.6);
      s.r.forEach((o) => { const p = (now - o.t) / 1.6; x.strokeStyle = ga((1 - p) * 0.75 * o.a); x.lineWidth = S.u * (1 + (1 - p) * 4); x.beginPath(); x.arc(cx, cy, R * (1.05 + p * 0.95), 0, TAU); x.stroke(); });
      glow(x, cx, cy, R * 0.9, R * 1.35, 0.1 + F.bass * 0.35); const k = 1 + F.bass * 0.035; cover(x, S, R * k, 'c'); }],
    star: ['النجمة الثمانية', (x, S) => { const { cx, cy, F, t } = S, R = S.R * 0.74; glow(x, cx, cy, R, R * 1.9, 0.06 + F.bass * 0.2);
      const star = (r, a0) => { x.beginPath(); for (let sq = 0; sq < 2; sq++) { for (let i = 0; i <= 4; i++) { const a = a0 + sq * Math.PI / 4 + i * Math.PI / 2; const px = cx + Math.cos(a) * r, py = cy + Math.sin(a) * r; i ? x.lineTo(px, py) : x.moveTo(px, py); } } };
      [[1.45 + F.bass * 0.12, t * 0.05, 0.9, 1.6], [1.7 + F.mid * 0.1, -t * 0.035, 0.45, 1], [1.98 + F.hi * 0.1, t * 0.02, 0.22, 1]].forEach(([k, a, al, lw]) => { star(R * k, a + Math.PI / 4); x.strokeStyle = ga(al); x.lineWidth = S.u * lw; x.lineJoin = 'round'; x.stroke(); });
      cover(x, S, R, 'c'); }],
    dust: ['غبار ذهبي', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.84, s = st.du || (st.du = { p: [] }); const em = Math.round((S.paused ? 0 : 1) * (1 + F.vol * 5 + F.beat * 8));
      for (let i = 0; i < em; i++) { const a = Math.random() * TAU; s.p.push({ a, r: R * 1.02, v: R * (0.25 + Math.random() * 0.6) * (0.6 + F.vol), l: 1, z: 0.6 + Math.random() * 1.4, w: Math.random() < 0.25 }); }
      if (s.p.length > 260) s.p.splice(0, s.p.length - 260); glow(x, cx, cy, R, R * 1.6, 0.05 + F.bass * 0.18);
      s.p.forEach((o) => { o.r += o.v * S.dt; o.l -= S.dt * 0.55; if (o.l <= 0) return; x.fillStyle = o.w ? `rgba(255,255,255,${o.l * 0.8})` : ga(o.l); x.beginPath(); x.arc(cx + Math.cos(o.a) * o.r, cy + Math.sin(o.a) * o.r, S.u * o.z * (0.6 + o.l), 0, TAU); x.fill(); });
      s.p = s.p.filter((o) => o.l > 0); cover(x, S, R, 'c'); }],
    mihrab: ['المحراب', (x, S) => {
      const { cx, F } = S, R = S.R * 0.84, w = R * 2.3, h = R * 2.9, cy = S.cy + R * 0.1, top = cy - h * 0.5, bot = cy + h * 0.5;
      const arch = (sc) => { const ww = w * sc, hh = h * sc, tp = cy - hh * 0.5, bt = cy + hh * 0.5, r = ww / 2; x.beginPath(); x.moveTo(cx - r, bt); x.lineTo(cx - r, tp + r * 0.95); x.bezierCurveTo(cx - r, tp + r * 0.2, cx - r * 0.25, tp + r * 0.05, cx, tp - r * 0.32); x.bezierCurveTo(cx + r * 0.25, tp + r * 0.05, cx + r, tp + r * 0.2, cx + r, tp + r * 0.95); x.lineTo(cx + r, bt); };
      const g = x.createLinearGradient(0, top, 0, bot); g.addColorStop(0, ga(0.16 + F.vol * 0.2)); g.addColorStop(1, ga(0.02)); arch(1); x.fillStyle = g; x.fill();
      x.lineWidth = S.u * 1.8; x.strokeStyle = ga(0.9); arch(1); x.stroke(); x.lineWidth = S.u; x.strokeStyle = ga(0.3 + F.bass * 0.45); arch(1.07 + F.bass * 0.025); x.stroke();
      const n = 22, vv = sym(F, n), bw = (w * 0.86) / n; for (let i = 0; i < n; i++) { const hh2 = Math.max(S.u * 2, vv[i] * R * 0.5), px2 = cx - w * 0.43 + i * bw; x.fillStyle = ga(0.55 + vv[i] * 0.45); x.beginPath(); rr(x, px2 + bw * 0.2, bot - hh2 - S.u * 4, bw * 0.6, hh2, bw * 0.3); x.fill(); }
      cover(x, Object.assign({}, S, { cy: cy - R * 0.12 }), R * 0.8, 'r');
    }],
    candles: ['الشموع', (x, S) => {
      const { cx, cy, F, t } = S, R = S.R * 0.74; cover(x, Object.assign({}, S, { cy: cy - R * 0.28 }), R, 'r');
      const n = 5, base = cy + R * 1.55, gap = R * 0.5, v2 = lin(F, n);
      for (let i = 0; i < n; i++) { const px = cx + (i - (n - 1) / 2) * gap, ch = R * (0.32 + (i % 2 ? 0.1 : 0.2) - Math.abs(i - 2) * 0.05), cw = R * 0.15, fl = 0.55 + v2[i] * 0.9 + 0.08 * Math.sin(t * 13 + i * 2.1);
        glow(x, px, base - ch - R * 0.08, R * 0.01, R * (0.22 + fl * 0.22), 0.18 + fl * 0.18);
        const cg = x.createLinearGradient(px - cw / 2, 0, px + cw / 2, 0); cg.addColorStop(0, '#d9ccb0'); cg.addColorStop(0.5, '#fbf3df'); cg.addColorStop(1, '#c9b994'); x.fillStyle = cg; x.beginPath(); rr(x, px - cw / 2, base - ch, cw, ch, cw * 0.2); x.fill();
        const fh = R * 0.16 * fl, sway = Math.sin(t * 7 + i) * R * 0.012; x.save(); x.translate(px + sway, base - ch - R * 0.015); const fg = x.createRadialGradient(0, -fh * 0.35, 0, 0, -fh * 0.35, fh * 0.6); fg.addColorStop(0, '#fffbe8'); fg.addColorStop(0.45, '#ffd36b'); fg.addColorStop(1, 'rgba(255,140,40,0)'); x.fillStyle = fg;
          x.beginPath(); x.moveTo(0, 0); x.bezierCurveTo(fh * 0.32, -fh * 0.25, fh * 0.12, -fh * 0.7, 0, -fh); x.bezierCurveTo(-fh * 0.12, -fh * 0.7, -fh * 0.32, -fh * 0.25, 0, 0); x.fill(); x.restore(); }
      x.fillStyle = ga(0.35); x.fillRect(cx - gap * 2.6, base, gap * 5.2, S.u * 1.5); }],
    neon: ['إطار مضيء', (x, S) => { const { cx, cy, F } = S, R = S.R * 0.86, e = R * 1.1, rad = R * 0.22, f = 0.6 + F.vol * 0.4 + F.beat * 0.3;
      [[S.u * 14, 0.06], [S.u * 8, 0.12], [S.u * 4, 0.3]].forEach(([lw, a]) => { x.strokeStyle = ga(Math.min(1, a * f * 1.6)); x.lineWidth = lw; x.beginPath(); rr(x, cx - e, cy - e, 2 * e, 2 * e, rad); x.stroke(); });
      x.strokeStyle = `rgba(255,240,200,${Math.min(1, 0.7 * f + 0.2)})`; x.lineWidth = S.u * 1.6; x.beginPath(); rr(x, cx - e, cy - e, 2 * e, 2 * e, rad); x.stroke(); cover(x, S, R, 'r', false); }]
  };
  const ORDER = ['mihrab', 'vinyl', 'strings', 'candles', 'halo', 'bars', 'blob', 'wave', 'spectrum', 'orbit', 'pulse', 'star', 'dust', 'neon'];
  window.PVZ = {
    list: ORDER.filter((k) => V[k]).map((k) => [k, V[k][0]]),
    reset() { Object.keys(st).forEach((k) => delete st[k]); cache = new WeakMap(); },
    cover(x, img, cx, cy, R, shape) { cover(x, { img, cx, cy }, R, shape); },
    has: (id) => !!V[id],
    vinyl: { geo: () => (st.vinyl && st.vinyl.g) || null, hold(on) { if (st.vinyl) st.vinyl.hold = !!on; }, turn(d) { if (st.vinyl) st.vinyl.a += d; } },
    /* x: سياق الرسم بمقياس الجهاز، B: {cx, cy, R} بالبكسل */
    draw(x, W, H, id, F, img, B, opts) {
      const f = V[id]; if (!f) return; x.setTransform(1, 0, 0, 1, 0, 0); x.clearRect(0, 0, W, H); x.lineCap = 'butt'; x.lineJoin = 'miter';
      const pk = opts.pk == null ? 1 : opts.pk, BB = Object.assign({}, B, { R: B.R * (0.95 + 0.05 * pk) }); x.globalAlpha = 0.72 + 0.28 * pk;
      f[1](x, Object.assign({ W, H, F, img, u: Math.max(1, B.R / 110), t: opts.t || 0, now: opts.now || 0, dt: opts.dt || 0.016, paused: !!opts.paused }, BB)); x.globalAlpha = 1;
    }
  };
})();
