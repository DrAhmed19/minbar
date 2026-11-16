/* استيراد من يوتيوب (للمالك): واجهة اختيار الفيديوهات ومراجعة المسودات والقنوات المتابَعة.
   التنزيل نفسه يعمل على GitHub Actions (.github/workflows/yt-import.yml) ويحفظ مسودات فقط؛ النشر يتم من هنا بعد المراجعة. */
(function () {
  'use strict';
  let E = null, unsub = null;
  const jid = (p) => p + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  const fmt = (s) => { s = Math.round(s || 0); return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0'); };
  const norm = (s) => String(s || '').normalize('NFKD').replace(/[ً-ٰٟـ]/g, '').replace(/[أإآٱ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, '');
  const keyOf = (u) => String(u || '').replace(/^\/?media\/u\//, '');
  const stop = () => { if (unsub) { try { unsub(); } catch (e) {} unsub = null; } };
  const CATS = ['لطميات', 'قصائد', 'مراثي', 'أناشيد', 'زيارات وأدعية'];
  const db = () => E.fdb();
  const col = (n) => db().collection(n);

  async function dispatch(job, mode) {
    const tk = await E.idTok();
    const r = await fetch('api/yt/run', { method: 'POST', headers: { authorization: 'Bearer ' + tk, 'content-type': 'application/json' }, body: JSON.stringify({ job, mode }) });
    const j = await r.json().catch(() => ({}));
    if (!r.ok || !j.ok) throw new Error(j.error || ('تعذّر التشغيل (' + r.status + ')'));
  }
  function watch(bx, ref, cb) { stop(); unsub = ref.onSnapshot((s) => { if (!bx.isConnected) return stop(); if (s.exists) cb(s.data()); }, (e) => E.toast('تعذّرت متابعة المهمة: ' + (e.code || e.message))); }
  const field = (bx, ph, v) => { const i = E.el('input', 'mdin'); i.placeholder = ph; i.value = v || ''; bx.appendChild(i); return i; };
  const catSel = (bx, v) => { const s = E.el('select', 'mdin'); [...new Set(CATS.concat(E.tracks().map((x) => x.cat).filter(Boolean)))].forEach((c) => { const o = E.el('option', '', c); o.value = c; s.appendChild(o); }); s.value = v || CATS[0]; bx.appendChild(s); return s; };

  /* تصحيح تاريخ القصائد المستوردة سابقاً (التي نُشرت قبل إضافة التاريخ): يُضبط على تاريخ نشرها بيوتيوب مرة واحدة */
  let bfDone = false;
  async function backfill() {
    if (bfDone || !E.tracks().length) return; bfDone = true;
    try {
      const L = []; (await col('ytDrafts').where('status', '==', 'published').get()).forEach((x) => L.push(x.data()));
      const T = E.tracks(), ALB = E.ALB(); let n = 0;
      for (const d of L) {
        const ms = dateMs(d.ud), t = ms && d.trackId && T.find((x) => x.id === d.trackId);
        if (t && !t.atYt && t.at !== ms) { await col('tracks').doc(t.id).update({ at: ms, atYt: 1 }); t.at = ms; t.atYt = 1; n++; }
      }
      for (const a of Object.values(ALB)) { if (!a.yt) continue; const mx = Math.max(0, ...T.filter((x) => x.album === a.id && x.atYt).map((x) => x.at || 0)); if (mx && mx !== a.at) { await col('albums').doc(a.id).update({ at: mx }); a.at = mx; n++; } }
      if (n) { E.toast('صُحّح تاريخ ' + n + ' عنصر حسب تاريخ نشره بيوتيوب'); E.fsLoad(); }
    } catch (e) { bfDone = false; }
  }

  /* ---------- الرئيسية ---------- */
  function home() {
    stop(); backfill();
    E.modal('استيراد من يوتيوب', (bx, close) => {
      bx.appendChild(E.el('p', 'hint', 'ألصق رابط فيديو أو قائمة تشغيل أو قناة (يوتيوب أو يوتيوب ميوزك). تُحفظ القصائد مسودات، وتراجعها قبل النشر.'));
      const u = field(bx, 'رابط يوتيوب'); u.dir = 'ltr'; u.inputMode = 'url';
      const go = E.btn('wide primary', 'فحص الرابط', () => startList(u.value.trim(), go)); bx.appendChild(go);
      const dr = E.btn('wide', 'المسودات', () => drafts()); bx.appendChild(dr);
      try { col('ytDrafts').where('status', '==', 'draft').get().then((s) => { if (s.size) dr.textContent = 'المسودات (' + s.size + ')'; }).catch(() => {}); } catch (e) {}
      bx.appendChild(E.btn('wide', 'القنوات المتابَعة (فحص يومي تلقائي)', () => sources()));
      bx.appendChild(E.btn('wide', 'إغلاق', close));
    });
  }

  async function startList(url, goBtn) {
    if (!/(youtube\.com|youtu\.be)/i.test(url)) return E.toast('ألصق رابط يوتيوب صحيحاً');
    const id = jid('l'); goBtn.disabled = true;
    try { await col('ytJobs').doc(id).set({ mode: 'list', url, status: 'queued', phase: 'بانتظار التشغيل…', upd: Date.now() }); await dispatch(id, 'list'); }
    catch (e) { goBtn.disabled = false; return E.toast(e.message || 'فشل التشغيل'); }
    progress('فحص الرابط', id, (j) => select(id, j));
  }

  /* ---------- متابعة مهمة ---------- */
  function progress(title, id, onDone) {
    E.modal(title, (bx, close) => {
      const ph = E.el('p', 'hint cen', 'بانتظار التشغيل…'), pr = E.el('div', 'upp'), log = E.el('div', 'ytlog'); pr.innerHTML = '<i></i><span></span>'; pr.hidden = true; bx.append(ph, pr, log);
      bx.appendChild(E.btn('wide', 'إخفاء (يستمر العمل بالخلفية)', () => { stop(); close(); }));
      let fin = false;
      watch(bx, col('ytJobs').doc(id), (j) => {
        ph.textContent = (j.status === 'failed' ? '✕ ' : '') + (j.phase || '') + (j.msg ? ' — ' + j.msg : '');
        if (j.status === 'queued' && Date.now() - (j.upd || 0) > 150000) ph.textContent += ' · لم يبدأ التشغيل بعد، تحقق من تبويب Actions في GitHub';
        if (j.total) { pr.hidden = false; pr.firstChild.style.width = Math.round(100 * (j.done || 0) / j.total) + '%'; pr.lastChild.textContent = (j.done || 0) + '/' + j.total; }
        log.textContent = ''; Object.entries(j.res || {}).filter(([, r]) => r.st !== 'ok').forEach(([v, r]) => log.appendChild(E.el('div', 'ytl bad', (r.st === 'skip' ? '↷ ' : '✕ ') + v + ' — ' + r.msg)));
        ph.classList.toggle('bad', j.status === 'failed');
        if (j.status === 'failed') stop();
        if (j.status === 'done' && !fin) { fin = true; stop(); onDone(j); }
      });
    });
  }

  /* ---------- اختيار الفيديوهات ---------- */
  function select(id, j) {
    const have = new Set(E.tracks().map((t) => norm(t.title)));
    const items = (j.entries || []).map((e) => ({ e, dup: have.has(norm(e.t)), off: !!e.x || e.k === 'draft' || e.k === 'published', sel: false }));
    const pls = j.playlists || []; let pf = -1, q = '';
    E.modal('اختيار الفيديوهات', (bx, close) => {
      bx.appendChild(E.el('p', 'hint', (j.title ? j.title + ' — ' : '') + items.length + ' فيديو' + (pls.length ? ' · ' + pls.length + ' قائمة' : '')));
      const sq = field(bx, 'بحث بالعنوان'); sq.oninput = () => { q = norm(sq.value); draw(); };
      if (pls.length) { const ch = E.el('div', 'ytch'); bx.appendChild(ch); const cd = () => { ch.textContent = ''; [['كل الفيديوهات', -1]].concat(pls.map((p, i) => [p.t, i])).forEach(([t, i]) => { const b = E.el('button', pf === i ? 'on' : '', t); b.type = 'button'; b.onclick = () => { pf = i; cd(); draw(); }; ch.appendChild(b); }); }; cd(); }
      const tl = E.el('div', 'ytk'); bx.appendChild(tl);
      const shown = () => items.filter((x) => (pf < 0 || (x.e.p || []).includes(pf)) && (!q || norm(x.e.t).includes(q)));
      tl.append(E.btn('', 'تحديد المعروض', () => { shown().forEach((x) => { if (!x.off) x.sel = true; }); draw(); }), E.btn('', 'إلغاء التحديد', () => { items.forEach((x) => { x.sel = false; }); draw(); }));
      const list = E.el('div', 'ytlist'); bx.appendChild(list);
      const rec = E.pickIn(bx, 'الرادود *', j.kind === 'channel' ? (j.title || '') : '', 'reciter');
      const cat = catSel(bx);
      const sbL = E.el('label', 'ytk'), sb = E.el('input'); sb.type = 'checkbox'; sb.checked = true; sbL.append(sb, E.el('span', '', 'جلب الترجمة الأصلية إن وُجدت (كلمات مبدئية)')); bx.appendChild(sbL);
      const cnt = E.el('p', 'hint'); bx.appendChild(cnt);
      const count = () => items.filter((x) => x.sel).length;
      function draw() {
        list.textContent = ''; const S = shown();
        S.slice(0, 400).forEach((x) => {
          const r = E.el('label', 'ytr' + (x.off ? ' off' : '')), c = E.el('input'); c.type = 'checkbox'; c.checked = x.sel; c.disabled = x.off;
          c.onchange = () => { x.sel = c.checked; upd(); };
          const t = E.el('span', '', x.e.t || x.e.id), badges = [fmt(x.e.d)];
          if (x.e.k === 'published') badges.push('منشورة'); else if (x.e.k === 'draft') badges.push('مسودة'); else if (x.e.k === 'rejected') badges.push('مرفوضة سابقاً'); else if (x.e.k === 'skipped') badges.push('متخطّاة (مكررة)');
          if (x.e.x) badges.push(x.e.x); if (x.dup && !x.off) badges.push('⚠ باسمها قصيدة عندك'); if (x.e.d > 2700) badges.push('طويلة');
          t.appendChild(E.el('small', '', badges.join(' · '))); r.append(c, t); list.appendChild(r);
        });
        if (S.length > 400) list.appendChild(E.el('p', 'hint cen', 'يُعرض أول 400 من ' + S.length + ' — استعمل البحث'));
        if (!S.length) list.appendChild(E.el('p', 'hint cen', 'لا نتائج'));
        upd();
      }
      function upd() { const n = count(); cnt.textContent = n ? 'المحدد: ' + n + ' · الوقت المتوقع نحو ' + Math.max(1, Math.round(n * 0.8)) + ' دقيقة' : 'لم يُحدَّد شيء'; go.disabled = !n; }
      const go = E.btn('wide primary', 'استيراد المحدد', async () => {
        const ids = items.filter((x) => x.sel && !x.off).map((x) => x.e.id), r = rec.value.trim();
        if (!ids.length) return E.toast('حدّد فيديو واحداً على الأقل'); if (!r) return E.toast('اكتب اسم الرادود');
        if (ids.length > 120 ? !confirm('العدد كبير: يُستورد 120 الآن والباقي (' + (ids.length - 120) + ') تلقائياً على دفعات، مرتين يومياً (نحو ' + Math.ceil((ids.length - 120) / 240) + ' يوم). المتابعة؟') : ids.length > 60 && !confirm('سيستغرق الاستيراد نحو ' + Math.round(ids.length * 0.8 / 60 * 10) / 10 + ' ساعة. المتابعة؟')) return;
        go.disabled = true;
        try { await col('ytJobs').doc(id).update({ sel: ids, opts: { reciter: r, cat: cat.value, subs: !!sb.checked }, mode: 'import', status: 'queued', phase: 'بانتظار التشغيل…', msg: '', res: {}, rest: [], done: 0, total: ids.length, upd: Date.now() }); await dispatch(id, 'import'); }
        catch (e) { go.disabled = false; return E.toast(e.message || 'فشل التشغيل'); }
        progress('استيراد ' + ids.length + ' فيديو', id, (jj) => finish(jj));
      });
      bx.appendChild(go); bx.appendChild(E.btn('wide', 'رجوع', home)); draw();
    });
  }
  function finish(j) {
    E.modal('اكتمل الاستيراد', (bx, close) => {
      bx.appendChild(E.el('p', 'hint cen', j.phase || ''));
      Object.entries(j.res || {}).filter(([, r]) => r.st !== 'ok').forEach(([v, r]) => bx.appendChild(E.el('div', 'ytl bad', (r.st === 'skip' ? '↷ ' : '✕ ') + v + ' — ' + r.msg)));
      bx.appendChild(E.btn('wide primary', 'فتح المسودات', drafts)); bx.appendChild(E.btn('wide', 'إغلاق', close));
    });
  }

  /* ---------- المسودات ---------- */
  /* تاريخ النشر على يوتيوب (YYYYMMDD) ← وقت بالميلي ثانية، به تُرتَّب القصائد والإصدارات */
  const dateMs = (u) => { const m = /^(\d{4})(\d\d)(\d\d)$/.exec(String(u || '')); return m ? Date.UTC(+m[1], +m[2] - 1, +m[3], 12) : 0; };
  async function publish(d, f) {
    const ALB = E.ALB(), title = f.ti.value.trim(), reciter = f.re.value.trim(), rel = dateMs(d.ud);
    if (!title || !reciter) throw new Error('العنوان والرادود مطلوبان');
    let alb = f.al.value, coverUsed = false;
    if (alb.indexOf('new:') === 0) {
      const plid = alb.slice(4), pl = (d.pl || []).find((p) => p.id === plid) || { t: 'إصدار' }, ex = Object.values(ALB).find((a) => a.yt === plid);
      if (ex) alb = ex.id;
      else {
        alb = 'al' + Date.now().toString(36); const ad = { name: pl.t, reciter, at: rel || Date.now(), yt: plid };
        if (d.cover) { try { const b = await (await fetch(d.cover)).blob(); const r = await E.upPut('c/' + alb + Date.now().toString(36) + '.jpg', b, 'image/jpeg'); ad.cover = r.url.replace(/^\//, ''); } catch (e) {} }
        await col('albums').doc(alb).set(ad); ALB[alb] = Object.assign({ id: alb }, ad);
      }
    }
    if (alb && rel && ALB[alb] && rel > (ALB[alb].at || 0)) { await col('albums').doc(alb).update({ at: rel }); ALB[alb].at = rel; }   // الإصدار يتبع أحدث قصائده
    const id = 'k' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    const o = { title, reciter, poet: f.po.value.trim(), cat: f.cat.value, upd: Date.now(), at: rel || Date.now(), audio: d.audio, size: d.size || 0, dur: d.dur || 0, yt: d.vid };
    if (rel) o.atYt = 1;
    if (alb) o.album = alb; else if (d.cover) { o.cover = d.cover; coverUsed = true; }
    let EN = null; try { EN = await E.energyOf(await (await fetch(d.audio)).blob()); o.sample = E.bestSegE(EN); } catch (e) {}
    await col('tracks').doc(id).set(o, { merge: true });
    if (f.sb && f.sb.checked && d.subs && d.subs.length) { try { await E.lySaveText({ id, title }, d.subs.map((x) => x.l).join('\n'), o.dur, EN); } catch (e) {} }
    await col('ytDrafts').doc(d.vid).update({ status: 'published', trackId: id, albumId: alb || '', pub: Date.now() });
    if (!coverUsed && d.cover) E.upDelKey(keyOf(d.cover));
    return id;
  }
  async function reject(d) {
    const ka = keyOf(d.audio), kc = d.cover ? keyOf(d.cover) : '';
    await col('ytDrafts').doc(d.vid).update({ status: 'rejected', audio: '', cover: '', subs: [], rej: Date.now() });
    if (ka) E.upDelKey(ka); if (kc) E.upDelKey(kc);
  }
  function card(d, cards, onGone) {
    const ALB = E.ALB(), have = new Set(E.tracks().map((t) => norm(t.title))), w = E.el('div', 'ytc'), top = E.el('div', 'ytt'), g = d.g || {};
    if (d.cover) { const im = E.el('img', 'ytcv'); im.src = d.cover; im.loading = 'lazy'; im.alt = ''; top.appendChild(im); }
    const m = E.el('div'); m.appendChild(E.el('small', '', fmt(d.dur) + (d.ch ? ' · ' + d.ch : '') + (d.ud ? ' · ' + String(d.ud).replace(/(\d{4})(\d\d)(\d\d)/, '$1-$2-$3') : '')));
    m.appendChild(E.el('small', '', 'العنوان الأصلي: ' + (d.ti || ''))); top.appendChild(m); w.appendChild(top);
    const ti = field(w, 'اسم القصيدة *', g.title), re = field(w, 'الرادود *', g.reciter), po = field(w, 'الشاعر', g.poet), cat = catSel(w, g.cat);
    if (have.has(norm(ti.value))) w.appendChild(E.el('p', 'hint bad', '⚠ عندك قصيدة بهذا الاسم، تأكد قبل النشر'));
    const al = E.el('select', 'mdin'); const addO = (v, t) => { const o = E.el('option', '', t); o.value = v; al.appendChild(o); }; addO('', 'بدون إصدار (قصيدة منفردة)'); const used = new Set();
    (d.pl || []).forEach((p) => { const ex = Object.values(ALB).find((a) => a.yt === p.id); if (ex) { addO(ex.id, 'إصدار: ' + ex.name); used.add(ex.id); } else addO('new:' + p.id, 'إصدار جديد: ' + p.t); });
    Object.values(ALB).sort((a, b) => (b.at || 0) - (a.at || 0)).forEach((a) => { if (!used.has(a.id)) addO(a.id, 'إضافة إلى: ' + a.name); });
    al.selectedIndex = (d.pl || []).length ? 1 : 0; w.appendChild(al);
    const au = E.el('audio'); au.controls = true; au.preload = 'none'; au.src = d.audio; w.appendChild(au);
    let sb = null;
    if (d.subs && d.subs.length) { const l = E.el('label', 'ytk'); sb = E.el('input'); sb.type = 'checkbox'; sb.checked = d.sk === 'manual'; l.append(sb, E.el('span', '', 'استخدام الترجمة ككلمات (' + d.subs.length + ' سطر، ' + (d.sk === 'manual' ? 'أصلية' : 'آلية، قد تحتاج تصحيحاً') + ')')); w.appendChild(l); }
    const st = E.el('small', 'hint'), row = E.el('div', 'ytk'); w.append(st, row);
    const f = { ti, re, po, cat, al, sb };
    const pub = E.btn('primary', 'نشر', async () => { pub.disabled = rej.disabled = true; st.textContent = 'جارٍ النشر…'; try { await publish(d, f); w.remove(); const i = cards.indexOf(c); if (i >= 0) cards.splice(i, 1); onGone(); E.fsLoad(); } catch (e) { pub.disabled = rej.disabled = false; st.textContent = '✕ ' + (e.message || 'فشل'); } });
    const rej = E.btn('', 'رفض', async () => { if (!confirm('رفض هذه المسودة وحذف ملفاتها؟')) return; pub.disabled = rej.disabled = true; try { await reject(d); w.remove(); const i = cards.indexOf(c); if (i >= 0) cards.splice(i, 1); onGone(); } catch (e) { pub.disabled = rej.disabled = false; st.textContent = '✕ ' + (e.message || 'فشل'); } });
    row.append(pub, rej); const c = { w, pub, st, run: () => publish(d, f) }; cards.push(c); return w;
  }
  function drafts() {
    stop();
    E.modal('المسودات', (bx, close) => {
      const info = E.el('p', 'hint cen', 'جارٍ التحميل…'), list = E.el('div', 'ytlist tall'), cards = [];
      const all = E.btn('wide primary', 'نشر الكل', async () => {
        if (!confirm('نشر كل المسودات الظاهرة بالإعدادات الحالية؟')) return; all.disabled = true; let ok = 0, bad = 0;
        for (const c of cards.slice()) { try { c.st.textContent = 'جارٍ النشر…'; await c.run(); c.w.remove(); cards.splice(cards.indexOf(c), 1); ok++; } catch (e) { c.st.textContent = '✕ ' + (e.message || 'فشل'); bad++; } }
        all.disabled = false; E.toast('نُشرت ' + ok + (bad ? ' · فشل ' + bad : '')); E.fsLoad(); sync();
      });
      const sync = () => { info.textContent = cards.length ? cards.length + ' مسودة بانتظار المراجعة' : 'لا توجد مسودات'; all.style.display = cards.length ? '' : 'none'; };
      bx.append(info, all, list, E.btn('wide', 'رجوع', home)); all.style.display = 'none';
      col('ytDrafts').where('status', '==', 'draft').get().then((s) => {
        const L = []; s.forEach((x) => L.push(x.data())); L.sort((a, b) => (b.at || 0) - (a.at || 0));
        L.forEach((d) => list.appendChild(card(d, cards, sync))); sync();
      }).catch((e) => { info.textContent = 'تعذّر التحميل: ' + (e.code || e.message); });
    });
  }

  /* ---------- القنوات المتابَعة ---------- */
  function sources() {
    stop();
    E.modal('القنوات المتابَعة', (bx, close) => {
      bx.appendChild(E.el('p', 'hint', 'يفحص النظام هذه القنوات يومياً ويضيف الفيديوهات الجديدة مسودات. أول فحص لقناة جديدة يسجّل الموجود ولا يستورده؛ لاستيراد القديم استعمل «فحص الرابط» من الصفحة السابقة.'));
      const list = E.el('div', 'ytlist'); bx.appendChild(list);
      const load = () => col('ytSrc').get().then((s) => {
        list.textContent = ''; const L = []; s.forEach((x) => L.push(Object.assign({ id: x.id }, x.data()))); if (!L.length) list.appendChild(E.el('p', 'hint cen', 'لا توجد قنوات متابَعة'));
        L.forEach((x) => {
          const r = E.el('div', 'ytc'); r.appendChild(E.el('b', '', x.name || x.url)); const lm = x.last ? (x.last.msg || '') + (x.last.at ? ' · ' + new Date(x.last.at).toLocaleDateString('ar-IQ') : '') : 'لم تُفحص بعد';
          r.appendChild(E.el('small', '', (x.reciter || '') + ' · ' + (x.cat || '') + ' · ' + lm)); const row = E.el('div', 'ytk');
          row.append(E.btn('', x.auto === false ? 'تفعيل' : 'إيقاف', async () => { await col('ytSrc').doc(x.id).update({ auto: x.auto === false }); load(); }),
            E.btn('', 'حذف', async () => { if (confirm('إيقاف متابعة هذه القناة؟')) { await col('ytSrc').doc(x.id).delete(); load(); } })); r.appendChild(row); list.appendChild(r);
        });
      }).catch((e) => E.toast('تعذّر التحميل: ' + (e.code || e.message)));
      load();
      bx.appendChild(E.el('b', '', 'إضافة قناة'));
      const u = field(bx, 'رابط القناة أو قائمة التشغيل'); u.dir = 'ltr'; const n = field(bx, 'اسم القناة'), r = E.pickIn(bx, 'الرادود *', '', 'reciter'), c = catSel(bx);
      bx.appendChild(E.btn('wide primary', 'متابعة هذه القناة', async () => {
        if (!/youtube\.com\/(@|channel\/|c\/|user\/|playlist)/i.test(u.value.trim())) return E.toast('ألصق رابط قناة أو قائمة تشغيل');
        if (!r.value.trim()) return E.toast('اكتب اسم الرادود');
        try { await col('ytSrc').doc(jid('s')).set({ url: u.value.trim(), name: n.value.trim() || r.value.trim(), reciter: r.value.trim(), cat: c.value, auto: true, base: false, seen: [], at: Date.now() }); u.value = n.value = ''; E.toast('أُضيفت'); load(); } catch (e) { E.toast('تعذّرت الإضافة: ' + (e.code || e.message)); }
      }));
      bx.appendChild(E.btn('wide', 'فحص الآن', async () => {
        try { await col('ytJobs').doc('scan').set({ status: 'queued', phase: 'بانتظار التشغيل…', msg: '', upd: Date.now(), kind: 'scan' }, { merge: true }); await dispatch('scan', 'scan'); }
        catch (e) { return E.toast(e.message || 'فشل التشغيل'); }
        progress('فحص القنوات', 'scan', (j) => { E.toast(j.phase || 'اكتمل الفحص'); drafts(); });
      }));
      bx.appendChild(E.btn('wide', 'رجوع', home));
    });
  }

  window.YTIMP = { open(env) { if (!env || !env.isOwner || !env.isOwner()) return; E = env; home(); } };
})();
