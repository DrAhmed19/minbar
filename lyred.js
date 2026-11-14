/* منبر — محرر الكلمات: تجهيز النص تلقائياً + تحرير وترتيب وتدقيق مع حفظ فوري */
(function () {
  'use strict';
  const r2 = (n) => Math.round(n * 100) / 100;
  const norm = (s) => String(s || '').replace(/[ً-ٰٟـ]/g, '').replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه').replace(/[^ء-ي0-9a-zA-Z ]/g, ' ').replace(/\s+/g, ' ').trim();
  const SEP = /^[\s*\-–—_.•~=۞#]+$/;
  const words = (s) => s.split(' ').filter(Boolean);
  const MAXW = 7;

  /* تقسيم سطر طويل لأجزاء متوازنة (كل جزء maxW كلمة تقريباً) */
  function splitBal(s, maxW) {
    const ws = words(s); if (ws.length <= maxW) return [s];
    const n = Math.ceil(ws.length / maxW), total = ws.join(' ').length, out = []; let k = 0;
    for (let j = 1; j <= n; j++) {
      if (j === n) { out.push(ws.slice(k).join(' ')); break; }
      const target = total * j / n; let acc = ws.slice(0, k).join(' ').length, best = k + 1, bd = 1e9;
      for (let e = k + 1; e <= ws.length - (n - j); e++) { acc += ws[e - 1].length + 1; const d = Math.abs(acc - target); if (d < bd) { bd = d; best = e; } }
      out.push(ws.slice(k, best).join(' ')); k = best;
    }
    return out.filter(Boolean);
  }
  /* تقسيم ذكي: أولاً عند القافية (الكلمات المنتهية بنفس نهاية آخر كلمة) ثم توازن الأجزاء الطويلة */
  function splitSmart(s, maxW) {
    const ws = words(s); if (ws.length <= maxW) return [s];
    const nw = ws.map(norm), n = ws.length, grp = {}; let cuts = [];
    nw.forEach((w, i) => { if (w.length >= 3) (grp[w.slice(-2)] = grp[w.slice(-2)] || []).push(i); });
    Object.keys(grp).map((e) => ({ ix: grp[e], c: grp[e].filter((i) => nw.indexOf(nw[i]) === nw.lastIndexOf(nw[i])).length })).filter((g) => g.c >= 2).sort((a, b) => b.c - a.c).forEach((g) => g.ix.forEach((i) => { const p = i + 1; if (p < 3 || n - p < 3 || cuts.some((q) => Math.abs(q - p) < 3)) return; cuts.push(p); }));
    cuts.sort((a, b) => a - b);
    if (n <= 2 * maxW) { const m = cuts.filter((p) => p >= n * 0.35 && p <= n * 0.65).sort((a, b) => Math.abs(a - n / 2) - Math.abs(b - n / 2))[0]; cuts = m ? [m] : []; }
    if (!cuts.length) return splitBal(s, maxW);
    const out = []; let k = 0; cuts.concat([ws.length]).forEach((e) => { splitBal(ws.slice(k, e).join(' '), maxW).forEach((x) => out.push(x)); k = e; });
    return out;
  }
  /* تجهيز النص الملصوق: مقاطع (بسطر فارغ أو فاصل) ← تقسيم الأشطر والأبيات الطويلة ← اكتشاف المستهل وتوزيعه بعد كل مقطع */
  function clean(text, opt) {
    opt = opt || {}; const maxW = opt.maxW || MAXW;
    const blocks = []; let cu = [];
    String(text || '').replace(/\r/g, '').split('\n').forEach((raw) => {
      if (!raw.trim() || SEP.test(raw)) { if (cu.length) { blocks.push(cu); cu = []; } return; }
      raw.split(/\t+|\s{3,}|\s*[*|\/]+\s*|\s+\.{3,}\s+|\s+[–—]+\s+/).forEach((p) => { p = p.replace(/\s+/g, ' ').trim(); if (!p || SEP.test(p)) return; (opt.split === false ? [p] : splitSmart(p, maxW)).forEach((x) => cu.push(x)); });
    });
    if (cu.length) blocks.push(cu);
    const flat = blocks.reduce((a, b) => a.concat(b), []), nf = flat.map(norm);
    /* المستهل: أول مقطع إذا النص مقسّم لمقاطع، وإلا الأسطر الأولى التي تتكرر لاحقاً */
    let rf = 0;
    if (opt.refrain != null) rf = Math.min(opt.refrain, flat.length);
    else if (blocks.length > 1 && blocks[0].length <= 6) rf = blocks[0].length;
    else { while (rf < Math.min(6, flat.length) && nf.indexOf(nf[rf], rf + 1) > 0) rf++; }
    const refrain = flat.slice(0, rf), rn = refrain.map(norm);
    let lines = flat, added = 0;
    if (opt.spread !== false && rf && blocks.length > 1) {
      lines = [];
      blocks.forEach((b, bi) => {
        b.forEach((x) => lines.push(x));
        const bn = b.map(norm), isRf = bn.length === rn.length && bn.every((x, i) => x === rn[i]), ends = rn.length && bn.slice(-rn.length).join('|') === rn.join('|'), nx = blocks[bi + 1], nxRf = nx && norm(nx[0]) === rn[0];
        if (bi > 0 && !isRf && !ends && !nxRf) { refrain.forEach((x) => lines.push(x)); added++; }
      });
    }
    return { lines, refrain, blocks: blocks.length, added };
  }
  /* توقيت للأسطر الجديدة: نحافظ على وقت كل سطر موجود سابقاً (بالترتيب) والباقي يتوزّع بين جيرانه */
  function retime(old, lines, dur, est) {
    const pool = {}; (old || []).forEach((x) => { const k = norm(x.l); (pool[k] = pool[k] || []).push(+x.t || 0); });
    let last = -1; const ts = lines.map((l) => { const q = pool[norm(l)]; if (!q) return null; while (q.length && q[0] < last) q.shift(); if (!q.length) return null; last = q.shift(); return last; });
    const known = ts.filter((x) => x != null).length, fresh = [];
    if (!known) { const e = est ? est(lines, dur || 300) : lines.map((l, i) => ({ t: r2((dur || 300) * (0.03 + 0.94 * i / lines.length)), l })); return { arr: e.map((x) => ({ t: r2(x.t), l: x.l })), fresh: lines.map((_, i) => i) }; }
    const n = lines.length;
    for (let i = 0; i < n; i++) { if (ts[i] != null) continue; fresh.push(i); let p = i - 1; while (p >= 0 && ts[p] == null) p--; let q = i + 1; while (q < n && ts[q] == null) q++;
      const a = p >= 0 ? ts[p] : 0, b = q < n ? ts[q] : Math.min(dur || a + 4 * (n - p), a + 4 * (q - p)); ts[i] = a + (b - a) * (i - p) / (q - p); }
    return { arr: lines.map((l, i) => ({ t: r2(ts[i]), l })), fresh };
  }
  /* التدقيق: يرجّع قائمة ملاحظات لكل سطر */
  function check(arr, dur, fresh, maxW) {
    const is = {}; const add = (i, m, k) => { (is[i] = is[i] || []).push({ m, k }); };
    arr.forEach((x, i) => {
      const l = (x.l || '').trim(), p = arr[i - 1];
      if (!l || l === '…') add(i, 'بدون نص', 'txt');
      else if (l !== '♪' && words(l).length > (maxW || MAXW) + 3) add(i, 'طويل', 'long');
      if (p && x.t < p.t - 0.001) add(i, 'وقته قبل السابق', 'ord');
      else if (p && x.t - p.t < 0.4) add(i, 'ملاصق للسابق', 'gap');
      if (dur && x.t > dur) add(i, 'بعد نهاية الصوت', 'end');
      if (fresh && fresh.has(i)) add(i, 'وقت تقريبي', 'new');
    });
    return is;
  }

  function open(c) {
    const { box, t, A, el, btn, toast, fmt1 } = c, sc = c.scroll, K = 'minbar.led.' + t.id;
    let arr = (c.lines || []).map((x) => ({ t: +x.t || 0, l: x.l || '' })), sel = -1, ripple = true, follow = true, dirty = false, saving = false, saveT = 0, nowI = -2, issI = -1;
    let stt = {}; try { stt = JSON.parse(localStorage.getItem(K) || '{}'); } catch (e) {}
    let fresh = new Set(stt.fresh || []), refrain = stt.rf || null, maxW = stt.maxW || MAXW; const undo = [];
    const dur = () => (isFinite(A.duration) && A.duration) || c.dur || 0;
    const keep = () => { try { localStorage.setItem(K, JSON.stringify({ fresh: [...fresh], rf: refrain, maxW })); } catch (e) {} };
    const autoRf = () => { const nf = arr.map((x) => norm(x.l)); let n = 0; while (n < Math.min(6, arr.length) && nf.indexOf(nf[n], n + 1) > 0) n++; return arr.slice(0, n).map((x) => x.l); };
    const rfList = () => (refrain && refrain.length ? refrain : autoRf());
    /* ---------- الحفظ الفوري ---------- */
    const stEl = el('span', 'le-st', '');
    const setSt = (k) => { stEl.dataset.k = k; stEl.textContent = k === 'ok' ? '✓ محفوظ' : k === 'wait' ? '… يحفظ' : k === 'bad' ? '✕ لم يُحفظ — اضغط للإعادة' : ''; };
    stEl.onclick = () => { if (stEl.dataset.k === 'bad') flush(); };
    async function flush() { clearTimeout(saveT); if (saving) { dirty = true; return; } saving = true; dirty = false; setSt('wait'); let ok = false; try { ok = await c.save(arr.map((x) => ({ t: r2(Math.max(0, x.t)), l: (x.l || '').trim() })).filter((x) => x.l)); } catch (e) {} saving = false; if (dirty) return flush(); setSt(ok === false ? 'bad' : 'ok'); }
    const touch = () => { dirty = true; setSt('wait'); clearTimeout(saveT); saveT = setTimeout(flush, 500); keep(); };
    const snap = () => { undo.push(JSON.stringify({ a: arr, f: [...fresh] })); if (undo.length > 40) undo.shift(); ub.disabled = false; };
    /* تعديل بنيوي: نسخة للتراجع ← التغيير ← حفظ ← إعادة رسم */
    const mut = (fn, keepSel) => { snap(); const r = fn(); touch(); if (!keepSel && typeof r === 'number') sel = r; draw(); };
    /* إزاحة فهارس الأسطر التقريبية بعد إدراج/حذف */
    const shiftF = (at, d) => { fresh = new Set([...fresh].filter((i) => !(d < 0 && i === at)).map((i) => (i >= at ? i + d : i))); };
    const play = (v) => { A.currentTime = Math.max(0, v); if (A.paused) c.play(); };

    /* ---------- الرأس ---------- */
    box.textContent = ''; const root = el('div', 'le');
    const hd = el('div', 'le-hd'), cnt = el('b', 'le-cnt', ''); const ub = btn('', '↶ تراجع', () => { const s = undo.pop(); if (!s) return; const o = JSON.parse(s); arr = o.a; fresh = new Set(o.f); ub.disabled = !undo.length; sel = -1; touch(); draw(); }); ub.disabled = true;
    const fb = btn('on', 'متابعة الصوت', () => { follow = !follow; fb.classList.toggle('on', follow); });
    hd.append(cnt, stEl, fb, ub); root.appendChild(hd);
    if (c.note) root.appendChild(el('p', 'le-note', c.note));
    const tools = el('div', 'le-tools'); root.appendChild(tools);
    const pasteB = btn('primary', arr.length ? '✎ النص الكامل' : '＋ لصق الكلمات', () => { pane.hidden = !pane.hidden; if (!pane.hidden) { ta.value = ta.value || uniqText(); prev(); ta.focus(); } });
    const syncB = btn('', '☝ ضبط بالنقر', () => { if (arr.length < 2) return toast('أضف الكلمات أولاً'); const go = () => { fresh.clear(); keep(); c.sync(arr.map((x) => x.l), sel > 0 ? { ls: arr.map((x) => x.l), st2: arr.slice(0, sel).map((x) => x.t), k: sel } : null); }; if (dirty || saving) flush().then(go); else go(); });
    tools.append(pasteB, syncB);
    /* ---------- لوحة اللصق والتجهيز التلقائي ---------- */
    const pane = el('div', 'le-pane'); pane.hidden = !!arr.length; root.appendChild(pane);
    const ta = document.createElement('textarea'); ta.className = 'le-ta'; ta.rows = 7; ta.spellcheck = false; ta.placeholder = 'الصق كلمات القصيدة كما هي.\n• اترك سطراً فارغاً بين المقاطع\n• أول مقطع = المستهل (الردّة) ويتوزّع بعد كل مقطع\n• الأبيات الطويلة تنقسم تلقائياً';
    const DK = 'minbar.lyr.draft.' + t.id; try { const d = localStorage.getItem(DK); if (d) ta.value = d; } catch (e) {}
    function uniqText() { const rf = rfList().map(norm), out = []; let i = 0; if (rf.length) { arr.slice(0, rf.length).forEach((x) => out.push(x.l)); out.push(''); i = rf.length; }
      while (i < arr.length) { if (rf.length && rf.every((r, j) => arr[i + j] && norm(arr[i + j].l) === r)) { if (out[out.length - 1] !== '') out.push(''); i += rf.length; continue; } out.push(arr[i].l); i++; } while (out.length && !out[out.length - 1]) out.pop(); return out.join('\n'); }
    const o1 = el('div', 'le-opt'), o2 = el('div', 'le-opt'), pv = el('div', 'le-pv', '');
    let oSplit = true, oSpread = true, oRf = null;
    const tog = (lbl, get, set) => { const b = el('button', 'le-tg' + (get() ? ' on' : ''), lbl); b.type = 'button'; b.onclick = () => { set(!get()); b.classList.toggle('on', get()); prev(); }; return b; };
    const stp = (lbl, get, set, lo, hi) => { const w = el('div', 'le-stp'), v = el('b', '', ''), m = el('button', '', '−'), p = el('button', '', '+'); m.type = p.type = 'button'; const up = () => { v.textContent = get(); }; m.onclick = () => { set(Math.max(lo, get() - 1)); up(); prev(); }; p.onclick = () => { set(Math.min(hi, get() + 1)); up(); prev(); }; w.append(el('span', '', lbl), m, v, p); up(); w._up = up; return w; };
    const rfStp = stp('أسطر المستهل', () => (oRf == null ? clean(ta.value, { maxW, split: oSplit }).refrain.length : oRf), (v) => { oRf = v; }, 0, 8);
    o1.append(tog('تقسيم الأبيات الطويلة', () => oSplit, (v) => { oSplit = v; }), stp('كلمات السطر', () => maxW, (v) => { maxW = v; }, 4, 14));
    o2.append(tog('توزيع المستهل بعد كل مقطع', () => oSpread, (v) => { oSpread = v; }), rfStp);
    const res = () => clean(ta.value, { maxW, split: oSplit, spread: oSpread, refrain: oRf });
    function prev() { rfStp._up(); const r = res(); pv.textContent = r.lines.length ? r.lines.length + ' سطر · ' + r.blocks + ' مقطع' + (r.refrain.length ? ' · المستهل ' + r.refrain.length + ' سطر' + (r.added ? ' أُضيف ' + r.added + ' مرة' : '') : ' · بدون مستهل') : 'الصق النص بالأعلى'; }
    ta.addEventListener('input', () => { oRf = null; clearTimeout(ta._t); ta._t = setTimeout(() => { try { localStorage.setItem(DK, ta.value); } catch (e) {} prev(); }, 250); });
    const ap = el('div', 'le-row'); ap.append(btn('primary', 'تطبيق', () => { const r = res(); if (r.lines.length < 2) return toast('أدخل سطرين على الأقل'); snap(); const o = retime(arr, r.lines, dur(), c.est); arr = o.arr; fresh = new Set(o.fresh); refrain = r.refrain.length ? r.refrain : null; sel = -1; pane.hidden = true; try { localStorage.removeItem(DK); } catch (e) {} touch(); draw(); pasteB.textContent = '✎ النص الكامل';
      toast(o.fresh.length === arr.length ? 'تجهّزت ' + arr.length + ' سطر — اضبط أوقاتها بـ«ضبط بالنقر»' : o.fresh.length ? 'تم — ' + o.fresh.length + ' سطر جديد وقته تقريبي' : 'تم'); }), btn('', 'إلغاء', () => { pane.hidden = true; }));
    pane.append(ta, o1, o2, pv, ap);
    /* ---------- شريط التدقيق ---------- */
    const chk = el('div', 'le-chk'); chk.hidden = true; root.appendChild(chk);
    const list = el('div', 'le-list'); root.appendChild(list); box.appendChild(root);
    let rows = [], iss = {};
    function drawChk() {
      iss = check(arr, dur(), fresh, maxW); const ks = Object.keys(iss).map(Number); chk.textContent = ''; chk.hidden = !ks.length; if (!ks.length) return;
      const by = {}; ks.forEach((i) => iss[i].forEach((x) => { by[x.k] = (by[x.k] || 0) + 1; }));
      chk.appendChild(el('span', '', ks.length + ' سطر يحتاج نظرة'));
      chk.appendChild(btn('primary', 'التالي ↓', () => { const L = Object.keys(iss).map(Number); if (!L.length) return; issI = L.find((i) => i > issI); if (issI == null) issI = L[0]; pick(issI, true); }));
      if (by.ord || by.gap || by.end) chk.appendChild(btn('', 'رتّب الأوقات', () => mut(() => { fixOrder(); }, true)));
      if (by.long) chk.appendChild(btn('', 'قسّم الطويلة', () => mut(() => { for (let i = arr.length - 1; i >= 0; i--) if (arr[i].l !== '♪' && words(arr[i].l).length > maxW + 3) splitAt(i, splitSmart(arr[i].l, maxW)); sel = -1; }, true)));
      if (by.new) chk.appendChild(btn('', 'الأوقات مؤكدة', () => mut(() => { fresh.clear(); }, true)));
    }
    /* أي سطر وقته قبل سابقه أو ملاصق له أو بعد النهاية: يتوزّع بين أقرب جارين سليمين */
    function fixOrder() { const n = arr.length, d = dur() || 1e9, ok = arr.map(() => true); let last = -1; for (let i = 0; i < n; i++) { if (arr[i].t > d || arr[i].t < last + 0.4) ok[i] = false; else last = arr[i].t; }
      for (let i = 0; i < n; i++) { if (ok[i]) continue; let p = i - 1; while (p >= 0 && !ok[p]) p--; let q = i + 1; while (q < n && !ok[q]) q++; const a = p >= 0 ? arr[p].t : 0, b = q < n ? arr[q].t : Math.min(d, a + 4 * (q - p)); arr[i].t = r2(a + (b - a) * (i - p) / (q - p)); fresh.add(i); } }
    function splitAt(i, parts) { if (parts.length < 2) return; const a = arr[i], nt = arr[i + 1] ? arr[i + 1].t : a.t + 3 * parts.length, span = Math.max(0.5 * parts.length, Math.min(nt - a.t, 6 * parts.length)), tot = parts.join(' ').length; let acc = 0;
      const out = parts.map((p) => { const o = { t: r2(a.t + span * acc / tot), l: p }; acc += p.length + 1; return o; }); arr.splice(i, 1, ...out); shiftF(i + 1, parts.length - 1); for (let j = 1; j < parts.length; j++) fresh.add(i + j); }
    /* ---------- القائمة ---------- */
    function draw() {
      const y = sc ? sc.scrollTop : 0; list.textContent = ''; rows = []; nowI = -2; cnt.textContent = arr.length + ' سطر'; syncB.textContent = sel > 0 ? '☝ ضبط بالنقر من المحدّد' : '☝ ضبط بالنقر'; drawChk();
      const rf = new Set(rfList().map(norm));
      if (!arr.length) list.appendChild(el('p', 'le-empty', 'لا توجد كلمات بعد — الصق النص بالأعلى.'));
      arr.forEach((x, i) => {
        const r = el('div', 'le-r' + (i === sel ? ' sel' : '') + (iss[i] ? ' iss' : '') + (rf.has(norm(x.l)) ? ' rf' : '')), top = el('div', 'le-top'), tm = el('button', 'le-tm', fmt1(x.t)), tx = el('div', 'le-tx', x.l || '…');
        tm.type = 'button'; tm.onclick = (e) => { e.stopPropagation(); play(x.t); if (sel !== i) pick(i); };
        top.append(tm, tx); if (iss[i]) top.appendChild(el('i', 'le-tag', iss[i].map((q) => q.m).join(' · '))); r.appendChild(top);
        top.onclick = () => pick(sel === i ? -1 : i);
        if (i === sel) r.appendChild(panel(i, tx));
        list.appendChild(r); rows.push({ r, tm });
      });
      if (sc) { sc.scrollTop = y; requestAnimationFrame(() => { sc.scrollTop = y; }); }
      tick();
    }
    function pick(i, scroll) { sel = i; draw(); if (scroll && rows[i]) { rows[i].r.scrollIntoView({ block: 'center', behavior: 'smooth' }); } }
    const setT = (i, v) => { const d = r2(v) - arr[i].t; if (!d) return; snap(); if (ripple) for (let j = i; j < arr.length; j++) arr[j].t = r2(Math.max(0, arr[j].t + d)); else arr[i].t = r2(Math.max(0, v)); fresh.delete(i); touch();
      for (let j = i; j < (ripple ? arr.length : i + 1); j++) rows[j] && (rows[j].tm.textContent = fmt1(arr[j].t)); drawChk(); const P = rows[i] && rows[i].r.querySelector('.le-now b'); if (P) P.textContent = fmt1(arr[i].t); };
    function panel(i, tx) {
      const x = arr[i], p = el('div', 'le-p'); p.onclick = (e) => e.stopPropagation();
      /* النص */
      const te = document.createElement('textarea'); te.className = 'le-te'; te.rows = 1; te.value = x.l; te.spellcheck = false; const fit = () => { te.style.height = 'auto'; te.style.height = te.scrollHeight + 'px'; };
      let s0 = false; te.addEventListener('input', () => { if (!s0) { snap(); s0 = true; } x.l = te.value.replace(/\n/g, ' '); tx.textContent = x.l || '…'; fit(); touch(); }); te.addEventListener('blur', () => { s0 = false; drawChk(); }); p.appendChild(te); requestAnimationFrame(fit);
      /* الوقت: تقديم وتأخير */
      const tr = el('div', 'le-t'); const mk = (n, d) => { const b = el('button', '', n); b.type = 'button'; b.onclick = () => setT(i, arr[i].t + d); return b; };
      const nw = el('button', 'le-now', ''); nw.type = 'button'; nw.append(el('span', '', 'الآن'), el('b', '', fmt1(x.t))); nw.onclick = () => setT(i, A.currentTime);
      tr.append(mk('−1', -1), mk('−0.2', -0.2), nw, mk('+0.2', 0.2), mk('+1', 1)); p.appendChild(tr);
      const rp = el('div', 'le-rp'); const rb = (v, n) => { const b = el('button', ripple === v ? 'on' : '', n); b.type = 'button'; b.onclick = () => { ripple = v; rp.querySelectorAll('button').forEach((q) => q.classList.toggle('on', q === b)); }; return b; };
      rp.append(el('span', '', 'التقديم/التأخير يحرّك:'), rb(true, 'هذا وكل ما بعده'), rb(false, 'هذا السطر فقط')); p.appendChild(rp);
      /* الأدوات */
      const ac = el('div', 'le-ac'); const a = (n, lbl, fn, cls) => { const b = el('button', cls || '', ''); b.type = 'button'; b.append(el('i', '', n), el('span', '', lbl)); b.onclick = fn; ac.appendChild(b); return b; };
      a('▲', 'للأعلى', () => { if (i < 1) return; mut(() => { const s = arr[i].l; arr[i].l = arr[i - 1].l; arr[i - 1].l = s; return i - 1; }); });
      a('▼', 'للأسفل', () => { if (i >= arr.length - 1) return; mut(() => { const s = arr[i].l; arr[i].l = arr[i + 1].l; arr[i + 1].l = s; return i + 1; }); });
      a('✂', 'تقسيم', () => { const s = x.l.trim(), c0 = te.selectionStart; let parts; if (document.activeElement === te && c0 > 0 && c0 < s.length) parts = [s.slice(0, c0).trim(), s.slice(c0).trim()]; else { const ws = words(s); if (ws.length < 2) return toast('السطر قصير'); parts = splitBal(s, Math.ceil(ws.length / 2)); } if (parts.length < 2 || !parts[0] || !parts[1]) return; mut(() => { splitAt(i, parts); return i; }); });
      a('⊕', 'دمج مع التالي', () => { if (i >= arr.length - 1) return; mut(() => { arr[i].l = (arr[i].l + ' ' + arr[i + 1].l).trim(); arr.splice(i + 1, 1); shiftF(i + 1, -1); return i; }); });
      a('＋', 'سطر جديد', () => mut(() => { const nx = arr[i + 1]; arr.splice(i + 1, 0, { t: r2(nx && nx.t > x.t ? (x.t + nx.t) / 2 : x.t + 3), l: '' }); shiftF(i + 1, 1); fresh.add(i + 1); return i + 1; }));
      a('⧉', 'تكرار', () => mut(() => { const nx = arr[i + 1]; arr.splice(i + 1, 0, { t: r2(nx && nx.t > x.t ? (x.t + nx.t) / 2 : x.t + 3), l: x.l }); shiftF(i + 1, 1); fresh.add(i + 1); return i + 1; }));
      a('↻', 'مستهل بعده', () => { const rf = rfList(); if (!rf.length) return toast('حدّد المستهل أولاً: اختر أول سطر منه واضغط ★'); mut(() => { const nx = arr[i + 1], a0 = x.t, b0 = nx && nx.t > a0 ? nx.t : a0 + 3 * (rf.length + 1), n = rf.length; const ins = rf.map((l, j) => ({ t: r2(a0 + (b0 - a0) * (j + 1) / (n + 1)), l })); arr.splice(i + 1, 0, ...ins); shiftF(i + 1, n); for (let j = 1; j <= n; j++) fresh.add(i + j); return i; }); });
      a('★', 'هذا المستهل', () => { ac.hidden = true; const q = el('div', 'le-q'); q.appendChild(el('span', '', 'كم سطر المستهل من هنا؟')); [1, 2, 3, 4, 5, 6].forEach((n) => { if (i + n > arr.length) return; const b = el('button', '', String(n)); b.type = 'button'; b.onclick = () => { refrain = arr.slice(i, i + n).map((z) => z.l); keep(); toast('تحدّد المستهل (' + n + ' سطر) — «↻ مستهل بعده» يدرجه'); draw(); }; q.appendChild(b); }); const xb = el('button', '', 'إلغاء'); xb.type = 'button'; xb.onclick = () => { q.remove(); ac.hidden = false; }; q.appendChild(xb); p.appendChild(q); });
      a('♪', 'فاصل موسيقي', () => mut(() => { const nx = arr[i + 1]; arr.splice(i + 1, 0, { t: r2(nx && nx.t > x.t ? (x.t + nx.t) / 2 : x.t + 3), l: '♪' }); shiftF(i + 1, 1); return i + 1; }));
      a('✕', 'حذف', () => mut(() => { arr.splice(i, 1); shiftF(i, -1); return Math.min(i, arr.length - 1); }), 'del');
      p.appendChild(ac); return p;
    }
    /* ---------- متابعة الصوت: تظليل السطر الجاري ---------- */
    const tick = (ev) => { if (!root.isConnected) { A.removeEventListener('timeupdate', tick); if (dirty) flush(); return; } const ct = A.currentTime; let k = -1; for (let i = 0; i < arr.length; i++) { if (ct >= arr[i].t - 0.05) k = i; else break; }
      if (k === nowI) return; if (rows[nowI]) rows[nowI].r.classList.remove('now'); nowI = k; if (rows[k]) { rows[k].r.classList.add('now'); if (ev && follow && sel < 0 && !A.paused && pane.hidden) rows[k].r.scrollIntoView({ block: 'center', behavior: 'smooth' }); } };
    A.addEventListener('timeupdate', tick);
    draw(); prev(); tick();
  }
  window.LYED = { clean, retime, check, norm, open };
})();
