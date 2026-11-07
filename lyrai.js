/* منبر — التحليل الذكي للكلمات: استخراج النص من الصوت + توزيع الكلمات على التوقيت مع مراعاة التكرار */
(function (root) {
  'use strict';
  /* ---------- تطبيع النص العربي (فصحى + لهجة عراقية) ---------- */
  const TASH = /[ً-ٰٟـۖ-ۭ]/g;
  const norm = (s) => String(s || '').replace(TASH, '').replace(/[إأآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه').replace(/ؤ/g, 'و').replace(/ئ/g, 'ي')
    .replace(/[گ]/g, 'ك').replace(/[چ]/g, 'ج').replace(/[پ]/g, 'ب').replace(/[ڤ]/g, 'ف').replace(/[^ء-يa-z0-9\s]/gi, ' ').replace(/\s+/g, ' ').trim();
  /* دمج الأصوات المتقاربة: العراقي ينطق ق=گ، ك=چ، ث=ت، ذ=د، ظ/ض=د وغيرها */
  const FOLD = { 'ث': 'ت', 'ذ': 'د', 'ظ': 'د', 'ض': 'د', 'ط': 'ت', 'ص': 'س', 'ق': 'ك', 'ج': 'ك', 'غ': 'ك', 'خ': 'ح', 'ء': '', 'ه': 'ه', 'ع': 'ا' };
  const fold = (w) => { let o = ''; for (const c of w) o += (c in FOLD) ? FOLD[c] : c; return o; };
  const skel = (w) => fold(w).replace(/[اويء]/g, '');
  function lev(a, b) {
    const n = a.length, m = b.length; if (!n) return m; if (!m) return n; let p = new Array(m + 1), c = new Array(m + 1); for (let j = 0; j <= m; j++) p[j] = j;
    for (let i = 1; i <= n; i++) { c[0] = i; for (let j = 1; j <= m; j++) c[j] = Math.min(p[j] + 1, c[j - 1] + 1, p[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); const t = p; p = c; c = t; }
    return p[m];
  }
  const cache = new Map();
  function wsim(a, b) {
    if (a === b) return 1; const key = a + '|' + b, h = cache.get(key); if (h !== undefined) return h;
    const fa = fold(a), fb = fold(b); let s = 1 - lev(fa, fb) / Math.max(fa.length, fb.length, 1);
    const ka = skel(a), kb = skel(b); if (ka.length >= 2 && kb.length >= 2) s = Math.max(s, 0.96 * (1 - lev(ka, kb) / Math.max(ka.length, kb.length)));
    if (cache.size > 200000) cache.clear(); cache.set(key, s); return s;
  }
  /* ---------- مطابقة سطر مع مقطع من الكلمات المسموعة ---------- */
  const G_MIS = -0.25, G_LW = -0.4, G_AW = -0.3, MATCH_MIN = 0.55;
  function spanScores(lw, ws, i) {
    const m = lw.length, maxS = Math.min(ws.length - i, Math.ceil(m * 1.7) + 3), res = new Float32Array(maxS + 1).fill(-1e9);
    let prev = new Float32Array(maxS + 1); for (let s = 0; s <= maxS; s++) prev[s] = s * G_AW; res[0] = m * G_LW;
    for (let a = 1; a <= m; a++) {
      const cur = new Float32Array(maxS + 1); cur[0] = prev[0] + G_LW;
      for (let s = 1; s <= maxS; s++) { const sm = wsim(lw[a - 1], ws[i + s - 1]), g = sm >= MATCH_MIN ? sm : G_MIS; cur[s] = Math.max(prev[s - 1] + g, prev[s] + G_LW, cur[s - 1] + G_AW); }
      prev = cur;
    }
    for (let s = 0; s <= maxS; s++) res[s] = prev[s]; return res;
  }
  /* تقسيم البيت إلى أشطر إذا فيه فاصل (* أو … أو | أو - أو مسافات كثيرة) */
  const SEP = /\s*(?:\*+|…|\.{3,}|\||\s[-–—]\s|\t|\s{3,}|\/\/)\s*/;
  function units(lines) {
    const U = []; lines.forEach((l, k) => { const ps = String(l).split(SEP).map((s) => s.trim()).filter(Boolean); const ok = ps.length > 1 && ps.every((s) => norm(s).split(' ').filter(Boolean).length >= 2); (ok ? ps : [String(l).trim()]).forEach((s, q, a) => U.push({ text: s, k, q, n: ok ? a.length : 1 })); }); return U;
  }
  /**
   * lines: ['نص السطر', ...]   words: [{w, t0, t1}] من التعرف على الصوت
   * يرجع out: [{t, l, k, conf, rep, part}] بترتيب الأداء — يشمل إعادة الأبيات أو الأشطر
   * الحالة = (آخر شطر قُرئ، أبعد شطر وصلنا له) حتى نعرف الرجوع للتكرار ثم إكمال القصيدة من حيث توقفت
   */
  function align(lines, words, opt) {
    opt = opt || {}; const K = lines.length; if (!K) return { out: [], stats: {} };
    const UN = units(lines), U = UN.length, LW = UN.map((u) => norm(u.text).split(' ').filter(Boolean));
    const keep = []; words.forEach((x, i) => { if (norm(x.w)) keep.push(i); }); const W = keep.map((i) => norm(words[i].w)), T = keep.map((i) => words[i]), N = W.length;
    if (!N) return { out: lines.map((l, k) => ({ t: k * 3, l, k, conf: 0, rep: false })), stats: { sung: 0, low: K, missing: K } };
    const SKIP = -0.05, OCC = 0.75, BEAM = opt.beam || 260, R = U + 1;
    const SC = new Array(U); const getS = (u, i) => { const a = SC[u] || (SC[u] = new Array(N)); return a[i] || (a[i] = LW[u].length ? spanScores(LW[u], W, i) : new Float32Array(1).fill(-1e9)); };
    const minOcc = LW.map((w) => Math.max(0.5, 0.38 * w.length));
    const f = new Array(N + 1); for (let j = 0; j <= N; j++) f[j] = new Map(); f[0].set(0, { v: 0, b: null });
    const put = (j, key, v, b) => { const o = f[j].get(key); if (!o || v > o.v) f[j].set(key, { v, b }); };
    for (let j = 0; j <= N; j++) {
      let ents = [...f[j].entries()]; if (!ents.length) continue; ents.sort((a, b) => b[1].v - a[1].v); const top = ents[0][1].v; ents = ents.slice(0, BEAM).filter((e) => e[1].v >= top - 22); f[j] = new Map(ents);
      if (j === N) break;
      for (const [key, o] of ents) put(j + 1, key, o.v + SKIP, { s: 1, key });
      const cand = new Map();
      for (const [key, o] of ents) {
        const p = Math.floor(key / R), m = key % R;
        for (let u1 = 1; u1 <= U; u1++) {
          let pr, nk;
          if (u1 > m) { pr = u1 === m + 1 ? 0 : -0.8 - 0.55 * Math.min(u1 - m - 2, 6); nk = u1 * R + u1; }
          else { if (u1 === p + 1) pr = -0.2; else if (u1 === p) pr = -0.35; else pr = m - u1 <= 14 ? -0.95 : -1.35; nk = u1 * R + m; }
          const v = o.v + pr, c = cand.get(nk); if (!c || v > c.v) cand.set(nk, { v, key });
        }
      }
      for (const [nk, c] of cand) {
        const u = Math.floor(nk / R) - 1, sc = getS(u, j), mo = minOcc[u];
        for (let s = 1; s < sc.length; s++) { const x = sc[s]; if (x < mo) continue; put(j + s, nk, c.v + x - OCC, { s: 0, key: c.key, u, st: j, en: j + s, sc: x }); }
      }
    }
    let bk = 0, bv = -1e18; for (const [k, o] of f[N]) if (o.v > bv) { bv = o.v; bk = k; }
    const occ = []; let j = N, key = bk;
    while (j > 0) { const o = f[j].get(key); if (!o || !o.b) break; const b = o.b; if (b.s) { j -= 1; key = b.key; } else { occ.push(b); j = b.st; key = b.key; } }
    occ.reverse();
    let res = occ.map((o) => ({ t: T[o.st].t0, t1: T[o.en - 1].t1, u: o.u, conf: +Math.max(0, Math.min(1, o.sc / LW[o.u].length)).toFixed(2), seen: true }));
    /* أشطر لم تُسمع → توقيت تقديري بين جيرانها */
    const seenU = new Set(res.map((r) => r.u)), chars = (u) => Math.max(4, norm(UN[u].text).length), filled = [];
    const fillB = (us, a, b) => { const tot = us.reduce((s, u) => s + chars(u), 0); let t = a; us.forEach((u) => { filled.push({ t, t1: t + 0.1, u, conf: 0, seen: false }); t += (b - a) * chars(u) / tot; }); };
    const lead = []; for (let u = 0; u < U && !seenU.has(u); u++) lead.push(u);
    if (lead.length && res.length) fillB(lead, Math.max(0, res[0].t - 3.2 * lead.length), res[0].t - 0.2);
    res.forEach((o, ix) => {
      filled.push(o); const nx = res[ix + 1], hi = nx ? nx.u : U; const us = []; for (let u = o.u + 1; u < hi; u++) if (!seenU.has(u)) { us.push(u); seenU.add(u); }
      if (us.length) fillB(us, o.t1 + 0.25, nx ? Math.max(o.t1 + 0.6, nx.t - 0.15) : o.t1 + 0.6 + 3.2 * us.length);
    });
    res = filled;
    /* دمج أشطر البيت المتتالية في سطر واحد؛ والشطر المعاد وحده يبقى سطراً مستقلاً */
    const out = [], seenK = new Set(), seenL = new Set();
    for (let i = 0; i < res.length; i++) {
      const a = res[i], ua = UN[a.u]; let parts = [a], q = ua.q;
      while (i + 1 < res.length && UN[res[i + 1].u].k === ua.k && UN[res[i + 1].u].q === q + 1) { i++; parts.push(res[i]); q++; }
      const whole = ua.q === 0 && parts.length === ua.n, txt = whole ? String(lines[ua.k]).trim() : parts.map((x) => UN[x.u].text).join(' ');
      const id = whole ? 'k' + ua.k : parts.map((x) => x.u).join(','); const rep = seenL.has(id) || (seenK.has(ua.k) && !whole) || (whole && seenK.has(ua.k));
      seenL.add(id); seenK.add(ua.k);
      out.push({ t: a.t, l: txt, k: ua.k, conf: +(parts.reduce((s, x) => s + x.conf, 0) / parts.length).toFixed(2), rep, part: !whole, seen: parts.some((x) => x.seen) });
    }
    let last = -1; out.forEach((o) => { let t = Math.max(0, o.t - (o.seen ? 0.12 : 0)); if (t <= last) t = last + 0.05; o.t = +t.toFixed(2); last = o.t; });
    return { out, occ: occ.map((o) => [o.u, o.st, o.en, +o.sc.toFixed(2)]), stats: { sung: new Set(occ.map((o) => UN[o.u].k)).size, low: out.filter((o) => o.conf < 0.45).length, repeats: out.filter((o) => o.rep).length, missing: K - new Set(occ.map((o) => UN[o.u].k)).size } };
  }
  /* ---------- استخراج أسطر من النص المسموع عند عدم وجود كلمات ---------- */
  const HALL = /(اشترك|الاشتراك|القناة|ترجمة|نانسي|قنقر|شكرا للمشاهدة|المشاهدة|موسيقى|subscribe|www|http)/i;
  function clean(words) {
    const o = []; let run = 0;
    words.forEach((x) => { const w = String(x.w || '').trim(); if (!w || HALL.test(w)) return; const nw = norm(w); if (!nw) return; const pv = o[o.length - 1]; if (pv && norm(pv.w) === nw) { run++; if (run >= 3) return; } else run = 0; o.push({ w, t0: x.t0, t1: x.t1 }); });
    return o;
  }
  function extract(words, opt) {
    opt = opt || {}; const ws = clean(words); if (!ws.length) return [];
    const gaps = []; for (let i = 1; i < ws.length; i++) gaps.push(ws[i].t0 - ws[i - 1].t1); const sg = gaps.slice().sort((a, b) => a - b);
    const gap = Math.max(0.55, Math.min(1.4, (sg[Math.floor(sg.length * 0.82)] || 0.8))), maxW = opt.maxWords || 8, maxD = opt.maxDur || 7.5, lines = []; let cur = null;
    ws.forEach((x, i) => { if (cur && ((x.t0 - cur.t1) >= gap || cur.n >= maxW || x.t1 - cur.t0 > maxD)) { lines.push(cur); cur = null; } if (!cur) cur = { t: x.t0, t1: x.t1, ws: [], n: 0 }; cur.ws.push(x.w); cur.n++; cur.t1 = x.t1; });
    if (cur) lines.push(cur);
    /* دمج سطر قصير جداً مع جاره */
    for (let i = lines.length - 1; i > 0; i--) if (lines[i].n <= 1 && lines[i].t - lines[i - 1].t1 < gap * 1.6 && lines[i - 1].n < maxW + 2) { lines[i - 1].ws.push(...lines[i].ws); lines[i - 1].n += lines[i].n; lines[i - 1].t1 = lines[i].t1; lines.splice(i, 1); }
    const out = []; lines.forEach((c) => {
      let l = c.ws.join(' '), rep = false; const nl = norm(l);
      for (let k = out.length - 1; k >= 0; k--) { const a = norm(out[k].l); if (Math.abs(a.length - nl.length) <= Math.max(3, nl.length * 0.25) && 1 - lev(fold(a), fold(nl)) / Math.max(a.length, nl.length, 1) >= 0.78) { rep = true; l = out[k].l; break; } }
      out.push({ t: +Math.max(0, c.t - 0.1).toFixed(2), l, conf: 0.5, rep, seen: true });
    });
    return out;
  }
  /* ================= توزيع على مستوى الجملة الملحّنة (أدق مع أخطاء السماع) ================= */
  const flat = (s) => fold(norm(s)).replace(/ /g, '');
  const sk2 = (s) => flat(s).replace(/[اويه]/g, '');
  function fitLev(a, b) { /* أقل كلفة لمطابقة a كاملة مع أي جزء من b */
    const n = a.length, m = b.length; if (!n) return 0; let p = new Array(m + 1).fill(0), c = new Array(m + 1);
    for (let i = 1; i <= n; i++) { c[0] = i; for (let j = 1; j <= m; j++) c[j] = Math.min(p[j] + 1, c[j - 1] + 1, p[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1)); const t = p; p = c; c = t; }
    let best = n; for (let j = 0; j <= m; j++) best = Math.min(best, p[j]); return best;
  }
  const simC = new Map();
  function csim(a, b) {
    const key = a + '\u0001' + b, h = simC.get(key); if (h !== undefined) return h; let best = 0;
    [[flat(a), flat(b), 1], [sk2(a), sk2(b), 0.95]].forEach(([x, y, w]) => {
      if (!x.length || !y.length) return; const r = 1 - lev(x, y) / Math.max(x.length, y.length);
      const sh = x.length <= y.length ? x : y, lg = x.length <= y.length ? y : x, f = (1 - fitLev(sh, lg) / sh.length) * Math.min(1, Math.pow(sh.length / lg.length, 0.35));
      best = Math.max(best, w * (0.45 * r + 0.55 * f));
    });
    if (simC.size > 300000) simC.clear(); simC.set(key, best); return best;
  }
  /* تقسيم الجمل الطويلة عند أطول وقفة */
  function phrases(segs) {
    const out = []; const push = (t0, t1, text, ws) => { if (norm(text)) out.push({ t0, t1, text, ws }); };
    segs.forEach((s) => {
      const ws = (s.words || []).filter((w) => norm(w.w)); const n = norm(s.text).split(' ').filter(Boolean).length;
      if (ws.length >= 9 && s.t1 - s.t0 > 7) { let bi = -1, bg = 0.35; for (let i = 3; i < ws.length - 3; i++) { const g = ws[i].t0 - ws[i - 1].t1; if (g > bg) { bg = g; bi = i; } } if (bi > 0) { const A = ws.slice(0, bi), B = ws.slice(bi); push(s.t0, A[A.length - 1].t1, A.map((w) => w.w).join(' '), A); push(B[0].t0, s.t1, B.map((w) => w.w).join(' '), B); return; } }
      void n; push(s.t0, s.t1, s.text, ws);
    });
    return out;
  }
  function alignP(lines, segs, opt) {
    opt = opt || {}; const K = lines.length; if (!K) return { out: [], stats: {} };
    const UN = units(lines), U = UN.length, P = phrases(segs), N = P.length, R = U + 1;
    if (!N) return { out: lines.map((l, k) => ({ t: k * 3, l, k, conf: 0, rep: false, seen: false })), stats: { sung: 0, missing: K } };
    const W = 4, BASE = opt.base != null ? opt.base : 0.3, SKP = -0.35, BEAM = 220;
    const txtU = (u, d) => UN.slice(u, u + d).map((x) => x.text).join(' '), txtP = (j, c) => P.slice(j, j + c).map((x) => x.text).join(' ');
    const score = (u, d, j, c) => W * (csim(txtU(u, d), txtP(j, c)) - BASE) - 0.25 * (d - 1) - 0.3 * (c - 1);
    const f = new Array(N + 1); for (let j = 0; j <= N; j++) f[j] = new Map(); f[0].set(0, { v: 0, b: null });
    const put = (j, key, v, b) => { const o = f[j].get(key); if (!o || v > o.v) f[j].set(key, { v, b }); };
    const prior = (p, m, u1) => { if (u1 > m) return u1 === m + 1 ? 0 : -1.2 - 0.9 * Math.min(u1 - m - 2, 6); if (u1 === p + 1) return -0.25; if (u1 === p) return -0.45; return m - u1 <= 16 ? -0.9 : -1.4; };
    for (let j = 0; j < N; j++) {
      let ents = [...f[j].entries()]; if (!ents.length) continue; ents.sort((a, b) => b[1].v - a[1].v); ents = ents.slice(0, BEAM); f[j] = new Map(ents);
      for (const [key, o] of ents) put(j + 1, key, o.v + SKP, { s: 1, key });
      const cand = new Map();
      for (const [key, o] of ents) { const p = Math.floor(key / R), m = key % R; for (let u1 = 1; u1 <= U; u1++) { const v = o.v + prior(p, m, u1), c = cand.get(u1 * R + m) || null; const nk = u1 * R + m; if (!c || v > c.v) cand.set(nk, { v, key, m }); } }
      for (const [nk, c] of cand) {
        const u = Math.floor(nk / R) - 1;
        for (let d = 1; d <= 3 && u + d <= U; d++) for (let cc = 1; cc <= 2 && j + cc <= N; cc++) {
          if (d > 1 && cc > 1) continue; const sc = score(u, d, j, cc), last = u + d, mm = Math.max(c.m, last);
          put(j + cc, last * R + mm, c.v + sc - (d > 1 ? 0 : 0), { s: 0, key: c.key, u, d, j, c: cc, sc });
        }
      }
    }
    let bk = 0, bv = -1e18; for (const [k, o] of f[N]) if (o.v > bv) { bv = o.v; bk = k; }
    const occ = [], skipped = []; let j = N, key = bk;
    while (j > 0) { const o = f[j].get(key); if (!o || !o.b) break; const b = o.b; if (b.s) { skipped.push(j - 1); j -= 1; key = b.key; } else { occ.push(b); j = b.j; key = b.key; } }
    occ.reverse(); skipped.reverse();
    /* أوقات كل شطر */
    let res = [];
    occ.forEach((o) => {
      const t0 = P[o.j].t0, t1 = P[o.j + o.c - 1].t1, conf = +Math.max(0, Math.min(1, csim(txtU(o.u, o.d), txtP(o.j, o.c)))).toFixed(2);
      if (o.d === 1) { res.push({ t: t0, t1, u: o.u, conf, seen: true }); return; }
      const ch = []; for (let q = 0; q < o.d; q++) ch.push(Math.max(3, flat(UN[o.u + q].text).length)); const tot = ch.reduce((a, b) => a + b, 0), ws = P[o.j].ws || [];
      let acc = 0; for (let q = 0; q < o.d; q++) { let t = t0 + (t1 - t0) * acc / tot; if (q && ws.length > 2) { const target = t; let bw = null, bd = 9; ws.forEach((w, i) => { if (!i) return; const g = w.t0 - ws[i - 1].t1, dd = Math.abs(w.t0 - target); if (dd < 1.6 && g >= 0 && (dd - g * 2) < bd) { bd = dd - g * 2; bw = w; } }); if (bw) t = bw.t0; } res.push({ t, t1: t0 + (t1 - t0) * (acc + ch[q]) / tot, u: o.u + q, conf, seen: true }); acc += ch[q]; }
    });
    /* أشطر لم تُطابق: توضع على الجمل المسموعة غير المستعملة بينها، وإلا بتوزيع تقديري */
    const seenU = new Set(res.map((r) => r.u)), freeP = skipped.map((i) => P[i]);
    const fill = (us, a, b) => { const fp = freeP.filter((p) => p.t0 >= a - 0.05 && p.t0 < b); if (fp.length >= us.length) { const step = fp.length / us.length; return us.map((u, q) => ({ t: fp[Math.floor(q * step)].t0, t1: fp[Math.floor(q * step)].t1, u, conf: 0.2, seen: true })); } const tot = us.length; return us.map((u, q) => ({ t: a + (b - a) * q / tot, t1: a + (b - a) * (q + 1) / tot, u, conf: 0, seen: false })); };
    const outR = []; const lead = []; for (let u = 0; u < U && !seenU.has(u); u++) { lead.push(u); seenU.add(u); }
    if (lead.length) outR.push(...fill(lead, 0, res.length ? res[0].t - 0.2 : P[N - 1].t1));
    res.forEach((o, ix) => { outR.push(o); const nx = res[ix + 1], hi = nx ? nx.u : U, us = []; for (let u = o.u + 1; u < hi; u++) if (!seenU.has(u)) { us.push(u); seenU.add(u); } if (us.length) outR.push(...fill(us, o.t1 + 0.1, nx ? nx.t - 0.1 : Math.max(o.t1 + 2 * us.length, P[N - 1].t1))); });
    /* دمج الأشطر */
    const out = [], seenK = new Set(), seenL = new Set();
    for (let i = 0; i < outR.length; i++) {
      const a = outR[i], ua = UN[a.u], parts = [a]; let q = ua.q;
      while (i + 1 < outR.length && UN[outR[i + 1].u].k === ua.k && UN[outR[i + 1].u].q === q + 1) { i++; parts.push(outR[i]); q++; }
      const whole = ua.q === 0 && parts.length === ua.n, txt = whole ? String(lines[ua.k]).trim() : parts.map((x) => UN[x.u].text).join(' '), id = whole ? 'k' + ua.k : parts.map((x) => x.u).join(',');
      const rep = seenL.has(id) || seenK.has(ua.k); seenL.add(id); seenK.add(ua.k);
      out.push({ t: a.t, l: txt, k: ua.k, conf: +(parts.reduce((s, x) => s + x.conf, 0) / parts.length).toFixed(2), rep, part: !whole, seen: parts.some((x) => x.seen) });
    }
    for (let i = out.length - 1; i >= 0; i--) if (out[i].rep && out[i].conf < 0.4) out.splice(i, 1);
    let last = -1; out.forEach((o) => { let t = Math.max(0, o.t - 0.15); if (t <= last) t = last + 0.05; o.t = +t.toFixed(2); last = o.t; });
    const sung = new Set(occ.flatMap((o) => Array.from({ length: o.d }, (_, q) => UN[o.u + q].k)));
    return { out, stats: { sung: sung.size, low: out.filter((o) => o.conf < 0.4).length, repeats: out.filter((o) => o.rep).length, missing: K - sung.size, phrases: N } };
  }
  /* استخراج من الجمل المسموعة */
  const BADC = /[^؀-ۿ\s\d.,،؟!:]/;
  function cleanSegs(segs) {
    const o = []; segs.forEach((s) => { let tx = String(s.text || '').trim(); if (!tx || BADC.test(tx.replace(/[a-z]/gi, 'x')) && /[^؀-ۿ\s]{2,}/.test(tx)) { tx = tx.replace(/[^؀-ۿ\s]/g, '').trim(); } if (!tx || HALL.test(tx) || norm(tx).length < 2) return;
      tx = tx.replace(/(\S+)(\s+\1){3,}/g, '$1 $1').replace(/(.{1,4}?)\1{3,}/g, '$1$1').split(/\s+/).filter((w) => w.length <= 16).join(' ').trim(); if (!tx || tx.length / Math.max(0.5, s.t1 - s.t0) > 30) return; const pv = o[o.length - 1]; if (pv && norm(pv.text) === norm(tx) && s.t0 - pv.t1 < 0.3) { pv.t1 = s.t1; return; } o.push({ t0: s.t0, t1: s.t1, text: tx, words: (s.words || []).filter((w) => !HALL.test(w.w)) }); });
    return o;
  }
  function extractP(segs) {
    const P = phrases(cleanSegs(segs)), out = [];
    P.forEach((c) => { let l = c.text.trim(), rep = false; const nl = flat(l); for (let k = out.length - 1; k >= 0; k--) { const a = flat(out[k].l); if (a && nl && csim(out[k].l, l) >= 0.72 && Math.abs(a.length - nl.length) <= Math.max(4, nl.length * 0.35)) { rep = true; l = out[k].l; break; } } out.push({ t: +Math.max(0, c.t0 - 0.1).toFixed(2), l, conf: 0.5, rep, seen: true }); });
    return out;
  }
  /* ---------- تحويل مقاطع بلا كلمات إلى كلمات بتوزيع متساوٍ (احتياط) ---------- */
  function segsToWords(segs) {
    const out = []; segs.forEach((s) => { const ws = String(s.text || '').trim().split(/\s+/).filter(Boolean), a = s.timestamp[0] || 0, b = s.timestamp[1] != null ? s.timestamp[1] : a + ws.length * 0.4; ws.forEach((w, i) => out.push({ w, t0: a + (b - a) * i / ws.length, t1: a + (b - a) * (i + 1) / ws.length })); }); return out;
  }
  /* ---------- الصوت: فك الترميز وتجهيزه للتعرف (أحادي 16k، تقليل الطبل والجهير) ---------- */
  async function prepAudio(url, prog) {
    const buf = await (await fetch(url)).arrayBuffer(); prog && prog('فك ترميز الصوت', 0.05);
    const AC = root.AudioContext || root.webkitAudioContext, ctx = new AC(); const dec = await ctx.decodeAudioData(buf); ctx.close && ctx.close();
    const off = new OfflineAudioContext(1, Math.ceil(dec.duration * 16000), 16000), src = off.createBufferSource(); src.buffer = dec;
    const hp = off.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 140; const lp = off.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 5200;
    src.connect(hp); hp.connect(lp); lp.connect(off.destination); src.start(); const r = await off.startRendering(); const d = r.getChannelData(0);
    let pk = 0; for (let i = 0; i < d.length; i += 7) pk = Math.max(pk, Math.abs(d[i])); const g = pk > 0 ? 0.9 / pk : 1; const o = new Float32Array(d.length); for (let i = 0; i < d.length; i++) o[i] = d[i] * g; return o;
  }
  const MODELS = { fast: ['onnx-community/whisper-base', 'Xenova/whisper-base'], good: ['onnx-community/whisper-small', 'Xenova/whisper-small'], best: ['onnx-community/whisper-large-v3-turbo', 'onnx-community/whisper-large-v3-turbo_timestamped'] };
  let asr = null, asrKey = '';
  async function loadAsr(q, prog) {
    const q0 = q;
    if (asr && asrKey === q) return asr; if (asr) { try { await asr.dispose(); } catch (e) {} asr = null; asrKey = ''; }
    let tf; try { tf = await import('https://cdn.jsdelivr.net/npm/@huggingface/transformers@3/dist/transformers.min.js'); } catch (e) { tf = await import('https://esm.sh/@huggingface/transformers@3'); }
    const env = tf.env; env.allowLocalModels = false;
    let dev = 'wasm'; try { if (root.navigator && navigator.gpu && await navigator.gpu.requestAdapter()) dev = 'webgpu'; } catch (e) {}
    if (dev === 'wasm') { try { env.backends.onnx.wasm.proxy = true; } catch (e) {} if (q === 'best') q = 'good'; }
    const mem = (root.navigator && navigator.deviceMemory) || 8; if (q === 'best' && mem < 6) q = 'good';
    const files = {}; let shown = 0;
    const pc = (p) => { if (!p || !p.file) return; const f = files[p.file] || (files[p.file] = { l: 0, t: 0 }); if (p.status === 'progress') { f.l = p.loaded || 0; f.t = p.total || f.t; } if (p.status === 'done') f.l = f.t = Math.max(f.t, f.l, 1); let L = 0, T = 0; Object.values(files).forEach((x) => { L += x.l; T += x.t; }); const v = T ? L / T : 0; if (v >= shown) { shown = v; prog && prog('تحميل النموذج ' + Math.round(v * 100) + '% (مرة واحدة)', 0.05 + 0.25 * v); } };
    let err = null;
    for (const id of MODELS[q] || MODELS.good) {
      try { asr = await tf.pipeline('automatic-speech-recognition', id, { device: dev, dtype: dev === 'webgpu' ? { encoder_model: q === 'best' ? 'fp16' : 'fp32', decoder_model_merged: 'q4' } : 'q8', progress_callback: pc }); asrKey = q0; return asr; } catch (e) { err = e; }
    }
    throw err || new Error('model');
  }
  /* تقطيع بلا تداخل عند أهدأ نقطة، حتى لا تتكرر القراءة */
  function cuts(pcm, SR) {
    const fr = Math.floor(SR * 0.05), nF = Math.floor(pcm.length / fr), en = new Float32Array(nF);
    for (let f = 0; f < nF; f++) { let s = 0; for (let i = f * fr; i < (f + 1) * fr; i += 2) s += pcm[i] * pcm[i]; en[f] = s; }
    const out = [0]; let s = 0; const W = Math.floor(28 / 0.05), MIN = Math.floor(20 / 0.05);
    while (s + W < nF) { let bi = s + W, bv = Infinity; for (let f = s + MIN; f <= s + W; f++) { const v = en[f] + (f > 0 ? en[f - 1] : 0) + (f + 1 < nF ? en[f + 1] : 0); if (v < bv) { bv = v; bi = f; } } out.push(bi * fr); s = bi; }
    out.push(pcm.length); return out;
  }
  /** يرجع جملاً مسموعة [{t0,t1,text,words}] */
  async function transcribe(url, quality, prog, stop, part) {
    const pcm = await prepAudio(url, prog); if (stop && stop()) throw new Error('cancel');
    const asrp = await loadAsr(quality || 'good', prog), SR = 16000, C = cuts(pcm, SR); let segs = [], w0 = 0;
    /* استئناف: لو انقطع التحليل (خروج من التطبيق) نكمل من آخر مقطع محفوظ */
    try { const sv = part && part.get(); if (sv && sv.n === C.length && Array.isArray(sv.segs)) { segs = sv.segs; w0 = sv.w; } } catch (e) {}
    for (let w = w0; w < C.length - 1; w++) {
      if (part) try { part.put({ n: C.length, w, segs }); } catch (e) {}
      prog && prog('الاستماع للقصيدة', 0.3 + 0.68 * w / (C.length - 1), { i: w, n: C.length - 1 });
      if (stop && stop()) throw new Error('cancel');
      const a = C[w], b = C[w + 1], off = a / SR, end = b / SR;
      await new Promise((rs) => setTimeout(rs, 40));
      let r; try { r = await asrp(pcm.subarray(a, b), { language: 'arabic', task: 'transcribe', return_timestamps: true, max_new_tokens: 160, repetition_penalty: 1.08 }); } catch (x) { r = await asrp(pcm.subarray(a, b), { language: 'arabic', task: 'transcribe' }); r.chunks = [{ text: r.text, timestamp: [0, (b - a) / SR] }]; }
      const ch = r.chunks || [];
      ch.forEach((c, i) => { const s0 = (c.timestamp && c.timestamp[0] != null ? c.timestamp[0] : 0) + off; let s1 = c.timestamp && c.timestamp[1] != null ? c.timestamp[1] + off : (ch[i + 1] && ch[i + 1].timestamp ? ch[i + 1].timestamp[0] + off : end); s1 = Math.min(end, Math.max(s0 + 0.3, s1)); const text = String(c.text || '').trim(); if (text && s0 < end) segs.push({ t0: s0, t1: s1, text }); });
    }
    segs.forEach((s) => { s.words = segsToWords([{ text: s.text, timestamp: [s.t0, s.t1] }]).map((x) => ({ w: x.w, t0: x.t0, t1: x.t1 })); });
    prog && prog('تم', 1); return cleanSegs(segs);
  }
  /* تحرير ذاكرة النموذج بعد الانتهاء حتى لا يغلق النظام الصفحة بالخلفية */
  async function free() { if (asr) { try { await asr.dispose(); } catch (e) {} asr = null; asrKey = ''; } }
  root.LYAI = { norm, wsim, align, alignP, extract, extractP, cleanSegs, csim, phrases, clean, units, transcribe, segsToWords, free };
  if (typeof module !== 'undefined') module.exports = root.LYAI;
})(typeof window !== 'undefined' ? window : globalThis);
