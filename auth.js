/* منبر: تسجيل مسبق + دخول Google + لوحة اختيار المجرّبين (Firebase) */
(function () {
  const C = window.MINBAR_FB || {};
  const A = { enabled: !!(C.apiKey && C.projectId && window.firebase), admin: false };
  window.MinbarAuth = A;
  if (!A.enabled) return;
  firebase.initializeApp(C);
  const auth = firebase.auth(), db = firebase.firestore();
  const $ = (id) => document.getElementById(id);
  const pane = (id) => ['gLoad', 'gSign', 'gForm', 'gWait'].forEach((x) => { $(x).hidden = x !== id; });
  let cb = {};
  const say = (m) => cb.toast && cb.toast(m);
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };

  A.signOut = () => auth.signOut();
  async function signIn() {
    const p = new firebase.auth.GoogleAuthProvider(); p.setCustomParameters({ prompt: 'select_account' });
    try { await auth.signInWithPopup(p); }
    catch (e) {
      if (e.code === 'auth/popup-blocked' || e.code === 'auth/operation-not-supported-in-this-environment') auth.signInWithRedirect(p);
      else if (e.code !== 'auth/popup-closed-by-user' && e.code !== 'auth/cancelled-popup-request') say('تعذّر الدخول: ' + (e.code || e.message));
    }
  }
  async function handle(u) {
    if (!u) { if (cb.onOut) cb.onOut(); A.admin = false; $('btnAdmin').hidden = true; $('btnTrialReset').hidden = true; pane('gSign'); if (window.__mjCode) return cb.onEnter({ uid: '', name: 'ضيف المجلس', email: '', photo: '', chan: '', guest: true, mj: true }); return; }
    pane('gLoad');
    try {
      let open = false;
      try { const c = await db.doc('config/app').get(); if (c.exists) open = !!c.data().open; } catch (e) {}
      let admin = false;
      try { await db.collection('waitlist').limit(1).get(); admin = true; } catch (e) {}
      A.admin = admin; $('btnAdmin').hidden = !admin; $('btnTrialReset').hidden = !admin;
      const prof = { uid: u.uid, name: u.displayName || '', email: u.email || '', photo: u.photoURL || '', chan: '', guest: false };
      if (admin || open || window.__mjCode) return cb.onEnter(prof); /* مؤقتاً: الدخول برمز المجلس بدون تحقق */
      const d = await db.doc('waitlist/' + u.uid).get();
      if (!d.exists) { $('gHello').textContent = 'مرحباً ' + (u.displayName || '') + '، يرجى إكمال بيانات التسجيل المسبق'; return pane('gForm'); }
      const st = d.data().status;
      if (st === 'approved') return cb.onEnter(prof);
      $('gWaitMsg').textContent = st === 'rejected'
        ? 'نشكر لك اهتمامك. لم يتم اختيارك ضمن مرحلة التجربة الحالية، وسنوافيك عند الإطلاق العام.'
        : 'تم تسجيلك بنجاح في قائمة الانتظار. عند اختيارك للتجربة ستتمكن من الدخول تلقائياً بنفس الحساب.';
      pane('gWait');
    } catch (e) { say('مشكلة بالاتصال: ' + (e.code || e.message)); pane('gSign'); }
  }
  async function register() {
    const u = auth.currentUser; if (!u) return;
    $('gReg').disabled = true;
    try {
      await db.doc('waitlist/' + u.uid).set({
        name: u.displayName || '', email: u.email || '', photo: u.photoURL || '',
        handle: $('gHandle').value.trim().slice(0, 100), note: $('gNote').value.trim().slice(0, 300),
        status: 'pending', createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });
      handle(u);
    } catch (e) { say('تعذّر التسجيل: ' + (e.code || e.message)); }
    $('gReg').disabled = false;
  }

  /* ---- لوحة الإدارة ---- */
  let cfgDoc = { limit: 5, open: false }, rows = [];
  async function loadAdmin() {
    try { const c = await db.doc('config/app').get(); if (c.exists) cfgDoc = Object.assign(cfgDoc, c.data()); } catch (e) {}
    const q = await db.collection('waitlist').orderBy('createdAt', 'desc').get();
    rows = q.docs.map((d) => Object.assign({ id: d.id }, d.data()));
    paintAdmin();
  }
  async function setStatus(id, status) {
    const ok = rows.filter((r) => r.status === 'approved').length;
    if (status === 'approved' && ok >= cfgDoc.limit) return say('وصلت للعدد المحدد (' + cfgDoc.limit + ')');
    try { await db.doc('waitlist/' + id).update({ status }); const r = rows.find((x) => x.id === id); r.status = status; paintAdmin(); }
    catch (e) { say('فشل التحديث: ' + (e.code || e.message)); }
  }
  function paintAdmin() {
    const ok = rows.filter((r) => r.status === 'approved').length;
    $('admStat').textContent = `المسجّلين: ${rows.length} · المقبولين: ${ok} من ${cfgDoc.limit}` + (cfgDoc.open ? ' · الدخول مفتوح للجميع' : '');
    $('admLim').value = cfgDoc.limit; $('admOpen').textContent = cfgDoc.open ? 'إغلاق الدخول' : 'فتح للجميع';
    const box = $('admList'); box.textContent = '';
    if (!rows.length) box.appendChild(el('div', 'hint', 'ما كو أحد مسجّل لحد الآن'));
    rows.forEach((r) => {
      const it = el('div', 'admi'), b = el('b', null, r.name || '(بدون اسم)');
      const chip = el('span', 'chip2' + (r.status === 'approved' ? ' ok' : r.status === 'rejected' ? ' no' : ''), r.status === 'approved' ? 'مقبول' : r.status === 'rejected' ? 'مرفوض' : 'بالانتظار'); b.appendChild(chip);
      it.appendChild(b); it.appendChild(el('small', null, r.email || ''));
      if (r.handle) it.appendChild(el('small', null, 'الحساب: ' + r.handle));
      if (r.note) it.appendChild(el('small', null, 'ملاحظة: ' + r.note));
      const row = el('div', 'row');
      [['قبول', 'approved', 'primary'], ['رفض', 'rejected', ''], ['انتظار', 'pending', '']].forEach(([t, s, k]) => {
        if (r.status === s) return; const bt = el('button', 'btn small ' + k, t); bt.type = 'button'; bt.onclick = () => setStatus(r.id, s); row.appendChild(bt);
      });
      it.appendChild(row); box.appendChild(it);
    });
  }
  async function saveCfg() { try { await db.doc('config/app').set({ limit: cfgDoc.limit, open: !!cfgDoc.open }, { merge: true }); } catch (e) { say('فشل الحفظ: ' + (e.code || e.message)); } paintAdmin(); }
  async function loadSurveys() {
    const box = $('admSurv'); box.textContent = '';
    const q = await db.collection('surveys').orderBy('createdAt', 'desc').limit(100).get();
    const rs = q.docs.map((d) => d.data()), avg = rs.length ? (rs.reduce((s, r) => s + (r.rating || 0), 0) / rs.length).toFixed(1) : '0';
    $('admStat').textContent = `عدد الردود: ${rs.length} · متوسط التقييم: ${avg} من 5`;
    if (!rs.length) box.appendChild(el('div', 'hint', 'لا توجد ردود بعد'));
    rs.forEach((r) => {
      const it = el('div', 'admi'), b = el('b', null, (r.who || '') + ' · ' + '★'.repeat(r.rating || 0) + '☆'.repeat(5 - (r.rating || 0)));
      b.appendChild(el('span', 'chip2', r.src === 'trial' ? 'بعد التجربة' : 'بعد التصدير')); it.appendChild(b);
      [['الأقسام المجرَّبة', r.used], ['سهولة الاستخدام', r.ease], ['الميزات المطلوبة', r.needs], ['المشكلة', r.issue], ['الاستخدام عند الإطلاق', r.willUse], ['ملاحظات', r.notes]].forEach(([k, v]) => { if (v) it.appendChild(el('small', null, k + ': ' + v)); });
      const t = r.createdAt && r.createdAt.toDate ? r.createdAt.toDate().toLocaleString('ar-IQ') : ''; if (t) it.appendChild(el('small', null, t));
      box.appendChild(it);
    });
  }
  async function loadRequests() {
    const box = $('admReq'); box.textContent = '';
    const q = await db.collection('requests').orderBy('createdAt', 'desc').limit(100).get();
    const rs = q.docs.map((d) => Object.assign({ id: d.id }, d.data()));
    $('admStat').textContent = `طلبات التجربة: ${rs.length} · بالانتظار: ${rs.filter((r) => r.status === 'pending').length}`;
    if (!rs.length) box.appendChild(el('div', 'hint', 'لا توجد طلبات بعد'));
    const grantTo = async (r, opt) => {
      try {
        if (opt) { const upd = { extMin: firebase.firestore.FieldValue.increment(opt.ext), updatedAt: firebase.firestore.FieldValue.serverTimestamp() }; if (opt.unlock) upd.unlockUntil = Date.now() + 864e5; await db.doc('grants/' + r.deviceId).set(upd, { merge: true }); }
        await db.doc('requests/' + r.id).update({ status: opt ? 'approved' : 'rejected' }); r.status = opt ? 'approved' : 'rejected'; loadRequests();
      } catch (e) { say('فشل التنفيذ: ' + (e.code || e.message)); }
    };
    rs.forEach((r) => {
      const it = el('div', 'admi'), b = el('b', null, r.name || '');
      b.appendChild(el('span', 'chip2' + (r.status === 'approved' ? ' ok' : r.status === 'rejected' ? ' no' : ''), r.status === 'approved' ? 'تمت الموافقة' : r.status === 'rejected' ? 'مرفوض' : 'بالانتظار')); it.appendChild(b);
      it.appendChild(el('small', null, 'المعرّف: ' + (r.contact || ''))); it.appendChild(el('small', null, 'النوع: ' + (r.type === 'unlock' ? 'فتح الميزات' : 'تمديد الفترة')));
      if (r.note) it.appendChild(el('small', null, 'ملاحظة: ' + r.note));
      const t = r.createdAt && r.createdAt.toDate ? r.createdAt.toDate().toLocaleString('ar-IQ') : ''; if (t) it.appendChild(el('small', null, t));
      if (r.status === 'pending') { const row = el('div', 'row'); [['تمديد 30 دقيقة', { ext: 30 }, 'primary'], ['تمديد 60 دقيقة', { ext: 60 }, ''], ['فتح الميزات 24 ساعة', { ext: 30, unlock: true }, ''], ['رفض', null, '']].forEach(([tx, opt, k]) => { const bt = el('button', 'btn small ' + k, tx); bt.type = 'button'; bt.onclick = () => grantTo(r, opt); row.appendChild(bt); }); it.appendChild(row); }
      box.appendChild(it);
    });
  }
  async function loadStats() {
    const box = $('admInfo'); box.textContent = '';
    const [tl, wl, sv, rq] = await Promise.all([db.collection('trialLogs').orderBy('createdAt', 'desc').limit(3000).get(), db.collection('waitlist').get(), db.collection('surveys').get(), db.collection('requests').get()]);
    const logs = tl.docs.map((d) => d.data()), starts = logs.filter((l) => l.event === 'start'), ends = logs.filter((l) => l.event === 'end'), uniq = (a) => new Set(a.map((x) => x.deviceId)).size;
    const wk = Date.now() - 7 * 864e5, wkS = starts.filter((l) => l.createdAt && l.createdAt.toMillis && l.createdAt.toMillis() > wk);
    const wls = wl.docs.map((d) => d.data()), pend = rq.docs.filter((d) => d.data().status === 'pending').length;
    $('admStat').textContent = 'إحصائيات الاستخدام (التجربة المحدودة وغيرها)';
    [['أجهزة جرّبت التجربة المحدودة', uniq(starts)], ['إجمالي مرات بدء التجربة', starts.length], ['أجهزة استنفدت الدقائق العشر', uniq(ends)], ['أجهزة جرّبت آخر 7 أيام', uniq(wkS)], ['طلبات التمديد والفتح', rq.size + ' (بالانتظار: ' + pend + ')'], ['المسجّلون مسبقاً', wl.size], ['المقبولون', wls.filter((x) => x.status === 'approved').length], ['ردود الاستبيان', sv.size]].forEach(([k, v]) => {
      const r = el('div', 'xrow'); r.appendChild(el('span', null, k)); r.appendChild(el('b', null, String(v))); box.appendChild(r); });
    if (logs.length >= 3000) box.appendChild(el('div', 'hint', 'الأرقام محسوبة من آخر 3000 سجل.'));
  }
  function setTab(n) {
    [1, 2, 3, 4].forEach((k) => $('admT' + k).classList.toggle('primary', n === k));
    $('admCtl').hidden = n !== 1; $('admList').hidden = n !== 1; $('admSurv').hidden = n !== 2; $('admReq').hidden = n !== 3; $('admInfo').hidden = n !== 4;
    const fail = (e) => say('تعذّر التحميل: ' + (e.code || e.message));
    if (n === 1) paintAdmin(); else if (n === 2) loadSurveys().catch(fail); else if (n === 3) loadRequests().catch(fail); else loadStats().catch(fail);
  }
  const TS = () => firebase.firestore.FieldValue.serverTimestamp();
  A.logTrial = (id, ev) => { try { db.collection('trialLogs').add({ deviceId: String(id).slice(0, 40), event: ev, createdAt: TS() }).catch(() => {}); } catch (e) {} };
  A.submitRequest = (d) => db.collection('requests').add(Object.assign({}, d, { createdAt: TS() }));
  A.fetchGrant = (id) => db.doc('grants/' + id).get().then((d) => (d.exists ? d.data() : null));
  A.fetchPublic = () => db.doc('config/public').get().then((d) => (d.exists ? d.data() : {}));
  A.submitSurvey = (data) => db.collection('surveys').add(Object.assign({}, data, { createdAt: firebase.firestore.FieldValue.serverTimestamp() }));
  function openAdmin() {
    let m = $('admModal');
    if (!m) {
      m = el('div', 'adm'); m.id = 'admModal';
      m.innerHTML = '<div class="admc"><div class="admh"><b>لوحة الإدارة</b><button class="btn small" id="admX" type="button">إغلاق</button></div><div class="admtabs"><button class="btn small primary" id="admT1" type="button">الطلبات</button><button class="btn small" id="admT2" type="button">الاستبيانات</button><button class="btn small" id="admT3" type="button">طلبات التجربة</button><button class="btn small" id="admT4" type="button">الإحصائيات</button></div><div class="admt" id="admStat"></div><div class="admb" id="admCtl"><button class="btn small" id="admRand" type="button">اختيار عشوائي للباقي</button><label>العدد <input id="admLim" type="number" min="1" max="500" style="width:60px"></label><button class="btn small" id="admOpen" type="button"></button></div><div id="admList"></div><div id="admSurv" hidden></div><div id="admReq" hidden></div><div id="admInfo" hidden></div></div>';
      document.body.appendChild(m);
      $('admX').onclick = () => { m.hidden = true; };
      $('admT1').onclick = () => setTab(1); $('admT2').onclick = () => setTab(2); $('admT3').onclick = () => setTab(3); $('admT4').onclick = () => setTab(4);
      $('admLim').onchange = () => { cfgDoc.limit = Math.max(1, +$('admLim').value || 5); saveCfg(); };
      $('admOpen').onclick = () => { if (!cfgDoc.open && !confirm('تفتح الدخول لأي شخص عنده حساب Google؟')) return; cfgDoc.open = !cfgDoc.open; saveCfg(); };
      $('admRand').onclick = async () => {
        const free = cfgDoc.limit - rows.filter((r) => r.status === 'approved').length;
        const pend = rows.filter((r) => r.status === 'pending').sort(() => Math.random() - .5).slice(0, Math.max(0, free));
        if (!pend.length) return say('ما كو أحد بالانتظار أو الأماكن مليانة');
        const bt = db.batch(); pend.forEach((r) => bt.update(db.doc('waitlist/' + r.id), { status: 'approved' }));
        try { await bt.commit(); pend.forEach((r) => { r.status = 'approved'; }); paintAdmin(); say('تم قبول ' + pend.length); } catch (e) { say('فشل: ' + (e.code || e.message)); }
      };
    }
    m.hidden = false; setTab(1); loadAdmin().catch((e) => say('تعذّر التحميل: ' + (e.code || e.message)));
  }

  A.start = (o) => {
    cb = o; $('gBox').hidden = false; pane('gLoad');
    $('gBtn').onclick = signIn; $('gReg').onclick = register; $('gOut1').onclick = $('gOut2').onclick = () => auth.signOut();
    $('btnAdmin').onclick = () => { if (A.admin) openAdmin(); };
    $('btnTrialReset').onclick = async () => { if (!A.admin) return; if (!confirm('إعادة فتح الفترة التجريبية لجميع المستخدمين؟ سيحصل كل جهاز على فترة تجريبية جديدة.')) return; try { await db.doc('config/public').set({ trialEpoch: Date.now() }, { merge: true }); say('تمت إعادة فتح الفترة التجريبية للجميع'); } catch (e) { say('فشل التنفيذ: ' + (e.code || e.message)); } };
    auth.onAuthStateChanged(handle);
  };
})();
