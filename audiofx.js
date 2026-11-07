/* منبر — محرك معالجة الصوت: تنقية ضجيج طيفية + EQ + ضغط + صدى + توحيد المستوى + محدد ناعم */
(function () {
  const PRESETS = [
    ['orig', 'الأصلي', {}],
    ['studio', 'استوديو', { bass: 2, mid: 1.5, treb: 2.5, comp: 0.5, rev: 0.06, den: 0.3, norm: true }],
    ['clear', 'صوت نقي', { bass: -2, mid: 3, treb: 3, comp: 0.4, den: 0.55, norm: true }],
    ['deep', 'باص عميق', { bass: 6, mid: 1, treb: 1, comp: 0.5, norm: true }],
    ['hall', 'صدى حسينية', { treb: 1, comp: 0.3, rev: 0.35, norm: true }],
    ['live', 'حفل مباشر', { bass: 3, treb: 2, comp: 0.6, rev: 0.2, norm: true }],
    ['radio', 'إذاعة', { bass: -4, mid: 4, treb: -1, comp: 0.8, norm: true }],
    ['denoise', 'تنقية الضجيج', { den: 0.8, comp: 0.2, norm: true }]
  ];
  const DEF = { gain: 0, bass: 0, mid: 0, treb: 0, rev: 0, comp: 0, den: 0, norm: false };
  const isOn = (p) => !!p && !!(p.gain || p.bass || p.mid || p.treb || p.rev || p.comp || p.den || p.norm);
  const tick = () => new Promise((r) => setTimeout(r, 0));

  function fft(re, im) {
    const n = re.length;
    for (let i = 1, j = 0; i < n; i++) { let bit = n >> 1; for (; j & bit; bit >>= 1) j ^= bit; j ^= bit; if (i < j) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
    for (let len = 2; len <= n; len <<= 1) {
      const ang = -2 * Math.PI / len, wr = Math.cos(ang), wi = Math.sin(ang), h = len >> 1;
      for (let i = 0; i < n; i += len) {
        let cr = 1, ci = 0;
        for (let j = 0; j < h; j++) {
          const a = i + j, b = a + h, vr = re[b] * cr - im[b] * ci, vi = re[b] * ci + im[b] * cr;
          re[b] = re[a] - vr; im[b] = im[a] - vi; re[a] += vr; im[a] += vi;
          const nc = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = nc;
        }
      }
    }
  }

  /* تنقية طيفية: نأخذ بصمة الضجيج من أهدأ الإطارات ثم نخفض الترددات القريبة منها */
  async function denoiseCh(x, amt, prog) {
    const N = 2048, H = 1024, B = N / 2 + 1, n = x.length;
    const w = new Float32Array(N); for (let i = 0; i < N; i++) w[i] = Math.sin(Math.PI * (i + 0.5) / N);
    const starts = []; for (let p = -H; p < n; p += H) starts.push(p);
    const nf = starts.length;
    // 1) طاقة كل إطار
    const en = new Float32Array(nf);
    for (let f = 0; f < nf; f++) { const p = starts[f]; let s = 0, c = 0; for (let i = 0; i < N; i += 8) { const k = p + i; if (k >= 0 && k < n) { s += x[k] * x[k]; c++; } } en[f] = c ? s / c : 0; }
    const sorted = Array.from(en).sort((a, b) => a - b);
    const thr = sorted[Math.min(nf - 1, Math.floor(nf * 0.12))];
    // 2) بصمة الضجيج
    const prof = new Float32Array(B); let pc = 0;
    const re = new Float32Array(N), im = new Float32Array(N);
    const stride = Math.max(1, Math.floor(nf / 600));
    for (let f = 0; f < nf; f += stride) {
      if (en[f] > thr) continue;
      const p = starts[f]; for (let i = 0; i < N; i++) { const k = p + i; re[i] = (k >= 0 && k < n ? x[k] : 0) * w[i]; im[i] = 0; }
      fft(re, im); for (let k = 0; k < B; k++) prof[k] += Math.hypot(re[k], im[k]); pc++;
    }
    if (!pc) return x;
    for (let k = 0; k < B; k++) prof[k] = prof[k] / pc;
    // تنعيم البصمة عبر الترددات
    const ps = new Float32Array(B); for (let k = 0; k < B; k++) { let s = 0, c = 0; for (let d = -4; d <= 4; d++) { const q = k + d; if (q >= 0 && q < B) { s += prof[q]; c++; } } ps[k] = s / c; }
    const over = 1.4 + amt * 1.6, floorG = Math.pow(10, -(10 + 22 * amt) / 20);
    // 3) المعالجة
    const out = new Float32Array(n), prev = new Float32Array(B).fill(1), g = new Float32Array(B);
    for (let f = 0; f < nf; f++) {
      const p = starts[f]; for (let i = 0; i < N; i++) { const k = p + i; re[i] = (k >= 0 && k < n ? x[k] : 0) * w[i]; im[i] = 0; }
      fft(re, im);
      for (let k = 0; k < B; k++) { const m = Math.hypot(re[k], im[k]) + 1e-9; let v = 1 - over * ps[k] / m; if (v < floorG) v = floorG; g[k] = v; }
      for (let k = 0; k < B; k++) {
        let s = g[k]; if (k > 0 && k < B - 1) s = (g[k - 1] + 2 * g[k] + g[k + 1]) / 4;
        s = 0.55 * s + 0.45 * prev[k]; prev[k] = s;
        re[k] *= s; im[k] *= s; if (k > 0 && k < B - 1) { re[N - k] *= s; im[N - k] *= s; }
      }
      for (let i = 0; i < N; i++) im[i] = -im[i];
      fft(re, im);
      for (let i = 0; i < N; i++) { const k = p + i; if (k >= 0 && k < n) out[k] += (re[i] / N) * w[i]; }
      if (f % 40 === 0) { prog && prog(f / nf); await tick(); }
    }
    return out;
  }

  function makeIR(ctx, sr, sec) {
    const len = Math.floor(sr * sec), b = ctx.createBuffer(2, len, sr);
    for (let c = 0; c < 2; c++) { const d = b.getChannelData(c); let lp = 0; for (let i = 0; i < len; i++) { const e = Math.pow(1 - i / len, 2.8); lp = lp * 0.6 + (Math.random() * 2 - 1) * 0.4; d[i] = lp * e; } }
    return b;
  }

  /* buf: AudioBuffer (لا يُعدَّل). يرجع AudioBuffer جديد بنفس الطول والمعدل */
  async function process(buf, params, onProg, cache) {
    const p = Object.assign({}, DEF, params || {});
    const sr = buf.sampleRate, len = buf.length, nch = Math.min(2, buf.numberOfChannels);
    const rep = (a, b) => onProg && onProg(a + (b - a) * 1);
    let src;
    const dq = Math.round(p.den * 10) / 10;
    if (dq > 0) {
      let chs = cache && cache.src === buf && cache.d[dq];
      if (!chs) {
        chs = [];
        for (let c = 0; c < nch; c++) chs.push(await denoiseCh(buf.getChannelData(c), dq, (v) => onProg && onProg(0.05 + 0.6 * ((c + v) / nch))));
        if (cache && cache.src === buf) cache.d[dq] = chs;
      }
      const tmp = new (window.AudioBuffer)({ length: len, numberOfChannels: 2, sampleRate: sr });
      tmp.copyToChannel(chs[0], 0); tmp.copyToChannel(chs[nch > 1 ? 1 : 0], 1); src = tmp;
    } else src = buf;
    rep(0.65, 0.65);
    const off = new OfflineAudioContext(2, len, sr), node = off.createBufferSource(); node.buffer = src;
    const hp = off.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = 35;
    const lo = off.createBiquadFilter(); lo.type = 'lowshelf'; lo.frequency.value = 110; lo.gain.value = p.bass;
    const mi = off.createBiquadFilter(); mi.type = 'peaking'; mi.frequency.value = 1800; mi.Q.value = 0.9; mi.gain.value = p.mid;
    const hi = off.createBiquadFilter(); hi.type = 'highshelf'; hi.frequency.value = 7000; hi.gain.value = p.treb;
    node.connect(hp); hp.connect(lo); lo.connect(mi); mi.connect(hi);
    let tail = hi;
    if (p.comp > 0) {
      const cp = off.createDynamicsCompressor(); cp.threshold.value = -18 - p.comp * 14; cp.knee.value = 18; cp.ratio.value = 2 + p.comp * 5; cp.attack.value = 0.01; cp.release.value = 0.22;
      const mk = off.createGain(); mk.gain.value = Math.pow(10, p.comp * 4 / 20);
      hi.connect(cp); cp.connect(mk); tail = mk;
    }
    const out = off.createGain(); out.gain.value = Math.pow(10, p.gain / 20);
    if (p.rev > 0) {
      const cv = off.createConvolver(); cv.buffer = makeIR(off, sr, 1.7); const wet = off.createGain(); wet.gain.value = p.rev * 0.9; const dry = off.createGain(); dry.gain.value = 1 - p.rev * 0.25;
      tail.connect(dry); dry.connect(out); tail.connect(cv); cv.connect(wet); wet.connect(out);
    } else tail.connect(out);
    out.connect(off.destination); node.start();
    const res = await off.startRendering();
    onProg && onProg(0.9);
    // توحيد المستوى + محدد ناعم
    const L = res.getChannelData(0), R = res.getChannelData(1);
    let gn = 1;
    if (p.norm) {
      const W = Math.floor(sr * 0.4); let sum = 0, cnt = 0;
      for (let a = 0; a + W <= len; a += W) { let s = 0; for (let i = a; i < a + W; i += 4) s += L[i] * L[i] + R[i] * R[i]; const ms = s / (W / 4) / 2; if (ms > 1e-6) { sum += ms; cnt++; } }
      if (cnt) { const rmsDb = 10 * Math.log10(sum / cnt); gn = Math.min(Math.pow(10, (-16 - rmsDb) / 20), 5); }
    }
    for (let i = 0; i < len; i++) {
      let a = L[i] * gn, b = R[i] * gn;
      if (a > 0.9 || a < -0.9) a = Math.sign(a) * (0.9 + 0.1 * Math.tanh((Math.abs(a) - 0.9) / 0.1));
      if (b > 0.9 || b < -0.9) b = Math.sign(b) * (0.9 + 0.1 * Math.tanh((Math.abs(b) - 0.9) / 0.1));
      L[i] = a; R[i] = b;
    }
    onProg && onProg(1);
    return res;
  }

  window.AFX = { PRESETS, DEF, isOn, process, _den: denoiseCh };
})();
