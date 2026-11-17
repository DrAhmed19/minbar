/* منبر — صفحة «مقاطعنا على تيك توك»: بطاقة الحساب الرسمية + مقاطع مختارة يثبّتها المشرف */
(function () {
  const USER = 'a1h9mad';
  const esc = (s) => String(s || '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const db = () => { try { return firebase.firestore(); } catch (e) { return null; } };
  const isAdmin = () => !!(window.MinbarAuth && MinbarAuth.admin);
  const info = (u) => fetch('api/tt?url=' + encodeURIComponent(u)).then((r) => r.json()).catch(() => null);
  let root = null, items = [], busy = false;
  const toast = (m) => { const t = document.getElementById('toast'); if (!t) return alert(m); t.textContent = m; t.hidden = false; clearTimeout(t._h); t._h = setTimeout(() => { t.hidden = true; }, 2600); };

  function shell() {
    root = document.createElement('div'); root.className = 'ttpg';
    root.innerHTML = '<div class="tth"><button class="ttb" type="button" aria-label="رجوع">‹</button><b>مقاطعنا على تيك توك</b><span></span></div>'
      + '<div class="ttbody"><div class="ttprof"><iframe src="https://www.tiktok.com/embed/@' + USER + '" loading="lazy" allow="encrypted-media; fullscreen" title="حساب تيك توك"></iframe></div>'
      + '<div class="ttsec"><b>مقاطع مختارة</b><span class="ttadm" hidden><input id="ttIn" dir="ltr" placeholder="الصق رابط مقطع تيك توك"><button type="button" id="ttAdd">إضافة</button></span></div>'
      + '<div class="ttgrid"></div></div>';
    document.body.appendChild(root);
    root.querySelector('.ttb').onclick = close;
    root.querySelector('#ttAdd').onclick = add;
  }
  function close() { if (root) { root.remove(); root = null; } }
  async function load() {
    const g = root.querySelector('.ttgrid'); g.innerHTML = '<div class="tthint">جارٍ التحميل…</div>';
    try { const q = await db().collection('tiktok').orderBy('order').limit(60).get(); items = q.docs.map((d) => Object.assign({ id: d.id }, d.data())).filter((x) => x.vid); } catch (e) { items = []; }
    paint();
    items.forEach((it) => info(it.url).then((m) => { if (m && m.thumb) { it.thumb = m.thumb; const im = root && root.querySelector('[data-v="' + it.vid + '"] img'); if (im) im.src = m.thumb; } }));
  }
  function paint() {
    if (!root) return;
    root.querySelector('.ttadm').hidden = !isAdmin();
    const g = root.querySelector('.ttgrid');
    if (!items.length) { g.innerHTML = '<div class="tthint">' + (isAdmin() ? 'أضف أول مقطع بلصق رابطه بالأعلى' : 'لا توجد مقاطع مختارة بعد') + '</div>'; return; }
    g.innerHTML = items.map((it) => '<button type="button" class="ttc" data-v="' + esc(it.vid) + '">' + (it.thumb ? '<img alt="" loading="lazy" referrerpolicy="no-referrer" src="' + esc(it.thumb) + '">' : '') + '<i>▶</i><span>' + esc(it.title) + '</span>' + (isAdmin() ? '<em data-del="' + esc(it.id) + '">حذف</em>' : '') + '</button>').join('');
    g.querySelectorAll('.ttc').forEach((b) => { b.onclick = (e) => { const d = e.target.closest('[data-del]'); if (d) { e.stopPropagation(); del(d.dataset.del); return; } play(b.dataset.v); }; });
  }
  function play(vid) {
    document.querySelectorAll('audio,video').forEach((a) => { try { a.pause(); } catch (e) {} });
    const m = document.createElement('div'); m.className = 'ttplay';
    m.innerHTML = '<button type="button" class="ttx" aria-label="إغلاق">✕</button><iframe src="https://www.tiktok.com/embed/v2/' + encodeURIComponent(vid) + '?lang=ar" allow="autoplay; encrypted-media; fullscreen" allowfullscreen title="مقطع تيك توك"></iframe>';
    m.querySelector('.ttx').onclick = () => m.remove(); m.onclick = (e) => { if (e.target === m) m.remove(); };
    document.body.appendChild(m);
  }
  async function add() {
    if (busy) return; const inp = root.querySelector('#ttIn'), u = inp.value.trim(); if (!u) return toast('الصق رابط المقطع أولاً');
    busy = true; const bt = root.querySelector('#ttAdd'); bt.disabled = true; bt.textContent = '…';
    try {
      const m = await info(u);
      if (!m || !m.id) toast((m && m.error) || 'تعذّر قراءة الرابط');
      else if (items.some((x) => x.vid === m.id)) toast('هذا المقطع مضاف مسبقاً');
      else {
        const top = items.length ? Math.min(...items.map((x) => x.order || 0)) : 0;
        await db().collection('tiktok').doc(m.id).set({ vid: m.id, url: m.url, title: m.title || '', thumb: m.thumb || '', order: top - 1, at: firebase.firestore.FieldValue.serverTimestamp() });
        inp.value = ''; toast('تمت الإضافة'); await load();
      }
    } catch (e) { toast('تعذّر الحفظ'); }
    busy = false; bt.disabled = false; bt.textContent = 'إضافة';
  }
  async function del(id) { if (!confirm('إزالة المقطع من الصفحة؟')) return; try { await db().collection('tiktok').doc(id).delete(); items = items.filter((x) => x.id !== id); paint(); } catch (e) { toast('تعذّر الحذف'); } }
  window.TikTokPage = { open() { if (root) return; shell(); load(); } };
})();
