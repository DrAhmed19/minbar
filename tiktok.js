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
      + '<div class="ttbody"><div class="ttprof"><b>@'+USER+'</b><span>مقاطعنا على تيك توك</span></div>'
      + '<a class="ttopen" href="https://www.tiktok.com/@' + USER + '" target="_blank" rel="noopener">فتح الحساب في TikTok</a>'
      + '<div class="ttsec"><b>مقاطع مختارة</b><span class="ttadm" hidden><textarea id="ttIn" dir="ltr" rows="2" placeholder="الصق رابط مقطع أو أكثر (سطر لكل رابط)"></textarea><button type="button" id="ttAdd">إضافة</button></span></div>'
      + '<div class="ttgrid"></div></div>';
    document.body.appendChild(root);
    root.querySelector('.ttb').onclick = close;
    root.querySelector('#ttAdd').onclick = add;
  }
  /* سكربت التضمين الرسمي من تيك توك: نعيد تحميله كل مرة حتى يحوّل أي تضمين جديد بالصفحة */
  function embedJs() { const o = document.getElementById('ttEmbedJs'); if (o) o.remove(); const sc = document.createElement('script'); sc.id = 'ttEmbedJs'; sc.async = true; sc.src = 'https://www.tiktok.com/embed.js'; document.body.appendChild(sc); }
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
    g.innerHTML = items.map((it) => '<a class="ttc" target="_blank" rel="noopener" href="' + esc(it.url) + '" data-v="' + esc(it.vid) + '">' + (it.thumb ? '<img alt="" loading="lazy" referrerpolicy="no-referrer" src="' + esc(it.thumb) + '">' : '') + '<i>▶</i><span>' + esc(it.title || 'مقطع على تيك توك') + '</span>' + (isAdmin() ? '<em data-del="' + esc(it.id) + '">حذف</em>' : '') + '</a>').join('');
    g.querySelectorAll('.ttc').forEach((b) => { b.onclick = (e) => { const d = e.target.closest('[data-del]'); if (d) { e.preventDefault(); e.stopPropagation(); del(d.dataset.del); } }; });
  }
  function play(vid) {
    document.querySelectorAll('audio,video').forEach((a) => { try { a.pause(); } catch (e) {} });
    const it = items.find((x) => x.vid === vid) || {}, url = it.url || ('https://www.tiktok.com/@' + USER + '/video/' + vid);
    const m = document.createElement('div'); m.className = 'ttplay';
    m.innerHTML = '<button type="button" class="ttx" aria-label="إغلاق">✕</button><div class="ttpv"><blockquote class="tiktok-embed" cite="' + esc(url) + '" data-video-id="' + esc(vid) + '" style="max-width:605px;min-width:325px;margin:0"><section></section></blockquote></div><a class="ttopen" href="' + esc(url) + '" target="_blank" rel="noopener">فتح في TikTok</a>';
    m.querySelector('.ttx').onclick = () => m.remove(); m.onclick = (e) => { if (e.target === m) m.remove(); };
    document.body.appendChild(m); embedJs();
  }
  const local = (u) => { const m = String(u).match(/@([\w.-]+)\/video\/(\d{8,25})/); return m ? { id: m[2], url: 'https://www.tiktok.com/@' + m[1] + '/video/' + m[2], title: '', thumb: '' } : null; };
  async function add() {
    if (busy) return; const inp = root.querySelector('#ttIn'), links = inp.value.split(/[\s,]+/).filter(Boolean); if (!links.length) return toast('الصق رابط المقطع أولاً');
    busy = true; const bt = root.querySelector('#ttAdd'); bt.disabled = true; bt.textContent = '…';
    let ok = 0, err = '';
    for (const u of links) {
      try {
        let m = await info(u); if (!m || !m.id) m = local(u);
        if (!m) { err = 'الرابط ما فيه رقم مقطع، انسخه من «مشاركة ← نسخ الرابط» للمقطع نفسه'; continue; }
        if (items.some((x) => x.vid === m.id)) { err = 'مضاف مسبقاً'; continue; }
        const top = items.length ? Math.min(...items.map((x) => x.order || 0)) : 0;
        const rec = { vid: m.id, url: m.url, title: m.title || '', thumb: m.thumb || '', order: top - 1, at: firebase.firestore.FieldValue.serverTimestamp() };
        await db().collection('tiktok').doc(m.id).set(rec);
        items.push(Object.assign({ id: m.id }, rec)); ok++;
      } catch (e) { err = 'تعذّر الحفظ: ' + (e && (e.code || e.message) || ''); }
    }
    if (ok) { inp.value = ''; toast('تمت إضافة ' + ok + (err ? ' — ' + err : '')); await load(); } else toast(err || 'تعذّرت الإضافة');
    busy = false; bt.disabled = false; bt.textContent = 'إضافة';
  }
  async function del(id) { if (!confirm('إزالة المقطع من الصفحة؟')) return; try { await db().collection('tiktok').doc(id).delete(); items = items.filter((x) => x.id !== id); paint(); } catch (e) { toast('تعذّر الحذف'); } }
  window.TikTokPage = { open() { if (root) return; shell(); load(); } };
})();
