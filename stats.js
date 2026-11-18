/* منبر — صفحة «الإحصائيات» للأدمن (من Google Analytics عبر /api/stats) */
(function () {
  const isAdmin = () => !!(window.MinbarAuth && MinbarAuth.admin);
  let root = null;
  const f = (n) => Number(n || 0).toLocaleString('ar-IQ');
  function bars(s, key, col) {
    const mx = Math.max(1, ...s.map((x) => x[key]));
    return '<div class="stbars">' + s.map((x) => '<div class="stbar"><i style="height:' + Math.max(3, Math.round((x[key] / mx) * 90)) + 'px;background:' + col + '"></i><b>' + f(x[key]) + '</b><small>' + x.d.slice(6) + '/' + x.d.slice(4, 6) + '</small></div>').join('') + '</div>';
  }
  async function open() {
    if (root) return;
    root = document.createElement('div'); root.className = 'ttpg stpg';
    root.innerHTML = '<div class="tth"><button class="ttb" type="button" aria-label="رجوع">‹</button><b>الإحصائيات</b><span></span></div><div class="ttbody"><div class="tthint">جارٍ التحميل…</div></div>';
    document.body.appendChild(root); root.querySelector('.ttb').onclick = () => { root.remove(); root = null; };
    const bd = root.querySelector('.ttbody');
    try {
      const u = firebase.auth().currentUser; if (!u) throw new Error('سجّل الدخول');
      const r = await fetch('api/stats', { headers: { authorization: 'Bearer ' + await u.getIdToken() } }), d = await r.json();
      if (!r.ok) throw new Error(d.error || 'تعذّر التحميل');
      bd.innerHTML = '<div class="stnow"><span class="stlive"></span><b>' + f(d.now) + '</b><small>نشط الآن (آخر 30 دقيقة)</small></div>'
        + '<div class="stgrid"><div><b>' + f(d.users.t) + '</b><small>اليوم</small></div><div><b>' + f(d.users.w) + '</b><small>آخر 7 أيام</small></div><div><b>' + f(d.users.m) + '</b><small>آخر 30 يوم</small></div></div>'
        + '<div class="stgrid"><div><b>' + f(d.fresh.t) + '</b><small>جدد اليوم</small></div><div><b>' + f(d.fresh.w) + '</b><small>جدد 7 أيام</small></div><div><b>' + f(d.fresh.m) + '</b><small>جدد 30 يوم</small></div></div>'
        + '<div class="stsec">المستخدمون النشطون يومياً</div>' + bars(d.series, 'u', '#1b7f5c')
        + '<div class="stsec">الجلسات (مرات الفتح)</div>' + bars(d.series, 's', '#c9a84c')
        + '<div class="stsec">الدول (آخر 30 يوم)</div>' + (d.countries.length ? d.countries.map((c) => '<div class="stc"><span>' + c[0] + '</span><b>' + f(c[1]) + '</b></div>').join('') : '<div class="tthint">لا بيانات بعد</div>')
        + '<div class="tthint">البيانات تتأخر قليلاً عن الواقع</div>';
    } catch (e) { bd.innerHTML = '<div class="tthint">' + String(e.message || e).replace(/</g, '&lt;') + '</div>'; }
  }
  /* نضيف صفّ «الإحصائيات» للأدمن بقائمة الحساب بجانب صفّ التيك توك بدون لمس مشغّل الصفحة */
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
