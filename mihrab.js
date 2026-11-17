/* منبر — افتتاحية المحراب (الشعار + اسم التطبيق) */
(function () {
  const W = 360, H = 640;
  const R = (p, a, b) => Math.min(1, Math.max(0, (p - a) / (b - a))), E = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2, L = (a, b, t) => a + (b - a) * t;
  const ob = v => { const c1 = .7, c3 = c1 + 1; return 1 + c3 * Math.pow(v - 1, 3) + c1 * Math.pow(v - 1, 2); };
  const SM = t => t * t * (3 - 2 * t);
  const FULL = new Image(); FULL.src = 'icons/name.png';
  const xs = [23.5, 39.5, 55.5, 71.5, 87.5], hs = [50, 72, 90, 72, 50];
  const dL = 'M60 6 Q14 22 14 58 L14 118', dR = 'M60 6 Q106 22 106 58 L106 118';
  const ARCHL = new Path2D(dL), ARCHR = new Path2D(dR);
  const ARCHLI = new Path2D('M60 14 Q21 28 21 60 L21 116'), ARCHRI = new Path2D('M60 14 Q99 28 99 60 L99 116');
  const INNER = new Path2D('M15 118 L15 58 Q15 23 60 7 Q105 23 105 58 L105 118 Z');
  // نقاط على القوس لموضع شرارة الرسم
  function samp(d) {
    const NS = 'http://www.w3.org/2000/svg', s = document.createElementNS(NS, 'svg'), p = document.createElementNS(NS, 'path');
    s.style.cssText = 'position:absolute;width:0;height:0'; p.setAttribute('d', d); s.appendChild(p); document.documentElement.appendChild(s);
    const n = p.getTotalLength(), out = []; for (let i = 0; i <= 80; i++) { const q = p.getPointAtLength(n * i / 80); out.push([q.x, q.y]); }
    s.remove(); return { n, out };
  }
  let SL, SR, HL = 118;
  try { SL = samp(dL); SR = samp(dR); HL = SL.n; } catch (e) {}
  const at = (S, t) => S.out[Math.round(Math.min(1, Math.max(0, t)) * 80)];
  const bk = (w, i) => .3 + .7 * (.5 + .5 * Math.sin(w * 6.283 + i * 1.1));
  const mkC = (w, h) => { const c = document.createElement('canvas'); c.width = w; c.height = h; return [c, c.getContext('2d')]; };
  const [lc, lx] = mkC(240, 260), [nc, nx] = mkC(960, 662), [pat, px] = mkC(720, 1280), [pm, pmx] = mkC(720, 1280);
  (() => { px.scale(2, 2); px.strokeStyle = 'rgba(232,200,120,1)'; px.lineWidth = .6; const T = 36;
    for (let y = -T; y < H + T; y += T) for (let x = -T; x < W + T; x += T) { const cx = x + ((y / T) % 2 ? T / 2 : 0); for (const r of [0, Math.PI / 4]) { px.save(); px.translate(cx, y); px.rotate(r); px.strokeRect(-9, -9, 18, 18); px.restore(); } px.beginPath(); px.arc(cx, y, 3, 0, 6.283); px.stroke(); } })();
  const motes = Array.from({ length: 34 }, () => ({ x: Math.random(), y: Math.random(), s: .4 + Math.random() * 1.1, v: .04 + Math.random() * .08, p: Math.random() * 6 }));
  const S0 = 2.45, S1 = 1.5, AY0 = H * .5 - 64 * S0, AY1 = 140, NW0 = 200, NW1 = 205, NH = w => w * 662 / 960;
  function gold(x) { const g = x.createLinearGradient(0, 0, 0, 120); g.addColorStop(0, '#F4DB92'); g.addColorStop(.5, '#E3BF66'); g.addColorStop(1, '#CFA34A'); return g; }
  let PTS = null;
  function pts() {
    if (PTS || !FULL.complete || !FULL.naturalWidth) return PTS;
    const [c, g] = mkC(240, 166); g.drawImage(FULL, 0, 0, 240, 166); const d = g.getImageData(0, 0, 240, 166).data, a = [];
    for (let y = 0; y < 166; y += 2) for (let X = 0; X < 240; X += 2) if (d[(y * 240 + X) * 4 + 3] > 150) a.push([X / 240, y / 166]);
    a.sort(() => Math.random() - .5);
    PTS = a.slice(0, 420).map(p => ({ x: p[0], y: p[1], d: Math.random() * .35, ox: (Math.random() - .5) * 60, oy: Math.random() * 20 }));
    return PTS;
  }
  function spark(x, X, Y, r) { const g = x.createRadialGradient(X, Y, 0, X, Y, r); g.addColorStop(0, 'rgba(255,255,245,1)'); g.addColorStop(.25, 'rgba(255,236,170,.85)'); g.addColorStop(1, 'rgba(232,196,106,0)'); x.fillStyle = g; x.beginPath(); x.arc(X, Y, r, 0, 6.283); x.fill(); }

  // el0: الثواني منذ البداية. compact: الشعار النهائي فقط (لشاشة الدخول)
  function scene(x, el0, Hc, compact) {
    const w = el0 / 1.8, el = compact ? 9 : el0 * 1.6;
    const mv = (t => 1 - Math.pow(2, -9 * t) * (1 - t))(R(el, 2.7, 3.9)), s = L(S0, S1, mv), ax = W / 2 - 60 * s, ay = L(AY0, AY1, mv);
    const done = R(el, 4.3, 5), lo = SM(R(el, .8, 1.9)) * (1 - SM(R(el, 2.6, 3.6))), br = done * (bk(w, 2) * .5 + bk(w, 0) * .5);
    let g;
    if (!compact) {
      const cy = L(H * .5, ay + 64 * s, mv); g = x.createRadialGradient(W / 2, cy, 0, W / 2, cy, 620); g.addColorStop(0, '#0e4636'); g.addColorStop(.45, '#06281e'); g.addColorStop(1, '#010a07'); x.fillStyle = g; x.fillRect(-1500, -1500, 3360, 3640);
      const vg = x.createRadialGradient(W / 2, H / 2, H * .3, W / 2, H / 2, H * .75); vg.addColorStop(0, 'rgba(0,0,0,0)'); vg.addColorStop(1, 'rgba(0,0,0,.45)'); x.fillStyle = vg; x.fillRect(-1500, -1500, 3360, 3640);
      const pa = .05 + .16 * lo + .03 * done;
      pmx.setTransform(1, 0, 0, 1, 0, 0); pmx.clearRect(0, 0, 720, 1280); pmx.globalCompositeOperation = 'source-over'; pmx.drawImage(pat, 0, 0); pmx.globalCompositeOperation = 'destination-in'; pmx.setTransform(2, 0, 0, 2, 0, 0);
      const pg = pmx.createRadialGradient(W / 2, ay + 70 * s, 10, W / 2, ay + 70 * s, 90 * s + 90); pg.addColorStop(0, 'rgba(0,0,0,1)'); pg.addColorStop(1, 'rgba(0,0,0,0)'); pmx.fillStyle = pg; pmx.fillRect(0, 0, W, H);
      x.save(); x.globalAlpha = pa; x.drawImage(pm, 0, 0, W, H); x.restore();
    }
    const ha = .07 + .2 * lo + .06 * R(el, 0, 1) + .07 * br; g = x.createRadialGradient(W / 2, ay + 70 * s, 0, W / 2, ay + 70 * s, compact ? 125 : 95 * s + 60); g.addColorStop(0, `rgba(240,205,120,${ha})`); g.addColorStop(1, 'rgba(240,205,120,0)'); x.fillStyle = g; x.fillRect(0, -100, W, H + 200);
    // ضوء المحراب
    if (lo > .001) {
      lx.setTransform(1, 0, 0, 1, 0, 0); lx.clearRect(0, 0, 240, 260); lx.setTransform(2, 0, 0, 2, 0, 0); lx.save(); lx.clip(INNER);
      const hw = 8 + lo * 48; let lg = lx.createLinearGradient(60 - hw, 0, 60 + hw, 0); lg.addColorStop(0, 'rgba(255,236,170,0)'); lg.addColorStop(.5, 'rgba(255,232,170,.62)'); lg.addColorStop(1, 'rgba(255,236,170,0)'); lx.fillStyle = lg; lx.fillRect(0, 0, 120, 130);
      lx.globalCompositeOperation = 'lighter';
      for (let i = -4; i <= 4; i++) { lx.save(); lx.translate(60, 124); lx.rotate(i * .11 + Math.sin(el * .7 + i) * .01); const rg = lx.createLinearGradient(0, 0, 0, -120); rg.addColorStop(0, 'rgba(255,236,190,.22)'); rg.addColorStop(1, 'rgba(255,240,200,0)'); lx.fillStyle = rg; lx.beginPath(); lx.moveTo(-1.2, 0); lx.lineTo(1.2, 0); lx.lineTo(4, -120); lx.lineTo(-4, -120); lx.fill(); lx.restore(); }
      motes.forEach(m => { const yy = 118 - ((m.y * 118 + el * m.v * 120) % 112), xx = 60 + (m.x - .5) * hw * 1.6 + Math.sin(el + m.p) * 2; lx.fillStyle = 'rgba(255,250,230,.9)'; lx.beginPath(); lx.arc(xx, yy, m.s * .6, 0, 6.283); lx.fill(); });
      lx.globalCompositeOperation = 'destination-in'; const fg = lx.createLinearGradient(0, 0, 0, 118); fg.addColorStop(0, 'rgba(0,0,0,.55)'); fg.addColorStop(.6, 'rgba(0,0,0,1)'); fg.addColorStop(.88, 'rgba(0,0,0,.75)'); fg.addColorStop(1, 'rgba(0,0,0,0)'); lx.fillStyle = fg; lx.fillRect(0, 0, 120, 130); lx.restore();
      x.save(); x.globalAlpha = Math.min(1, lo * .9); x.globalCompositeOperation = 'lighter'; x.drawImage(lc, ax, ay, 120 * s, 130 * s); x.restore();
      g = x.createRadialGradient(W / 2, ay + 118 * s, 0, W / 2, ay + 118 * s, 70 * s); g.addColorStop(0, `rgba(255,230,160,${.28 * lo})`); g.addColorStop(1, 'rgba(255,230,160,0)');
      x.save(); x.translate(W / 2, ay + 118 * s); x.scale(1, .18); x.translate(-W / 2, -(ay + 118 * s)); x.fillStyle = g; x.fillRect(0, 0, W, H); x.restore();
    }
    // القوس
    const dr = E(R(el, 0, 1.05)), lw = 4.6 / s;
    x.save(); x.translate(ax, ay); x.scale(s, s); x.lineCap = 'round'; x.lineJoin = 'round'; x.setLineDash([HL, HL]); x.lineDashOffset = HL * (1 - dr);
    x.strokeStyle = 'rgba(0,0,0,.45)'; x.lineWidth = lw; x.shadowColor = 'rgba(0,0,0,.6)'; x.shadowBlur = 10; x.shadowOffsetY = 3; x.translate(0, 1.2 / s); x.stroke(ARCHL); x.stroke(ARCHR); x.translate(0, -1.2 / s);
    x.shadowOffsetY = 0; x.shadowColor = 'rgba(246,215,130,.85)'; x.shadowBlur = 6 + 16 * lo + 6 * br; x.strokeStyle = gold(x); x.lineWidth = lw; x.stroke(ARCHL); x.stroke(ARCHR);
    x.shadowBlur = 0; x.strokeStyle = 'rgba(255,250,225,.55)'; x.lineWidth = lw * .28; x.stroke(ARCHL); x.stroke(ARCHR);
    const di = E(R(el, .35, 1.35)); x.lineDashOffset = HL * (1 - di); x.globalAlpha = .55; x.strokeStyle = gold(x); x.lineWidth = lw * .32; x.stroke(ARCHLI); x.stroke(ARCHRI); x.globalAlpha = 1;
    if (el > 4.2) { const ph = ((el0 + 10) % 3.2) / 3.2; if (ph < .55) { const q = SM(ph / .55) * HL * 1.2; x.setLineDash([16, HL * 3]); x.lineDashOffset = -q + 16; x.strokeStyle = 'rgba(255,252,235,.85)'; x.lineWidth = lw * .7; x.shadowColor = 'rgba(255,240,190,1)'; x.shadowBlur = 10; x.stroke(ARCHL); x.stroke(ARCHR); } }
    x.restore();
    if (dr > 0 && dr < 1 && SL) [SL, SR].forEach(S => { const p = at(S, dr); spark(x, ax + p[0] * s, ay + p[1] * s, 9); });
    // الأعمدة
    const rs = R(el, 3.35, 4.3);
    if (rs > 0) {
      x.save(); x.translate(ax, ay); x.scale(s, s); const gd = gold(x);
      const rr = (bx, y, w2, h2, r2) => { x.beginPath(); x.roundRect ? x.roundRect(bx, y, w2, h2, r2) : x.rect(bx, y, w2, h2); };
      xs.forEach((bx, i) => { const r = Math.max(0, Math.min(1.15, ob(Math.max(0, Math.min(1, rs * 1.7 - i * .17))))), h = hs[i] * bk(w, i) * r; if (h < .6) return;
        x.shadowColor = 'rgba(0,0,0,.35)'; x.shadowBlur = 8; x.shadowOffsetY = 2.5; x.fillStyle = gd; rr(bx, 116 - h, 9, h, 4.5); x.fill();
        x.shadowOffsetY = 0; x.shadowColor = `rgba(246,215,130,${.6 + .2 * br})`; x.shadowBlur = 6 + 6 * br; x.fill(); x.shadowBlur = 0;
        if (h > 6) { x.fillStyle = 'rgba(255,250,225,.55)'; rr(bx + 2.2, 116 - h + 3, 1.3, h - 6, .65); x.fill(); } });
      x.restore();
    }
    // الاسم: ذرات ذهب تطلع من ضوء المحراب وتتجمع على شكله
    const ep = SM(R(el, 1.15, 2.75));
    if (ep > 0 && FULL.complete && FULL.naturalWidth) {
      const nw = L(NW0, NW1, mv), nh = NH(nw), ccy = L(AY0 + 70 * S0, AY1 + 130 * S1 + 18 + NH(NW1) / 2, mv);
      nx.globalCompositeOperation = 'source-over'; nx.clearRect(0, 0, 960, 662); nx.drawImage(FULL, 0, 0, 960, 662);
      const sp = compact ? ((el0 % 8) / 1.7) : R(el, 4.2, 5.8);
      if (sp > 0 && sp < 1) { const c = 1.3 - 1.6 * E(sp), k = v => Math.max(0, Math.min(1, v)); const sg = nx.createLinearGradient(0, 0, 960, 260); sg.addColorStop(0, 'rgba(255,250,230,0)'); sg.addColorStop(k(c - .17), 'rgba(255,250,230,0)'); sg.addColorStop(k(c), 'rgba(255,252,238,.75)'); sg.addColorStop(k(c + .17), 'rgba(255,250,230,0)'); sg.addColorStop(1, 'rgba(255,250,230,0)'); nx.globalCompositeOperation = 'source-atop'; nx.fillStyle = sg; nx.fillRect(0, 0, 960, 662); }
      x.save(); x.translate(W / 2, ccy); x.scale(L(.97, 1, ep), L(.97, 1, ep));
      x.globalAlpha = SM(R(ep, .5, 1));
      x.shadowColor = `rgba(20,10,0,${.5 + .35 * lo})`; x.shadowBlur = 12 + 8 * lo; x.shadowOffsetY = 4; x.drawImage(nc, -nw / 2, -nh / 2, nw, nh);
      x.shadowOffsetY = 0; x.shadowColor = 'rgba(246,215,130,.75)'; x.shadowBlur = 6 + 10 * lo + 5 * br; x.drawImage(nc, -nw / 2, -nh / 2, nw, nh); x.globalAlpha = 1;
      if (ep < 1) {
        const P = pts();
        if (P) {
          x.globalCompositeOperation = 'lighter'; x.shadowBlur = 0; const sy = (ay + 118 * s) - ccy, fade = 1 - SM(R(ep, .7, 1));
          P.forEach(p => { const t = SM(R(ep, p.d, p.d + .62)); if (t <= 0) return; const tx = -nw / 2 + p.x * nw, ty = -nh / 2 + p.y * nh, cx = L(p.ox, tx, t), cy = L(sy - p.oy, ty, t) - Math.sin(t * Math.PI) * 22; x.fillStyle = `rgba(255,236,170,${.85 * fade})`; x.beginPath(); x.arc(cx, cy, .85, 0, 6.283); x.fill(); });
        }
      }
      x.restore();
    }
    if (!compact) {
      const ta = SM(R(el, 4.8, 5.6));
      if (ta > 0) { x.save(); x.globalAlpha = ta * .75; x.textAlign = 'center'; x.direction = 'rtl'; x.font = '14px AmiriR, F2, serif'; x.fillStyle = '#CDBB8A'; x.fillText('إهداء إلى الحاج باسم الكربلائي', W / 2, Hc - 44 - (Hc - H) / 2); x.restore(); }
    }
  }

  function run(cv, compact) {
    const x = cv.getContext('2d'); let t0 = performance.now(), on = true;
    function fit() {
      const r = cv.getBoundingClientRect(), d = Math.min(3, window.devicePixelRatio || 1);
      if (cv.width !== Math.round(r.width * d) || cv.height !== Math.round(r.height * d)) { cv.width = Math.round(r.width * d); cv.height = Math.round(r.height * d); }
      return [r.width, r.height, d];
    }
    function f(t) {
      if (!on) return;
      if (!cv.isConnected) { on = false; return; }
      const [cw, ch, d] = fit(); if (!cw || !ch) { requestAnimationFrame(f); return; }
      x.setTransform(1, 0, 0, 1, 0, 0); x.clearRect(0, 0, cv.width, cv.height);
      if (compact) {
        // صندوق الشعار النهائي: x 44..316 ، y 108..516
        const k = Math.min(cw / 272, ch / 408); x.setTransform(d * k, 0, 0, d * k, d * (cw / 2 - 180 * k), d * (ch / 2 - 312 * k));
        scene(x, (t - t0) / 1000, H, true);
      } else {
        const k = Math.min(cw / W, ch / H), Hc = ch / k; x.setTransform(d * k, 0, 0, d * k, d * (cw - W * k) / 2, d * (ch - H * k) / 2);
        scene(x, (t - t0) / 1000, Hc, false);
      }
      requestAnimationFrame(f);
    }
    requestAnimationFrame(f);
    return { stop() { on = false; }, restart() { t0 = performance.now(); } };
  }
  window.Mihrab = { splash: cv => run(cv, false), mark: cv => run(cv, true) };
})();
