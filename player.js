/* منبر — المشغل */
(function () {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const LSK = 'minbar.plr', CATK = 'minbar.catalog', CATC = 'minbar.catalog.cache';
  const I = {
    rw: '<path d="M4 12a8 8 0 1 0 2.4-5.7"/><path d="M4 4v4h4"/>',
    fw: '<path d="M20 12a8 8 0 1 1-2.4-5.7"/><path d="M20 4v4h-4"/>',
    undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
    back: '<path d="M9 6l6 6-6 6"/>',
    fwd: '<path d="M15 6l-6 6 6 6"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7.5v.5"/>', share: '<circle cx="18" cy="5" r="2.5"/><circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="19" r="2.5"/><path d="M8.2 10.8l7.6-4.4M8.2 13.2l7.6 4.4"/>', users: '<circle cx="9" cy="8" r="3.2"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6M16 4.6a3 3 0 010 6M18 14c2 .6 3.5 2.6 3.5 5"/>', pulse: '<path d="M3 12h4l2-6 4 12 2-6h6"/>', flame: '<path d="M12 21c4 0 7-2.7 7-6.5 0-3.5-2.5-5.5-4-8-1 2-2 3-3.5 3.5C11 7 10 5 9.5 3 7 6 5 9 5 14.5 5 18.3 8 21 12 21z"/>', mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/>', plist: '<path d="M4 6h12M4 11h12M4 16h7M17 14v6M14 17h6"/>',
    play: '<path d="M7 4.5v15l13-7.5z" fill="currentColor" stroke-linejoin="round"/>', pause: '<path d="M7 4h3.5v16H7zM13.5 4H17v16h-3.5z" fill="currentColor"/>',
    next: '<path d="M5 5l10 7-10 7z" fill="currentColor"/><path d="M19 5v14"/>', prev: '<path d="M19 5L9 12l10 7z" fill="currentColor"/><path d="M5 5v14"/>',
    shuf: '<path d="M16 3h5v5M4 20L21 3M21 16v5h-5M15 15l6 6M4 4l5 5"/>', rep: '<path d="M17 2l4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4M21 13v2a3 3 0 0 1-3 3H3"/>',
    heart: '<path d="M12 21s-7-4.4-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6c-2.5 4.6-9.5 9-9.5 9z"/>', lib: '<path d="M4 5h4v14H4zM10 5h4v14h-4zM16.5 6l3.7-1 3 13-3.7 1z"/>',
    studio: '<path d="M4 20l4-1 11-11-3-3L5 16zM14 6l3 3"/>', down: '<path d="M6 9l6 6 6-6"/>', arch: '<path d="M5 21V11a7 7 0 0 1 14 0v10"/><path d="M9 21v-5a3 3 0 0 1 6 0v5M3 21h18M12 4V2"/>', hand: '<path d="M7 11V5.5a1.5 1.5 0 0 1 3 0V10m0-4.5v-1a1.5 1.5 0 0 1 3 0V10m0-4a1.5 1.5 0 0 1 3 0v4m0-1.5a1.5 1.5 0 0 1 3 0V14a7 7 0 0 1-7 7h-1a6 6 0 0 1-5-2.7L3.6 14a1.5 1.5 0 0 1 2.4-1.8L7 13.5"/>', dl: '<path d="M12 4v11M7.5 10.5L12 15l4.5-4.5"/><path d="M5 19h14"/>', moon: '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>', timer: '<circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 2h6"/>',
    color: '<path d="M12 3a9 9 0 1 0 0 18c1.2 0 1.8-.8 1.8-1.7 0-1.1-.9-1.4-.9-2.4 0-.9.7-1.6 1.6-1.6H17a4 4 0 0 0 4-4C21 6.6 17 3 12 3z"/><circle cx="7.5" cy="11" r="1.2"/><circle cx="10" cy="7.2" r="1.2"/><circle cx="14.5" cy="7.2" r="1.2"/>', speed: '<path d="M12 14l4-5M4.5 17a9 9 0 1 1 15 0"/>', text: '<path d="M4 6h16M4 12h10M4 18h14"/>', cut: '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4L8.1 15.9M14.5 14.5L20 20M8.1 8.1L12 12"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/>', queue: '<path d="M3 6h13M3 12h13M3 18h7M16 14l5 3-5 3z"/>', more: '<circle cx="12" cy="5" r="1.6" fill="currentColor"/><circle cx="12" cy="12" r="1.6" fill="currentColor"/><circle cx="12" cy="19" r="1.6" fill="currentColor"/>', eq: '<path d="M4 10v4M8 6v12M12 3v18M16 7v10M20 10v4"/>', up: '<path d="M6 15l6-6 6 6"/>', x: '<path d="M6 6l12 12M18 6L6 18"/>', check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>', spark: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z" fill="currentColor" stroke="none"/>', chat: '<path d="M4 5h16v11H9l-5 4z"/>', send: '<path d="M21 3L3 11l7 2 2 7z"/>', power: '<path d="M12 3v8M6.3 6.3a8 8 0 1 0 11.4 0"/>', save: '<path d="M5 3h11l3 3v15H5zM8 3v5h7V3M8 21v-7h8v7"/>', reset: '<path d="M4 12a8 8 0 1 0 2.3-5.7M4 4v4h4"/>', wave: '<path d="M3 12h2l2-6 3 12 3-15 3 15 2-6h3"/>', gear: '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-2.9 1.2V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-2.9-1.2l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.7 1.7 0 0 0 3 15.1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.7 1.7 0 0 0 9 4.6V4.5a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 2.9 1.2l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0 1.2 2.9h.1a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>', lay: '<rect x="4" y="4" width="16" height="16" rx="3"/><path d="M4 14h16"/>', note: '<path d="M9 18V5l11-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>'
  };
  const ic = (n, s) => `<svg class="pi" viewBox="0 0 24 24" ${s ? `style="width:${s}px;height:${s}px"` : ''}>${I[n]}</svg>`;
  const LF = [['F0', 'كايرو', 700], ['F1', 'تجوّل', 700], ['F2', 'أميري', 700], ['F8', 'نسخ', 700], ['F13', 'شهرزاد', 700], ['F17', 'لطيف', 700], ['F3', 'رقعة', 700], ['F10', 'رقعة الحبر', 700], ['F12', 'ميرزا', 700], ['F5', 'المسيري', 700], ['F4', 'ريم كوفي', 700], ['F15', 'ريم الحبر', 400], ['F14', 'كوفي', 700], ['F6', 'لالزار', 400], ['F9', 'رقّاص', 400], ['F7', 'كاتبة', 400], ['F16', 'بلاكا', 400], ['F11', 'فايبز', 400]];
  const EDK = 'minbar.lyr.edits', SGK = 'minbar.lyr.sugg';
  const jget = (k, d) => { try { return JSON.parse(localStorage.getItem(k) || 'null') || d; } catch (e) { return d; } };
  const load = () => { try { return JSON.parse(localStorage.getItem(LSK) || '{}'); } catch (e) { return {}; } };
  const st = Object.assign({ fav: [], speed: 1, shuf: false, rep: 0, viz: 'mihrab', lay: 'a', ly: { font: 'F2', color: '#E8C468', size: 1, tr: 'slide' } }, load());
  /* وضع الأداء تلقائي: كل جلسة تبدأ بالشكل الكامل (مؤثرات الصوت) على الأجهزة القادرة، والآيفون يبقى بدونها حتى يستمر الصوت بالخلفية؛ وإذا صار خطأ تبدأ الجلسة الجاية بوضع الأداء */
  (function () { let fail = false; try { fail = sessionStorage.getItem('mbFxFail') === '1'; } catch (e) {} const ios = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1); st.fx = !fail && !ios && (navigator.hardwareConcurrency || 4) >= 4 && (navigator.deviceMemory || 4) >= 3; })();
  window.addEventListener('error', () => { try { sessionStorage.setItem('mbFxFail', '1'); } catch (e) {} try { liteSet(true); } catch (e) {} });
  try { const mp = { '#f3d88a': '#E8C468', '#e6e1d3': '#FFFFFF', '#7fe0b5': '#2FBF8F', '#c0c7cc': '#FFFFFF' }; const c0 = (st.ly.color || '').toLowerCase(); if (mp[c0]) st.ly.color = mp[c0]; } catch (e) {}
  st.ly.size = Math.max(0.85, Math.min(1.2, +st.ly.size || 1));
  const save = () => { try { localStorage.setItem(LSK, JSON.stringify({ fav: st.fav, speed: st.speed, uvol: st.uvol, bg: st.bg, latm: st.latm, shuf: st.shuf, rep: st.rep, viz: st.viz, lay: st.lay, ly: st.ly, au: st.au, cm: st.cm })); } catch (e) {} };
  const fmt = (t) => { t = Math.max(0, t || 0); return String(Math.floor(t / 60)).padStart(2, '0') + ':' + String(Math.floor(t % 60)).padStart(2, '0'); };
  let tracks = [], view = [], cur = -1, tab = 'lib', cat = 'الكل', q = '', sleepT = 0, sleepAt = 0, clipA = 0, clipB = 0, clipPrev = false;
  const A = new Audio(); A.preload = 'auto'; A.preservesPitch = true;
  const toast = (m) => { const t = $('toast'); if (t) { t.textContent = m; t.classList.add('on'); clearTimeout(toast.h); toast.h = setTimeout(() => t.classList.remove('on'), 2200); } };

  const root = document.createElement('div'); root.id = 'plr'; root.className = 'ovl plr'; root.hidden = true;
  root.innerHTML = `
  <div class="ovh"><div class="brand"><img src="icons/brand-mark.png" alt=""><span>منبر</span></div><div class="plrsb"><button class="ib" id="plrRecB" aria-label="التعرّف على القصيدة">${ic('mic', 21)}</button><button class="aqc" id="plrAq" type="button" hidden><i></i><b></b><small></small></button><button class="ib" id="plrAddB" aria-label="إضافة قصيدة" hidden>${ic('plus', 22)}</button><button class="ib" id="plrSearchB" aria-label="بحث">${ic('search', 22)}</button></div></div>
  <div class="plrlt" id="plrLt" hidden></div>
  <div class="plrsearch" id="plrSearch" hidden><input id="plrQ" placeholder="ابحث باسم القصيدة أو الرادود أو الشاعر" autocomplete="off"></div>
  <div class="plrchips" id="plrCats"></div>
  <div class="ovb plrbody" id="plrBody"></div>
  <div class="plrmini" id="plrMini" hidden>
    <div class="plrprog"><i id="plrMiniP"></i></div>
    <div class="plrmrow"><div class="plrcov sm" id="plrMiniC"></div><div class="plrmt" id="plrMiniT"><b></b><small></small></div>
      <button class="plrib" id="plrMiniPlay"></button><button class="plrib" id="plrMiniNext">${ic('next', 22)}</button></div>
  </div>
  <nav class="plrnav"><button data-t="lib" class="on">${ic('lib', 22)}<span>المكتبة</span></button><button data-t="fav">${ic('heart', 22)}<span>المفضلة</span></button><button data-t="smp">${ic('pulse', 22)}<span>عينات</span></button><button data-t="pls" id="plrNavPl">${ic('plist', 22)}<span>القوائم</span></button></nav>
  <div class="plrhs" id="plrHs" hidden><div class="hst"></div><div class="hsw"><p class="hsc"></p><p class="hsn"></p></div><div class="hsp"><i></i></div><div class="hsctl"><button class="hspp" type="button">${ic('pause', 22)}</button><button class="hsx" type="button">${ic('x', 22)}</button></div></div>
  <div class="plrsmp" id="plrSmp" hidden><div class="smhd"><b>عينات</b><button class="ib" id="plrSmpX" aria-label="إغلاق">${ic('x', 20)}</button></div><div class="smpl" id="plrSmpL"></div></div>
  <div class="plrfull lay-a" id="plrFull" hidden>
    <div class="plrbgi" id="plrBgI"></div><img class="plrbgf" id="plrBgF" alt="">
    <canvas class="plrviz" id="plrViz"></canvas>
    <div class="plrfh" id="plrFh"><button class="ib" id="plrClose" aria-label="إغلاق">${ic('down', 24)}</button><span id="plrCount"></span><button class="mjc" id="plrMj" type="button" hidden>${ic('users', 14)}<b></b></button><div class="fhr"><button class="ib" id="plrMore" aria-label="المزيد">${ic('more', 20)}</button></div></div>
    <div class="plrcml" id="plrCmL"></div><div class="plrrx" id="plrRx"></div><div class="plrscr" id="plrScr" hidden><b></b></div>
    <div class="plrfb">
      <div class="plrstage" id="plrStage"></div>
      <div class="lyx" id="plrLyr"><div class="lyt"></div><div class="lye">لا تتوفر كلمات · اضغط مطوّلاً للإضافة</div></div>
      <div class="plrgl">
      <div class="plrtt" id="plrTt"><button class="ib slb" id="plrSlB" aria-label="مؤقت الإيقاف" hidden>${ic('moon', 18)}<i id="plrSlV"></i></button><img class="ttc" id="plrTtC" alt=""><button class="ib tb" id="plrFav" aria-label="مفضلة">${ic('heart', 20)}</button><div><b id="plrTitle"></b><small id="plrSub"></small></div><button class="ib tb" id="plrCmB" aria-label="التعليقات">${ic('chat', 20)}</button></div>
      <canvas class="plrwave" id="plrWave"></canvas><canvas class="plrspec" id="plrSpec"></canvas><div class="plrln" id="plrLn"><div class="lt"><i id="plrLnF"></i><b id="plrLnK"></b></div></div>
      <div class="plrtm"><span id="plrCur">00:00</span><span id="plrDur">00:00</span></div>
      <div class="plrctl"><button class="sm" id="plrShuf">${ic('shuf', 22)}<span>عشوائي</span></button><button id="plrPrev">${ic('prev', 28)}</button><button class="main" id="plrPlay"></button><button id="plrNext">${ic('next', 28)}</button><button class="sm" id="plrRep">${ic('rep', 22)}<span>تكرار</span></button></div>
      </div>
    </div>
    <div class="plrdock"><button id="plrQB">${ic('queue', 22)}<span>القائمة</span></button><button id="plrLyB">${ic('text', 22)}<span>الكلمات</span></button><button id="plrVzB">${ic('eq', 22)}<span>القالب</span></button><button class="tg" id="plrTg">${ic('wave', 24)}<span>الصوت</span></button><button id="plrMdB">${ic('arch', 22)}<span>الأجواء</span></button></div>
    <div class="plrsheetbg" id="plrBg" hidden></div>
    <div class="plrtp" id="plrTp" hidden>
      <div class="gr"></div>
      <div class="tph"><b>إعدادات العرض</b><button class="ib" id="plrTpX" aria-label="إغلاق">${ic('x', 20)}</button></div>
      <div class="seg tabs" id="plrTpT"><button data-k="v" class="on" type="button">المظهر</button><button data-k="t" type="button">الأدوات</button></div>
      <div class="tpc tpv tpV"><h4>${ic('eq', 16)}القالب <b class="vzn" id="plrVizN"></b></h4><div class="seg vzc" id="plrVizC"></div><div class="vizgrid" id="plrVizP"></div></div>
      <div class="tpc tpV"><h4>${ic('lay', 16)}ترتيب الواجهة</h4><div class="laycards" id="plrLayP"></div></div>
      <div class="tpc tpV"><h4>${ic('color', 16)}لون الخلفية <b class="vzn" id="plrBgN"></b></h4><div class="bgsw" id="plrBgP"></div></div>
      <div class="tpc tpT" hidden><div class="tools tgrp" id="plrTools"></div></div>
      <div hidden><div class="seg" id="plrSpeedP"></div></div>
      <div id="plrSleepP" hidden></div>
      <div class="tpc tpT" hidden><h4>${ic('cut', 16)}التصميم على مقطع</h4><button class="btn wide" id="plrClip" type="button">اختيار مقطع وتصميمه</button>
      <div class="plrclip" id="plrClipBox" hidden>
        <div class="plrcliph"><b>تحديد المقطع</b><span id="plrClipLen"></span></div>
        <div class="clsug" id="plrClipSug"></div>
        <canvas class="clov" id="plrClipOv"></canvas>
        <canvas class="cldt" id="plrClipDt"></canvas>
        <div class="cltm"><b id="plrAV">0:00</b><span dir="rtl">حد أقصى دقيقة · تلتصق بالأبيات</span><b id="plrBV">0:00</b></div>
        <div class="clly" id="plrClipLy"></div>
        <div class="row cllen" id="plrClipLn"></div>
        <div class="row"><button class="btn small" id="plrPrevClip" type="button">▶ معاينة</button></div>
        <button class="btn primary wide" id="plrDesign" type="button">التصميم على هذا المقطع</button>
      </div></div>
    </div>
    <div class="plrqs qsx" id="plrQs" hidden><div class="qhd"><div class="gr"></div><div class="qtop"><div><b>قائمة التشغيل</b><small id="plrQc"></small></div><button class="qt" id="plrQsv" type="button" aria-label="حفظ كقائمة">${ic('plist', 18)}</button><button class="qt" id="plrQsh" type="button" aria-label="خلط">${ic('shuf', 18)}</button><button class="qt" id="plrQrp" type="button" aria-label="تكرار">${ic('rep', 18)}</button></div></div><div id="plrQl"></div></div>
    <div class="plrlys" id="plrLys" hidden>
      <div class="plrfh lyh" id="plrLyH"><i class="grb"></i><button class="ib" id="plrLyBack" aria-label="رجوع">${ic('down', 20)}</button><span>الكلمات</span><button class="ib" id="plrAdmB" aria-label="طلبات الكلمات" hidden>${ic('queue', 18)}</button><button class="ib ok" id="plrLyOk" aria-label="تطبيق">${ic('check', 20)}</button></div>
      <div class="seg tabs" id="plrLyT"><button data-k="style" class="on">المظهر</button><button data-k="edit">التحرير</button></div>
      <div class="plrlyscroll" id="plrLyScroll">
        <div id="plrLyStyle">
          <div class="lyx pre" id="plrLyPre"><div class="lyt"></div></div>
          <h4>الخط</h4><div class="fontgrid" id="plrLyF"></div>
          <h4>اللون</h4><div class="plrsw" id="plrLyC"></div>
          <h4>الحجم</h4><div class="srow"><span>الحجم</span><div class="slh" id="plrLyS"></div><b id="plrLySV"></b></div>
          <h4>تقسيم الأسطر الطويلة</h4><div class="seg" id="plrLySp"></div>
          <h4>طريقة الانتقال بين الأبيات</h4><div class="trgrid" id="plrLyTr"></div>
        </div>
        <div id="plrLyEdit" hidden><div class="hint" id="plrLyHint"></div><div id="plrLyL"></div></div>
      </div>
    </div>
    <div class="plrqs plrau" id="plrAu" hidden><div class="gr"></div>
      <div class="auh"><b>الصوت</b><button class="aupb" id="plrAuPB" type="button"><span></span>${ic('down', 16)}</button><button class="ib" id="plrAuSv" aria-label="حفظ">${ic('save', 17)}</button><button class="ib" id="plrAuR" aria-label="إعادة ضبط">${ic('reset', 17)}</button><button class="ib" id="plrAuX" aria-label="إغلاق">${ic('x', 17)}</button></div>
      <div class="seg autab" id="plrAuT"><button data-k="b" class="on">النطاقات</button><button data-k="f">المؤثرات</button><button data-k="a">متقدّم</button></div>
      <div class="hint aun" id="plrAuN" hidden>المعالجة متاحة للملفات المرفوعة على منبر فقط.</div>
      <div class="aupn" id="auB">
        <div class="eqw"><canvas id="plrEq"></canvas></div>
        <div class="aurow"><div class="pre"><span>التضخيم المسبق</span><div class="slh" id="auPre"></div><b id="auPreV"></b></div><button class="pw" id="auLim" type="button">${ic('power', 15)}<span>المحدِّد</span></button></div>
        <div class="bands" id="auBands"></div>
      </div>
      <div class="aupn" id="auF" hidden>
        <div class="aurow"><button class="pw" id="auAgc" type="button">${ic('power', 15)}<span>التحكم التلقائي بالمستوى</span></button></div>
        <div class="bal"><div class="fxh"><span>التوازن</span><b id="auBalV"></b></div><div class="balr"><i>يسار</i><div class="slh" id="auBal"></div><i>يمين</i></div></div>
        <div class="knobs" id="auKF"></div>
      </div>
      <div class="aupn" id="auA" hidden>
        <div class="bal"><div class="fxh"><span>طبقة الصوت</span><b id="auPiV"></b></div><div class="balr"><i>−12</i><div class="slh" id="auPi"></div><i>+12</i></div></div>
        <div class="bal"><div class="fxh"><span>سرعة التشغيل</span><b id="auSpV"></b></div><div class="balr"><i>0.5×</i><div class="slh" id="auSp"></div><i>2×</i></div></div>
        <div class="knobs" id="auKA"></div>
        <div class="aurow"><button class="pw" id="auFl" type="button">${ic('power', 15)}<span>التموّج (Flanger)</span></button></div>
      </div>
      <div class="aupl" id="plrAuPL" hidden><div class="tph"><b>الإعدادات المسبقة</b><button class="ib" id="plrAuPLX" aria-label="إغلاق">${ic('x', 17)}</button></div><div class="aupll" id="plrAuPLL"></div>
        <div class="ausv"><input id="plrAuSN" maxlength="24" placeholder="اسم الإعداد"><button class="btn small primary" id="plrAuSB" type="button">حفظ الحالي</button></div></div>
    </div>
    <div class="plrqs plrcm" id="plrCm" hidden><div class="gr"></div>
      <div class="tph"><b>التعليقات</b><button class="ib" id="plrCmX" aria-label="إغلاق">${ic('x', 18)}</button></div>
      <div class="cmin"><input id="plrCmI" maxlength="70" placeholder="عبّر عن حبك للقصيدة عند هذه اللحظة" autocomplete="off"><small class="cmn" id="plrCmN">70</small><button id="plrCmS" aria-label="إرسال">${ic('send', 18)}</button></div>
      <div class="cmo"><div class="seg" id="plrCmOn"></div><div class="seg" id="plrCmV"></div></div><button class="btn small wide" id="plrCmMod" type="button" hidden>مراجعة التعليقات والفلتر</button>
      <div class="cmlist" id="plrCmList"></div>
    </div>
    <div class="plrqs plrcv" id="plrCv" hidden><div class="gr"></div>
      <div class="tph"><b>اختيار الغلاف</b><button class="ib" id="plrCvX" aria-label="إغلاق">${ic('x', 17)}</button></div>
      <div class="hint cvh">يظهر الغلاف المختار لك فقط.</div>
      <div class="cvg" id="plrCvG"></div>
      <div class="row cvr"><button class="btn small primary" id="plrCvF" type="button">من المعرض</button><button class="btn small" id="plrCvD" type="button">الغلاف الأصلي</button></div>
      <input type="file" id="plrCvIn" accept="image/*" hidden>
    </div>
    <div class="plrqs plradm" id="plrAdm" hidden><div class="gr"></div><div class="tph"><b>طلبات الكلمات</b><button class="ib" id="plrAdmX" aria-label="إغلاق">${ic('x', 18)}</button></div><div id="plrAdmL"></div></div>
  </div>`;
  document.body.appendChild(root); root.querySelectorAll('input,textarea').forEach((e) => { e.spellcheck = false; e.setAttribute('autocorrect', 'off'); e.setAttribute('autocapitalize', 'off'); });
  const g = (id) => $(id);

  const hash = (s) => { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) | 0; return Math.abs(h); };
  const GR = [['#0E5C46', '#06261d'], ['#B98A2E', '#5a3d0c'], ['#1F6F78', '#0b2f35'], ['#8C3B2E', '#3a140f'], ['#4B3F72', '#1c1733'], ['#2F6B3A', '#0f2a14']];
  const gOf = (t) => GR[hash(t.id || t.title) % GR.length];
  const CVK = (t) => 'minbar.cover.' + t.id; const cov = (t) => { try { return localStorage.getItem(CVK(t)) || t.cover || ''; } catch (e) { return t.cover || ''; } };
  function coverEl(t, el) {
    el.textContent = ''; el.style.background = ''; const cu = cov(t);
    if (cu) { const im = document.createElement('img'); im.src = cu; im.alt = ''; im.onerror = () => { im.remove(); gen(); }; el.appendChild(im); } else gen();
    function gen() { const c = gOf(t); el.style.background = `radial-gradient(120% 90% at 30% 20%,${c[0]},${c[1]})`; const w = document.createElement('div'); w.className = 'gcv'; w.innerHTML = `<svg viewBox="0 0 100 100"><g fill="none" stroke="currentColor" stroke-width="1.2"><rect x="26" y="26" width="48" height="48"/><rect x="26" y="26" width="48" height="48" transform="rotate(45 50 50)"/><circle cx="50" cy="50" r="14"/></g></svg><b></b><small></small>`; w.children[1].textContent = t.title || ''; w.children[2].textContent = t.reciter || ''; el.appendChild(w); }
  }
  async function coverBlob(t) {
    if (cov(t)) { try { const r = await fetch(cov(t)); if (r.ok) return await r.blob(); } catch (e) {} }
    const c = document.createElement('canvas'); c.width = c.height = 1080; const x = c.getContext('2d'), k = gOf(t);
    const gr = x.createLinearGradient(0, 0, 1080, 1080); gr.addColorStop(0, k[0]); gr.addColorStop(1, k[1]); x.fillStyle = gr; x.fillRect(0, 0, 1080, 1080);
    x.save(); x.translate(540, 540); x.strokeStyle = 'rgba(243,216,138,.22)'; x.lineWidth = 6; for (let q = 0; q < 2; q++) { x.save(); x.rotate(q * Math.PI / 4); x.strokeRect(-260, -260, 520, 520); x.restore(); } x.beginPath(); x.arc(0, 0, 150, 0, 7); x.stroke(); x.restore(); x.fillStyle = '#F3D88A'; x.textAlign = 'center'; x.font = '700 110px Amiri,Cairo,sans-serif'; x.fillText((t.title || '').slice(0, 18), 540, 560); x.font = '500 56px Cairo,sans-serif'; x.fillStyle = 'rgba(255,255,255,.85)'; x.fillText(t.reciter || '', 540, 660);
    return await new Promise((r) => c.toBlob(r, 'image/jpeg', 0.92));
  }

  async function loadCatalog() {
    const url = localStorage.getItem(CATK) || 'catalog.json'; let j = null;
    try { const r = await fetch(url, { cache: 'no-cache' }); if (r.ok) { j = await r.json(); try { localStorage.setItem(CATC, JSON.stringify(j)); } catch (e) {} } } catch (e) {}
    if (!j) { try { j = JSON.parse(localStorage.getItem(CATC) || 'null'); } catch (e) {} }
    catCovers = (j && j.covers) || []; BASE = ((j && j.tracks) || []).map((t, i) => Object.assign({ id: 't' + i, lyrics: [], cat: 'أخرى' }, t));
    let fsc = []; try { fsc = JSON.parse(localStorage.getItem(FSK) || '[]'); } catch (e) {} tracks = BASE.concat(fsc); render(); fsLoad(); setTimeout(() => { if (deepAt) deepGo(); else { lastRestore(); setTimeout(uiRestore, 600); } }, 300);
  }
  /* القصائد المرفوعة: بياناتها في Firestore (tracks) وملفاتها في مخزن Cloudflare */
  const FSK = 'minbar.tracks.fs', OWNER = 'ahmad1999199919999@gmail.com'; let BASE = [];
  const isOwner = () => { try { const u = firebase.auth().currentUser; return !!u && u.email === OWNER && u.emailVerified; } catch (e) { return false; } };
  function fsSet(arr) { const id = cur >= 0 && tracks[cur] ? tracks[cur].id : null; tracks = BASE.concat(arr); if (id) cur = tracks.findIndex((t) => t.id === id); render(); setTimeout(() => { try { newCheck(); } catch (e) {} }, 500); }
  let ALB = {}; try { ALB = JSON.parse(localStorage.getItem(FSK + '.alb') || '{}'); } catch (e) {}
  async function fsLoad() { const db = fdb(); if (!db) return; try { const [s, sa] = await Promise.all([db.collection('tracks').get(), db.collection('albums').get()]); ALB = {}; sa.forEach((d) => { ALB[d.id] = Object.assign({ id: d.id }, d.data()); }); try { localStorage.setItem(FSK + '.alb', JSON.stringify(ALB)); } catch (e) {}
      const arr = []; s.forEach((d) => { const x = d.data(); if (!x || !x.audio || x.hidden) return; const al = x.album && ALB[x.album]; arr.push(Object.assign({ lyrics: [], cat: 'أخرى' }, x, { id: d.id, fs: 1, ownCover: x.cover || '', cover: x.cover || (al && al.cover) || '', albumName: al ? al.name : '' })); }); arr.sort((a, b) => (b.at || 0) - (a.at || 0));
      const js = JSON.stringify(arr); if (js !== localStorage.getItem(FSK)) { try { localStorage.setItem(FSK, js); } catch (e) {} fsSet(arr); } } catch (e) {} }
  /* بحث متسامح (همزات/تشكيل/ة-ه) ويشمل نص الكلمات */
  const NZ = (s) => (window.LYAI ? window.LYAI.norm(s) : String(s || '').toLowerCase());
  const hay = (t) => { const ly = GLY[t.id] || (t.lyrics && t.lyrics.length ? t.lyrics : []); const key = (ly.length || 0) + ':' + (t.title || '') + (t.reciter || '') + (t.poet || ''); if (t._hk !== key) { t._hk = key; t._h = NZ([t.title, t.reciter, t.poet].join(' ')); t._hl = NZ(ly.map((x) => x.l).join(' ')); } return t; };
  const hit = (t, k) => { if (!k) return true; const nk = NZ(k); if (!nk) return true; hay(t); return t._h.includes(nk) || t._hl.includes(nk); };
  function filtered() {
    const k = q.trim().toLowerCase(); if (tab === 'pls') { const pl = pls().find((x) => x.id === plSel); return pl ? pl.ids.map(byId).filter(Boolean).filter((t) => hit(t, k)) : []; }
    return tracks.filter((t) => (tab !== 'fav' || st.fav.includes(t.id)) && (cat === 'الكل' || t.cat === cat) && hit(t, k));
  }
  function render() {
    const cs = ['الكل'].concat([...new Set(tracks.map((t) => t.cat).filter(Boolean))]); const bar = g('plrCats'); bar.textContent = '';
    cs.forEach((c) => { const b = document.createElement('button'); b.className = 'plrchip' + (c === cat ? ' on' : ''); b.textContent = c; b.onclick = () => { cat = c; render(); }; bar.appendChild(b); });
    const body = g('plrBody'); body.textContent = ''; g('plrLt').hidden = true; view = filtered(); g('plrCats').hidden = tab === 'pls';
    if (tab === 'pls') { if (!plSel) return plRender(body); const pl = pls().find((x) => x.id === plSel); if (!pl) { plSel = null; return render(); } const hb = el('div', 'plhd'); const bk = el('button', 'ib'); bk.innerHTML = ic('next', 18); bk.onclick = () => { plSel = null; render(); }; const nm = el('b', '', pl.name); const pa = el('button', 'btn small primary', 'تشغيل الكل'); pa.onclick = () => plPlay(pl); const dl = el('button', 'btn small', 'حذف'); dl.onclick = () => { if (!confirm('حذف القائمة «' + pl.name + '»؟')) return; plsSet(pls().filter((x) => x.id !== pl.id)); plSel = null; render(); }; hb.append(bk, nm, pa, dl); body.appendChild(hb); }
    g('plrCats').hidden = tab === 'pls' || (tab === 'lib' && libV !== 'all'); if (tab === 'lib' && libRender(body)) return; if (tab === 'lib' && tracks.length) body.insertBefore(el('div'), null);
    if (!view.length) { const d = document.createElement('div'); d.className = 'hint'; d.style.textAlign = 'center'; d.textContent = tab === 'fav' ? 'لا توجد عناصر في المفضلة' : (tracks.length ? 'لا توجد نتائج' : 'لا توجد قصائد بعد'); body.appendChild(d); return; }
    const grid = document.createElement('div'); grid.className = 'plrgrid';
    view.forEach((t) => {
      const c = document.createElement('div'); c.className = 'plrcard' + (cur >= 0 && tracks[cur] === t ? ' on' : ''); const cv = document.createElement('div'); cv.className = 'plrcov'; coverEl(t, cv);
      const m = document.createElement('div'); m.className = 'plrcm'; const b = document.createElement('b'); b.textContent = t.title; const s = document.createElement('small'); s.textContent = t.reciter || ''; m.append(b, s);
      const h = document.createElement('button'); h.className = 'plrheart' + (st.fav.includes(t.id) ? ' on' : ''); h.innerHTML = ic('heart', 18); h.onclick = (e) => { e.stopPropagation(); tog(t.id); render(); };
      c.append(cv, m, h); c.onclick = () => { if (c._lp) { c._lp = 0; return; } if (tracks[cur] !== t) qFrom(t, view); play(tracks.indexOf(t), true); }; lpMenu(c, t); grid.appendChild(c);
    });
    body.appendChild(grid); occRender(body);
  }
  function tog(id) { const i = st.fav.indexOf(id); if (i >= 0) st.fav.splice(i, 1); else st.fav.push(id); save(); favUi(); }
  function favUi() { const t = tracks[cur]; g('plrFav').classList.toggle('on', !!t && st.fav.includes(t.id)); }

  function play(i, open) {
    const t = tracks[i]; if (!t) return;
    if (i === cur && A.src) { if (A.paused) fadePlay(); if (open) openFull(); return; }
    cur = i; startAudio(t); loadImg(t); if (!g('plrQs').hidden) setTimeout(qBuild, 0);
    g('plrMini').hidden = false; g('plrTitle').textContent = t.title; g('plrSub').textContent = [t.reciter, t.poet].filter(Boolean).join(' · ');
    const mt = g('plrMiniT'); mt.firstChild.textContent = t.title; mt.lastChild.textContent = t.reciter || '';
    coverEl(t, g('plrMiniC')); stageBuild(); counter(); lyrBuild(); favUi(); clipReset(); render(); meta(); waveDraw();
    gFetch(t); cmLoad(t); envLoad(t); bgSet(t);
    if (open) openFull();
  }
  function bgSet(t) {
    const b = g('plrBgI'), u = cov(t), bf = g('plrBgF'), tc = g('plrTtC'); if (u) { bf.src = u; if (tc) tc.src = u; } else { bf.removeAttribute('src'); if (tc) tc.removeAttribute('src'); } b.style.backgroundImage = ''; if (!u) return; const im = new Image();
    im.onload = () => { try { const c = document.createElement('canvas'); c.width = c.height = 40; c.getContext('2d').drawImage(im, 0, 0, 40, 40); b.style.backgroundImage = `url(${c.toDataURL('image/jpeg', 0.7)})`; } catch (e) { b.style.backgroundImage = `url("${u}")`; } }; im.src = u;
  }
  /* تحليل الصوت الحي + عرض مؤثرات التصميم */
  let ac = null, an = null, fbuf = null, useLive = false, live = null, hist = [], beat = 0, cum = 0, pBass = 0, curImg = null, lastTs = 0, vTok = 0;
  const corsC = {};
  async function corsOk(url) {
    let u; try { u = new URL(url, location.href); } catch (e) { return false; } if (u.origin === location.origin) return true;
    if (corsC[u.origin] !== undefined) return corsC[u.origin];
    try { const r = await fetch(url, { method: 'HEAD', mode: 'cors' }); return (corsC[u.origin] = r.ok); } catch (e) { return (corsC[u.origin] = false); }
  }
  async function startAudio(t) {
    const tok = ++vTok; anLoad(t); const ok = await corsOk(t.audio); if (tok !== vTok) return;
    const FX = st.fx === true; /* وضع الأداء (الافتراضي): بدون WebAudio = أخف، أبرد، ويستمر بالخلفية */
    if (ok && FX && !ac) { A.crossOrigin = 'anonymous'; }
    A.__seekFail = false; A.src = t.audio; /* لا ننزّل نسخة كاملة بالتوازي مع البث (تخنق الاتصال فينقطع الصوت): نؤجلها حتى يستقر التشغيل */ clearTimeout(MB.tm); MB.tm = setTimeout(() => { const c = tracks[cur]; if (c && c.id === t.id) mediaBlob(c); }, 25000); A.playbackRate = st.speed; A.volume = st.uvol == null ? 1 : st.uvol; if (AU.fade && ac) { AU.fade.gain.cancelScheduledValues(0); AU.fade.gain.value = 1; }
    if (ok && FX && !ac) { try { const AC = window.AudioContext || window.webkitAudioContext; try { ac = new AC({ latencyHint: 'playback' }); } catch (x) { ac = new AC(); } const sn = ac.createMediaElementSource(A); an = ac.createAnalyser(); an.fftSize = 2048; an.smoothingTimeConstant = 0.15; auBuild(sn); an.connect(ac.destination); fbuf = new Uint8Array(an.frequencyBinCount); } catch (e) { ac = null; } }
    useLive = !!(ok && ac); auNote(); if (ac && ac.state === 'suspended') ac.resume().catch(() => {});
    if (A.__noAuto) A.__noAuto = false; else A.play().catch(() => {});
  }
  /* حل نهائي لمشكلة التقديم: تنزيل الملف كاملاً كنسخة محلية (مع تخزين لآخر المقاطع) ثم الاستبدال بسلاسة.
     إذا فشل القفز قبل اكتمال التنزيل يُحفظ الموضع المطلوب ويُطبَّق فور الجاهزية */
  const MB = { id: null, url: null, ready: false, pend: null, busy: null, seekT: null, want: null, wantAt: 0 };
  /* قفز مضمون إلى موضع محدد (رابط مشاركة، استئناف، مجلس): يُعاد تطبيقه حتى يتحقق فعلاً */
  function seekTo(t) { MB.tryAt = 0; MB.want = Math.max(0, t); MB.wantAt = Date.now(); MB.lw = MB.want; MB.lwAt = Date.now(); if (A.readyState >= 1) { try { A.currentTime = MB.want; } catch (e) {} } }
  const wantCov = (w) => { try { for (let i = 0; i < A.seekable.length; i++) if (A.seekable.start(i) <= w && A.seekable.end(i) >= w + 1) return true; } catch (e) {} return false; };
  const wantChk = () => { if (MB.want == null) return; if (Date.now() - MB.wantAt > 30000) { MB.want = null; return; } if (A.readyState < 1 || A.seeking) return; const cov = wantCov(MB.want) && !(A.__seekFail && !MB.ready);
    if (Math.abs(A.currentTime - MB.want) > 1.5) { if (cov && Date.now() - (MB.tryAt || 0) > 1200) { MB.tryAt = Date.now(); const w = MB.want; try { A.currentTime = w; } catch (e) {} setTimeout(() => { if (MB.want === w && Math.abs(A.currentTime - w) > 1.5) { A.__seekFail = true; if (MB.ready) swapToBlob(true); } }, 900); } }
    else if (A.readyState >= 2 && cov && (A.paused || A.currentTime > MB.want + 0.4)) MB.want = null; };
  ['loadedmetadata', 'loadeddata', 'canplay', 'playing', 'timeupdate'].forEach((ev) => A.addEventListener(ev, wantChk));
  function mediaBlob(t) {
    if (!t || !t.audio || /^blob:/.test(t.audio)) return null; if (MB.id === t.id && (MB.ready || MB.busy)) return MB.busy;
    if (MB.url) { try { URL.revokeObjectURL(MB.url); } catch (e) {} } Object.assign(MB, { id: t.id, url: null, ready: false, pend: null });
    const id = t.id, key = new URL(t.audio, location.href).href;
    MB.busy = (async () => { let r = null, c = null; try { c = await caches.open('mbr-media'); r = await c.match(key); } catch (e) {}
      if (!r) { const f = await fetch(key); if (!f.ok) throw new Error('net'); r = f; if (c) { try { await c.put(key, f.clone()); const ks = await c.keys(); for (let i = 0; i < ks.length - 8; i++) await c.delete(ks[i]); } catch (e) {} } }
      const b = await r.blob(); if (MB.id !== id) return; MB.url = URL.createObjectURL(b); MB.ready = true; swapToBlob(); })().catch(() => { if (MB.id === id) MB.busy = null; });
    return MB.busy;
  }
  function swapToBlob(force) { const t = tracks[cur]; if (!t || MB.id !== t.id || !MB.url || A.src === MB.url) return; /* لا نقطع الصوت أثناء التشغيل إلا عند الحاجة (تقديم فاشل) */ if (!force && !A.paused && !A.__seekFail) return; const lwOk = MB.lw != null && Date.now() - (MB.lwAt || 0) < 60000 && A.currentTime < MB.lw - 1.5, pos = MB.want != null ? MB.want : MB.pend != null ? MB.pend : lwOk ? MB.lw : A.currentTime, was = !A.paused || (MB.pend != null && !A.__keepPaused); MB.pend = null; MB.lw = null;
    const go = () => { A.removeEventListener('loadedmetadata', go); try { A.currentTime = pos; } catch (e) {} A.playbackRate = st.speed || 1; if (was) A.play().catch(() => {}); }; A.addEventListener('loadedmetadata', go); A.src = MB.url; }
  A.addEventListener('seeking', () => { MB.seekT = A.currentTime; });
  A.addEventListener('seeked', () => { const want = MB.seekT; MB.seekT = null; if (want == null) return; if (MB.ready) { if (A.currentTime < want - 1.5 && MB.url && A.src !== MB.url) { MB.pend = want; swapToBlob(true); } return; } if (A.currentTime < want - 1.5) { MB.pend = want; const t = tracks[cur]; if (t) { mediaBlob(t); toast('جارٍ تجهيز المقطع للانتقال…'); } } });
  function loadImg(t) {
    const im = new Image(); curImg = im; im.onload = () => { if (curImg === im) setTimeout(bgApply, 0); };
    if (cov(t)) { im.crossOrigin = 'anonymous'; im.src = cov(t); im.onerror = () => gen(); } else gen();
    function gen() { coverBlob(t).then((b) => { if (curImg === im && b) im.src = URL.createObjectURL(b); }); }
  }
  let fqd = null, tdb = null;
  /* تقدير مكوّنات الصوت: المنشد / الإيقاع (اللطم والطبل) / الجمهور / الآلات — بتطبيع متكيّف */
  let stK = false; const agF = [], agP = [], STM = { voc: 0, drum: 0, crowd: 0, inst: 0, on: 0 }, SAG = {}; let pfq = null;
  function stemsApply(dt, vb, cb, hb, lb, on) {
    const ag = (k, db, up, down) => { const q = SAG[k] || (SAG[k] = { f: db - 10, p: db + 4 }); q.f = db < q.f ? q.f + (db - q.f) * Math.min(1, dt * 5) : q.f + dt * (up || 1); q.p = db > q.p ? q.p + (db - q.p) * Math.min(1, dt * 15) : q.p - dt * (down || 2); return Math.max(0, Math.min(1, (db - q.f) / Math.max(14, q.p - q.f))); };
    const harm = Math.max(0, Math.min(1, (vb.peak - 6) / 22)), noisy = Math.max(0, Math.min(1, (cb.flat - 0.18) / 0.4));
    const sm = (k, x, at, rl) => { STM[k] += (x - STM[k]) * Math.min(1, dt * (x > STM[k] ? at : rl)); };
    sm('voc', ag('voc', vb.db) * (0.35 + 0.65 * harm), 14, 5); sm('crowd', ag('crowd', cb.db) * noisy, 10, 4); sm('inst', ag('inst', hb.db) * 0.7 + ag('low', lb.db) * 0.3 * (1 - on), 10, 4);
    STM.drum = Math.max(STM.drum * Math.pow(0.08, dt), on); STM.on = on > 0.25 ? on : 0;
  }
  function stemsCalc(dt) {
    const ny = ac.sampleRate / 2, n = fqd.length, bi = (f) => Math.max(1, Math.min(n - 1, Math.round(f / ny * n)));
    const band = (f0, f1) => { const a = bi(f0), b = bi(f1); let s = 0, lg = 0, mx = 0, c = 0; for (let k = a; k < b; k++) { const pw = Math.pow(10, fqd[k] / 10); s += pw; lg += Math.log(pw + 1e-14); if (pw > mx) mx = pw; c++; } const m = s / c; return { db: 10 * Math.log10(m + 1e-14), flat: Math.exp(lg / c) / (m + 1e-14), peak: mx / (m + 1e-14) }; };
    const flux = (f0, f1) => { if (!pfq) return 0; const a = bi(f0), b = bi(f1); let s = 0; for (let k = a; k < b; k++) { const d = fqd[k] - pfq[k]; if (d > 0) s += d; } return s / (b - a); };
    const vb = band(250, 3500), cb = band(500, 6000), hb = band(5000, 14000), lb = band(40, 160);
    const on = Math.max(0, Math.min(1, (flux(40, 180) * 0.7 + flux(1500, 6000) * 0.5 - 2.2) / 6));
    stemsApply(dt, vb, cb, hb, lb, on);
    if (!pfq || pfq.length !== n) pfq = new Float32Array(n); pfq.set(fqd);
  }
  /* ===== تحليل صوتي مسبق: يُحسب مرة واحدة (بالخلفية عند المالك) ويُقرأ وقت التشغيل بلا أي معالجة صوت — يحرّك الرسم واللطم بدل التحليل الحي ===== */
  const APPV = '3.92';
  const ANV = 'v1', ANKEY = (t) => 'n/' + t.id + '-' + ANV + '.bin', ANOK = (t) => /^[A-Za-z0-9_-]{3,64}$/.test((t && t.id) || '');
  let PRE = null; const PF = { dd: new Float32Array(22), vb: { db: 0, peak: 1 }, cb: { db: 0, flat: 0 }, hb: { db: 0 }, lb: { db: 0 }, on: 0 }; let synW = null, synT = 0;
  async function anLoad(t) { PRE = null; if (!t || t.an !== 1 || !ANOK(t)) return; try { const r = await fetch('media/u/' + ANKEY(t)); if (!r.ok) return; const b = new Uint8Array(await r.arrayBuffer()); if (b.length < 12 || b[0] !== 77 || b[1] !== 66 || b[2] !== 65) return; const nf = new DataView(b.buffer).getUint32(8, true); if (tracks[cur] && tracks[cur].id === t.id) PRE = { id: t.id, fps: b[4], nf, W: b[5] + b[6], d: b, o: 12 }; } catch (e) {} }
  function preAt(t) { const P = PRE; if (!P || !P.nf || !tracks[cur] || tracks[cur].id !== P.id) return false; let x = Math.max(0, t) * P.fps, i = Math.floor(x); if (i >= P.nf - 1) { i = P.nf - 1; x = i; } const f = x - i, i1 = Math.min(P.nf - 1, i + 1), d = P.d, a = P.o + i * P.W, b = P.o + i1 * P.W, q = (k) => d[a + k] + (d[b + k] - d[a + k]) * f, dq = (k) => q(k) / 1.5 - 140;
    for (let k = 0; k < 22; k++) PF.dd[k] = dq(k); PF.vb.db = dq(22); PF.cb.db = dq(23); PF.hb.db = dq(24); PF.lb.db = dq(25); PF.vb.peak = Math.pow(2, q(26) / 30); PF.cb.flat = q(27) / 255; PF.on = Math.max(0, Math.min(1, (q(28) / 12 * 0.7 + q(29) / 12 * 0.5 - 2.2) / 6)); return true; }
  function synWave(v, t) { if (!synW) synW = new Float32Array(2048); let a = 0; for (let i = 0; i < v.length; i++) a += v[i]; a = a / v.length * 0.5; for (let j = 0; j < 2048; j++) synW[j] = a * (0.6 * Math.sin(j * 0.045 + t * 40) + 0.3 * Math.sin(j * 0.19 + t * 27) + 0.2 * (Math.random() - 0.5)); return synW; }
  const AN = (() => { const N = 2048, rev = new Uint16Array(N), cs = new Float64Array(N / 2), sn = new Float64Array(N / 2), w = new Float64Array(N), bits = 11; for (let i = 0; i < N; i++) { let r = 0; for (let b = 0; b < bits; b++) if (i & (1 << b)) r |= 1 << (bits - 1 - b); rev[i] = r; w[i] = 0.42 - 0.5 * Math.cos(2 * Math.PI * i / N) + 0.08 * Math.cos(4 * Math.PI * i / N); } for (let i = 0; i < N / 2; i++) { cs[i] = Math.cos(2 * Math.PI * i / N); sn[i] = -Math.sin(2 * Math.PI * i / N); } return { N, rev, cs, sn, w }; })();
  function anFFT(re, im) { const { N, rev, cs, sn } = AN; for (let i = 0; i < N; i++) { const j = rev[i]; if (j > i) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
    for (let len = 2; len <= N; len <<= 1) { const h = len >> 1, st = N / len; for (let i = 0; i < N; i += len) for (let k = 0, ti = 0; k < h; k++, ti += st) { const wr = cs[ti], wi = sn[ti], a = i + k, b = a + h, xr = re[b] * wr - im[b] * wi, xi = re[b] * wi + im[b] * wr; re[b] = re[a] - xr; im[b] = im[a] - xi; re[a] += xr; im[a] += xi; } } }
  async function anCompute(x, sr, onp) {
    const N = AN.N, B = N / 2, hop = sr / 30, nf = Math.floor(x.length / hop), W = 30, out = new Uint8Array(12 + nf * W), ny = sr / 2, re = new Float64Array(N), im = new Float64Array(N), sm = new Float64Array(B), fq = new Float32Array(B), pf = new Float32Array(B);
    out.set([77, 66, 65, 1, 30, 22, 8, 0]); new DataView(out.buffer).setUint32(8, nf, true);
    const bi = (f) => Math.max(1, Math.min(B - 1, Math.round(f / ny * B))), bands = [];
    for (let i = 0; i < 22; i++) { const f0 = 40 * Math.pow(400, i / 22), f1 = 40 * Math.pow(400, (i + 1) / 22), a = Math.max(1, Math.floor(f0 / ny * B)), b = Math.max(a + 1, Math.ceil(f1 / ny * B)); bands.push([a, b, 3.2 * Math.log2(Math.max(1, Math.sqrt(f0 * f1) / 150))]); }
    const bandS = (f0, f1) => { const a = bi(f0), b = bi(f1); let s = 0, lg = 0, mx = 0, c = 0; for (let k = a; k < b; k++) { const pw = Math.pow(10, fq[k] / 10); s += pw; lg += Math.log(pw + 1e-14); if (pw > mx) mx = pw; c++; } const m = s / c; return { db: 10 * Math.log10(m + 1e-14), flat: Math.exp(lg / c) / (m + 1e-14), peak: mx / (m + 1e-14) }; };
    const flux = (f0, f1) => { const a = bi(f0), b = bi(f1); let s = 0; for (let k = a; k < b; k++) { const d = fq[k] - pf[k]; if (d > 0) s += d; } return s / (b - a); };
    const Q = (v) => Math.max(0, Math.min(255, Math.round((v + 140) * 1.5))), U = (v) => Math.max(0, Math.min(255, Math.round(v)));
    for (let j = 0; j < nf; j++) {
      const end = Math.round(j * hop); for (let i = 0; i < N; i++) { const s = end - N + i; re[i] = (s >= 0 && s < x.length ? x[s] : 0) * AN.w[i]; im[i] = 0; } anFFT(re, im);
      for (let k = 0; k < B; k++) { const m = Math.sqrt(re[k] * re[k] + im[k] * im[k]) / N; sm[k] = 0.15 * sm[k] + 0.85 * m; fq[k] = Math.max(-140, 20 * Math.log10(sm[k] + 1e-12)); }
      const o = 12 + j * W; for (let i = 0; i < 22; i++) { const bd = bands[i]; let s = 0; for (let k = bd[0]; k < bd[1] && k < B; k++) s += Math.pow(10, fq[k] / 10); out[o + i] = Q(10 * Math.log10(s / (bd[1] - bd[0]) + 1e-12) + bd[2]); }
      const vb = bandS(250, 3500), cb = bandS(500, 6000), hb = bandS(5000, 14000), lb = bandS(40, 160);
      out[o + 22] = Q(vb.db); out[o + 23] = Q(cb.db); out[o + 24] = Q(hb.db); out[o + 25] = Q(lb.db); out[o + 26] = U(Math.log2(Math.max(1, vb.peak)) * 30); out[o + 27] = U(cb.flat * 255); out[o + 28] = U(flux(40, 180) * 12); out[o + 29] = U(flux(1500, 6000) * 12);
      pf.set(fq); if (j % 120 === 119) { if (anAbort && !A.paused) throw 'abort'; if (onp) onp(j / nf); await new Promise((z) => setTimeout(z, 0)); }
    }
    return out;
  }
  let anBusy = false, anAbort = false; A.addEventListener('play', () => { if (anBusy) anAbort = true; }); const anFail = new Set(); const toastDone = (n, bad) => { if (n || bad) toast('انتهى التحليل: نجح ' + n + (bad ? ' · فشل ' + bad : '')); };
  const anPending = () => tracks.filter((t) => t.fs && t.an !== 1 && ANOK(t) && t.audio && !anFail.has(t.id));
  async function anRun(manual) {
    if (anBusy || !isOwner() || !fdb() || document.hidden || (!manual && (!A.paused || aqBusy || aiBusy))) return; let todo = anPending(); if (!todo.length) { if (manual) toast('كل القصائد محلَّلة'); return; }
    anBusy = true; anAbort = false; toast('بدأ تحليل الصوت: ' + todo.length + ' قصيدة (' + (manual ? 'يدوي' : 'تلقائي') + ')'); let n = 0, bad = 0;
    for (const t of todo) { if (document.hidden || (!manual && !A.paused)) break;
      try { if (!manual && anAbort) break; const ab = await (await fetch(t.audio)).arrayBuffer(); if (!manual && anAbort) break; const buf = await new OfflineAudioContext(1, 1, 32000).decodeAudioData(ab); if (buf.duration > 1500) throw 0; let x = buf.getChannelData(0); if (buf.numberOfChannels > 1) { const y = buf.getChannelData(1), m = new Float32Array(x.length); for (let i = 0; i < m.length; i++) m[i] = (x[i] + y[i]) / 2; x = m; }
        const out = await anCompute(x, 32000, (v) => { const c = g('plrAq'); if (c && !c.hidden) c.querySelector('small').textContent = 'تحليل ' + Math.round(v * 100) + '% · ' + t.title; });
        await upPut(ANKEY(t), out, 'application/octet-stream'); await fdb().collection('tracks').doc(t.id).set({ an: 1 }, { merge: true }); t.an = 1; n++; }
      catch (e) { if (e === 'abort') break; anFail.add(t.id); bad++; console.warn('an', t.id, e); if (bad === 1) toast('تعذّر تحليل «' + (t.title || t.id) + '»: ' + String((e && (e.message || e.error || e.name)) || e || 'خطأ').slice(0, 80)); }
      await new Promise((z) => setTimeout(z, 800)); }
    anBusy = false; toastDone(n, bad);
  }
  setTimeout(() => { try { anRun(false); } catch (e) {} }, 8000); setInterval(() => { try { anRun(false); } catch (e) {} }, 60000); document.addEventListener('visibilitychange', () => { if (!document.hidden) setTimeout(() => anRun(false), 6000); });
  function bandUpd(i, dd, dt, k60, v) { if (agF[i] == null) { agF[i] = dd - 12; agP[i] = dd + 6; } agF[i] = dd < agF[i] ? agF[i] + (dd - agF[i]) * Math.min(1, dt * 6) : agF[i] + dt * 1.2; agP[i] = dd > agP[i] ? agP[i] + (dd - agP[i]) * Math.min(1, dt * 20) : agP[i] - dt * 2.2;
        const span = Math.max(20, agP[i] - agF[i]), xa = Math.max(0, Math.min(1, (dd - agF[i]) / span)), xf = Math.max(0, Math.min(1, (dd + 78) / 54)); const x = Math.pow(xa * 0.7 + xf * 0.3, 1.6) * (dd < -82 ? 0 : 1);
        v[i] = x > v[i] ? v[i] + (x - v[i]) * Math.min(1, 0.85 * k60 + 0.15) : v[i] + (x - v[i]) * 0.26 * k60; }
  function feat(dt) {
    const N = 22, v = live ? live.vals : new Float32Array(N), k60 = Math.min(1, dt * 60); let wave = live && live.wave, pf = false;
    if (useLive && an && !A.paused) {
      if (!fqd) { fqd = new Float32Array(an.frequencyBinCount); tdb = new Float32Array(an.fftSize); } an.getFloatFrequencyData(fqd); an.getFloatTimeDomainData(tdb); wave = tdb;
      const ny = ac.sampleRate / 2, bins = fqd.length;
      for (let i = 0; i < N; i++) {
        const f0 = 40 * Math.pow(16000 / 40, i / N), f1 = 40 * Math.pow(16000 / 40, (i + 1) / N), a = Math.max(1, Math.floor(f0 / ny * bins)), b = Math.max(a + 1, Math.ceil(f1 / ny * bins));
        let s = 0; for (let k = a; k < b && k < bins; k++) s += Math.pow(10, fqd[k] / 10); const db = 10 * Math.log10(s / (b - a) + 1e-12), fc = Math.sqrt(f0 * f1), tilt = 3.2 * Math.log2(Math.max(1, fc / 150));
        bandUpd(i, db + tilt, dt, k60, v);
      }
    } else if (!A.paused && preAt(A.currentTime)) { pf = true; for (let i = 0; i < N; i++) bandUpd(i, PF.dd[i], dt, k60, v); if ((synT = (synT + 1) % 2) === 0 || !wave) wave = synWave(v, A.currentTime); }
    else if (!A.paused) { const t = A.currentTime; for (let i = 0; i < N; i++) v[i] = 0.18 + 0.4 * Math.abs(Math.sin(t * 3.1 + i * 0.6)) * (1 - i / N * 0.5); }
    else for (let i = 0; i < N; i++) v[i] *= Math.pow(0.9, k60);
    if (useLive && an && !A.paused && fqd && (!LITE || (stK = !stK))) stemsCalc(dt); else if (pf) stemsApply(dt, PF.vb, PF.cb, PF.hb, PF.lb, PF.on); else { ['voc', 'drum', 'crowd', 'inst'].forEach((k) => { STM[k] *= Math.pow(0.9, k60); }); }
    const avg = (a, b) => { let s2 = 0; for (let i = a; i < b; i++) s2 += v[i]; return s2 / (b - a); };
    const bass = avg(0, 4), mid = avg(4, 13), hi = avg(13, N), vol = avg(0, N), fl = Math.max(0, bass - pBass); pBass = bass;
    beat = Math.max(beat * Math.pow(0.86, k60), fl > 0.04 ? Math.min(1, fl * 7) : 0, STM.on); cum += dt * (A.paused ? 0 : 0.6 + vol * 1.5);
    live = { vals: v, vol, bass, mid, hi, beat, cum, f: Math.floor(A.currentTime * 30), sp: null, hist: [v], wave, stems: STM, pre: pf }; dlyPush();
  }

  /* خلفية «أجواء»: هادئة تتنفس مع الصوت بلطف */
  const amb = { b: 0, v: 0, m: 0, ps: null };
  function drawAmbient(x, W, H, t, F, B) {
    x.setTransform(1, 0, 0, 1, 0, 0); x.globalAlpha = 1; x.globalCompositeOperation = 'source-over'; const k = 0.06; amb.b += (F.bass - amb.b) * k; amb.v += (F.vol - amb.v) * k; amb.m += (F.mid - amb.m) * k; const u = Math.min(W, H);
    x.clearRect(0, 0, W, H);
    /* مركز الغلاف الفعلي */
    let cx = B ? B.cx : W / 2, cy = B ? B.cy : H * 0.4, rr = B ? B.R * 0.86 : u * 0.22;
    const fx = x, HS = 0.5; if (!amb.bg || amb.bg.width !== Math.round(W * HS) || amb.bg.height !== Math.round(H * HS)) { amb.bg = document.createElement('canvas'); amb.bg.width = Math.round(W * HS); amb.bg.height = Math.round(H * HS); }
    x = amb.bg.getContext('2d'); x.setTransform(HS, 0, 0, HS, 0, 0); x.clearRect(0, 0, W, H);
    [[0.2, 0.15, '26,138,104', 0.7, 0.27], [0.85, 0.7, '20,110,84', 0.65, 0.21]].forEach(([px, py, c, r, sp], i) => {
      const bx = W * (px + 0.08 * Math.sin(t * sp * 0.5 + i * 2)), by = H * (py + 0.06 * Math.cos(t * sp * 0.4 + i)), rad = Math.max(W, H) * r;
      const gr = x.createRadialGradient(bx, by, 0, bx, by, rad); gr.addColorStop(0, `rgba(${c},${0.18 + amb.v * 0.08})`); gr.addColorStop(1, `rgba(${c},0)`); x.fillStyle = gr; x.fillRect(0, 0, W, H);
    });
    /* أشعة هادئة: تُرسم مرة واحدة ثم تُدار */
    const L = Math.ceil(Math.hypot(W, H)); if (!amb.ray || amb.rl !== L) { const oc = document.createElement('canvas'), RS = 0.35; oc.width = oc.height = Math.round(L * 2 * RS); const o = oc.getContext('2d'); o.scale(RS, RS); o.translate(L, L); const n = 18;
      for (let i = 0; i < n; i++) { const a0 = i * Math.PI * 2 / n, w = 0.05, gr = o.createLinearGradient(0, 0, Math.cos(a0) * L * 0.6, Math.sin(a0) * L * 0.6); gr.addColorStop(0, 'rgba(232,196,104,1)'); gr.addColorStop(1, 'rgba(232,196,104,0)'); o.fillStyle = gr; o.beginPath(); o.moveTo(0, 0); o.lineTo(Math.cos(a0 - w) * L, Math.sin(a0 - w) * L); o.lineTo(Math.cos(a0 + w) * L, Math.sin(a0 + w) * L); o.closePath(); o.fill(); }
      amb.ray = oc; amb.rl = L; }
    x.save(); x.translate(cx, cy); x.rotate(t * 0.02); x.globalAlpha = 0.05 + amb.m * 0.07; x.drawImage(amb.ray, -L, -L, 2 * L, 2 * L); x.restore(); x.globalAlpha = 1;
    x = fx; x.drawImage(amb.bg, 0, 0, W, H);
    /* هالة تتنفس مع الجهير */
    const hr = rr * (1.25 + amb.b * 0.18), hg = x.createRadialGradient(cx, cy, rr * 0.85, cx, cy, hr * 1.6); hg.addColorStop(0, `rgba(232,196,104,${0.16 + amb.b * 0.22})`); hg.addColorStop(1, 'rgba(232,196,104,0)'); x.fillStyle = hg; x.beginPath(); x.arc(cx, cy, hr * 1.6, 0, 7); x.fill();
    x.strokeStyle = `rgba(243,216,138,${0.12 + amb.b * 0.3})`; x.lineWidth = Math.max(1, u / 300); x.beginPath(); x.arc(cx, cy, rr * (1.12 + amb.b * 0.08), 0, 7); x.stroke();
    if (!amb.ps) amb.ps = Array.from({ length: 30 }, (_, i) => ({ x: Math.random(), y: Math.random(), s: 0.5 + Math.random(), p: i }));
    amb.ps.forEach((q) => { q.y -= (0.0005 + amb.v * 0.0012) * q.s; if (q.y < -0.02) { q.y = 1.02; q.x = Math.random(); } const px = (q.x + 0.02 * Math.sin(t * 0.4 + q.p)) * W; x.fillStyle = `rgba(243,216,138,${0.08 + 0.18 * q.s * (0.4 + amb.v)})`; x.beginPath(); x.arc(px, q.y * H, (0.7 + q.s * 1.2) * u / 380, 0, 7); x.fill(); });
    if (window.PVZ && B) window.PVZ.cover(x, curImg, cx, cy, rr, 'c');
  }

  /* ساعة ناعمة: تتقدّم كل إطار وتُصحَّح بلطف على وقت المشغل، مع تعويض تأخر مخرج الصوت */
  const clk = { ct: 0, at: 0, v: 0 };
  function nowT() {
    const ct = A.currentTime, pn = performance.now() / 1000; if (A.paused || A.seeking) { clk.v = ct; clk.ct = ct; clk.at = pn; return ct; }
    if (ct !== clk.ct) { clk.ct = ct; clk.at = pn; } const est = clk.ct + (pn - clk.at) * (A.playbackRate || 1);
    clk.v = Math.abs(est - clk.v) > 0.3 ? est : clk.v + (est - clk.v) * 0.25 + 0; clk.v = Math.max(clk.v, 0); return clk.v;
  }
  const outLat = () => { try { return ac && useLive ? Math.min(0.4, (ac.outputLatency || 0) + (ac.baseLatency || 0)) : 0; } catch (e) { return 0; } };
  const heardT = () => Math.max(0, nowT() - outLat());
  /* صندوق المرئيات: المساحة بين الشريط العلوي وشريط الكلمات */
  let boxC = null, boxAt = 0;
  function vizBox(cv, dpr) {
    const n = performance.now(); if (boxC && n - boxAt < 400 && boxC.w === cv.width) return boxC;
    const cr = cv.getBoundingClientRect(), hd = g('plrFh').getBoundingClientRect(), ly = g('plrLyr').getBoundingClientRect();
    let top = Math.max(cr.top, hd.bottom + 8), bot = Math.min(cr.bottom, ly.top - 8); if (st.lay === 'b' || bot - top < 120) { top = cr.top + 8; bot = cr.bottom - 8; } if (st.lay === 'c') { top = hd.bottom + 20; bot = (g('plrTt').getBoundingClientRect().top) - 20; }
    const hh = bot - top, cx = cr.width / 2, cy = top - cr.top + hh / 2, R = Math.max(40, Math.min(cr.width * 0.31, hh * 0.36));
    boxC = { cx: cx * dpr, cy: cy * dpr, R: R * dpr, w: cv.width }; boxAt = n; return boxC;
  }
  let lnK = 0; A.addEventListener('pause', () => { A.__pz = performance.now(); });
  let vizAcc = 0, bpLast = -1, vizDpr = 2, vizMs = 5, vzSk = false; const vs = { pk: 0, dx: 0, to: 0, drag: false, after: null };
  /* الوضع الخفيف للأجهزة الضعيفة: تلقائي حسب الجهاز أو حسب الأداء الفعلي */
  /* الوضع الخفيف: للأجهزة الضعيفة فقط، ولا يُحفظ دائماً (كان يُحفظ فيُخفض الجودة إلى الأبد بعد لحظة بطء واحدة) */
  try { localStorage.removeItem('minbar.lite'); } catch (e) {}
  let LITE = (navigator.hardwareConcurrency || 8) <= 3 || (navigator.deviceMemory || 8) <= 2, lfE = 0.016, lfN = 0;
  const liteSet = (on) => { LITE = on; root.classList.toggle('lite', on); if (on) vizDpr = Math.min(vizDpr, 1.5); };
  if (LITE) { root.classList.add('lite'); vizDpr = 1.5; }
  /* لما المتصفح تخلص ذاكرة الرسم يفقد الكانفس سياقه ويطلع مربع أبيض بوجه حزين: نخفف الرسم ونعيد بناء الكانفس */
  root.addEventListener('contextlost', (e) => { const cv = e.target; try { liteSet(true); vizDpr = 1; } catch (x) {} setTimeout(() => { try { cv.width = 1; cv.height = 1; } catch (x) {} try { waveDraw(); } catch (x) {} }, 400); }, true);
  root.addEventListener('contextrestored', () => { try { waveDraw(); } catch (x) {} }, true);
  function liteCheck(raw) { if (LITE || document.hidden) return; lfE = lfE * 0.95 + Math.min(0.2, raw) * 0.05; if (lfE > 1 / 20) { if (++lfN > 300) liteSet(true); } else lfN = Math.max(0, lfN - 2); }
  function vizLoop(ts) {
    if (root.hidden || g('plrFull').hidden || document.hidden) { vizOn = false; return; }
    requestAnimationFrame(vizLoop);
    const raw = (ts - lastTs) / 1000 || 0.016; if (raw < (LITE ? 1 / 32 : A.paused && performance.now() - (A.__pz || 0) > 2000 ? 1 / 12 : 1 / 42)) return; liteCheck(raw); const dt = Math.min(0.1, raw); lastTs = ts; feat(dt); if (st.lay === 'a') { specDraw(dt); if ((lnK = (lnK + 1) % 3) === 0) lnUi(); }
    lyBp += ((live ? live.bass : 0) - lyBp) * 0.25; if (Math.abs(lyBp - bpLast) > (LITE ? 0.06 : 0.015)) { bpLast = lyBp; g('plrLyr').style.setProperty('--bp', lyBp.toFixed(2)); g('plrPlay').style.setProperty('--bp', lyBp.toFixed(2)); }
    cmTick(); rxTick(); latmTick(); if (!A.paused) lyrTick(); if (!g('plrLys').hidden) return;
    const cv = g('plrViz'); if (cv.hidden || !(window.PVZ && window.PVZ.has(st.viz) || st.viz === 'ambient')) return;
    const dpr = Math.min(window.devicePixelRatio || 1, vizDpr), w = cv.clientWidth, h = cv.clientHeight; if (!w || !h) return; const t0d = performance.now();
    if (cv.width !== Math.round(w * dpr) || cv.height !== Math.round(h * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); }
    if (LITE && vizMs > 11 && (vzSk = !vzSk) && !vs.drag && Math.abs(vs.dx - vs.to) < 1) return;
    const x = cv.getContext('2d'); x.setTransform(1, 0, 0, 1, 0, 0); x.globalAlpha = 1; x.globalCompositeOperation = 'source-over'; x.shadowBlur = 0; x.shadowColor = 'transparent'; try { x.filter = 'none'; } catch (e) {} x.lineWidth = 1; x.setLineDash && x.setLineDash([]);
    vs.pk += ((A.paused ? 0 : 1) - vs.pk) * Math.min(1, dt * 4); vs.dx += (vs.to - vs.dx) * (vs.drag ? 1 : Math.min(1, dt * 9)); if (vs.after && Math.abs(vs.dx - vs.to) < 6) { const f2 = vs.after; vs.after = null; f2(); }
    try { const T = heardT(), B0 = vizBox(cv, dpr), sx = vs.dx * dpr, B = Object.assign({}, B0, { cx: B0.cx + sx }); x.setTransform(1, 0, 0, 1, 0, 0); const fa = 1 - Math.min(0.85, Math.abs(vs.dx) / (cv.clientWidth || 360));
      if (st.viz === 'ambient') { drawAmbient(x, cv.width, cv.height, T + ts / 1000, live, B); } else { window.PVZ.draw(x, cv.width, cv.height, st.viz, live, curImg, B, { t: T, now: ts / 1000, dt, paused: A.paused, pk: vs.pk * fa + 0.0001, ctl: window.__plrCtl }); }
      if (fa < 1) { x.setTransform(1, 0, 0, 1, 0, 0); x.globalCompositeOperation = 'destination-in'; x.fillStyle = `rgba(0,0,0,${fa.toFixed(3)})`; x.fillRect(0, 0, cv.width, cv.height); x.globalCompositeOperation = 'source-over'; }
    } catch (e) { console.warn(e); }
    x.setTransform(1, 0, 0, 1, 0, 0); const dms = performance.now() - t0d; vizMs = vizMs * 0.95 + dms * 0.05; if (vizMs > 12 && vizDpr > (LITE ? 1.25 : 1.5)) { vizDpr = Math.max(LITE ? 1.25 : 1.5, vizDpr - 0.25); vizMs = 6; } else if (vizMs < 3 && vizDpr < (LITE ? 1 : 1.5)) { vizDpr = Math.min(LITE ? 1 : 1.5, vizDpr + 0.25); vizMs = 6; }
  }

  let vizOn = false, lyBp = 0; document.addEventListener('visibilitychange', () => { if (!document.hidden) { try { if (ac && ac.state !== 'running' && !A.paused) ac.resume().catch(() => {}); COVC2(); window.PVZ && window.PVZ.reset(); amb.ray = null; amb.bg = null; boxC = null; const vc = g('plrViz'); vc.width = 0; } catch (e) {} const w = g('plrWave'); w.width = 0; requestAnimationFrame(() => { waveDraw(); if (!g('plrFull').hidden) { vizStart(); layout(0, false); } }); } }); window.addEventListener('pageshow', () => requestAnimationFrame(waveDraw)); g('plrWave').addEventListener('contextrestored', waveDraw);
  function vizStart() { if (!vizOn) { vizOn = true; lastTs = performance.now(); requestAnimationFrame(vizLoop); } }
  /* قوالب العرض: كل قالب يغيّر شخصية الواجهة كاملة (الألوان، الخطوط، الأزرار، الشريط، القوائم) */
  const THM = {
    mihrab: { A: '#E8C468', A2: '#F3D88A', I: '#2a2106', B: ['#0c4a39', '#07281e', '#04140f'], S: '#0f2a22', T: 'F2', btn: 'arch', dock: 'glass', pg: 'line' },
    retro: { A: '#F2A541', A2: '#FFD39A', I: '#1b1206', B: ['#2a2724', '#171513', '#0b0a09'], S: '#1e1b18', T: 'F14', btn: 'disc', dock: 'metal', pg: 'tape' },
    scope: { A: '#6CFF9E', A2: '#C9FFD9', I: '#02140a', B: ['#06170f', '#030c07', '#010503'], S: '#05120b', T: 'F1', btn: 'squ', dock: 'outline', pg: 'seg' },
    metal: { A: '#D9DEE2', A2: '#FFFFFF', I: '#15181a', B: ['#2e3236', '#1a1d20', '#0c0e0f'], S: '#1d2023', T: 'F0', btn: 'disc', dock: 'metal', pg: 'thick' },
    water: { A: '#7FD3E8', A2: '#CFF3FB', I: '#032029', B: ['#0b4552', '#05252d', '#021217'], S: '#062a33', T: 'F13', btn: 'glass', dock: 'float', pg: 'glow' },
    glass: { A: '#FFFFFF', A2: '#F3D88A', I: '#0f2a22', B: ['#1f3d35', '#122722', '#081512'], S: 'rgba(20,40,34,.92)', T: 'F5', btn: 'glass', dock: 'float', pg: 'line' },
    silk: { A: '#E9C7FF', A2: '#F3D88A', I: '#2a1530', B: ['#3a2244', '#1f1226', '#0f0913'], S: '#24142b', T: 'F12', btn: 'squ', dock: 'float', pg: 'glow' },
    wood: { A: '#E8A85C', A2: '#FFD7A6', I: '#2a1606', B: ['#3a2414', '#21140a', '#100904'], S: '#26170c', T: 'F3', btn: 'circle', dock: 'bar', pg: 'thick' },
    neon: { A: '#36F1CD', A2: '#FF4FD8', I: '#03110e', B: ['#120f22', '#0a0814', '#040309'], S: '#0d0b18', T: 'F4', btn: 'ring', dock: 'outline', pg: 'glow' },
    night: { A: '#F3D88A', A2: '#BFD1FF', I: '#1c1a10', B: ['#16244a', '#0b142c', '#050914'], S: '#0e1833', T: 'F2', btn: 'circle', dock: 'glass', pg: 'line' }
  };
  const VTH = { mihrab: 'mihrab', ambient: 'mihrab', cover: 'mihrab', wring: 'silk', vinyl: 'retro', cassette: 'retro', jog: 'retro', reels: 'retro', knob: 'metal', speaker: 'metal', scope: 'scope', pond: 'water', dots: 'glass', card: 'glass', silk: 'silk', strings: 'wood', candles: 'wood', neon: 'neon', pulse: 'neon', spectrum: 'neon', bars: 'neon', halo: 'night', star: 'night', orbit: 'night', dust: 'night', blob: 'night', wave: 'night' };
  let THC = THM.mihrab;
  /* لون الخلفية: تلقائي من الغلاف (افتراضي) / لون القالب / لون يختاره المستخدم — مع ضبط التباين والإضاءة */
  if (!st.bg) st.bg = 'auto';
  const BGS = [['auto', 'من الغلاف'], ['theme', 'لون القالب'], ['#000000', 'أسود فاخر'], ['#0d1b2a', 'كحلي'], ['#0c4a39', 'أخضر'], ['#4a0f1a', 'عنابي'], ['#2b1640', 'بنفسجي'], ['#3a2414', 'بني'], ['#23272b', 'فحمي'], ['#0f3b44', 'فيروزي']];
  const hsl2 = (h, s, l) => { s /= 100; l /= 100; const k = (n) => (n + h / 30) % 12, a = s * Math.min(l, 1 - l), f = (n) => l - a * Math.max(-1, Math.min(k(n) - 3, Math.min(9 - k(n), 1))); return '#' + [f(0), f(8), f(4)].map((x) => Math.round(x * 255).toString(16).padStart(2, '0')).join(''); };
  const rgb2hsl = (r, g0, b) => { r /= 255; g0 /= 255; b /= 255; const mx = Math.max(r, g0, b), mn = Math.min(r, g0, b), l = (mx + mn) / 2; let h = 0, s = 0; if (mx !== mn) { const d = mx - mn; s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn); h = mx === r ? (g0 - b) / d + (g0 < b ? 6 : 0) : mx === g0 ? (b - r) / d + 2 : (r - g0) / d + 4; h *= 60; } return [h, s * 100, l * 100]; };
  const hex2hsl = (hx) => { const n = parseInt(hx.slice(1), 16); return rgb2hsl(n >> 16 & 255, n >> 8 & 255, n & 255); };
  let COVC = new WeakMap(); const COVC2 = () => { COVC = new WeakMap(); };
  function coverHue(im) { if (!im || !im.naturalWidth) return null; if (COVC.has(im)) return COVC.get(im); let res = null; try { const c = document.createElement('canvas'); c.width = c.height = 32; const x = c.getContext('2d'); x.drawImage(im, 0, 0, 32, 32); const d = x.getImageData(0, 0, 32, 32).data; const bins = new Float32Array(36), sat = new Float32Array(36); let lsum = 0, n = 0, ssum = 0;
      for (let i = 0; i < d.length; i += 4) { const [h, s, l] = rgb2hsl(d[i], d[i + 1], d[i + 2]); lsum += l; ssum += s; n++; if (s < 18 || l < 10 || l > 90) continue; const w = (s / 100) * (1 - Math.abs(l - 50) / 50); const k = Math.floor(h / 10) % 36; bins[k] += w; sat[k] += s * w; }
      let bk = -1, bv = 0; for (let k = 0; k < 36; k++) { const v = bins[k] + (bins[(k + 35) % 36] + bins[(k + 1) % 36]) * 0.5; if (v > bv) { bv = v; bk = k; } }
      res = bv > n * 0.02 ? { h: bk * 10 + 5, s: Math.min(70, sat[bk] / bins[bk]), mono: false } : { h: 150, s: 8, mono: true, l: lsum / n }; } catch (e) { res = null; } COVC.set(im, res); return res; }
  function bgPal(k) { const T = THC; if (k === 'theme') return null; if (k === '#000000') return { B: ['#151515', '#0a0a0a', '#000000'], S: '#0f0f0f', lux: true, A: T.A === '#FFFFFF' ? '#E8C468' : null };
    let h, s; if (k === 'auto') { const c = coverHue(curImg); if (!c) return null; if (c.mono) return { B: ['#1a1a1a', '#0d0d0d', '#030303'], S: '#121212', lux: true }; h = c.h; s = Math.max(28, c.s); } else { [h, s] = hex2hsl(k); if (s < 6) return { B: [hsl2(h, s, 16), hsl2(h, s, 9), hsl2(h, s, 4)], S: hsl2(h, s, 10) }; }
    const pal = { B: [hsl2(h, s * 0.75, 22), hsl2(h, s * 0.7, 12), hsl2(h, s * 0.6, 5)], S: hsl2(h, s * 0.6, 11) };
    const [ah] = hex2hsl(T.A), dh = Math.min(Math.abs(ah - h), 360 - Math.abs(ah - h)); if (dh < 28 && T.A !== '#FFFFFF') pal.A = '#E8C468' === T.A ? '#F5F0E6' : '#E8C468'; return pal; }
  function bgApply(fromTheme) { const f = g('plrFull'), T = THC, s = f.style; let P = bgPal(st.bg); if (st.bg === 'auto' && !P && !(curImg && curImg.complete)) P = null;
    const B = P ? P.B : T.B, S = P ? P.S : T.S, A = (P && P.A) || T.A; s.setProperty('--thB1', B[0]); s.setProperty('--thB2', B[1]); s.setProperty('--thB3', B[2]); s.setProperty('--thS', S); f.classList.toggle('lux', !!(P && P.lux));
    if (A !== T.A) { s.setProperty('--thA', A); const n = parseInt(A.slice(1), 16), c = `${n >> 16 & 255},${n >> 8 & 255},${n & 255}`; s.setProperty('--thAa', `rgba(${c},.16)`); s.setProperty('--thAg', `rgba(${c},.45)`); s.setProperty('--thAl', `rgba(${c},.5)`); THC = Object.assign({}, T, { A }); } else if (!fromTheme) { THC = THM[VTH[st.viz] || 'mihrab']; }
    const mt = document.querySelector('meta[name=theme-color]'); if (mt && !f.hidden && !root.hidden) mt.content = B[0]; }
  function bgUi() { const b = g('plrBgP'); if (!b) return; b.textContent = ''; BGS.forEach(([k, n]) => { const x = el('button', 'bgs' + (st.bg === k ? ' on' : '')); x.type = 'button'; x.title = n; const sw = el('i'); if (k === 'auto') { const c = coverHue(curImg); sw.style.background = c && !c.mono ? `conic-gradient(${hsl2(c.h, c.s, 30)},${hsl2(c.h, c.s, 12)},${hsl2(c.h, c.s, 30)})` : 'conic-gradient(#333,#000,#333)'; sw.innerHTML = ic('spark', 13); } else if (k === 'theme') { sw.style.background = `linear-gradient(135deg,${THM[VTH[st.viz] || 'mihrab'].B[0]},${THM[VTH[st.viz] || 'mihrab'].B[2]})`; sw.innerHTML = ic('lay', 13); } else sw.style.background = k === '#000000' ? 'radial-gradient(circle at 35% 30%,#3a3a3a,#000 70%)' : `linear-gradient(135deg,${hsl2(...hex2hsl(k).slice(0, 2), 26)},${k})`; x.appendChild(sw); x.appendChild(el('small', '', n)); x.onclick = () => { st.bg = k; save(); bgApply(); bgUi(); }; b.appendChild(x); });
    const cu = el('label', 'bgs' + (st.bg && st.bg[0] === '#' && !BGS.some((q) => q[0] === st.bg) ? ' on' : '')); const ci = document.createElement('input'); ci.type = 'color'; ci.value = st.bg && st.bg[0] === '#' ? st.bg : '#0c4a39'; ci.oninput = () => { st.bg = ci.value; save(); bgApply(); }; ci.onchange = bgUi; const sw = el('i'); sw.style.background = 'conic-gradient(#e74c3c,#f1c40f,#2ecc71,#3498db,#9b59b6,#e74c3c)'; cu.append(ci, sw, el('small', '', 'لون آخر')); b.appendChild(cu);
    g('plrBgN').textContent = (BGS.find((q) => q[0] === st.bg) || [0, 'مخصّص'])[1]; }
  function themeApply() { const k = VTH[st.viz] || 'mihrab', T = THM[k], f = g('plrFull'); THC = T; f.dataset.th = k; f.dataset.btn = T.btn; f.dataset.dock = T.dock; f.dataset.pg = T.pg;
    const s = f.style; s.setProperty('--thA', T.A); s.setProperty('--thA2', T.A2); s.setProperty('--thI', T.I); s.setProperty('--thB1', T.B[0]); s.setProperty('--thB2', T.B[1]); s.setProperty('--thB3', T.B[2]); s.setProperty('--thS', T.S); s.setProperty('--thT', `"${T.T}", Cairo, sans-serif`); const ha = (h0, a) => { const n = parseInt(h0.slice(1), 16); return `rgba(${n >> 16 & 255},${n >> 8 & 255},${n & 255},${a})`; }; s.setProperty('--thAa', ha(T.A, 0.16)); s.setProperty('--thAg', ha(T.A, 0.45)); s.setProperty('--thAl', ha(T.A, 0.5));
    bgApply(true); try { waveDraw(); } catch (e) {} }
  function applyViz() {
    const isC = st.viz === 'cover', isA = st.viz === 'ambient'; layApply(); g('plrFull').dataset.viz = st.viz; themeApply(); requestAnimationFrame(() => { const bx = g('plrLyr'); if (bx._i != null && bx._i > -2) { const k = bx._i; bx._i = -3; lyxGo(bx, k, true); } }); g('plrStage').hidden = !isC; g('plrViz').hidden = isC; g('plrFull').classList.toggle('amb', isA); lyStyle(); if (isC && cur >= 0) stageBuild(); vizPills();
    layout(0, false); waveDraw(); if (!g('plrFull').hidden) { vizStart(); requestAnimationFrame(() => { layout(0, false); waveDraw(); }); }
  }
  const LAYS = [['a', 'غامر', '<rect x="3" y="3" width="42" height="64" rx="6" fill="currentColor" opacity=".18"/><circle cx="24" cy="26" r="11" fill="currentColor" opacity=".5"/><rect x="9" y="46" width="30" height="3" rx="1.5" fill="currentColor"/><rect x="13" y="53" width="22" height="3" rx="1.5" fill="currentColor" opacity=".5"/>'], ['b', 'كلاسيكي', '<rect x="9" y="6" width="30" height="30" rx="6" fill="currentColor" opacity=".5"/><rect x="9" y="43" width="30" height="3" rx="1.5" fill="currentColor"/><rect x="13" y="50" width="22" height="3" rx="1.5" fill="currentColor" opacity=".5"/><rect x="9" y="58" width="30" height="3" rx="1.5" fill="currentColor" opacity=".3"/>'], ['c', 'الكلمات أولاً', '<rect x="3" y="3" width="42" height="64" rx="6" fill="currentColor" opacity=".12"/><rect x="8" y="20" width="32" height="3" rx="1.5" fill="currentColor" opacity=".4"/><rect x="6" y="30" width="36" height="5" rx="2.5" fill="currentColor"/><rect x="8" y="42" width="32" height="3" rx="1.5" fill="currentColor" opacity=".4"/>']];
  function layApply() { const f = g('plrFull'); f.classList.remove('lay-a', 'lay-b', 'lay-c'); f.classList.add('lay-' + st.lay); const p = g('plrLayP'); p.textContent = ''; LAYS.forEach(([k, n, svg]) => { const b = document.createElement('button'); b.className = st.lay === k ? 'on' : ''; b.innerHTML = `<svg viewBox="0 0 48 70">${svg}</svg><span>${n}</span>`; b.onclick = () => { st.lay = k; save(); applyViz(); }; p.appendChild(b); }); }
  const thumbC = {};
  const VIZMAP = { ring: 'bars', starpulse: 'star', mirror: 'spectrum', particles: 'dust', sphere: 'orbit', ridges: 'wave', vu: 'spectrum' };
  if (VIZMAP[st.viz]) st.viz = VIZMAP[st.viz]; if (st.viz !== "ambient" && st.viz !== "cover" && window.PVZ && !window.PVZ.has(st.viz)) st.viz = "mihrab";
  function vizPills() {
    const box = g('plrVizP'); box.textContent = ''; const PL = window.PVZ ? window.PVZ.list : [], L = PL.slice(0, 1).concat([['ambient', 'أجواء']], PL.filter((q) => q[0] === 'wring'), [['cover', 'غلاف']], PL.slice(1).filter((q) => q[0] !== 'wring'));
    const N = 22, vals = new Float32Array(N); for (let i = 0; i < N; i++) vals[i] = 0.3 + 0.5 * Math.abs(Math.sin(i * 0.7 + 1)) * (1 - i / N * 0.4);
    const wave = new Float32Array(256); for (let i = 0; i < 256; i++) wave[i] = 0.25 * Math.sin(i * 0.19) * Math.sin(i * 0.031);
    const F = { vals, vol: 0.5, bass: 0.6, mid: 0.45, hi: 0.35, beat: 0.5, cum: 3, wave };
    const VC = [['كلاسيكية', ['mihrab', 'ambient', 'cover', 'card', 'dots', 'silk']], ['أجهزة', ['vinyl', 'cassette', 'jog', 'reels', 'knob', 'speaker', 'scope']], ['حيّة', ['wring', 'halo', 'bars', 'blob', 'wave', 'spectrum', 'orbit', 'pulse', 'star', 'dust', 'neon', 'pond', 'strings', 'candles']]];
    if (vizPills.c == null) { vizPills.c = Math.max(0, VC.findIndex((q) => q[1].includes(st.viz))); }
    const vc = g('plrVizC'); if (vc) { vc.textContent = ''; VC.forEach(([cn], ci) => { const cb = el('button', ci === vizPills.c ? 'on' : '', cn); cb.type = 'button'; cb.onclick = () => { vizPills.c = ci; vizPills(); }; vc.appendChild(cb); }); }
    const cur0 = L.find((q) => q[0] === st.viz); if (cur0) g('plrVizN').textContent = cur0[1];
    L.filter(([k]) => VC[vizPills.c][1].includes(k)).forEach(([k, n]) => {
      const b = document.createElement('button'); b.className = 'vz' + (st.viz === k ? ' on' : ''); const c = document.createElement('canvas'), TS = Math.round(200 * Math.min(2, Math.max(1.5, window.devicePixelRatio || 1))); c.width = c.height = TS; const x = c.getContext('2d'); x.imageSmoothingQuality = 'high'; const u = TS / 200;
      try {
        if (k === 'cover') { const cc = document.createElement('div'); cc.className = 'plrcov'; if (curImg && curImg.naturalWidth) x.drawImage(curImg, 30 * u, 30 * u, 140 * u, 140 * u); else { x.fillStyle = 'rgba(232,196,104,.5)'; x.fillRect(30 * u, 30 * u, 140 * u, 140 * u); } }
        else if (k === 'ambient') drawAmbient(x, TS, TS, 2, F, { cx: TS / 2, cy: TS / 2, R: 50 * u }); else window.PVZ.draw(x, TS, TS, k, F, curImg, { cx: TS / 2, cy: TS / 2, R: 50 * u }, { t: 1.2, now: 1.2, dt: 0.016 });
      } catch (e) {}
      b.title = n; b.append(c, el('span', '', n)); b.onclick = () => { st.viz = k; save(); applyViz(); vizPills(); }; box.appendChild(b); if (st.viz === k) { g('plrVizN').textContent = n; requestAnimationFrame(() => { const r = box.getBoundingClientRect(), q = b.getBoundingClientRect(); box.scrollLeft += (q.left + q.width / 2) - (r.left + r.width / 2); }); }
    });
  }
  (function () {
    const cv = g('plrViz'); let x0 = 0, y0 = 0, on = false, dx = 0, dy = 0, hz = false;
    /* محرك الخدش العام: d بالراديان، nat = سرعة الدوران الطبيعية (راديان/ث) عند السرعة 1 */
    const sc = { on: false, w: 0, acc: 0, tot: 0, t0: 0, lt: 0, play: false, h: 0, back: 0, pd: 0, mv: false, nat: 1.15, fwd: false }, PV = () => window.PVZ && window.PVZ.vinyl;
    const cpt = (e) => { const r = cv.getBoundingClientRect(), k = cv.width / (r.width || 1); return [(e.clientX - r.left) * k, (e.clientY - r.top) * k]; };
    const scTick = () => { if (!sc.on) return; sc.h = requestAnimationFrame(scTick); const n = performance.now(), dt = Math.max(0.008, (n - sc.lt) / 1000); sc.lt = n; const inst = sc.acc / dt; sc.acc = 0; sc.w += (inst - sc.w) * Math.min(1, dt * 14);
      if (!sc.mv) { if (n - sc.t0 > 220) { A.playbackRate = 0.25; dragVol(0.0001); } return; } const w = sc.w, sp = st.speed || 1, NAT = sc.nat;
      if (w > NAT * 0.1) { A.preservesPitch = false; A.playbackRate = Math.max(0.25, Math.min(4, (w / NAT) * sp)); if (A.paused) A.play().catch(() => {}); dragVol(1); }
      else if (w < -NAT * 0.1 && !sc.fwd) { A.playbackRate = 1; dragVol(0.35); if (A.paused) A.play().catch(() => {}); }
      else { A.playbackRate = 0.25; dragVol(0.0001); } };
    const scrBegin = (nat, fwd) => { if (cur < 0) return; Object.assign(sc, { on: true, nat: Math.max(3.49, nat || 1.15), fwd: !!fwd, w: A.paused ? 0 : Math.max(3.49, nat || 1.15), acc: 0, tot: 0, pd: 0, mv: false, t0: performance.now(), lt: performance.now(), play: !A.paused }); if (ac && ac.state === 'suspended') ac.resume().catch(() => {}); cancelAnimationFrame(sc.h); sc.h = requestAnimationFrame(scTick); };
    const scrTurn = (d) => { if (!sc.on) return; if (sc.fwd && d < 0) d = 0; sc.tot += Math.abs(d); if (!sc.mv && sc.tot > 0.06) sc.mv = true; sc.acc += d; const n = performance.now(); if (d < 0) sc.pd += d; if (sc.pd && n - sc.back > 55 && A.duration) { A.currentTime = Math.max(0, A.currentTime + (sc.pd / sc.nat) * (st.speed || 1)); sc.pd = 0; sc.back = n; } };
    const scEnd = () => { if (!sc.on) return false; sc.on = false; cancelAnimationFrame(sc.h); PV() && PV().hold(false); const tap = !sc.mv && performance.now() - sc.t0 < 450; A.preservesPitch = true; A.playbackRate = st.speed || 1; if (tap) { toggle(); return true; } dragVol(1, true); if (!sc.play) fadePause(); return false; };
    /* واجهة التحكم للتصاميم التفاعلية */
    let skT = 0; const K = window.__plrCtl = {
      get p() { return A.duration ? A.currentTime / A.duration : 0; }, get dur() { return A.duration || 0; }, get playing() { return !A.paused; }, get rate() { return A.paused ? 0 : A.playbackRate; },
      seek(q, now) { if (!A.duration) return; const n = performance.now(); if (!now && n - skT < 70) return; skT = n; A.currentTime = Math.max(0, Math.min(A.duration - 0.05, q * A.duration)); },
      toggle: () => toggle(), get vol() { return st.uvol == null ? 1 : st.uvol; }, setVol(v) { st.uvol = Math.max(0, Math.min(1, v)); A.volume = st.uvol; save(); },
      get speed() { return st.speed || 1; }, setSpeed(v) { st.speed = Math.round(Math.max(0.5, Math.min(2, v)) * 20) / 20; A.playbackRate = st.speed; save(); pills(); },
      scrBegin, scrTurn, scrEnd: scEnd, get scrubbing() { return sc.on; },
      get title() { const t = tracks[cur]; return t ? t.title : ''; }, get sub() { const t = tracks[cur]; return t ? (t.reciter || '') : ''; }, get peaks() { const t = tracks[cur]; return t && ENV.get(t.id); }
    };
    if (st.uvol != null) A.volume = st.uvol;
    const hitV = (e) => { if (st.viz !== 'vinyl' || !PV() || !PV().geo() || cur < 0) return false; const G = PV().geo(), [px, py] = cpt(e); return Math.hypot(px - G.cx, py - G.cy) < G.R * 0.98; };
    let va = 0, dev = false;
    cv.addEventListener('pointerdown', (e) => {
      if (hitV(e)) { const G = PV().geo(), [px, py] = cpt(e); va = Math.atan2(py - G.cy, px - G.cx); scrBegin(1.15); PV().hold(true); try { cv.setPointerCapture(e.pointerId); } catch (x) {} return; }
      if (window.PVZ && PVZ.devHas && PVZ.devHas(st.viz) && cur >= 0) { const [px, py] = cpt(e); if (PVZ.devDown(st.viz, px, py)) { dev = true; try { cv.setPointerCapture(e.pointerId); } catch (x) {} return; } }
      on = true; x0 = e.clientX; y0 = e.clientY; dx = 0; dy = 0; hz = false; });
    cv.addEventListener('pointermove', (e) => {
      if (dev) { const [px, py] = cpt(e); PVZ.devMove(st.viz, px, py); return; }
      if (sc.on && PV() && st.viz === 'vinyl') { const G = PV().geo(), [px, py] = cpt(e), a = Math.atan2(py - G.cy, px - G.cx); let d = a - va; if (d > Math.PI) d -= 2 * Math.PI; if (d < -Math.PI) d += 2 * Math.PI; va = a; PV().turn(d); scrTurn(d); return; }
      if (!on) return; dx = e.clientX - x0; dy = e.clientY - y0; if (!hz && Math.abs(dx) > 12 && Math.abs(dx) > Math.abs(dy)) hz = true; if (hz) { vs.drag = true; vs.to = vs.dx = dx; dragVol(1 - Math.min(1, Math.abs(dx) / (cv.clientWidth * 0.6)) * 0.92); } });
    const up = () => { if (dev) { dev = false; PVZ.devUp(st.viz); scEnd(); return; } if (sc.on) return scEnd(); if (!on) return; on = false; vs.drag = false; const W = cv.clientWidth || 360;
      if (hz && Math.abs(dx) > W * 0.22 && tracks.length > 1) { const d = dx < 0 ? 1 : -1; vs.to = -d * W; vs.after = () => { step(d); vs.dx = d * W * 0.8; vs.to = 0; }; }
      else if (hz) { vs.to = 0; dragVol(1, true); } else if (Math.abs(dy) < 12 && Math.abs(dx) < 12) toggle(); };
    cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', () => { if (dev) { dev = false; PVZ.devUp(st.viz); } scEnd(); on = false; vs.drag = false; vs.to = 0; dragVol(1, true); });
  })();
  function meta() {
    const t = tracks[cur]; if (!t || !('mediaSession' in navigator)) return;
    try { navigator.mediaSession.metadata = new MediaMetadata({ title: t.title, artist: t.reciter || '', album: t.poet || 'منبر', artwork: cov(t) ? [{ src: cov(t), sizes: '512x512' }] : [{ src: 'icons/brand-mark.png' }] }); } catch (e) {}
  }
  /* قائمة التشغيل الحقيقية: ترتيب ثابت قابل للتعديل والسحب، والخلط يرتّب الباقي مرة واحدة */
  const QK = 'minbar.queue', DUK = 'minbar.dur'; const Q = (() => { try { return Object.assign({ ids: [], base: [] }, JSON.parse(localStorage.getItem(QK) || '{}')); } catch (e) { return { ids: [], base: [] }; } })();
  const qSave = () => { try { localStorage.setItem(QK, JSON.stringify(Q)); } catch (e) {} }, byId = (id) => tracks.find((x) => x.id === id);
  const shufA = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  function qFrom(t, list, label) { Q.src = label || (tab === 'fav' ? 'المفضلة' : tab === 'pls' && plSel ? ((pls().find((x) => x.id === plSel) || {}).name || 'قائمة') : q ? 'نتائج البحث' : cat !== 'الكل' ? 'المكتبة · ' + cat : 'المكتبة'); Q.base = (list || (view.length ? view : tracks)).map((x) => x.id); Q.ids = st.shuf ? [t.id].concat(shufA(Q.base.filter((x) => x !== t.id))) : Q.base.slice(); qSave(); }
  function qEnsure(t) { Q.ids = Q.ids.filter((id) => byId(id)); if (!Q.ids.includes(t.id)) qFrom(t); }
  function qShuf() { const t = tracks[cur]; if (!t) return; qEnsure(t); if (st.shuf) { const i = Q.ids.indexOf(t.id); Q.ids = Q.ids.slice(0, i + 1).concat(shufA(Q.ids.slice(i + 1))); } else { const extra = Q.ids.filter((id) => !Q.base.includes(id)); Q.ids = Q.base.filter((id) => byId(id)).concat(extra); } qSave(); if (!g('plrQs').hidden) qBuild(); }
  function qNext(t, d) { qEnsure(t); const i = Q.ids.indexOf(t.id), j = i + d; if (j < 0 || j >= Q.ids.length) return null; return byId(Q.ids[j]); }
  function step(d) {
    if (!tracks.length) return; const t = tracks[cur]; if (!t) return play(0);
    let n = qNext(t, d); if (!n) { qEnsure(t); n = byId(Q.ids[d > 0 ? 0 : Q.ids.length - 1]); if (d > 0 && st.shuf) { Q.ids = shufA(Q.ids); qSave(); n = byId(Q.ids[0]); } }
    if (n) play(tracks.indexOf(n));
  }
  function ui() {
    const p = !A.paused; { const f = g('plrFull'), was = f.classList.contains('playing'); f.classList.toggle('playing', p); if (was !== p) { const m = g('plrPlay'); m.classList.remove('tgl'); void m.offsetWidth; m.classList.add('tgl'); } } g('plrPlay').innerHTML = ic(p ? 'pause' : 'play', 30); g('plrMiniPlay').innerHTML = ic(p ? 'pause' : 'play', 24);
    if (!g('plrQs').hidden && g('plrQsh')) { g('plrQsh').classList.toggle('on', st.shuf); g('plrQrp').classList.toggle('on', st.rep > 0); g('plrQrp').dataset.rm = st.rep === 2 ? '1' : ''; qPr(); }
    g('plrShuf').classList.toggle('on', st.shuf); g('plrRep').classList.toggle('on', st.rep > 0); g('plrRep').dataset.rm = st.rep === 2 ? '1' : '';
    pills();
  }
  function fadePlay() { clearTimeout(fadePause.h); if (ac && ac.state === 'suspended') ac.resume().catch(() => {}); A.play().catch(() => {}); }
  function fadePause() { if (AU.fade && ac && !A.paused) { const g2 = AU.fade.gain, T = ac.currentTime; g2.cancelScheduledValues(T); g2.setValueAtTime(Math.max(0.0001, g2.value), T); g2.exponentialRampToValueAtTime(0.0001, T + 0.22); clearTimeout(fadePause.h); fadePause.h = setTimeout(() => { A.pause(); }, 230); } else A.pause(); }
  const toggle = () => { if (cur < 0) return; if (A.paused) fadePlay(); else fadePause(); };
  g('plrPlay').onclick = g('plrMiniPlay').onclick = (e) => { e.stopPropagation(); toggle(); };
  g('plrNext').onclick = g('plrMiniNext').onclick = (e) => { e.stopPropagation(); if (Date.now() - (g('plrNext')._held || 0) < 450) return; step(1); }; g('plrPrev').onclick = () => { if (Date.now() - (g('plrPrev')._held || 0) < 450) return; if (A.currentTime > 4) A.currentTime = 0; else step(-1); };
  g('plrShuf').onclick = () => { st.shuf = !st.shuf; save(); qShuf(); ui(); }; g('plrRep').onclick = () => { st.rep = (st.rep + 1) % 3; save(); ui(); };
  /* زر الإعجاب الموحّد: ضغطة = إعجاب بهذه اللحظة (+ المفضلة أول مرة، ×n للمتتالي)، ضغطة مطوّلة = إزالة من المفضلة */
  let cmbN = 0, cmbT = 0, favLP = 0, favLong = false;
  const favB = g('plrFav'); favB.insertAdjacentHTML('beforeend', '<i class="cmb"></i>');
  favB.addEventListener('pointerdown', () => { favLong = false; clearTimeout(favLP); favLP = setTimeout(() => { const t = tracks[cur]; if (t && st.fav.includes(t.id)) { favLong = true; tog(t.id); if (tab === 'fav') render(); toast('أُزيلت من المفضلة'); } }, 650); });
  ['pointerup', 'pointerleave', 'pointercancel'].forEach((ev) => favB.addEventListener(ev, () => clearTimeout(favLP)));
  favB.onclick = () => { if (favLong) { favLong = false; return; } const t = tracks[cur]; if (!t) return; if (!st.fav.includes(t.id)) { tog(t.id); if (tab === 'fav') render(); }
    cmbN++; clearTimeout(cmbT); const cb = favB.querySelector('.cmb'); if (cmbN >= 2) { cb.textContent = '×' + cmbN; cb.classList.remove('go'); void cb.offsetWidth; cb.classList.add('go'); } cmbT = setTimeout(() => { cmbN = 0; cb.textContent = ''; }, 1400);
    favB.classList.remove('pop'); void favB.offsetWidth; favB.classList.add('pop'); const k = g('plrRx').querySelector('.rxb'); if (k) rxSend('❤️', k); };
  function openFull() { g('plrFull').hidden = false; applyViz();  }
  function closeFull() { tp(false); qs(false); au(false); cmS(false); g('plrFull').hidden = true; }
  g('plrMini').onclick = openFull; (function () { const m = g('plrMini'), f = g('plrFull'); let y0 = 0, dy = 0, drag = false, t0 = 0;
    m.addEventListener('touchstart', (e) => { y0 = e.touches[0].clientY; dy = 0; drag = false; t0 = Date.now(); }, { passive: true });
    m.addEventListener('touchmove', (e) => { dy = y0 - e.touches[0].clientY; if (!drag && dy > 8) { drag = true; f.style.transition = 'none'; f.hidden = false; f.style.visibility = 'visible'; applyViz(); } if (drag) { e.preventDefault(); const H = root.clientHeight; f.style.transform = `translateY(${Math.max(0, H - dy - 80)}px)`; } }, { passive: false });
    m.addEventListener('touchend', () => { if (!drag) return; drag = false; const H = root.clientHeight, v = dy / Math.max(1, Date.now() - t0); f.style.transition = ''; f.style.visibility = ''; requestAnimationFrame(() => { f.style.transform = ''; if (dy > H * 0.25 || v > 0.5) openFull(); else closeFull(); }); });
  })(); g('plrClose').onclick = closeFull;
  function pills() {
    const sp = g('plrSpeedP'), sl = g('plrSleepP'); sp.textContent = ''; sl.textContent = '';
    [0.75, 1, 1.25, 1.5, 2].forEach((v) => { const b = document.createElement('button'); b.textContent = v + 'x'; b.className = st.speed === v ? 'on' : ''; b.onclick = () => { st.speed = v; A.playbackRate = v; save(); pills(); }; sp.appendChild(b); });
    [[0, 'إيقاف'], [15, '15 دقيقة'], [30, '30 دقيقة'], [60, 'ساعة']].forEach(([m, l]) => { const b = document.createElement('button'); b.textContent = l; b.className = sleepT === m ? 'on' : ''; b.onclick = () => { setSleep(m); pills(); }; sl.appendChild(b); });
  }
  let sleepEnd = false, slTick = 0;
  function setSleep(n) { sleepT = n; clearTimeout(sleepAt); sleepEnd = n === 'end'; if (n && n !== 'end') { sleepAt = setTimeout(() => { fadePause(); sleepT = 0; slUi(); }, n * 60000); sleepAt0 = Date.now() + n * 60000; } slUi(); }
  let sleepAt0 = 0;
  function slUi() { const b = g('plrSlB'), v = g('plrSlV'); b.classList.toggle('on', !!sleepT); v.textContent = sleepT === 'end' ? '⏹' : sleepT ? Math.max(1, Math.ceil((sleepAt0 - Date.now()) / 60000)) : ''; clearInterval(slTick); if (sleepT && sleepT !== 'end') slTick = setInterval(slUi, 30000); }
  g('plrSlB').onclick = () => { const seq = [0, 15, 30, 60, 'end'], i2 = (seq.indexOf(sleepT) + 1) % seq.length, n = seq[i2]; setSleep(n); toast(n === 0 ? 'أُلغي مؤقت الإيقاف' : n === 'end' ? 'سيتوقف التشغيل بنهاية هذه القصيدة' : 'سيتوقف التشغيل بعد ' + n + ' دقيقة'); };
  A.addEventListener('ended', () => { if (sleepEnd) { sleepEnd = false; sleepT = 0; A.__stop = true; slUi(); } });
  const tp = (on) => { g('plrTp').hidden = !on; g('plrBg').hidden = !on; if (on) { vizPills(); layApply(); toolsUi(); bgUi(); g('plrMore').classList.remove('newdot'); try { localStorage.setItem('minbar.seen.335', '1'); } catch (e) {} } };
  g('plrTpT').querySelectorAll('button').forEach((bt) => bt.onclick = () => { g('plrTpT').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x === bt)); const v = bt.dataset.k === 'v'; g('plrTp').querySelectorAll('.tpV').forEach((e) => e.hidden = !v); g('plrTp').querySelectorAll('.tpT').forEach((e) => e.hidden = v); });
  g('plrMore').onclick = () => tp(g('plrTp').hidden);
  g('plrVzB').onclick = () => tp(true); g('plrTg').onclick = () => au(g('plrAu').hidden); g('plrBg').onclick = () => { tp(false); qs(false); admShow(false); au(false); cmS(false); g('plrCv').hidden = true; }; g('plrTpX').onclick = () => tp(false); g('plrAdmX').onclick = () => admShow(false);
  function counter() { const list = view.length ? view : tracks; g('plrCount').textContent = (list.indexOf(tracks[cur]) + 1) + ' من ' + list.length; }
  function dragVol(v, ramp) { if (AU.fade && ac) { const g2 = AU.fade.gain, T = ac.currentTime; g2.cancelScheduledValues(T); if (ramp) { g2.setValueAtTime(Math.max(0.0001, g2.value), T); g2.linearRampToValueAtTime(1, T + 0.25); } else g2.setTargetAtTime(Math.max(0.0001, v), T, 0.03); } else A.volume = Math.max(0, Math.min(1, v)); }
  /* دوّار الأغلفة */
  const idxAt = (o) => { const list = view.length ? view : tracks; const k = list.indexOf(tracks[cur]); return tracks.indexOf(list[(k + o + list.length) % list.length]); };
  function layout(dx, anim) {
    const w = g('plrStage').clientWidth || root.clientWidth || 360, cw = (g('plrStage').firstElementChild || {}).offsetWidth || Math.min(w * 0.64, 300), sw = cw + 18;
    [...g('plrStage').children].forEach((d) => { const o = +d.dataset.o, f = Math.max(0, 1 - Math.abs(o + dx / (sw * 1.05))); d.style.transition = anim ? '' : 'none'; const ff = Math.max(0, 1 - Math.abs(o + dx / sw)); d.style.transform = `translateX(${o * sw + dx}px) scale(${(0.9 + 0.1 * Math.min(1, ff)).toFixed(3)})`; d.style.opacity = (0.75 + 0.25 * Math.min(1, ff)).toFixed(2); d.style.zIndex = o === 0 ? 2 : 1; });
  }
  function stageBuild() {
    const box = g('plrStage'); box.textContent = ''; if (cur < 0 || st.viz !== 'cover') return;
    [-1, 0, 1].forEach((o) => { const d = document.createElement('div'); d.className = 'plrcov plrslide'; d.dataset.o = o; const t = tracks[idxAt(o)]; if (t) coverEl(t, d); box.appendChild(d); });
    layout(0, false);
  }
  (function () {
    const box = g('plrStage'); let x0 = 0, dx = 0, on = false;
    let dyy = 0, y1 = 0, lp = 0, lpd = false; box.addEventListener('pointerdown', (e) => { on = true; x0 = e.clientX; y1 = e.clientY; dyy = 0; dx = 0; lpd = false; clearTimeout(lp); lp = setTimeout(() => { if (on && Math.abs(dx) < 8 && Math.abs(dyy) < 8) { lpd = true; on = false; layout(0, true); try { navigator.vibrate && navigator.vibrate(20); } catch (x) {} coverSheet(); } }, 550); try { box.setPointerCapture(e.pointerId); } catch (x) {} });
    box.addEventListener('pointermove', (e) => { if (!on) return; dx = e.clientX - x0; dyy = e.clientY - y1; const hx = Math.abs(dyy) > Math.abs(dx) ? 0 : dx; layout(hx, false); dragVol(1 - Math.min(1, Math.abs(hx) / ((box.firstElementChild || box).offsetWidth || 250)) * 0.92); });
    const end = (ev) => { clearTimeout(lp); if (lpd || !on) return; on = false; const sw0 = ((box.firstElementChild || box).offsetWidth || 250) + 18; if (!(Math.abs(dx) > sw0 * 0.3 && (view.length || tracks.length) > 1)) dragVol(1, true); if (Math.abs(dyy) > 30 && Math.abs(dyy) > Math.abs(dx)) { layout(0, true); return; } const sw = sw0; if (Math.abs(dx) > sw * 0.3 && (view.length || tracks.length) > 1) { const d = dx < 0 ? 1 : -1; layout(-d * sw, true); setTimeout(() => step(d), 220); } else if (Math.abs(dx) < 6) toggle(); else layout(0, true); };
    box.addEventListener('pointerup', end); box.addEventListener('pointercancel', end);
  })();
  /* شريط التقدّم النقطي بشكل موجة الصوت الحقيقية */
  const ENV = new Map(); let envBusy = null;
  async function envLoad(t, force) {
    if (!t || ENV.has(t.id) || envBusy === t.id) return; try { const c = JSON.parse(localStorage.getItem('minbar.env.' + t.id) || 'null'); if (c) { ENV.set(t.id, Float32Array.from(c)); waveDraw(); return; } } catch (e) {} envBusy = t.id;
    /* الموجة من التحليل المحسوب مسبقاً (بدون تنزيل وفك الملف أثناء التشغيل = سبب انقطاع الصوت بعد ثانيتين) */
    if (t.an === 1) { for (let i = 0; i < 20 && !(PRE && PRE.id === t.id); i++) await new Promise((r) => setTimeout(r, 300));
      if (PRE && PRE.id === t.id) { const P = PRE, B = 400, e = new Float32Array(B); let mx = 0; for (let i = 0; i < B; i++) { const a = Math.floor(i * P.nf / B), z = Math.max(a + 1, Math.floor((i + 1) * P.nf / B)); let s = 0, c = 0; for (let f = a; f < z && f < P.nf; f++) { const o = P.o + f * P.W; for (let k = 2; k < 20; k += 3) { s += Math.pow(10, (P.d[o + k] / 1.5 - 140) / 20); c++; } } e[i] = c ? s / c : 0; mx = Math.max(mx, e[i]); }
        for (let i = 0; i < B; i++) e[i] = mx ? Math.pow(e[i] / mx, 0.6) : 0; ENV.set(t.id, e); try { localStorage.setItem('minbar.env.' + t.id, JSON.stringify(Array.from(e, (v) => Math.round(v * 100) / 100))); } catch (x) {} if (tracks[cur] === t) waveDraw(); envBusy = null; return; } }
    if (!force) { envBusy = null; return; }
    await new Promise((r) => setTimeout(r, 2500)); if (tracks[cur] !== t) { envBusy = null; return; }
    try { const r = await fetch(t.audio); if (!r.ok) throw 0; const ab = await r.arrayBuffer(); const oc = new OfflineAudioContext(1, 1, 8000); const d = (await oc.decodeAudioData(ab)).getChannelData(0); const B = 400, step = Math.floor(d.length / B), e = new Float32Array(B); let mx = 0;
      for (let i = 0; i < B; i++) { let s = 0; for (let j = i * step; j < (i + 1) * step; j += 4) s += d[j] * d[j]; e[i] = Math.sqrt(s / (step / 4)); mx = Math.max(mx, e[i]); } for (let i = 0; i < B; i++) e[i] = mx ? Math.pow(e[i] / mx, 0.8) : 0; ENV.set(t.id, e); try { localStorage.setItem('minbar.env.' + t.id, JSON.stringify(Array.from(e, (v) => Math.round(v * 100) / 100))); } catch (x) {} if (tracks[cur] === t) waveDraw();
    } catch (e) { ENV.set(t.id, null); } envBusy = null;
  }
  function waveDraw() {
    const cv = g('plrWave'); if (!cv.offsetWidth) return; const dpr = Math.min(window.devicePixelRatio || 1, 2), w = cv.offsetWidth, h = cv.offsetHeight || 40;
    if (cv.width !== Math.round(w * dpr) || cv.height !== Math.round(h * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); }
    const x = cv.getContext('2d'); x.setTransform(dpr, 0, 0, dpr, 0, 0); x.clearRect(0, 0, w, h);
    const t = tracks[cur], d = A.duration || 0, p = d ? A.currentTime / d : 0, env = t && ENV.get(t.id), bw = 2.4, step = 5, n = Math.floor(w / step), seed = hash((t && t.id) || 'x');
    for (let i = 0; i < n; i++) {
      const f = (i + 0.5) / n; let e; if (env) e = env[Math.min(env.length - 1, Math.floor(f * env.length))]; else e = 0.45 + 0.4 * (((Math.sin(seed + i * 12.9898) * 43758.5453) % 1 + 1) % 1);
      const bh = Math.max(3, (0.18 + 0.82 * e) * h * 0.92), px = i * step + (step - bw) / 2;
      x.fillStyle = f <= p ? THC.A : 'rgba(255,255,255,.22)'; x.beginPath(); x.roundRect ? x.roundRect(px, (h - bh) / 2, bw, bh, 1.2) : x.rect(px, (h - bh) / 2, bw, bh); x.fill();
    }
    try { if (d && st.cm.on) { const seen = {}; (cmList || []).forEach((c) => { const px = Math.round(c.t / d * w / 12) * 12; if (seen[px]) return; seen[px] = 1; const r = 5.5, X = Math.max(r, Math.min(w - r, px)); x.fillStyle = c.mine ? '#E8C468' : '#2b7a62'; x.beginPath(); x.arc(X, r, r, 0, 6.283); x.fill(); x.fillStyle = '#fff'; x.font = '700 7px Cairo, sans-serif'; x.textAlign = 'center'; x.textBaseline = 'middle'; x.fillText((c.name || '•').trim().charAt(0) || '•', X, r + 0.5); }); } } catch (e) {}
  }


  (function () {
    const cv = g('plrWave'); let on = false;
    const sk = (e) => { const r = cv.getBoundingClientRect(); if (A.duration) { A.currentTime = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)) * A.duration; waveDraw(); } };
    cv.addEventListener('pointerdown', (e) => { on = true; try { cv.setPointerCapture(e.pointerId); } catch (x) {} sk(e); });
    cv.addEventListener('pointermove', (e) => { if (on) sk(e); }); ['pointerup', 'pointercancel'].forEach((n) => cv.addEventListener(n, () => { on = false; }));
    window.addEventListener('resize', waveDraw);
    /* شريط التقدم الخطي (الغامر) */
    const ln = g('plrLn'); let lo = false; const lsk = (e) => { const r = ln.getBoundingClientRect(); if (A.duration) { A.currentTime = Math.max(0, Math.min(1, (e.clientX - r.left) / r.width)) * A.duration; lnUi(); } };
    ln.addEventListener('pointerdown', (e) => { lo = true; ln.classList.add('on'); try { ln.setPointerCapture(e.pointerId); } catch (x) {} lsk(e); });
    ln.addEventListener('pointermove', (e) => { if (lo) lsk(e); }); ['pointerup', 'pointercancel'].forEach((n) => ln.addEventListener(n, () => { lo = false; ln.classList.remove('on'); }));
  })();
  function lnUi() { const d = A.duration || 0, p = d ? Math.min(1, A.currentTime / d) : 0, s = (p * 100).toFixed(2) + '%'; g('plrLnF').style.width = s; g('plrLnK').style.left = s; }
  /* شكل الصوت الحي: المنشد في الوسط، ثم الإيقاع، ثم الجمهور، ثم الآلات نحو الأطراف */
  const SPC = { h: [] };
  /* الصوت يُسمع بعد تحليله بزمن «تأخير الإخراج» (قد يصل لربع ثانية بالأندرويد)، فنؤخر الرسم بنفس المقدار حتى يطابق ما تسمعه */
  const DLY = []; function dlyPush() { if (!live) return; const n = performance.now(); DLY.push({ ts: n, v: Float32Array.from(live.vals), s: { voc: STM.voc, drum: STM.drum, crowd: STM.crowd, inst: STM.inst } }); while (DLY.length > 2 && n - DLY[0].ts > 700) DLY.shift(); }
  function dlyGet() { if (!DLY.length) return null; const lat = ac ? (ac.outputLatency || ac.baseLatency || 0) : 0, tgt = performance.now() - Math.min(0.6, lat) * 1000; let f = DLY[0]; for (let i = DLY.length - 1; i >= 0; i--) if (DLY[i].ts <= tgt) { f = DLY[i]; break; } return f; }
  function specDraw(dt) {
    const cv = g('plrSpec'); if (!cv.offsetWidth) return; const dpr = Math.min(window.devicePixelRatio || 1, 2), w = cv.offsetWidth, h = cv.offsetHeight;
    if (cv.width !== Math.round(w * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); } const x = cv.getContext('2d'); x.setTransform(dpr, 0, 0, dpr, 0, 0); x.clearRect(0, 0, w, h);
    const fr = dlyGet(), S = (fr && fr.s) || { voc: 0, drum: 0, crowd: 0, inst: 0 }, V = fr ? fr.v : null, half = 22, step = w / 2 / half, bw = Math.max(2, step * 0.42), t = performance.now() / 1000;
    const hx = (h0) => { const n = parseInt(h0.slice(1), 16); return [n >> 16 & 255, n >> 8 & 255, n & 255]; }; const Z = [['voc', 0, hx(THC.A2)], ['drum', 0.34, [255, 255, 255]], ['crowd', 0.62, hx(THC.A)], ['inst', 0.9, [225, 232, 228]]], ga = (f, m) => Math.exp(-((f - m) * (f - m)) / 0.03);
    for (let i = 0; i < half; i++) { const f = i / (half - 1); let ws = 0, lv = 0, cr = 0, cg = 0, cb = 0; Z.forEach(([k, m, c]) => { const w = ga(f, m); ws += w; lv += w * (S[k] || 0); cr += w * c[0]; cg += w * c[1]; cb += w * c[2]; }); lv /= ws;
      const bd = V ? V[Math.min(21, Math.round(f * 21))] || 0 : 0, tgt = A.paused || !(useLive || (live && live.pre)) ? 0.06 : Math.min(1, 0.06 + lv * 0.62 + bd * 0.42);
      SPC.h[i] = (SPC.h[i] || 0) + (tgt - (SPC.h[i] || 0)) * Math.min(1, dt * (tgt > (SPC.h[i] || 0) ? 40 : 12)); const v = SPC.h[i], bh = Math.max(bw * 1.6, v * (h - 4));
      x.fillStyle = `rgba(${cr / ws | 0},${cg / ws | 0},${cb / ws | 0},${(0.55 + v * 0.45).toFixed(3)})`;
      [w / 2 - (i + 0.5) * step, w / 2 + (i + 0.5) * step].forEach((cx) => { x.beginPath(); x.roundRect ? x.roundRect(cx - bw / 2, (h - bh) / 2, bw, bh, bw / 2) : x.rect(cx - bw / 2, (h - bh) / 2, bw, bh); x.fill(); }); }
  }
  /* منع تداخل التشغيل: داخل التطبيق وبين النوافذ */
  let bc = null; try { bc = new BroadcastChannel('minbar-play'); bc.onmessage = (e) => { if (e.data === 'play' && !A.paused) A.pause(); }; } catch (e) {}
  A.addEventListener('play', () => { if (AU.fade && ac) { const g2 = AU.fade.gain, T = ac.currentTime; g2.cancelScheduledValues(T); if (g2.value < 0.5) { g2.setValueAtTime(Math.max(0.0001, g2.value), T); g2.exponentialRampToValueAtTime(1, T + 0.25); } else g2.setValueAtTime(1, T); } try { bc && bc.postMessage('play'); } catch (e) {} document.querySelectorAll('audio,video').forEach((m) => { if (m !== A && !m.paused) m.pause(); }); });
  document.addEventListener('play', (e) => { if (e.target !== A && !A.paused) fadePause(); }, true);
  let posT = 0; A.addEventListener('timeupdate', () => { const n = Date.now(); if (n - posT < 4000 || !('mediaSession' in navigator) || !A.duration) return; posT = n; try { navigator.mediaSession.setPositionState({ duration: A.duration, playbackRate: A.playbackRate, position: Math.min(A.currentTime, A.duration) }); } catch (e) {} });
  ['play', 'pause'].forEach((e) => A.addEventListener(e, ui));
  A.addEventListener('ended', () => { if (A.__stop) { A.__stop = false; ui(); return; } if (st.rep === 2) { A.currentTime = 0; A.play(); } else if (st.rep === 1 || qNext(tracks[cur], 1)) step(1); else ui(); });
  A.addEventListener('loadedmetadata', () => { try { const t = tracks[cur]; if (t && isFinite(A.duration)) { const du = JSON.parse(localStorage.getItem(DUK) || '{}'); if (du[t.id] !== Math.round(A.duration)) { du[t.id] = Math.round(A.duration); localStorage.setItem(DUK, JSON.stringify(du)); } } } catch (e) {} g('plrDur').textContent = fmt(A.duration); clipReset(); waveDraw(); });
  A.addEventListener('timeupdate', () => {
    const d = A.duration || 0; g('plrCur').textContent = fmt(A.currentTime); if (d) { g('plrMiniP').style.width = (A.currentTime / d * 100) + '%'; if (!g('plrFull').hidden) waveDraw(); }
    lyrTick(); if (clipPrev && A.currentTime >= clipB) { A.currentTime = clipA; }
  });
  if ('mediaSession' in navigator) { const ms = navigator.mediaSession; const h = (a, f) => { try { ms.setActionHandler(a, f); } catch (e) {} }; h('play', () => fadePlay()); h('pause', () => fadePause()); h('seekbackward', () => { A.currentTime = Math.max(0, A.currentTime - 10); }); h('seekforward', () => { A.currentTime = Math.min(A.duration || 0, A.currentTime + 10); }); h('nexttrack', () => step(1)); h('previoustrack', () => step(-1)); h('seekto', (d) => { A.currentTime = d.seekTime; }); }

  /* الكلمات */
  const TMK = 'minbar.lyr.times', MYK = 'minbar.lyr.mine', SQK = 'minbar.lyr.subq', GLK = 'minbar.lyr.gly';
  const GLY = Object.assign({}, (function () { try { return JSON.parse(localStorage.getItem('minbar.lyr.gly') || '{}'); } catch (e) { return {}; } })()), GED = {}; let lyrI = -2, demoH = 0;
  const TRS = [['slide', 'انزلاق', '⇅'], ['scroll', 'تمرير', '↕'], ['fade', 'تلاشٍ', '◐'], ['zoom', 'تكبير', '⊕'], ['kar', 'تعبئة', '▰'], ['blur', 'ضبابي', '◌'], ['rise', 'صعود', '↑'], ['flip', 'انقلاب', '⟲'], ['glow', 'توهّج', '✦'], ['focus', 'تركيز', '◎']];
  const jset = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) {} };
  const r2 = (n) => Math.round(n * 100) / 100;
  const fmt1 = (t) => fmt(t) + '.' + String(Math.floor((t % 1) * 10));
  const MJLY = {};
  function linesOf(t) {
    if (!t) return [];
    const base = jget(MYK, {})[t.id] || GLY[t.id] || MJLY[t.id] || (t.lyrics && t.lyrics.length ? t.lyrics : []);
    const ed = jget(EDK, {})[t.id] || {}, tm = jget(TMK, {})[t.id] || {}, ge = GED[t.id] || {};
    return base.map((x, i) => { const gl = ge[i + ':l'], gt = ge[i + ':t']; const o = gl ? gl.val : x.l, ot = gt ? +gt.val : x.t; return { t: tm[i] != null ? tm[i] : ot, l: ed[i] != null ? ed[i] : o, o, ot, i, ed: ed[i] != null || tm[i] != null }; });
  }
  function lyStyle() {
    try { lyT = null; } catch (e) {}
    const b = g('plrFull'); b.style.setProperty('--lyf', `"${st.ly.font}", Cairo, sans-serif`); b.style.setProperty('--lyc', st.ly.color); b.style.setProperty('--lys', st.ly.size); { const f0 = LF.find((x) => x[0] === st.ly.font); b.style.setProperty('--lyw', f0 ? f0[2] : 700); }
    const f = LF.find((x) => x[0] === st.ly.font); try { document.fonts.load(`${f ? f[2] : 700} 30px "${st.ly.font}"`, 'قصيدة').then(() => { b.style.setProperty('--lyf', `"${st.ly.font}", Cairo, sans-serif`); }); } catch (e) {}
    ['plrLyr', 'plrLyPre'].forEach((id) => { g(id).dataset.tr = st.ly.tr || 'slide'; });
    const re = () => ['plrLyr', 'plrLyPre'].forEach((id) => { const bx = g(id), k = bx._i; if (k != null && k > -2) { bx._i = -3; lyxGo(bx, k, true); } }); requestAnimationFrame(re); setTimeout(re, 400);
  }
  /* شريط الكلمات المنزلق: كل الأسطر في عمود يصعد بسلاسة، والحالي في الوسط */
  function lyxSet(box, lines) {
    const tr = box.querySelector('.lyt'), key = lines.join('\u0001'); if (box._k === key) return; box._k = key; box._i = -2; tr.textContent = '';
    lines.forEach((l) => { const d = document.createElement('div'); const sep = /^[\s*\-–—_.•~=]+$/.test(l || ''); d.className = 'll' + (sep ? ' sep' : ''); d.textContent = sep ? '۞' : l; tr.appendChild(d); }); tr.style.transition = 'none'; tr.style.transform = 'translateY(0)';
  }
  function lyxGo(box, k, instant) {
    if (box._i === k && !instant) return; const tr = box.querySelector('.lyt'), ch = tr.children; if (!ch.length) return;
    const prev = box._i; box._i = k; for (let i = 0; i < ch.length; i++) { const c = ch[i]; c.classList.toggle('cur', i === k); c.classList.toggle('nb', i === k - 1 || i === k + 1); if (i !== k) c.style.removeProperty('--kp'); }
    const H = box.clientHeight, el2 = ch[Math.max(0, k)], y = k < 0 ? H / 2 - (el2.offsetTop + el2.offsetHeight / 2) + el2.offsetHeight : H / 2 - (el2.offsetTop + el2.offsetHeight / 2);
    tr.style.transition = instant || prev === -2 ? 'none' : ''; tr.style.transform = `translateY(${y.toFixed(1)}px)`;
  }
  let lyL = null, lyT = null;
  function splitLong(L) {
    if (st.ly.split === false) return L; const bw = (g('plrLyr') && g('plrLyr').clientWidth) || Math.min(innerWidth, 480), lim = Math.max(12, Math.min(60, Math.floor((bw - 36) / (26 * (st.ly.size || 1) * 0.5)))), o = [];
    L.forEach((x, i) => { const s = (x.l || '').trim(); if (s.length <= lim || s.indexOf(' ') < 0) { o.push(x); return; } const ws = s.split(' '), n = Math.min(ws.length, Math.max(2, Math.min(6, Math.ceil(s.length / lim)))), cum = [0]; ws.forEach((w) => cum.push(cum[cum.length - 1] + w.length + 1)); const cuts = [0];
      for (let j = 1; j < n; j++) { const tg = s.length * j / n; let bk = cuts[cuts.length - 1] + 1, bd = 1e9; for (let k = cuts[cuts.length - 1] + 1; k <= ws.length - (n - j); k++) { const d = Math.abs(cum[k] - tg); if (d < bd) { bd = d; bk = k; } } cuts.push(bk); } cuts.push(ws.length);
      const nt = L[i + 1] ? L[i + 1].t : x.t + 5, span = nt - x.t > 0 ? nt - x.t : n * 2.5; /* وقت البيت يتوزّع بالتساوي على أجزائه */ for (let j = 0; j < n; j++) o.push(Object.assign({}, x, { l: ws.slice(cuts[j], cuts[j + 1]).join(' '), t: x.t + span * j / n })); });
    return o;
  }
  function lyLines() { const t = tracks[cur]; if (!t) return []; if (lyT !== t) { lyT = t; lyL = splitLong(linesOf(t)); } return lyL; }
  function lyrBuild() { lyT = null; const box = g('plrLyr'); box._i = -2; box._k = null; lyrTick(true); }
  function lyrTick(force) {
    const t = tracks[cur], box = g('plrLyr'); if (!t) return; const L = lyLines();
    box.classList.toggle('empty', !L.length); if (!L.length) { lyxSet(box, []); return; }
    lyxSet(box, L.map((x) => x.l)); const ct = heardT(); let k = -1; for (let i = 0; i < L.length; i++) if (ct >= L[i].t - 0.05) k = i; else break;
    lyxGo(box, k, !!force && box._i === -2); lyrI = k;
    if ((st.ly.tr || 'slide') === 'kar' && k >= 0) { const a = L[k].t, b = L[k + 1] ? L[k + 1].t : a + 4, p = Math.max(0, Math.min(1, (ct - a) / Math.max(0.4, b - a))), c = box.querySelector('.lyt').children[k]; if (c) c.style.setProperty('--kp', (p * 100).toFixed(1)); }
  }
  g('plrLyr').onclick = null;
  (function () { const bx = g('plrLyr'); let tm = 0, x0 = 0, y0 = 0; const cancel = () => { clearTimeout(tm); bx.classList.remove('lp'); };
    bx.addEventListener('pointerdown', (e) => { x0 = e.clientX; y0 = e.clientY; clearTimeout(tm); bx.classList.add('lp'); tm = setTimeout(() => { bx.classList.remove('lp'); if (performance.now() - (bx._nc || 0) < 450) return; bx._nc = performance.now() + 600; try { navigator.vibrate && navigator.vibrate(15); } catch (x) {} openLys(); }, 550); });
    bx.addEventListener('pointermove', (e) => { if (Math.abs(e.clientX - x0) + Math.abs(e.clientY - y0) > 10) cancel(); }); ['pointerup', 'pointercancel', 'pointerleave'].forEach((n) => bx.addEventListener(n, cancel));
    bx.addEventListener('contextmenu', (e) => e.preventDefault()); })();
  /* سحب الكلمات للأعلى أو الأسفل = الانتقال بين الأبيات */
  (function () {
    const box = g('plrLyr'); let on = false, y0 = 0, base = 0, drag = false, kk = -1;
    const tyOf = (tr) => { const m = /translateY\((-?[\d.]+)px\)/.exec(tr.style.transform || ''); return m ? +m[1] : 0; };
    box.addEventListener('pointerdown', (e) => { if (box.classList.contains('empty') || cur < 0) return; on = true; drag = false; y0 = e.clientY; base = tyOf(box.querySelector('.lyt')); kk = box._i; box._k0 = kk; });
    box.addEventListener('pointermove', (e) => { if (!on) return; const dy = e.clientY - y0, tr = box.querySelector('.lyt'), ch = tr.children; if (!drag) { if (Math.abs(dy) < 8) return; drag = true; try { box.setPointerCapture(e.pointerId); } catch (x) {} box.classList.add('drg'); tr.style.transition = 'none'; }
      const y = base + dy; tr.style.transform = `translateY(${y.toFixed(1)}px)`; const c = box.clientHeight / 2 - y; let best = 0, bd = 1e9; for (let i = 0; i < ch.length; i++) { const m = ch[i].offsetTop + ch[i].offsetHeight / 2, d = Math.abs(m - c); if (d < bd) { bd = d; best = i; } }
      if (best !== kk) { kk = best; for (let i = 0; i < ch.length; i++) { ch[i].classList.toggle('cur', i === kk); ch[i].classList.toggle('nb', i === kk - 1 || i === kk + 1); } try { navigator.vibrate && navigator.vibrate(6); } catch (x) {} } });
    const end = () => { if (!on) return; on = false; if (!drag) return; box._nc = performance.now(); box.classList.remove('drg'); const L = lyLines(), q = L[kk]; if (kk !== box._k0 && q && isFinite(q.t) && A.duration) { A.currentTime = Math.max(0, Math.min(A.duration - 0.1, q.t + 0.12)); if (A.paused) fadePlay(); } box.querySelector('.lyt').style.transition = ''; box._i = -3; lyxGo(box, kk); };
    box.addEventListener('pointerup', end); box.addEventListener('pointercancel', end);
  })();
  /* معاينة متحركة للانتقال */
  const DEMO = ['السلام عليك يا أبا عبد الله', 'وعلى الأرواح التي حلّت بفنائك', 'عليك منّي سلام الله أبداً', 'ما بقيتُ وبقي الليل والنهار', 'ولا جعله الله آخر العهد منّي'];
  let demoRaf = 0;
  function demoStart() {
    cancelAnimationFrame(demoRaf); const box = g('plrLyPre'); box._k = null; lyxSet(box, DEMO); const t0 = performance.now(), D = 2600;
    const f = (now) => { if (g('plrLys').hidden) return; const e = (now - t0) / D, k = Math.floor(e) % DEMO.length, p = e % 1; lyxGo(box, k); if ((st.ly.tr || 'slide') === 'kar') { const c = box.querySelector('.lyt').children[k]; c && c.style.setProperty('--kp', (p * 100).toFixed(1)); } demoRaf = requestAnimationFrame(f); };
    requestAnimationFrame(() => { box._i = -2; lyxGo(box, 0, true); demoRaf = requestAnimationFrame(f); });
  }
  const demoStop = () => cancelAnimationFrame(demoRaf);
  function openLys() { lyStyle(); lysStyleBuild(); lysTab(g('plrLyT').querySelector('.on').dataset.k); g('plrLys').hidden = false; g('plrAdmB').hidden = !(window.MinbarAuth && window.MinbarAuth.admin); demoStart(); flush(); }
  function closeLys() { try { const ae = document.activeElement; if (ae && ae.blur && g('plrLys').contains(ae)) ae.blur(); } catch (e) {} demoStop(); g('plrLys').hidden = true; uiSave(null); lyrBuild(); }
  g('plrLyOk').onclick = () => { closeLys(); toast('تم التطبيق'); };
  g('plrLyB').onclick = openLys; g('plrLyBack').onclick = closeLys;
  g('plrLyT').querySelectorAll('button').forEach((b) => b.onclick = () => { g('plrLyT').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x === b)); lysTab(b.dataset.k); });
  const UIK = 'minbar.ui.ly'; const uiSave = (o) => { try { if (o) localStorage.setItem(UIK, JSON.stringify(o)); else localStorage.removeItem(UIK); } catch (e) {} };
  function lysTab(k) { g('plrLyStyle').hidden = k !== 'style'; g('plrLyEdit').hidden = k !== 'edit'; if (k === 'edit') lysEditBuild(); const t = tracks[cur]; if (t) uiSave({ id: t.id, tab: k }); }
  /* بعد رجوع التطبيق من الخلفية (أو إعادة تحميله من النظام) نرجع لنفس شاشة التحرير */
  function uiRestore() { let o = null; try { o = JSON.parse(localStorage.getItem(UIK) || 'null'); } catch (e) {} const t = tracks[cur]; if (!o || !t || t.id !== o.id) return; openFull();
    g('plrLyT').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x.dataset.k === o.tab)); openLys();
    let run = null; try { run = JSON.parse(localStorage.getItem('minbar.ai.run') || 'null'); } catch (e) {} if (run && run.id === t.id && o.tab === 'edit') snack('التحليل توقّف عند خروجك من التطبيق', 'استئناف', () => { aiQ = run.q || aiQ; aiRun(t, run.mode, run.lines); }, 12000); }
  /* لوحة المفاتيح: النافذة تأخذ المساحة الظاهرة فقط، والحقل يبقى ظاهراً */
  if (window.visualViewport) { const vv = window.visualViewport, vu = () => { root.style.setProperty('--vvh', vv.height + 'px'); }; vv.addEventListener('resize', vu); vu(); }
  g('plrLys').addEventListener('focusin', (e) => { const f = e.target; if (!f || !/TEXTAREA|INPUT/.test(f.tagName)) return; setTimeout(() => { try { f.scrollIntoView({ block: 'center', behavior: 'smooth' }); } catch (x) {} }, 320); });
  function lysStyleBuild() { const scr = g('plrLyScroll'), sy = scr.scrollTop; requestAnimationFrame(() => { scr.scrollTop = sy; }); lysStyleBuild0(); scr.scrollTop = sy; }
  function lysStyleBuild0() {
    const SP = g('plrLySp'); SP.textContent = ''; [[true, 'تلقائي'], [false, 'إيقاف']].forEach(([v, n]) => { const b = el('button', (st.ly.split !== false) === v ? 'on' : '', n); b.type = 'button'; b.onclick = () => { st.ly.split = v; save(); lyrBuild(); lysStyleBuild(); }; SP.appendChild(b); });
    const F = g('plrLyF'), C = g('plrLyC'), T = g('plrLyTr'); F.textContent = ''; C.textContent = ''; T.textContent = '';
    LF.forEach(([id, n]) => { const b = document.createElement('button'); b.className = 'fp' + (st.ly.font === id ? ' on' : ''); b.innerHTML = '<span></span><small></small>'; b.firstChild.style.fontFamily = `"${id}"`; b.firstChild.style.fontWeight = LF.find((q) => q[0] === id)[2]; b.firstChild.textContent = n; b.lastChild.remove(); b.onclick = () => { st.ly.font = id; save(); lyStyle(); lysStyleBuild(); }; F.appendChild(b); });
    [['#E8C468', 'ذهبي'], ['#FFFFFF', 'أبيض'], ['#2FBF8F', 'أخضر'], ['#8EC9FF', 'أزرق'], ['#CDB4FF', 'بنفسجي'], ['#FF9DB1', 'وردي'], ['#FF6B6B', 'أحمر'], ['#FFB36B', 'برتقالي']].forEach(([c, cn]) => { const b = document.createElement('button'); b.style.background = c; b.title = cn; b.dataset.n = cn; b.className = st.ly.color.toLowerCase() === c.toLowerCase() ? 'on' : ''; b.onclick = () => { st.ly.color = c; save(); lyStyle(); lysStyleBuild(); }; C.appendChild(b); });
    
    g('plrLySV').textContent = Math.round(st.ly.size * 100) + '%'; mount('plrLyS', sld({ min: 85, max: 120, step: 1, value: Math.round(st.ly.size * 100), def: 100, onInput: (v) => { st.ly.size = v / 100; g('plrLySV').textContent = v + '%'; save(); lyStyle(); } }));
    TRS.forEach(([k, n, d]) => { const b = document.createElement('button'); b.className = 'tr' + ((st.ly.tr || 'slide') === k ? ' on' : ''); b.innerHTML = '<i></i><b></b>'; b.firstChild.textContent = d; b.lastChild.textContent = n; b.onclick = () => { st.ly.tr = k; save(); lyStyle(); lysStyleBuild(); demoStart(); lyrBuild(); }; T.appendChild(b); });
  }
  /* مزامنة مع الخادم (Firestore) — محلياً أولاً، والاعتماد العام بالتصويت أو بموافقة المشرف */
  const fdb = () => { try { return (window.MinbarAuth && window.MinbarAuth.enabled && window.firebase && firebase.firestore) ? firebase.firestore() : null; } catch (e) { return null; } };
  const fuid = () => { try { const u = firebase.auth().currentUser; return u ? u.uid : null; } catch (e) { return null; } };
  let THR = 10;
  async function gFetch(t) {
    const db = fdb(); if (!db || !t) return;
    try {
      const c = await db.doc('config/app').get(); if (c.exists && c.data().lyrThreshold) THR = +c.data().lyrThreshold;
      const d = await db.doc('lyrApproved/' + t.id).get(); if (d.exists) { try { const xd = d.data(), sec = (xd.at && xd.at.seconds) || 0, ak = jget('minbar.lyr.lowAck', {}); if (xd.by === 'auto' && ak[t.id] !== sec) { ak[t.id] = sec; jset('minbar.lyr.lowAck', ak); const lw = jget(LOWK, {}); if (xd.low && xd.low.length) lw[t.id] = xd.low; else delete lw[t.id]; jset(LOWK, lw); } } catch (e) {} try { GLY[t.id] = JSON.parse(d.data().json || '[]'); const c2 = jget(GLK, {}); c2[t.id] = GLY[t.id]; jset(GLK, c2); } catch (e) {} }
      const q = await db.collection('lyrEdits').where('track', '==', t.id).get(), best = {};
      q.forEach((s) => { const x = s.data(), n = (x.voters || []).length; if (n >= THR) { const k = x.line + ':' + x.field; if (!best[k] || n > best[k].n) best[k] = { n, val: x.val }; } });
      GED[t.id] = best; if (tracks[cur] === t) lyrBuild();
    } catch (e) {}
  }
  function suggest(track, line, field, val) { const sg = jget(SGK, []); sg.push({ track, line, field, val, ts: Date.now() }); jset(SGK, sg.slice(-500)); flush(); }
  async function flush() {
    const db = fdb(), u = fuid(); if (!db || !u) return;
    const sg = jget(SGK, []).filter((x) => x.field), left = [];
    for (const x of sg) { try { const id = [x.track, x.line, x.field, hash(String(x.val))].join('__'); await db.doc('lyrEdits/' + id).set({ track: x.track, line: x.line, field: x.field, val: x.val, voters: firebase.firestore.FieldValue.arrayUnion(u) }, { merge: true }); } catch (e) { left.push(x); } }
    jset(SGK, left);
    const sq = jget(SQK, []), l2 = [];
    for (const x of sq) { try { await db.collection('lyrSubs').add({ track: x.track, title: x.title, json: x.json, uid: u, status: 'pending', createdAt: firebase.firestore.FieldValue.serverTimestamp() }); } catch (e) { l2.push(x); } }
    jset(SQK, l2);
  }
  const isAdm = () => !!(window.MinbarAuth && window.MinbarAuth.admin);
  const plain = (L) => L.map((x) => ({ t: r2(x.t), l: x.l }));
  function clearLocal(id) { const a = jget(EDK, {}), b = jget(TMK, {}), m = jget(MYK, {}); delete a[id]; delete b[id]; delete m[id]; jset(EDK, a); jset(TMK, b); jset(MYK, m); }
  /* المشرف: التعديل يُعتمد للجميع مباشرة */
  async function applyGlobal(t, arr, quiet) { try { localStorage.removeItem('minbar.lyr.draft.' + t.id); } catch (e) {}
    GLY[t.id] = arr; const c = jget(GLK, {}); c[t.id] = arr; jset(GLK, c); clearLocal(t.id); lyrBuild();
    const db = fdb(); if (!db) { if (!quiet) toast('حُفظ على هذا الجهاز؛ تعذّر الاتصال بالخادم'); return false; }
    try { await db.doc('lyrApproved/' + t.id).set({ json: JSON.stringify(arr), title: t.title || '', by: fuid(), at: firebase.firestore.FieldValue.serverTimestamp() }); if (!quiet) toast('تم التطبيق للجميع'); return true; }
    catch (e) { toast(e.code === 'permission-denied' ? 'تعذّر الحفظ للجميع: يلزم تحديث قواعد Firestore' : 'تعذّر الحفظ للجميع'); return false; }
  }
  let admT = 0; const admSoon = (t) => { clearTimeout(admT); admT = setTimeout(() => applyGlobal(t, plain(linesOf(t)), true).then((ok) => ok && toast('تم التطبيق للجميع')), 900); };
  function saveMine(t, arr) { try { localStorage.removeItem('minbar.lyr.draft.' + t.id); } catch (e) {} const m = jget(MYK, {}); const a = jget(EDK, {}), b = jget(TMK, {}); delete a[t.id]; delete b[t.id]; jset(EDK, a); jset(TMK, b); m[t.id] = arr; jset(MYK, m); lyrBuild(); }
  function commit(t, arr) { if (isAdm()) return applyGlobal(t, arr); saveMine(t, arr); submitLyrics(t, arr); }
  const el = (tag, cls, txt) => { const e = document.createElement(tag); if (cls) e.className = cls; if (txt != null) e.textContent = txt; return e; };
  const btn = (cls, txt, fn) => { const b = el('button', 'btn small ' + (cls || ''), txt); b.type = 'button'; b.onclick = fn; return b; };
  function lysEditBuild() {
    const t = tracks[cur], box = g('plrLyL'), hint = g('plrLyHint'); box.textContent = ''; if (!t) return; const L = linesOf(t), mine = jget(MYK, {})[t.id], adm = isAdm();
    hint.textContent = adm ? 'التعديلات تُطبَّق للجميع مباشرة.' : 'تعديلاتك تظهر لك فوراً، وتُعتمد للجميع بعد المراجعة.';
    try { const sd = JSON.parse(localStorage.getItem(SYK(t)) || 'null'); if (sd && sd.ls && sd.k < sd.ls.length + 1) { const bn = el('div', 'mybar'); bn.append(el('span', '', 'ضبط يدوي غير مكتمل (' + Math.min(sd.k, sd.ls.length) + ' / ' + sd.ls.length + ')'), btn('primary', 'متابعة', () => syncView(box, t, sd.ls, sd)), btn('', 'حذف', () => { localStorage.removeItem(SYK(t)); lysEditBuild(); })); box.appendChild(bn); } } catch (e) {}
    box.appendChild(aiCard(t, L));
    if (mine && !adm) { const bar = el('div', 'mybar'); bar.append(el('span', '', 'هذه نسختك الخاصة'), btn('primary', 'إرسال للمراجعة', () => submitLyrics(t, mine)), btn('', 'حذف نسختي', () => { const m = jget(MYK, {}); delete m[t.id]; jset(MYK, m); lyrBuild(); lysEditBuild(); })); box.appendChild(bar); }
    if (!L.length) return;
    box.appendChild(el('h4', 'lsth', 'الأسطر والتوقيت'));
    const lowS = new Set(jget(LOWK, {})[t.id] || []); if (lowS.size) { const bn = el('div', 'mybar'); bn.append(el('span', '', lowS.size + ' بيت ضبطه تلقائي غير مؤكد (معلّم بالأصفر) — استمع وصحّح')); bn.appendChild(btn('', 'تم', () => { const lw = jget(LOWK, {}); delete lw[t.id]; jset(LOWK, lw); lysEditBuild(); })); box.insertBefore(bn, box.querySelector('.lsth')); }
    L.forEach((ln, li) => {
      const r = el('div', 'plrlr' + (ln.ed ? ' ed' : '') + (lowS.has(li) ? ' low' : '')), top = el('div', 'lrt'), tm = el('button', 'tm', fmt1(ln.t));
      const ta = mkTa(ln.l); roTa(ta); const adj = el('div', 'adj'); adj.hidden = true;
      const setT = (v) => {
        v = Math.max(0, r2(v)); const all = jget(TMK, {}); all[t.id] = all[t.id] || {}; if (Math.abs(v - ln.ot) > 0.001) all[t.id][ln.i] = v; else delete all[t.id][ln.i]; jset(TMK, all);
        ln.t = v; tm.textContent = fmt1(v); r.classList.add('ed'); if (adm) admSoon(t); else if (Math.abs(v - ln.ot) > 0.001) suggest(t.id, ln.i, 't', v); lyrBuild(); /* لا نقفز بالصوت عند تعديل الوقت؛ اضغط الوقت نفسه للاستماع من عنده */
      };
      [['−0.5', -0.5], ['−0.1', -0.1], ['+0.1', 0.1], ['+0.5', 0.5]].forEach(([n, d]) => { const b = el('button', '', n); b.onclick = () => setT(ln.t + d); adj.appendChild(b); });
      const nowB = el('button', 'now', 'الآن'); nowB.onclick = () => setT(A.currentTime); adj.appendChild(nowB);
      tm.onclick = () => { A.currentTime = ln.t; if (A.paused) fadePlay(); adj.hidden = !adj.hidden; };
      ta.addEventListener('input', () => { clearTimeout(ta._t); ta._t = setTimeout(() => ta.onchange(true), 500); });
      ta.onchange = (quiet) => {
        const v = ta.value.trim(), all = jget(EDK, {}); all[t.id] = all[t.id] || {};
        if (v && v !== ln.o) { all[t.id][ln.i] = v; if (!adm) suggest(t.id, ln.i, 'l', v); } else delete all[t.id][ln.i]; jset(EDK, all); ln.l = v || ln.o; r.classList.toggle('ed', !!(v && v !== ln.o)); lyrBuild();
        if (adm) admSoon(t); else if (quiet !== true) toast('تم حفظ التعديل');
      };
      const sp = el('button', 'x sp', '✂'); sp.title = 'تقسيم السطر'; sp.onclick = () => splitLine(t, ln.i, ta);
      const dl = el('button', 'x sp', '✕'); dl.title = 'حذف السطر'; dl.onclick = () => { const arr = plain(linesOf(t)); arr.splice(ln.i, 1); commit(t, arr); lysEditBuild(); toast('حُذف السطر'); };
      const gp = el('button', 'x sp', '♪'); gp.title = 'إدراج فراغ موسيقي بعد هذا السطر'; gp.onclick = () => { const arr = plain(linesOf(t)); arr.splice(ln.i + 1, 0, { t: r2(Math.max(ln.t + 0.5, A.currentTime)), l: '♪' }); arr.sort((a, b) => a.t - b.t); commit(t, arr); lysEditBuild(); toast('أُدرج فراغ'); };
      const ad = el('button', 'x sp', '＋'); ad.title = 'إضافة سطر جديد بعد هذا السطر'; ad.onclick = () => { const arr = plain(linesOf(t)), nx = arr[ln.i + 1]; arr.splice(ln.i + 1, 0, { t: r2(nx && nx.t > ln.t ? (ln.t + nx.t) / 2 : ln.t + 3), l: '…' }); commit(t, arr); lysEditBuild(); toast('أُضيف سطر — اكتب نصّه واضبط وقته'); setTimeout(() => { const x = box.querySelectorAll('.plrlr .lrt textarea')[ln.i + 1]; if (x) { x.scrollIntoView({ block: 'center' }); x.click(); try { x.select(); } catch (e) {} } }, 80); };
      top.append(tm, ta, ad, sp, gp, dl); r.append(top, adj); box.appendChild(r); fitTa(ta);
    });
  }
  function splitLine(t, i, ta) {
    const arr = plain(linesOf(t)), a = arr[i]; if (!a) return; const s = a.l.trim(); let cut = ta && ta.selectionStart > 1 && ta.selectionStart < s.length - 1 ? ta.selectionStart : -1;
    if (cut < 0) { const ws = s.split(' '); if (ws.length < 2) return toast('السطر قصير'); let acc = 0, best = 1e9; for (let k = 1; k < ws.length; k++) { acc += ws[k - 1].length + 1; if (Math.abs(acc - s.length / 2) < best) { best = Math.abs(acc - s.length / 2); cut = acc; } } }
    const p1 = s.slice(0, cut).trim(), p2 = s.slice(cut).trim(); if (!p1 || !p2) return; const nt = arr[i + 1] ? arr[i + 1].t : a.t + 5;
    arr.splice(i, 1, { t: a.t, l: p1 }, { t: r2(a.t + Math.min(nt - a.t, 8) * p1.length / s.length * 0.95), l: p2 });
    if (isAdm()) applyGlobal(t, arr); else saveMine(t, arr); lysEditBuild(); toast('تم تقسيم السطر');
  }
  function mkTa(v) { const ta = document.createElement('textarea'); ta.rows = 1; ta.value = v || ''; ta.spellcheck = false; ta.setAttribute('autocorrect', 'off'); ta.setAttribute('autocapitalize', 'off'); ta.setAttribute('autocomplete', 'off'); ta.addEventListener('input', () => fitTa(ta)); return ta; }
  /* السطر للقراءة حتى تضغطه، حتى يصير التمرير سهلاً بدون فتح لوحة المفاتيح بالغلط */
  function roTa(ta) { ta.readOnly = true; ta.classList.add('ro'); ta.addEventListener('click', () => { if (!ta.readOnly) return; ta.readOnly = false; ta.classList.remove('ro'); ta.focus(); }); ta.addEventListener('blur', () => { ta.readOnly = true; ta.classList.add('ro'); }); }
  function fitTa(ta) { requestAnimationFrame(() => { const sc = g('plrLyScroll'), y = sc ? sc.scrollTop : 0; ta.style.height = 'auto'; ta.style.height = ta.scrollHeight + 'px'; if (sc && sc.scrollTop !== y) sc.scrollTop = y; }); }
  /* ✦ التحليل الذكي */
  let aiQ = localStorage.getItem('minbar.ai.q') || 'good', aiStop = false, aiBusy = false;
  function aiCard(t, L) {
    const c = el('div', 'aic'), h = el('div', 'aih'); h.innerHTML = `<b>${ic('spark', 16)} الكلمات والتوزيع التلقائي</b>`; c.appendChild(h);
    const uniq = []; L.forEach((x) => { if (x.l && x.l !== '♪' && !uniq.includes(x.l)) uniq.push(x.l); });
    const DK = 'minbar.lyr.draft.' + t.id; let dr = null; try { dr = localStorage.getItem(DK); } catch (e) {}
    const ta = mkTa(dr != null ? dr : uniq.join('\n')); ta.className = 'comp'; ta.rows = 5; ta.placeholder = 'سطر لكل بيت أو شطر، ويُفصل الشطران بـ *'; c.appendChild(ta);
    if (dr != null) { const nb = el('div', 'aiql', 'تم استرجاع مسودتك المحفوظة'); c.appendChild(nb); }
    ta.addEventListener('input', () => { clearTimeout(ta._t); ta._t = setTimeout(() => { try { localStorage.setItem(DK, ta.value); } catch (e) {} }, 250); });
    const ls = () => ta.value.split('\n').map((s) => s.trim()).filter(Boolean);
    c.appendChild(el('div', 'aiql', 'دقة التحليل'));
    const q = el('div', 'seg'); [['fast', 'سريع'], ['good', 'دقيق'], ['best', 'الأعلى دقة']].forEach(([k, n]) => { const b = el('button', aiQ === k ? 'on' : '', n); b.type = 'button'; b.onclick = () => { if (aiBusy) return; aiQ = k; localStorage.setItem('minbar.ai.q', k); q.querySelectorAll('button').forEach((x) => x.classList.toggle('on', x === b)); }; q.appendChild(b); }); c.appendChild(q);
    const row = el('div', 'row');
    row.append(btn('primary', '✦ توزيع تلقائي على الصوت', () => { const l = ls(); if (l.length < 2) return toast('أدخل سطرين على الأقل'); aiRun(t, 'align', l); }),
      btn('', 'ضبط يدوي', () => { const l = ls(); if (l.length < 2) return toast('أدخل سطرين على الأقل'); syncView(g('plrLyL'), t, l); }));
    c.appendChild(row);
    const r2b = el('div', 'row'); r2b.append(btn('', 'استخراج مسودة من الصوت', () => aiRun(t, 'extract'))); c.appendChild(r2b);
    const pg = el('div', 'aipg'); pg.hidden = true; pg.innerHTML = '<ol class="aist"><li data-s="0">تجهيز الصوت</li><li data-s="1">تحميل نموذج التعرّف</li><li data-s="2">الاستماع للقصيدة</li><li data-s="3">مطابقة الأبيات</li></ol><div class="bar"><i></i></div><div class="st"><span class="m"></span><b class="pc"></b></div><div class="st2"><span class="el"></span><span class="eta"></span></div>';
    const cx = btn('', 'إيقاف التحليل', () => { aiStop = true; }); cx.classList.add('aicx'); pg.appendChild(cx); c.appendChild(pg);
    return c;
  }
  const ASRK = (t, q) => 'minbar.asr3.' + t.id + '.' + q;
  async function aiRun(t, mode, lines, fresh) {
    if (aiBusy) return toast('التحليل جارٍ'); if (!window.LYAI) return toast('محرك التحليل غير محمّل');
    const box = g('plrLyL'); let card = box.querySelector('.aic:not(.rv)'); if (!card) { lysEditBuild(); card = box.querySelector('.aic'); }
    const pg = card.querySelector('.aipg'), bar = pg.querySelector('.bar i'), msg = pg.querySelector('.m'), pc = pg.querySelector('.pc'), elT = pg.querySelector('.el'), eta = pg.querySelector('.eta'); pg.hidden = false; card.classList.add('busy'); aiBusy = true; aiStop = false;
    try { localStorage.setItem('minbar.ai.run', JSON.stringify({ id: t.id, mode, lines, q: aiQ })); } catch (e) {}
    pg.scrollIntoView({ behavior: 'smooth', block: 'center' });
    /* مؤشر حي: الوقت المنقضي + تقدّم سلس داخل كل مقطع + تقدير الوقت المتبقي */
    const T0 = Date.now(); let base = 0, nxt = 0.02, ch = null, chT = 0, chAvg = 0, last = Date.now();
    const step = (s) => pg.querySelectorAll('.aist li').forEach((li) => { const k = +li.dataset.s; li.className = k < s ? 'ok' : k === s ? 'on' : ''; });
    const prog = (s, v, info) => { last = Date.now(); msg.textContent = s; base = v;
      if (/فك|تجهيز/.test(s)) step(0); else if (/تحميل/.test(s)) step(1); else if (info) { step(2); if (!ch || ch.i !== info.i) { const n2 = Date.now(); if (ch) chAvg = chAvg ? chAvg * 0.6 + (n2 - chT) * 0.4 : n2 - chT; ch = info; chT = n2; } nxt = 0.3 + 0.68 * (info.i + 1) / info.n; msg.textContent = 'الاستماع للقصيدة — المقطع ' + (info.i + 1) + ' من ' + info.n; } else if (/ترتيب|مطابقة/.test(s)) step(3); };
    const tick = setInterval(() => { const sec = Math.round((Date.now() - T0) / 1000); elT.textContent = 'منذ ' + fmt(sec); let v = base;
      if (ch) { const e = Date.now() - chT, est = chAvg || 25000; v = base + (nxt - base) * Math.min(0.95, e / est); if (chAvg) { const left = (ch.n - ch.i) * chAvg - e; eta.textContent = left > 4000 ? 'متبقٍ تقريباً ' + fmt(left / 1000) : 'اقترب الانتهاء'; } else eta.textContent = 'يحسب الوقت المتبقي…'; }
      bar.style.width = Math.max(2, v * 100).toFixed(1) + '%'; pc.textContent = Math.round(v * 100) + '%'; pg.classList.toggle('slow', Date.now() - last > 45000); }, 250);
    prog('تجهيز الصوت…', 0.02); if (aiQ === 'best' && !navigator.gpu) toast('«الأعلى دقة» بطيء على هذا الجهاز');
    const PK = 'minbar.asr.part.' + t.id + '.' + aiQ; if (fresh) try { localStorage.removeItem(PK); } catch (e) {}
    const part = { get: () => JSON.parse(localStorage.getItem(PK) || 'null'), put: (o) => { try { localStorage.setItem(PK, JSON.stringify(o)); } catch (e) {} } };
    const done = () => { clearInterval(tick); pg.hidden = true; card.classList.remove('busy'); aiBusy = false; try { localStorage.removeItem('minbar.ai.run'); } catch (e) {} try { window.LYAI.free(); } catch (e) {} };
    try {
      let segs = null; if (!fresh) { try { const c = JSON.parse(localStorage.getItem(ASRK(t, aiQ)) || 'null'); if (c) segs = c.map((x) => ({ t0: x[0], t1: x[1], text: x[2], words: window.LYAI.segsToWords([{ text: x[2], timestamp: [x[0], x[1]] }]) })); } catch (e) {} }
      if (!segs) { segs = await window.LYAI.transcribe(t.audio, aiQ, prog, () => aiStop, part); if (segs.length) { try { localStorage.setItem(ASRK(t, aiQ), JSON.stringify(segs.map((x) => [r2(x.t0), r2(x.t1), x.text]))); localStorage.removeItem(PK); } catch (e) {} } }
      prog('مطابقة الأبيات…', 0.98); await new Promise((r) => setTimeout(r, 30));
      let rows, st2 = null;
      if (mode === 'extract') rows = window.LYAI.extractP(segs); else { const r = window.LYAI.alignP(lines, segs, { base: 0.35 }); rows = r.out; st2 = r.stats; }
      done(); if (!rows.length) return toast('تعذّر تمييز كلام واضح في هذا التسجيل');
      aiReview(t, rows, mode, st2, lines);
    } catch (e) { done(); toast(e && e.message === 'cancel' ? 'أُوقف التحليل — يُستأنف من حيث توقّف عند الإعادة' : 'تعذّر التحليل. يلزم اتصال بالإنترنت عند الاستخدام الأول.'); console.warn(e); }
  }
  function aiReview(t, rows, mode, stt, lines) {
    const box = g('plrLyL'); box.textContent = ''; const head = el('div', 'aic rv'), nRep = rows.filter((r) => r.rep).length, nLow = rows.filter((r) => r.conf < 0.45).length;
    head.innerHTML = `<b>${ic('spark', 16)} النتيجة</b>`; head.appendChild(el('p', 'aip', rows.length + ' سطر' + (nRep ? ' · ' + nRep + ' معاد' : '') + (nLow ? ' · ' + nLow + ' للمراجعة' : '') + '. اضغط الوقت للاستماع.'));
    const acts = el('div', 'row'); const getRows = () => rows.filter((r) => !r.del).map((r) => ({ t: r2(r.t), l: r.l.trim() })).filter((r) => r.l);
    acts.append(btn('primary', isAdm() ? 'اعتماد للجميع' : 'حفظ وإرسال', () => { commit(t, getRows()); lysEditBuild(); }), btn('', 'حفظ على هذا الجهاز', () => { saveMine(t, getRows()); toast('حُفظت على هذا الجهاز'); lysEditBuild(); }));
    const acts2 = el('div', 'row'); acts2.append(btn('', 'تحليل جديد', () => { lysEditBuild(); aiRun(t, mode, lines, true); }), btn('', 'رجوع', () => lysEditBuild()));
    head.append(acts, acts2); box.appendChild(head);
    rows.forEach((o) => {
      const r = el('div', 'plrlr ai' + (o.conf < 0.45 ? ' low' : '')), top = el('div', 'lrt'), tm = el('button', 'tm', fmt1(o.t)); tm.onclick = () => { A.currentTime = o.t; if (A.paused) fadePlay(); };
      const ta = mkTa(o.l); ta.addEventListener('input', () => { o.l = ta.value; });
      const tg = el('div', 'tags'); if (o.rep) tg.appendChild(el('span', 'rep', '↻ إعادة')); if (o.part) tg.appendChild(el('span', '', 'شطر')); if (o.seen === false) tg.appendChild(el('span', 'q', 'تقريبي'));
      const x = el('button', 'x', '×'); x.onclick = () => { o.del = !o.del; r.classList.toggle('del', !!o.del); };
      top.append(tm, ta, x); r.append(top); if (tg.childNodes.length) r.appendChild(tg); box.appendChild(r); fitTa(ta);
    });
  }
  function composer() {}
  /* الضبط اليدوي: حفظ فوري للتقدّم، تنقّل بالسحب، وأدوات دقيقة */
  const SYK = (t) => 'minbar.lyr.sync.' + t.id;
  function syncView(box, t, ls, resume) {
    const sv = resume || { ls, st2: [], k: 0 }; ls = sv.ls; const st2 = sv.st2 || []; let k = sv.k || 0, slow = false, raf = 0, seg = null, view = sv.view || 'sync';
    let N = ls.length; const LAT = 0.12;
    const keep = () => { try { localStorage.setItem(SYK(t), JSON.stringify({ ls, st2, k, view })); } catch (e) {} };
    const setRate = () => { A.playbackRate = slow ? 0.75 : (st.speed || 1); };
    const stopLoop = () => { cancelAnimationFrame(raf); raf = 0; clearInterval(seg); seg = null; };
    const leave = () => { stopLoop(); slow = false; setRate(); };
    const sc = g('plrLyScroll'); sc.scrollTo({ top: 0 });
    const avgDur = () => { let s = 0, n = 0; for (let i = 1; i < k; i++) if (st2[i] != null && st2[i - 1] != null) { s += st2[i] - st2[i - 1]; n++; } return n ? Math.max(1.5, s / n) : 4; };
    const ibn = (icn, lbl, fn, cls) => { const b = el('button', 'sib' + (cls ? ' ' + cls : '')); b.type = 'button'; b.innerHTML = ic(icn, 20) + '<span></span>'; b.lastChild.textContent = lbl; b.onclick = fn; return b; };
    /* ---------- شاشة الضبط ---------- */
    function paintSync() {
      view = 'sync'; keep(); stopLoop(); box.textContent = ''; const w = el('div', 'sy2');
      const hd = el('div', 'sy2h'); const cnt = el('b'); hd.append(el('span', '', 'الضبط اليدوي'), cnt); const bar = el('div', 'sy2bar'); bar.appendChild(el('i')); w.append(hd, bar);
      const list = el('div', 'sy2l'); const rows = ls.map((x, i) => { const r = el('div', 'sy2r'); r.innerHTML = '<i class="fl"></i><span class="tt"></span><span class="tx"></span>'; r.children[2].textContent = x;
        r.onclick = () => { if (i >= k) return; snack('إعادة الضبط من البيت ' + (i + 1) + '؟', 'نعم', () => { k = i; st2.length = i; A.currentTime = Math.max(0, (i > 0 ? st2[i - 1] : 0) - (i > 0 ? 0.3 : 0)); if (A.paused) fadePlay(); keep(); upd(true); }); };
        list.appendChild(r); return r; }); w.appendChild(list);
      const fx = el('div', 'sy2fx'); const fxl = el('span'); const nud = (d) => { if (k < 1) return; st2[k - 1] = Math.max(0, r2(st2[k - 1] + d)); keep(); upd(); };
      fx.append(el('button', '', '−0.1'), fxl, el('button', '', '+0.1')); fx.firstChild.onclick = () => nud(-0.1); fx.lastChild.onclick = () => nud(0.1); w.appendChild(fx);
      const go = el('button', 'sy2go'); go.type = 'button'; w.appendChild(go);
      const mark = () => { if (k >= N) return; if (A.paused) { fadePlay(); if (k === 0) { /* أول ضغطة تبدأ التشغيل فقط إذا كنا قبل الصوت */ } }
        const ol = ac && ac.outputLatency ? ac.outputLatency : 0; st2[k] = Math.max(0, r2(A.currentTime - LAT - ol)); if (k > 0 && st2[k] <= st2[k - 1]) st2[k] = r2(st2[k - 1] + 0.2); k++; keep(); upd(true); try { navigator.vibrate && navigator.vibrate(10); } catch (x) {} };
      go.addEventListener('pointerdown', (e) => { e.preventDefault(); go.classList.add('dn'); mark(); }); ['pointerup', 'pointerleave', 'pointercancel'].forEach((n) => go.addEventListener(n, () => go.classList.remove('dn')));
      const ctl = el('div', 'sy2c'); const pp = ibn(A.paused ? 'play' : 'pause', A.paused ? 'تشغيل' : 'إيقاف', () => toggle(), 'big');
      ctl.append(ibn('rw', '3 ث', () => { A.currentTime = Math.max(0, A.currentTime - 3); }), pp, ibn('fw', '3 ث', () => { A.currentTime += 3; }),
        ibn('speed', 'أبطأ', function () { slow = !slow; setRate(); this.classList.toggle('on', slow); }, slow ? 'on' : ''),
        ibn('undo', 'تراجع', () => { if (k < 1) return; k--; st2.length = k; A.currentTime = Math.max(0, (k > 0 ? st2[k - 1] : 0) - 0.5); keep(); upd(true); }));
      w.appendChild(ctl);
      const ft = el('div', 'row'); ft.append(btn('', 'حفظ والخروج', () => { keep(); leave(); lysEditBuild(); toast('حُفظ التقدّم — تكمل لاحقاً من نفس البيت'); }), btn('primary', 'مراجعة', () => { if (!k) return toast('اضبط بيتاً واحداً على الأقل'); paintRev(); })); w.appendChild(ft);
      box.appendChild(w);
      let lastK = -1, lastP = null;
      function upd(scroll) { cnt.textContent = Math.min(k, N) + ' / ' + N; bar.firstChild.style.width = (k / N * 100) + '%';
        go.textContent = k === 0 ? 'ابدأ — البيت الأول' : k < N ? 'البيت التالي ↓' : 'تم ضبط كل الأبيات'; go.disabled = k >= N; fx.hidden = k < 1; if (k > 0) fxl.textContent = 'البيت ' + k + ' يبدأ عند ' + fmt1(st2[k - 1]);
        rows.forEach((r, i) => { r.className = 'sy2r' + (i < k - 1 ? ' done' : i === k - 1 ? ' act' : i === k ? ' nx' : ''); r.children[1].textContent = st2[i] != null && i < k ? fmt1(st2[i]) : ''; if (i !== k - 1) r.firstChild.style.transform = 'scaleX(0)'; });
        if (scroll || lastK !== k) { const r = rows[Math.min(N - 1, Math.max(0, k - 1))]; if (r) list.scrollTo({ top: r.offsetTop - list.clientHeight * 0.35, behavior: 'smooth' }); lastK = k; } }
      const loop = () => { if (!w.isConnected) return stopLoop(); raf = requestAnimationFrame(loop); if (A.paused !== lastP) { lastP = A.paused; pp.innerHTML = ic(A.paused ? 'play' : 'pause', 22) + '<span>' + (A.paused ? 'تشغيل' : 'إيقاف') + '</span>'; }
        if (k > 0) { const r = rows[k - 1], s = st2[k - 1]; if (r && s != null) { const f = Math.max(0, Math.min(1, (A.currentTime - s) / avgDur())); r.firstChild.style.transform = 'scaleX(' + f.toFixed(3) + ')'; r.classList.toggle('long', f >= 1); } } };
      upd(true); raf = requestAnimationFrame(loop);
      if (k > 0 && st2[k - 1] != null && resume) { A.currentTime = Math.max(0, st2[k - 1] - 1); }
      resume = null;
    }
    /* ---------- شاشة المراجعة ---------- */
    function playSeg(i, b) { stopLoop(); A.currentTime = st2[i]; fadePlay(); const end = i + 1 < k ? st2[i + 1] : st2[i] + 8; box.querySelectorAll('.rvr').forEach((x) => x.classList.toggle('pl', x === b)); seg = setInterval(() => { if (A.currentTime >= end - 0.05 || A.paused) { clearInterval(seg); seg = null; if (!A.paused) fadePause(); b.classList.remove('pl'); } }, 50); }
    function paintRev() {
      view = 'rev'; keep(); stopLoop(); box.textContent = ''; const w = el('div', 'sy2 rv');
      const hd = el('div', 'sy2h'); hd.append(el('span', '', 'مراجعة الضبط'), el('b', '', k + ' / ' + N)); w.appendChild(hd);
      w.appendChild(el('p', 'sy2p', 'اضغط ▶ لسماع البيت فقط · عدّل الوقت بـ − و + · اضغط النص لتصحيحه · ⟲ لإعادة الضبط من هذا البيت'));
      const list = el('div', 'rvl');
      for (let i = 0; i < k; i++) { const r = el('div', 'rvr'); const pl = el('button', 'rp'); pl.type = 'button'; pl.innerHTML = ic('play', 16); pl.onclick = () => playSeg(i, r);
        const tw = el('div', 'rt'); const mn = el('button', '', '−'), tb = el('b', '', fmt1(st2[i])), pp = el('button', '', '+'); const nd = (d) => { st2[i] = Math.max(i ? st2[i - 1] + 0.1 : 0, r2(st2[i] + d)); tb.textContent = fmt1(st2[i]); keep(); }; mn.onclick = () => nd(-0.1); pp.onclick = () => nd(0.1); tw.append(mn, tb, pp);
        const tx = el('div', 'rx', ls[i]); tx.onclick = () => { const ta = mkTa(ls[i]); ta.className = 'rxe'; tx.replaceWith(ta); ta.focus(); fitTa(ta); const fin = () => { ls[i] = ta.value.trim() || ls[i]; tx.textContent = ls[i]; ta.replaceWith(tx); keep(); }; ta.onblur = fin; ta.onkeydown = (e) => { if (e.key === 'Enter') { e.preventDefault(); ta.blur(); } }; };
        const rs = el('button', 'rr'); rs.type = 'button'; rs.innerHTML = ic('reset', 16); rs.title = 'إعادة الضبط من هنا'; rs.onclick = () => { k = i; st2.length = i; A.currentTime = Math.max(0, (i ? st2[i - 1] : 0) - 0.3); fadePlay(); paintSync(); };
        const ad = el('button', 'rr', '＋'); ad.type = 'button'; ad.title = 'إضافة بيت ناقص بعد هذا'; ad.onclick = () => { ls.splice(i + 1, 0, '…'); st2.splice(i + 1, 0, r2(i + 1 < k ? (st2[i] + st2[i + 1]) / 2 : st2[i] + 3)); k++; N = ls.length; keep(); paintRev(); toast('أُضيف بيت — اضغط نصّه لكتابته'); };
        const dx = el('button', 'rr', '✕'); dx.type = 'button'; dx.title = 'حذف هذا البيت'; dx.onclick = () => { ls.splice(i, 1); st2.splice(i, 1); k--; N = ls.length; keep(); paintRev(); };
        const ra = el('div', 'rra'); ra.append(rs, ad, dx); r.append(pl, tw, tx, ra); list.appendChild(r); }
      if (k < N) { const mr = el('div', 'rvm', 'باقي ' + (N - k) + ' بيت لم يُضبط بعد'); mr.onclick = () => { A.currentTime = Math.max(0, st2[k - 1] - 1); fadePlay(); paintSync(); }; list.appendChild(mr); }
      w.appendChild(list);
      const mk = () => ls.slice(0, k).map((x, i) => ({ t: r2(st2[i]), l: x })), clr = () => { try { localStorage.removeItem(SYK(t)); } catch (e) {} };
      const a1 = el('div', 'row'); a1.append(btn('primary', isAdm() ? 'حفظ واعتماد للجميع' : 'حفظ وإرسال للمراجعة', () => { if (k < N && !confirm('لم تُضبط كل الأبيات. حفظ المضبوط فقط؟')) return; leave(); clr(); commit(t, mk()); lysEditBuild(); }));
      const a2 = el('div', 'row'); a2.append(btn('', 'متابعة الضبط', () => { A.currentTime = Math.max(0, (k ? st2[k - 1] : 0) - 1); paintSync(); }), btn('', 'إعادة من البداية', () => { if (!confirm('مسح كل التوقيتات والبدء من جديد؟')) return; st2.length = 0; k = 0; A.currentTime = 0; keep(); paintSync(); }));
      w.append(a1, a2); box.appendChild(w);
    }
    if (!resume) { A.currentTime = 0; } fadePlay();
    if (view === 'rev' && k > 0) paintRev(); else paintSync();
  }
  function submitLyrics(t, arr) { const q2 = jget(SQK, []); q2.push({ track: t.id, title: t.title, json: JSON.stringify(arr), ts: Date.now() }); jset(SQK, q2); flush().then(() => toast(fuid() ? 'أُرسلت للمراجعة. ستظهر للجميع بعد موافقة المشرف' : 'حُفظت. ستُرسل عند تسجيل الدخول')); toast('تم الحفظ'); }
  /* مراجعة الطلبات (للمشرف فقط) */
  function admShow(on) { const tp0 = on && !g('plrLys').hidden; g('plrAdm').classList.toggle('top', tp0); g('plrBg').classList.toggle('top', tp0); g('plrAdm').hidden = !on; g('plrBg').hidden = !on && g('plrTp').hidden && g('plrQs').hidden; }
  g('plrAdmB').onclick = async () => {
    const db = fdb(), box = g('plrAdmL'); box.textContent = 'جارٍ التحميل...'; admShow(true); if (!db) { admShow(false); toast('غير متصل بالخادم'); return; }
    try {
      const q3 = await db.collection('lyrSubs').where('status', '==', 'pending').limit(30).get(); box.textContent = ''; if (q3.empty) { admShow(false); toast('لا توجد طلبات الآن'); return; }
      q3.forEach((s) => {
        const x = s.data(); let arr = []; try { arr = JSON.parse(x.json || '[]'); } catch (e) {} const r = document.createElement('div'); r.className = 'admr'; const h = document.createElement('b'); h.textContent = (x.title || x.track) + ' — ' + arr.length + ' سطر'; const pv = document.createElement('p'); pv.textContent = arr.slice(0, 4).map((z) => z.l).join(' / ');
        const ok = document.createElement('button'); ok.className = 'btn small primary'; ok.textContent = 'قبول'; ok.onclick = async () => { try { await db.doc('lyrApproved/' + x.track).set({ json: x.json, by: fuid(), at: firebase.firestore.FieldValue.serverTimestamp() }); await s.ref.update({ status: 'approved' }); r.remove(); toast('تم الاعتماد'); } catch (e) { toast('تعذّر التنفيذ: ' + (e.code || e.message)); } };
        const no = document.createElement('button'); no.className = 'btn small'; no.textContent = 'رفض'; no.onclick = async () => { try { await s.ref.update({ status: 'rejected' }); r.remove(); } catch (e) { toast('تعذّر التنفيذ: ' + (e.code || e.message)); } };
        r.append(h, pv, ok, no); box.appendChild(r);
      });
    } catch (e) { admShow(false); console.warn(e); toast(e.code === 'permission-denied' ? 'لا توجد صلاحية لقراءة الطلبات: انسخ قواعد firestore-lyrics.rules.txt إلى Firebase' : e.code === 'unavailable' ? 'لا يوجد اتصال بالخادم' : 'تعذّر تحميل الطلبات: ' + (e.code || e.message)); }
  };
  /* قائمة التشغيل */
  const qs = (on) => { g('plrQs').hidden = !on; g('plrBg').hidden = !on; };
  function qBuild() {
    const t0 = tracks[cur]; const box = g('plrQl'); box.textContent = ''; if (!t0) return; qEnsure(t0); let du = {}; try { du = JSON.parse(localStorage.getItem(DUK) || '{}'); } catch (e) {}
    const ci = Q.ids.indexOf(t0.id), up = Q.ids.slice(ci + 1).map(byId).filter(Boolean), tot = up.reduce((s, x) => s + (du[x.id] || 0), 0);
    g('plrQc').textContent = (Q.src ? 'من: ' + Q.src + ' · ' : '') + (up.length ? up.length + ' قصيدة' + (tot ? ' · ' + fmt(tot) : '') : 'لا يوجد تالٍ');
    g('plrQsh').classList.toggle('on', st.shuf); g('plrQrp').classList.toggle('on', st.rep > 0); g('plrQrp').dataset.rm = st.rep === 2 ? '1' : '';
    const row = (t, kind) => { const r = el('div', 'qr ' + kind); r.dataset.id = t.id; const c = el('div', 'plrcov sm'); coverEl(t, c); const m = el('div', 'qm'); m.append(el('b', '', t.title), el('small', '', t.reciter || ''));
      const d = el('span', 'qd', du[t.id] ? fmt(du[t.id]) : ''); r.append(c, m, d);
      if (kind === 'now') { const eq = el('i', 'qeq' + (A.paused ? ' ps' : '')); eq.innerHTML = '<s></s><s></s><s></s>'; c.appendChild(eq); r.appendChild(el('div', 'qpr')); }
      else { const h = el('button', 'qh'); h.type = 'button'; h.setAttribute('aria-label', 'سحب لإعادة الترتيب'); h.innerHTML = '<s></s><s></s><s></s>'; r.appendChild(h); qDrag(r, h); qSwipe(r, t); r.onclick = (e) => { if (r._mv) return; play(tracks.indexOf(t)); qBuild(); }; }
      return r; };
    box.appendChild(el('h4', 'qsec', 'يُشغَّل الآن')); box.appendChild(row(t0, 'now'));
    if (up.length) { box.appendChild(el('h4', 'qsec', 'التالي')); const L = el('div', 'qlist'); L.id = 'plrQup'; up.forEach((t) => L.appendChild(row(t, 'up'))); box.appendChild(L); }
    const prev = Q.ids.slice(0, ci).map(byId).filter(Boolean); if (prev.length) { box.appendChild(el('h4', 'qsec', 'تم تشغيلها')); const L2 = el('div', 'qlist past'); prev.slice(-30).reverse().forEach((t) => { const r = row(t, 'past'); r.querySelector('.qh').remove(); L2.appendChild(r); }); box.appendChild(L2); }
    qPr();
  }
  function qPr() { const b = g('plrQl').querySelector('.qr.now .qpr'); if (b) b.style.width = (A.duration ? A.currentTime / A.duration * 100 : 0) + '%'; const e = g('plrQl').querySelector('.qeq'); if (e) e.classList.toggle('ps', A.paused); }
  A.addEventListener('timeupdate', () => { if (!g('plrQs').hidden) qPr(); });
  /* إعادة الترتيب بالسحب من المقبض */
  function qDrag(r, h) {
    let y0 = 0, on = false, list = null, items = [], from = 0, to = 0, H = 0, sc = null, raf = 0, lastY = 0;
    const end = () => { if (!on) return; on = false; cancelAnimationFrame(raf); r.classList.remove('drg'); items.forEach((x) => { x.style.transform = ''; x.style.transition = ''; });
      if (to !== from) { const ids = items.map((x) => x.dataset.id), [mvd] = ids.splice(from, 1); ids.splice(to, 0, mvd); const ci = Q.ids.indexOf(tracks[cur].id); Q.ids = Q.ids.slice(0, ci + 1).concat(ids); qSave(); qBuild(); try { navigator.vibrate && navigator.vibrate(8); } catch (e) {} } };
    const upd = () => { const dy = lastY - y0 + (sc.scrollTop - sc._s0); r.style.transform = `translateY(${dy}px)`; to = Math.max(0, Math.min(items.length - 1, from + Math.round(dy / H)));
      items.forEach((x, i) => { if (x === r) return; let o = 0; if (from < to && i > from && i <= to) o = -H; if (from > to && i < from && i >= to) o = H; x.style.transform = o ? `translateY(${o}px)` : ''; }); };
    const auto = () => { if (!on) return; const R = sc.getBoundingClientRect(); if (lastY < R.top + 60) sc.scrollTop -= 8; else if (lastY > R.bottom - 60) sc.scrollTop += 8; upd(); raf = requestAnimationFrame(auto); };
    h.addEventListener('pointerdown', (e) => { e.stopPropagation(); e.preventDefault(); list = r.parentNode; items = [...list.children]; from = to = items.indexOf(r); H = r.offsetHeight + 4; y0 = lastY = e.clientY; sc = g('plrQs'); sc._s0 = sc.scrollTop; on = true; r.classList.add('drg'); items.forEach((x) => { if (x !== r) x.style.transition = 'transform .18s'; }); try { h.setPointerCapture(e.pointerId); } catch (x) {} raf = requestAnimationFrame(auto); try { navigator.vibrate && navigator.vibrate(6); } catch (x) {} });
    h.addEventListener('pointermove', (e) => { if (!on) return; lastY = e.clientY; upd(); });
    h.addEventListener('pointerup', end); h.addEventListener('pointercancel', end);
  }
  /* السحب جانباً للحذف من القائمة */
  function qSwipe(r, t) {
    let x0 = 0, y0 = 0, dx = 0, on = false, hz = false;
    r.addEventListener('pointerdown', (e) => { if (e.target.closest('.qh')) return; on = true; hz = false; r._mv = false; x0 = e.clientX; y0 = e.clientY; dx = 0; });
    r.addEventListener('pointermove', (e) => { if (!on) return; dx = e.clientX - x0; const dy = e.clientY - y0; if (!hz) { if (Math.abs(dy) > 10) { on = false; return; } if (Math.abs(dx) > 12) { hz = true; r._mv = true; try { r.setPointerCapture(e.pointerId); } catch (x) {} r.style.transition = 'none'; } else return; } r.style.transform = `translateX(${dx}px)`; r.style.opacity = 1 - Math.min(0.7, Math.abs(dx) / 260); });
    const end = () => { if (!on) return; on = false; r.style.transition = ''; if (hz && Math.abs(dx) > 110) { r.style.transform = `translateX(${dx > 0 ? 120 : -120}%)`; r.style.opacity = 0; setTimeout(() => { Q.ids = Q.ids.filter((id) => id !== t.id); qSave(); qBuild(); toast('حُذفت من قائمة التشغيل'); }, 200); } else { r.style.transform = ''; r.style.opacity = ''; } setTimeout(() => { r._mv = false; }, 50); };
    r.addEventListener('pointerup', end); r.addEventListener('pointercancel', end);
  }
  /* ضغطة مطوّلة على القصيدة: تشغيل التالي / إضافة للقائمة */
  function lpMenu(c, t) { let tm = 0; c.addEventListener('pointerdown', () => { tm = setTimeout(() => { c._lp = 1; try { navigator.vibrate && navigator.vibrate(15); } catch (e) {} qMenu(t); }, 520); }); ['pointerup', 'pointercancel', 'pointerleave', 'pointermove'].forEach((n) => c.addEventListener(n, (e) => { if (n === 'pointermove' && Math.abs(e.movementY || 0) + Math.abs(e.movementX || 0) < 3) return; clearTimeout(tm); })); }
  g('plrQsv').onclick = () => plSave(); g('plrQsh').onclick = () => g('plrShuf').click(); g('plrQrp').onclick = () => g('plrRep').click();
  g('plrQB').onclick = () => { qBuild(); qs(true); requestAnimationFrame(() => { g('plrQs').scrollTop = 0; }); };

  /* اختيار المقطع الذكي: لمحة كاملة + نافذة دقيقة + التصاق بالأبيات أو بالسكتات + مقترحات */
  const CMAX = 60, CMIN = 3;
  const cLines = () => { const t = tracks[cur]; return linesOf(t).filter((x) => isFinite(x.t)).map((x) => ({ t: +x.t, l: x.l || '' })).sort((a, b) => a.t - b.t); };
  const cEnv = () => { const t = tracks[cur]; return t && ENV.get(t.id); };
  function cSnaps(kind) { const d = A.duration || 0, L = cLines(), o = []; if (L.length >= 2) { L.forEach((x, i) => { if (kind === 'a') o.push(Math.max(0, x.t - 0.25)); else if (i > 0) o.push(Math.max(0, x.t - 0.2)); }); if (kind === 'b') o.push(d); return o; }
    const e = cEnv(); if (!e) return o; const n = e.length; for (let i = 2; i < n - 2; i++) if (e[i] < e[i - 1] && e[i] <= e[i + 1] && e[i] < 0.35) o.push(i / n * d); return o; }
  function cSnap(v, kind, tol) { const S = cSnaps(kind); let best = v, bd = tol; S.forEach((q) => { const dd = Math.abs(q - v); if (dd < bd) { bd = dd; best = q; } }); return best; }
  function cSet(a, b, how) { const d = A.duration || 0; if (!d) return; a = Math.max(0, Math.min(a, d - CMIN)); b = Math.max(a + CMIN, Math.min(b, d, a + CMAX));
    if (how === 'a') a = Math.max(b - CMAX, Math.min(a, b - CMIN)); clipA = a; clipB = b; clipUi(); }
  function cFit(a, len) { const d = A.duration || 0; a = cSnap(a, 'a', 3); let b = a + len; const bs = cSnaps('b').filter((q) => q > a + CMIN && q <= a + CMAX); if (bs.length) { let best = b, bd = 1e9; bs.forEach((q) => { const dd = Math.abs(q - b); if (dd < bd) { bd = dd; best = q; } }); b = best; } cSet(a, Math.min(b, d)); }
  function cSuggest() { const d = A.duration || 0, L = cLines(), e = cEnv(), o = []; if (!d) return o;
    o.push(['المطلع', L.length ? L[0].t : 0, 35]);
    if (L.length > 3) { const nm = (s) => s.replace(/[ً-ٟـ\s.،,!؟]/g, ''); const c = {}; L.forEach((x) => { const k = nm(x.l); if (k.length > 4) c[k] = (c[k] || 0) + 1; }); let bk = '', bn = 1; Object.keys(c).forEach((k) => { if (c[k] > bn) { bn = c[k]; bk = k; } }); if (bk) { const i = L.findIndex((x) => nm(x.l) === bk); o.push(['اللازمة', L[i].t, 30]); } }
    if (e) { const n = e.length, w = Math.max(1, Math.round(30 / d * n)); let s = 0, bs = -1, bi = 0; for (let i = 0; i < n; i++) { s += e[i]; if (i >= w) s -= e[i - w]; if (i >= w - 1 && s > bs) { bs = s; bi = i - w + 1; } } o.push(['الأقوى', bi / n * d, 30]); }
    o.push(['من الآن', A.currentTime, 30]); return o; }
  function clipUi() { const d = A.duration || 0; if (!d) return; g('plrAV').textContent = fmt(clipA); g('plrBV').textContent = fmt(clipB); g('plrClipLen').textContent = 'المدة ' + fmt(clipB - clipA);
    const L = cLines().filter((x) => x.t >= clipA - 0.3 && x.t < clipB - 0.5); g('plrClipLy').textContent = L.length ? ('«' + L[0].l + '»' + (L.length > 1 ? '  …  «' + L[L.length - 1].l + '»' : '') + '  ·  ' + L.length + ' بيت') : '';
    [...g('plrClipLn').children].forEach((b) => b.classList.toggle('on', Math.abs((clipB - clipA) - (+b.dataset.l)) < 2.5)); cDraw(); }
  function cDraw() {
    const d = A.duration || 0; if (!d) return; const e = cEnv(), L = cLines(), dpr = Math.min(2, window.devicePixelRatio || 1);
    const prep = (cv) => { const w = cv.clientWidth, h = cv.clientHeight; if (!w) return null; if (cv.width !== Math.round(w * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); } const x = cv.getContext('2d'); x.setTransform(dpr, 0, 0, dpr, 0, 0); x.clearRect(0, 0, w, h); return [x, w, h]; };
    const bars = (x, w, h, t0, t1, n) => { for (let i = 0; i < n; i++) { const tt = t0 + (i + 0.5) / n * (t1 - t0), v = e ? e[Math.min(e.length - 1, Math.max(0, Math.floor(tt / d * e.length)))] : 0.35 + 0.25 * Math.abs(Math.sin(i * 0.7)), bh = Math.max(2, v * (h - 10)), px = i * w / n, ins = tt >= clipA && tt <= clipB; x.fillStyle = ins ? '#E8C468' : 'rgba(255,255,255,.22)'; x.fillRect(px + 0.6, (h - bh) / 2, w / n - 1.2, bh); } };
    let r = prep(g('plrClipOv')); if (r) { const [x, w, h] = r, X = (t) => t / d * w; bars(x, w, h, 0, d, Math.floor(w / 3)); x.fillStyle = 'rgba(232,196,104,.14)'; x.fillRect(X(clipA), 0, X(clipB) - X(clipA), h); x.strokeStyle = '#E8C468'; x.lineWidth = 1.5; x.strokeRect(X(clipA), 0.75, X(clipB) - X(clipA), h - 1.5); x.fillStyle = '#fff'; x.fillRect(X(A.currentTime) - 1, 0, 2, h); }
    r = prep(g('plrClipDt')); if (r) { const [x, w, h] = r, pad = Math.max(4, (clipB - clipA) * 0.18), t0 = Math.max(0, clipA - pad), t1 = Math.min(d, clipB + pad); cv0 = { t0, t1, w }; const X = (t) => (t - t0) / (t1 - t0) * w;
      bars(x, w, h - 16, t0, t1, Math.floor(w / 4)); x.fillStyle = 'rgba(0,0,0,.35)'; x.fillRect(0, 0, X(clipA), h - 16); x.fillRect(X(clipB), 0, w - X(clipB), h - 16);
      L.forEach((q) => { if (q.t < t0 || q.t > t1) return; x.fillStyle = 'rgba(127,224,181,.85)'; x.beginPath(); x.arc(X(q.t), h - 8, 2.6, 0, 6.3); x.fill(); });
      [[clipA, 1], [clipB, 0]].forEach(([tt]) => { const px = X(tt); x.fillStyle = '#E8C468'; x.fillRect(px - 1.5, 0, 3, h - 16); x.beginPath(); x.roundRect ? x.roundRect(px - 7, (h - 16) / 2 - 14, 14, 28, 6) : x.rect(px - 7, (h - 16) / 2 - 14, 14, 28); x.fill(); x.fillStyle = '#3a2a08'; for (let k = -1; k <= 1; k++) x.fillRect(px - 3, (h - 16) / 2 + k * 6 - 0.75, 6, 1.5); });
      if (A.currentTime >= t0 && A.currentTime <= t1) { x.fillStyle = '#fff'; x.fillRect(X(A.currentTime) - 1, 0, 2, h - 16); } }
  }
  let cv0 = null, cRaf = 0; const cLoop = () => { if (g('plrClipBox').hidden) return; cDraw(); cRaf = requestAnimationFrame(cLoop); };
  (function () {
    const ov = g('plrClipOv'), dt = g('plrClipDt'); let m = null;
    const tAt = (cv, e, t0, t1) => { const r = cv.getBoundingClientRect(), f = (e.clientX - r.left) / r.width; return t0 + f * (t1 - t0); };
    ov.addEventListener('pointerdown', (e) => { const d = A.duration || 0; if (!d) return; ov.setPointerCapture(e.pointerId); m = 'ov'; const len = clipB - clipA, c = tAt(ov, e, 0, d); cSet(c - len / 2, c + len / 2); });
    ov.addEventListener('pointermove', (e) => { if (m !== 'ov') return; const d = A.duration || 0, len = clipB - clipA, c = tAt(ov, e, 0, d); let a = Math.max(0, Math.min(d - len, c - len / 2)); cSet(a, a + len); });
    ov.addEventListener('pointerup', () => { if (m === 'ov') { const len = clipB - clipA; cFit(clipA, len); A.currentTime = clipA; } m = null; });
    let g0 = 0, a0 = 0, b0 = 0, T0 = null;
    dt.addEventListener('pointerdown', (e) => { if (!cv0) return; dt.setPointerCapture(e.pointerId); T0 = Object.assign({}, cv0); const t = tAt(dt, e, T0.t0, T0.t1), px = (q) => (q - T0.t0) / (T0.t1 - T0.t0) * T0.w, r = dt.getBoundingClientRect(), xp = (e.clientX - r.left) / r.width * T0.w;
      m = Math.abs(xp - px(clipA)) < 22 ? 'a' : Math.abs(xp - px(clipB)) < 22 ? 'b' : (t > clipA && t < clipB ? 'mv' : null); g0 = t; a0 = clipA; b0 = clipB; });
    dt.addEventListener('pointermove', (e) => { if (!m || !T0) return; const t = tAt(dt, e, T0.t0, T0.t1), tol = (T0.t1 - T0.t0) * 0.03;
      if (m === 'a') { const v = cSnap(t, 'a', tol); cSet(v, clipB, 'a'); A.currentTime = clipA; } else if (m === 'b') { const v = cSnap(t, 'b', tol); cSet(clipA, v); } else if (m === 'mv') { const dd = t - g0, d = A.duration || 0, len = b0 - a0; const a = Math.max(0, Math.min(d - len, a0 + dd)); cSet(a, a + len); } });
    const end = () => { if (m === 'mv') cFit(clipA, clipB - clipA); if (m === 'b') A.currentTime = Math.max(clipA, clipB - 2.5); m = null; T0 = null; clipUi(); };
    dt.addEventListener('pointerup', end); dt.addEventListener('pointercancel', end);
    const ln = g('plrClipLn'); [15, 30, 45, 60].forEach((s) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'btn small'; b.dataset.l = s; b.textContent = s + ' ث'; b.onclick = () => cFit(clipA, s); ln.appendChild(b); });
  })();
  function cSugUi() { const box = g('plrClipSug'); box.textContent = ''; cSuggest().forEach(([n, a, len]) => { const b = document.createElement('button'); b.type = 'button'; b.className = 'chip'; b.textContent = n; b.onclick = () => { cFit(a, len); A.currentTime = clipA; }; box.appendChild(b); }); }
  function clipReset() { const d = A.duration || 0; clipA = 0; clipB = Math.min(d || 30, 30); clipPrev = false; clipUi(); }
  g('plrClip').onclick = () => { const b = g('plrClipBox'); b.hidden = !b.hidden; if (!b.hidden) { const d = A.duration || 0; envLoad(tracks[cur], true); cSugUi(); cFit(Math.min(A.currentTime, Math.max(0, d - 5)), 30); cancelAnimationFrame(cRaf); cRaf = requestAnimationFrame(cLoop); setTimeout(cSugUi, 4000); } };
  g('plrPrevClip').onclick = () => { if (clipPrev) { A.pause(); clipPrev = false; g('plrPrevClip').textContent = '▶ معاينة'; return; } A.currentTime = clipA; clipPrev = true; g('plrPrevClip').textContent = '⏸ إيقاف'; A.play().catch(() => {}); };
  g('plrDesign').onclick = async () => {
    const t = tracks[cur]; if (!t || !window.__plrDesign) return; const btn = g('plrDesign'); btn.disabled = true; btn.textContent = 'جارٍ التجهيز...'; A.pause();
    try {
      const r = await fetch(t.audio); if (!r.ok) throw 0; const ab = await r.blob(), ext = (t.audio.split('?')[0].split('.').pop() || 'mp3').slice(0, 4);
      const af = new File([ab], (t.title || 'audio') + '.' + ext, { type: ab.type || 'audio/mpeg' }), cb = await coverBlob(t), cf = new File([cb], 'cover.jpg', { type: cb.type || 'image/jpeg' });
      tp(false); g('plrFull').hidden = true; root.hidden = true; await window.__plrDesign(af, cf, t, clipA, clipB);
    } catch (e) { toast('تعذّر تحميل الصوت للتصميم'); }
    btn.disabled = false; btn.textContent = 'التصميم على هذا المقطع';
  };

  /* التنقل */
  g('plrSearchB').onclick = () => { const s = g('plrSearch'); s.hidden = !s.hidden; if (!s.hidden) g('plrQ').focus(); else { q = ''; g('plrQ').value = ''; render(); } };
  g('plrQ').oninput = () => { q = g('plrQ').value; render(); };
  root.querySelectorAll('.plrnav button').forEach((b) => b.onclick = () => { plSel = null; b.classList.remove('newdot');
    if (b.dataset.t === 'smp') { root.querySelectorAll('.plrnav button').forEach((x) => x.classList.toggle('on', x === b)); smpOpen(); return; }
    if (b.dataset.t === 'studio') { root.hidden = true; const h = $('home'); if (h && h.hidden && !$('btnHome').hidden) { /* داخل المحرر */ } return; }
    tab = b.dataset.t; root.querySelectorAll('.plrnav button').forEach((x) => x.classList.toggle('on', x === b)); render();
  });
  document.addEventListener('click', (e) => { if (e.target && e.target.id === 'homeToPlr') open(); });
  function open() { root.hidden = false; if (!tracks.length) loadCatalog(); ui(); }
  /* شريط تحكم مخصص: السحب من المؤشر فقط (لا قفز عند النقر على الشريط) */
  function sld(o) {
    const w = el('div', 'sl' + (o.v ? ' v' : '')), tr = el('div', 'tr'), fl = el('i', 'fl'), th = el('b', 'th'); tr.appendChild(fl); w.append(tr, th);
    let val = o.value; const span = o.max - o.min, st0 = o.step || 0.1, mid = o.bi ? (0 - o.min) / span : 0;
    const paint = () => { const p = (val - o.min) / span, lo = Math.min(mid, p), hi = Math.max(mid, p); if (o.v) { th.style.bottom = (p * 100) + '%'; fl.style.bottom = (lo * 100) + '%'; fl.style.height = ((hi - lo) * 100) + '%'; } else { th.style.left = (p * 100) + '%'; fl.style.left = (lo * 100) + '%'; fl.style.width = ((hi - lo) * 100) + '%'; } };
    const setV = (v, fire) => { v = Math.max(o.min, Math.min(o.max, Math.round(v / st0) * st0)); v = +v.toFixed(3); if (v === val && !fire) return; val = v; paint(); o.onInput && o.onInput(val); };
    let a0 = 0, v0 = 0, drag = false, tap = 0;
    th.addEventListener('pointerdown', (e) => { e.preventDefault(); e.stopPropagation(); drag = true; a0 = o.v ? e.clientY : e.clientX; v0 = val; th.classList.add('on'); try { th.setPointerCapture(e.pointerId); } catch (x) {} const n = Date.now(); if (n - tap < 300 && o.def != null) { setV(o.def, true); drag = false; } tap = n; });
    th.addEventListener('pointermove', (e) => { if (!drag) return; const len = o.v ? tr.clientHeight : tr.clientWidth; if (!len) return; const d = o.v ? (a0 - e.clientY) : (e.clientX - a0); setV(v0 + d / len * span); });
    const end = () => { drag = false; th.classList.remove('on'); }; th.addEventListener('pointerup', end); th.addEventListener('pointercancel', end);
    w.set = (v) => { val = v; paint(); }; w.get = () => val; requestAnimationFrame(paint); paint(); return w;
  }
  const mount = (id, w) => { const h = g(id); h.textContent = ''; h.appendChild(w); return w; };
  /* ================= قسم الصوت: معادل 12 نطاقاً + مؤثرات حيّة ================= */
  const EQF = [30, 50, 90, 160, 300, 500, 1000, 1600, 3000, 5000, 9000, 16000];
  const fmtF = (f) => f >= 1000 ? (f / 1000) + 'k' : String(f);
  const Z12 = () => EQF.map(() => 0);
  const KN = { zb: 0, cp: 0, zm: 0, zt: 0, echo: 0, rev: 0, wid: 0, rot: 0, wah: 0 };
  const AUD = () => ({ pre: 'flat', pitch: 0, preamp: 0, lim: true, eq: Z12(), agc: false, bal: 0, fl: false, k: Object.assign({}, KN), on: { zb: false, cp: false, zm: false, zt: false, echo: false, rev: false, wid: false, rot: false, wah: false } });
  const PR = (eq, k, x) => Object.assign({ eq, k: k || {} }, x || {});
  const AUP = [
    ['flat', 'مسطّح (الأصلي)', PR(Z12())],
    ['vocal', 'وضوح صوت الرادود', PR([-3, -3, -2, -1, 0, 1, 2.5, 3.5, 4, 3, 1.5, 0], { cp: 35 })],
    ['bt', 'تعزيز الجهير والحدّة', PR([5, 4.5, 3.5, 2, 0, -1, -1, 0, 1.5, 3, 4, 4.5])],
    ['vb', 'الصوت والجهير', PR([4.5, 4, 3, 1, -0.5, 0, 1.5, 3, 3, 1.5, 0.5, 0])],
    ['hall', 'صدى القاعة', PR([1, 1, 0.5, 0, 0, 0, 0.5, 1, 1.5, 1.5, 1, 0.5], { rev: 45, cp: 25 })],
    ['live', 'أداء حي', PR([2.5, 2.5, 2, 1, 0, 0, 0.5, 1.5, 2, 2, 2, 1.5], { rev: 22, cp: 40, wid: 40 })],
    ['speech', 'وضوح الكلام', PR([-6, -5, -3, -1, 0, 1.5, 3, 4, 3.5, 2, 0, -2], { cp: 55 }, { agc: true })],
    ['deep', 'جهير عميق', PR([7, 6.5, 5, 3, 1, 0, 0, 0, 0, 0.5, 0.5, 0], { zb: 30 })],
    ['bright', 'حدّة عالية', PR([0, 0, 0, 0, 0, 0, 1, 2, 3.5, 5, 6, 6], { zt: 25 })],
    ['night', 'الاستماع الليلي', PR([-4, -3, -1.5, 0, 0.5, 1, 1, 0.5, 0, -1, -2.5, -4], { cp: 80 }, { agc: true })],
    ['radio', 'إذاعي', PR([-12, -9, -5, -1, 2, 4, 4, 3, 2, 0, -3, -6], { cp: 70 })],
    ['head', 'سماعات الرأس', PR([3, 2.5, 1.5, 0, -1, -1, 0, 1, 2, 2.5, 2, 1], { wid: 30 })],
    ['d8', 'صوت محيطي 8D', PR([1, 1, 0.5, 0, 0, 0, 0, 0.5, 1, 1, 1, 0.5], { rev: 15, wid: 35, rot: 30 })]
  ];
  const AUCK = 'minbar.au.custom'; const auCustom = () => jget(AUCK, []);
  (function () { const d = AUD(), s = st.au && st.au.eq && st.au.eq.length === 12 ? st.au : null; st.au = Object.assign(d, s || {}); st.au.k = Object.assign({}, KN, st.au.k || {}); st.au.on = Object.assign({}, d.on, st.au.on || {}); })();
  const AU = {};
  function auIR(sec) { const sr = ac.sampleRate, len = Math.floor(sr * sec), b = ac.createBuffer(2, len, sr); for (let c = 0; c < 2; c++) { const d = b.getChannelData(c); let lp = 0; for (let i = 0; i < len; i++) { const e = Math.pow(1 - i / len, 3); lp = lp * 0.55 + (Math.random() * 2 - 1) * 0.45; d[i] = lp * e * (i < sr * 0.012 ? i / (sr * 0.012) : 1); } } return b; }
  const PSW = `function makePV(sr, N, O) {
  const S = N / O, lat = N - S, half = N / 2, win = new Float32Array(N), re = new Float32Array(N), im = new Float32Array(N), aM = new Float32Array(half + 1), aF = new Float32Array(half + 1), sM = new Float32Array(half + 1), sF = new Float32Array(half + 1);
  for (let k = 0; k < N; k++) win[k] = 0.5 - 0.5 * Math.cos(2 * Math.PI * k / N);
  const lg = Math.log2(N), rev = new Uint32Array(N); for (let i = 0; i < N; i++) { let r = 0, x = i; for (let b = 0; b < lg; b++) { r = (r << 1) | (x & 1); x >>= 1; } rev[i] = r; }
  const cs = new Float32Array(half), sn = new Float32Array(half); for (let i = 0; i < half; i++) { cs[i] = Math.cos(2 * Math.PI * i / N); sn[i] = Math.sin(2 * Math.PI * i / N); }
  function fft(inv) {
    for (let i = 0; i < N; i++) { const j = rev[i]; if (j > i) { let t = re[i]; re[i] = re[j]; re[j] = t; t = im[i]; im[i] = im[j]; im[j] = t; } }
    for (let size = 2; size <= N; size <<= 1) { const h = size >> 1, st = N / size; for (let i = 0; i < N; i += size) for (let j = 0, k = 0; j < h; j++, k += st) { const wr = cs[k], wi = inv ? sn[k] : -sn[k], a = i + j, b = a + h, tr = re[b] * wr - im[b] * wi, ti = re[b] * wi + im[b] * wr; re[b] = re[a] - tr; im[b] = im[a] - ti; re[a] += tr; im[a] += ti; } }
  }
  const mk = () => ({ inF: new Float32Array(N), outF: new Float32Array(N), acc: new Float32Array(2 * N), lp: new Float32Array(half + 1), sp: new Float64Array(half + 1) });
  const chs = [mk(), mk()]; let rover = lat; const expct = 2 * Math.PI * S / N, fpb = sr / N, TP = 2 * Math.PI;
  function frame(c, r) {
    for (let k = 0; k < N; k++) { re[k] = c.inF[k] * win[k]; im[k] = 0; } fft(false);
    for (let k = 0; k <= half; k++) { const x = re[k], y = im[k], ph = Math.atan2(y, x); let t = ph - c.lp[k]; c.lp[k] = ph; t -= k * expct; let q = Math.trunc(t / Math.PI); q += q >= 0 ? (q & 1) : -(q & 1); t -= Math.PI * q; aM[k] = 2 * Math.sqrt(x * x + y * y); aF[k] = (k + O * t / TP) * fpb; }
    sM.fill(0); sF.fill(0); for (let k = 0; k <= half; k++) { const i = Math.round(k * r); if (i <= half) { sM[i] += aM[k]; sF[i] = aF[k] * r; } }
    for (let k = 0; k <= half; k++) { let t = sF[k] / fpb - k; t = TP * t / O + k * expct; c.sp[k] = (c.sp[k] + t) % TP; const ph = c.sp[k]; re[k] = sM[k] * Math.cos(ph); im[k] = sM[k] * Math.sin(ph); }
    for (let k = half + 1; k < N; k++) { re[k] = 0; im[k] = 0; } fft(true);
    const g = 2 / (half * O); for (let k = 0; k < N; k++) c.acc[k] += g * win[k] * re[k];
    for (let k = 0; k < S; k++) c.outF[k] = c.acc[k]; c.acc.copyWithin(0, S, 2 * N); c.acc.fill(0, 2 * N - S); c.inF.copyWithin(0, S, N);
  }
  return function process(ins, outs, n, r) {
    for (let s = 0; s < n; s++) { for (let ci = 0; ci < 2; ci++) { const c = chs[ci], src = ins[Math.min(ci, ins.length - 1)]; c.inF[rover] = src ? src[s] : 0; if (outs[ci]) outs[ci][s] = c.outF[rover - lat]; }
      rover++; if (rover >= N) { rover = lat; frame(chs[0], r); if (ins.length > 1 || outs.length > 1) frame(chs[1], r); else chs[1].outF.set(chs[0].outF); } }
  };
}

class PS extends AudioWorkletProcessor{static get parameterDescriptors(){return[{name:'ratio',defaultValue:1,minValue:0.25,maxValue:4}]}constructor(){super();this.P=makePV(sampleRate,2048,4)}process(I,O,P){const o=O[0];if(!o||!o[0])return true;this.P(I[0]||[],o,o[0].length,P.ratio[0]);return true}}registerProcessor('minbar-ps',PS);`;
  function auPitch(x) {
    AU.psIn = ac.createGain(); AU.psDry = ac.createGain(); AU.psWet = ac.createGain(); AU.psWet.gain.value = 0; AU.psOut = ac.createGain();
    x.connect(AU.psIn); AU.psIn.connect(AU.psDry); AU.psDry.connect(AU.psOut); AU.psWet.connect(AU.psOut);
    if (ac.audioWorklet) { const url = URL.createObjectURL(new Blob([PSW], { type: 'application/javascript' })); ac.audioWorklet.addModule(url).then(() => { AU.ps = new AudioWorkletNode(ac, 'minbar-ps', { outputChannelCount: [2] }); AU.ps.connect(AU.psWet); auApply(true); }).catch(() => {}); }
    return AU.psOut;
  }
  function auBuild(src) {
    const c = ac, N = (t) => c['create' + t](), bq = (type, f, q) => { const b = N('BiquadFilter'); b.type = type; b.frequency.value = f; if (q) b.Q.value = q; return b; }; let x = src;
    const chain = (n) => { x.connect(n); x = n; return n; };
    chain(bq('highpass', 22)); x = auPitch(x); AU.pre = chain(N('Gain'));
    AU.eq = EQF.map((f, i) => chain(bq(i === 0 ? 'lowshelf' : i === EQF.length - 1 ? 'highshelf' : 'peaking', f, 1.6)));
    AU.zb = chain(bq('lowshelf', 95)); AU.zm = chain(bq('peaking', 1200, 0.7)); AU.zt = chain(bq('highshelf', 7500));
    AU.cp = chain(N('DynamicsCompressor')); AU.cp.knee.value = 12; AU.cp.attack.value = 0.006; AU.cp.release.value = 0.2; AU.mk = chain(N('Gain'));
    AU.agc = chain(N('DynamicsCompressor')); AU.agc.knee.value = 20; AU.agc.attack.value = 0.25; AU.agc.release.value = 1; AU.agm = chain(N('Gain'));
    const pre = x; AU.sum = N('Gain'); AU.sum.channelCount = 2; AU.sum.channelCountMode = 'explicit'; AU.sum.channelInterpretation = 'speakers';
    AU.dry = N('Gain'); pre.connect(AU.dry); AU.dry.connect(AU.sum);
    AU.cv = N('Convolver'); AU.cv.buffer = auIR(2.4); AU.wet = N('Gain'); AU.cv.connect(AU.wet); AU.agm2 = pre; AU.wet.connect(AU.sum);
    AU.ed = c.createDelay(1); AU.ed.delayTime.value = 0.33; AU.efb = N('Gain'); AU.ew = N('Gain'); AU.ed.connect(AU.efb); AU.efb.connect(AU.ed); AU.ed.connect(AU.ew); AU.ew.connect(AU.sum); x = AU.sum;
    AU.fd = c.createDelay(0.05); AU.fd.delayTime.value = 0.004; AU.fo = N('Oscillator'); AU.fo.frequency.value = 0.22; AU.fod = N('Gain'); AU.fod.gain.value = 0.0028; AU.fo.connect(AU.fod); AU.fod.connect(AU.fd.delayTime); AU.fo.start();
    AU.ffb = N('Gain'); AU.fw = N('Gain'); AU.fsum = N('Gain'); x.connect(AU.fsum); AU.fsrc = x; AU.fd.connect(AU.ffb); AU.ffb.connect(AU.fd); AU.fd.connect(AU.fw); AU.fw.connect(AU.fsum); x = AU.fsum;
    AU.wf = bq('bandpass', 900, 3.5); AU.wo = N('Oscillator'); AU.wo.frequency.value = 1.6; AU.wod = N('Gain'); AU.wod.gain.value = 650; AU.wo.connect(AU.wod); AU.wod.connect(AU.wf.frequency); AU.wo.start(); AU.ww = N('Gain'); AU.ww.gain.value = 0; AU.wsum = N('Gain'); x.connect(AU.wsum); x.connect(AU.wf); AU.wf.connect(AU.ww); AU.ww.connect(AU.wsum); x = AU.wsum;
    const sp = c.createChannelSplitter(2), mg = c.createChannelMerger(2); AU.ll = N('Gain'); AU.lr = N('Gain'); AU.rr = N('Gain'); AU.rl = N('Gain');
    x.connect(sp); sp.connect(AU.ll, 0); sp.connect(AU.lr, 0); sp.connect(AU.rr, 1); sp.connect(AU.rl, 1); AU.ll.connect(mg, 0, 0); AU.rl.connect(mg, 0, 0); AU.rr.connect(mg, 0, 1); AU.lr.connect(mg, 0, 1); x = mg;
    AU.pan = c.createStereoPanner ? c.createStereoPanner() : N('Gain'); chain(AU.pan);
    if (AU.pan.pan) { AU.lfo = N('Oscillator'); AU.lfo.type = 'sine'; AU.lfd = N('Gain'); AU.lfd.gain.value = 0; AU.lfo.connect(AU.lfd); AU.lfd.connect(AU.pan.pan); AU.lfo.start(); }
    AU.master = chain(N('Gain')); AU.fade = chain(N('Gain')); AU.lim = chain(N('DynamicsCompressor')); AU.lim.knee.value = 0; AU.lim.attack.value = 0.002; AU.lim.release.value = 0.12; AU.lim.connect(an);
    auApply(true);
  }
  function auApply(now) {
    if (!AU.eq) return; const s = st.au, T = ac.currentTime, k = now ? 0.001 : 0.04, set = (prm, v) => { try { prm.setTargetAtTime(v, T, k); } catch (e) { prm.value = v; } };
    const kv = (n) => s.on[n] ? s.k[n] / 100 : 0;
    set(AU.pre.gain, Math.pow(10, s.preamp / 20)); const sg = eqSolve(s.eq); AU.eq.forEach((b, i) => set(b.gain, sg[i] || 0));
    set(AU.zb.gain, kv('zb') * 10); set(AU.zm.gain, kv('zm') * 8); set(AU.zt.gain, kv('zt') * 9);
    const cp = kv('cp'); set(AU.cp.threshold, -cp * 32); set(AU.cp.ratio, 1 + cp * 8); set(AU.mk.gain, Math.pow(10, cp * 8 / 20));
    set(AU.agc.threshold, s.agc ? -32 : 0); set(AU.agc.ratio, s.agc ? 4 : 1); set(AU.agm.gain, s.agc ? Math.pow(10, 9 / 20) : 1);
    const rv = kv('rev'), ec = kv('echo'); set(AU.wet.gain, rv * 0.9); set(AU.dry.gain, 1 - rv * 0.3); set(AU.efb.gain, ec * 0.55); set(AU.ew.gain, ec * 0.6);
    set(AU.ffb.gain, s.fl ? 0.55 : 0); set(AU.fw.gain, s.fl ? 0.7 : 0); if (AU.ww) set(AU.ww.gain, kv('wah') * 1.6);
    const w = 1 + kv('wid'); set(AU.ll.gain, 0.5 + 0.5 * w); set(AU.rr.gain, 0.5 + 0.5 * w); set(AU.lr.gain, 0.5 - 0.5 * w); set(AU.rl.gain, 0.5 - 0.5 * w);
    if (AU.pan.pan) { set(AU.pan.pan, s.bal); if (AU.lfo) { const r = kv('rot'); AU.lfo.frequency.value = 0.03 + r * 0.35; set(AU.lfd.gain, r > 0 ? Math.min(0.9, 1 - Math.abs(s.bal)) : 0); } }
    set(AU.master.gain, 1); const ps = s.pitch || 0, on = !!AU.ps && Math.abs(ps) > 0.04;
    const lk = (key, v, a, b) => { AU.L = AU.L || {}; if (!!AU.L[key] === v || !a || !b) return; try { v ? a.connect(b) : a.disconnect(b); } catch (e) {} AU.L[key] = v; };
    lk('cv', rv > 0, AU.agm2, AU.cv); lk('ed', ec > 0, AU.agm2, AU.ed); lk('fd', !!s.fl, AU.fsrc, AU.fd); lk('ps', on, AU.psIn, AU.ps); set(AU.psDry.gain, on ? 0 : 1); set(AU.psWet.gain, on ? 1 : 0); if (AU.ps) AU.ps.parameters.get('ratio').setValueAtTime(Math.pow(2, ps / 12), T); set(AU.lim.threshold, s.lim ? -1 : 0); set(AU.lim.ratio, s.lim ? 20 : 1);
  }
  const au = (on) => { g('plrAu').hidden = !on; g('plrBg').hidden = !on; g('plrAuPL').hidden = true; if (on) { auUi(); eqStart(); } };
  g('plrAuX').onclick = () => au(false); g('plrAuR').onclick = () => {
    const s = st.au, k = g('plrAuT').querySelector('.on').dataset.k, d = AUD();
    if (k === 'b') { s.eq = Z12(); s.preamp = 0; s.lim = true; }
    else if (k === 'f') { s.agc = false; s.bal = 0; ['zb', 'cp', 'zm', 'zt'].forEach((n) => { s.k[n] = 0; s.on[n] = false; }); }
    else { s.pitch = 0; s.fl = false; st.speed = 1; A.playbackRate = 1; pills(); ['echo', 'rev', 'wid', 'rot', 'wah'].forEach((n) => { s.k[n] = 0; s.on[n] = false; }); }
    void d; s.pre = JSON.stringify(s.eq) === JSON.stringify(Z12()) && !Object.values(s.on).some(Boolean) && !s.agc && !s.bal && !s.preamp && !s.pitch && !s.fl ? 'flat' : 'custom'; save(); auApply(); auUi(); toast('أُعيد ضبط قسم «' + g('plrAuT').querySelector('.on').textContent + '»');
  };
  function auNote() { const n = g('plrAuN'); if (!n) return; if (st.fx !== true) { n.textContent = 'وضع الأداء مفعّل: الرسم يعمل لكن المؤثرات الصوتية متوقفة. لتفعيلها: الأدوات ← وضع الأداء.'; n.hidden = !tracks[cur]; return; } n.textContent = 'المعالجة متاحة للملفات المرفوعة على منبر فقط.'; n.hidden = !!useLive || !tracks[cur]; }
  function auFrom(p, k) { const d = AUD(); d.eq = p.eq.slice(); Object.keys(p.k || {}).forEach((n) => { d.k[n] = p.k[n]; d.on[n] = true; }); if (p.agc) d.agc = true; if (p.preamp) d.preamp = p.preamp; if (p.fl) d.fl = true; d.pre = k; return d; }
  function auPreset(k) { const b = AUP.find((x) => x[0] === k), c = auCustom().find((x) => x.id === k); if (b) st.au = auFrom(b[2], k); else if (c) { st.au = Object.assign(AUD(), JSON.parse(JSON.stringify(c.s))); st.au.pre = k; } else return; save(); auApply(); auUi(); }
  const auName = () => { const b = AUP.find((x) => x[0] === st.au.pre), c = auCustom().find((x) => x.id === st.au.pre); return b ? b[1] : c ? c.n : 'مخصّص'; };
  const auMod = (soft) => { if (st.au.pre !== 'custom') { st.au.pre = 'custom'; g('plrAuPB').firstChild.textContent = auName(); } save(); auApply(); if (!soft) auUi(); };
  g('plrAuT').querySelectorAll('button').forEach((b) => b.onclick = () => { g('plrAuT').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x === b)); ['b', 'f', 'a'].forEach((k) => { g('au' + k.toUpperCase()).hidden = k !== b.dataset.k; }); if (b.dataset.k === 'b') eqStart(); });
  /* قائمة الإعدادات المسبقة */
  function auList() {
    const L = g('plrAuPLL'); L.textContent = ''; const add = (id, n, del) => { const r = el('button', 'aupi' + (st.au.pre === id ? ' on' : '')); r.type = 'button'; r.append(el('i'), el('span', '', n)); r.onclick = () => { auPreset(id); g('plrAuPL').hidden = true; }; if (del) { const x = el('b', 'x', '×'); x.onclick = (e) => { e.stopPropagation(); jset(AUCK, auCustom().filter((c) => c.id !== id)); auList(); }; r.appendChild(x); } L.appendChild(r); };
    AUP.forEach(([k, n]) => add(k, n)); const cs = auCustom(); if (cs.length) { L.appendChild(el('div', 'auplh', 'إعداداتي')); cs.forEach((c) => add(c.id, c.n, true)); }
  }
  g('plrAuPB').onclick = () => { auList(); g('plrAuPL').hidden = false; }; g('plrAuPLX').onclick = () => { g('plrAuPL').hidden = true; };
  g('plrAuSv').onclick = () => { auList(); g('plrAuPL').hidden = false; setTimeout(() => g('plrAuSN').focus(), 50); };
  g('plrAuSB').onclick = () => { const n = g('plrAuSN').value.trim(); if (!n) return toast('اكتب اسماً للإعداد'); const id = 'c' + Date.now(), s = JSON.parse(JSON.stringify(st.au)); const cs = auCustom(); cs.push({ id, n, s }); jset(AUCK, cs.slice(-20)); st.au.pre = id; save(); g('plrAuSN').value = ''; auList(); auUi(); toast('حُفظ الإعداد'); };
  /* مقبض دائري */
  function knob(box, key, name) {
    const s = st.au, w = el('div', 'kn' + (s.on[key] ? ' on' : '')), sv = document.createElementNS('http://www.w3.org/2000/svg', 'svg'); sv.setAttribute('viewBox', '0 0 100 100');
    const arc = (v) => { const a0 = 135, a1 = 135 + 270 * v, r = 40, P = (a) => [50 + r * Math.cos(a * Math.PI / 180), 50 + r * Math.sin(a * Math.PI / 180)]; const [x0, y0] = P(a0), [x1, y1] = P(a1); return `M${x0} ${y0} A${r} ${r} 0 ${a1 - a0 > 180 ? 1 : 0} 1 ${x1} ${y1}`; };
    sv.innerHTML = `<path d="${arc(1)}" class="kt"/><path class="kv"/><circle class="kh" r="6.5"/><text x="50" y="57" text-anchor="middle"></text>`;
    const pv = sv.querySelector('.kv'), kh = sv.querySelector('.kh'), tx = sv.querySelector('text'), paint = () => { const v = s.k[key] / 100, a = (135 + 270 * v) * Math.PI / 180; pv.setAttribute('d', v > 0.001 ? arc(v) : ''); kh.setAttribute('cx', 50 + 40 * Math.cos(a)); kh.setAttribute('cy', 50 + 40 * Math.sin(a)); tx.textContent = Math.round(s.k[key]); };
    paint(); let drag = false, la = 0, acc = 0;
    const ang = (e) => { const r = sv.getBoundingClientRect(); return Math.atan2(e.clientY - (r.top + r.height / 2), e.clientX - (r.left + r.width / 2)) * 180 / Math.PI; };
    sv.addEventListener('pointerdown', (e) => { const r = sv.getBoundingClientRect(), dx = e.clientX - (r.left + r.width / 2), dy = e.clientY - (r.top + r.height / 2), d = Math.hypot(dx, dy) / (r.width / 2); if (d < 0.45) return; drag = true; la = ang(e); acc = s.k[key]; try { sv.setPointerCapture(e.pointerId); } catch (x) {} e.preventDefault(); });
    sv.addEventListener('pointermove', (e) => { if (!drag) return; const a = ang(e); let da = a - la; if (da > 180) da -= 360; if (da < -180) da += 360; la = a; acc = Math.max(0, Math.min(100, acc + da / 270 * 100)); const v = Math.round(acc); if (v !== s.k[key]) { s.k[key] = v; if (!s.on[key] && v > 0) { s.on[key] = true; w.classList.add('on'); w.querySelector('.pw').classList.add('on'); } paint(); auMod(true); } });
    ['pointerup', 'pointercancel'].forEach((n) => sv.addEventListener(n, () => { drag = false; }));
    const p = el('button', 'pw' + (s.on[key] ? ' on' : '')); p.type = 'button'; p.innerHTML = ic('power', 14) + `<span>${name}</span>`; p.onclick = () => { s.on[key] = !s.on[key]; w.classList.toggle('on', s.on[key]); p.classList.toggle('on', s.on[key]); auMod(true); };
    w.append(sv, p); box.appendChild(w);
  }
  const pwSet = (id, on) => g(id).classList.toggle('on', !!on);
  function auUi() {
    const s = st.au; auNote(); g('plrAuPB').firstChild.textContent = auName();
    const pv = (v) => { g('auPreV').textContent = (v > 0 ? '+' : '') + (+v).toFixed(1) + ' dB'; }; pv(s.preamp); mount('auPre', sld({ min: -12, max: 12, step: 0.1, value: s.preamp, bi: true, def: 0, onInput: (v) => { s.preamp = v; pv(v); auMod(true); } }));
    pwSet('auLim', s.lim); g('auLim').onclick = () => { s.lim = !s.lim; pwSet('auLim', s.lim); auMod(true); };
    pwSet('auAgc', s.agc); g('auAgc').onclick = () => { s.agc = !s.agc; pwSet('auAgc', s.agc); auMod(true); };
    pwSet('auFl', s.fl); g('auFl').onclick = () => { s.fl = !s.fl; pwSet('auFl', s.fl); auMod(true); };
    const bv = () => { g('auBalV').textContent = Math.abs(s.bal) < 0.005 ? 'الوسط' : (s.bal < 0 ? 'يسار ' : 'يمين ') + Math.round(Math.abs(s.bal) * 100) + '%'; }; bv(); mount('auBal', sld({ min: -1, max: 1, step: 0.01, value: s.bal, bi: true, def: 0, onInput: (v) => { s.bal = v; bv(); auMod(true); } }));
    const piv = () => { g('auPiV').textContent = (s.pitch > 0 ? '+' : '') + (+s.pitch || 0).toFixed(1); }; piv(); mount('auPi', sld({ min: -12, max: 12, step: 0.1, value: s.pitch || 0, bi: true, def: 0, onInput: (v) => { s.pitch = v; piv(); auMod(true); } }));
    const sv2 = () => { g('auSpV').textContent = '×' + (+st.speed).toFixed(2); }; sv2(); mount('auSp', sld({ min: 0.5, max: 2, step: 0.05, value: st.speed, def: 1, onInput: (v) => { st.speed = v; A.playbackRate = v; sv2(); save(); pills(); } }));
    const B = g('auBands'); B.textContent = ''; AU.bandS = [];
    EQF.forEach((f, i) => { const c = el('div', 'bnd'), v = el('b', ''), lb = el('span', '', fmtF(f)); const sh = () => { v.textContent = (s.eq[i] > 0 ? '+' : '') + (+s.eq[i]).toFixed(1); }; sh();
      const w = sld({ v: true, min: -12, max: 12, step: 0.1, value: s.eq[i], bi: true, def: 0, onInput: (x) => { s.eq[i] = x; sh(); auMod(true); } }); w.sh = sh; AU.bandS[i] = w; c.append(v, w, lb); B.appendChild(c); });
    const KF = g('auKF'); KF.textContent = ''; [['zb', 'تعزيز الجهير'], ['cp', 'الضاغط'], ['zm', 'تعزيز الوسط'], ['zt', 'تعزيز الحدّة']].forEach(([k, n]) => knob(KF, k, n));
    const KA = g('auKA'); KA.textContent = ''; [['echo', 'الصدى'], ['rev', 'الترديد'], ['wid', 'اتساع المجال'], ['rot', 'الدوران 8D'], ['wah', 'الواوا (AutoWah)']].forEach(([k, n]) => knob(KA, k, n));
  }
  /* استجابة المرشحات حسابياً (نفس معادلات Web Audio) + تصحيح الكسب حتى يمرّ المنحنى بالنقاط */
  const EQQ = 1.6, FS = 48000;
  function bqDb(type, f0, g, f, fs) {
    const A = Math.pow(10, g / 40), w0 = 2 * Math.PI * f0 / fs, cs = Math.cos(w0), sn = Math.sin(w0); let b0, b1, b2, a0, a1, a2;
    if (type === 'peaking') { const al = sn / (2 * EQQ); b0 = 1 + al * A; b1 = -2 * cs; b2 = 1 - al * A; a0 = 1 + al / A; a1 = -2 * cs; a2 = 1 - al / A; }
    else { const al = sn / 2 * Math.SQRT2, sA = 2 * Math.sqrt(A) * al;
      if (type === 'lowshelf') { b0 = A * ((A + 1) - (A - 1) * cs + sA); b1 = 2 * A * ((A - 1) - (A + 1) * cs); b2 = A * ((A + 1) - (A - 1) * cs - sA); a0 = (A + 1) + (A - 1) * cs + sA; a1 = -2 * ((A - 1) + (A + 1) * cs); a2 = (A + 1) + (A - 1) * cs - sA; }
      else { b0 = A * ((A + 1) + (A - 1) * cs + sA); b1 = -2 * A * ((A - 1) + (A + 1) * cs); b2 = A * ((A + 1) + (A - 1) * cs - sA); a0 = (A + 1) - (A - 1) * cs + sA; a1 = 2 * ((A - 1) - (A + 1) * cs); a2 = (A + 1) - (A - 1) * cs - sA; } }
    const w = 2 * Math.PI * f / fs, c1 = Math.cos(w), s1 = Math.sin(w), c2 = Math.cos(2 * w), s2 = Math.sin(2 * w);
    const nr = b0 + b1 * c1 + b2 * c2, ni = -(b1 * s1 + b2 * s2), dr = a0 + a1 * c1 + a2 * c2, di = -(a1 * s1 + a2 * s2);
    return 10 * Math.log10((nr * nr + ni * ni) / (dr * dr + di * di));
  }
  const btype = (i) => i === 0 ? 'lowshelf' : i === EQF.length - 1 ? 'highshelf' : 'peaking';
  const eqResp = (gs, f, fs) => { let d = 0; for (let j = 0; j < EQF.length; j++) if (gs[j]) d += bqDb(btype(j), EQF[j], gs[j], f, fs); return d; };
  let solK = '', solV = null;
  function eqSolve(target) {
    const key = target.join(','); if (key === solK) return solV; const fs = ac ? ac.sampleRate : FS, g2 = target.slice();
    for (let it = 0; it < 12; it++) { let err = 0; const act = EQF.map((f) => eqResp(g2, f, fs)); for (let i = 0; i < EQF.length; i++) { const e = target[i] - act[i]; err += Math.abs(e); g2[i] = Math.max(-24, Math.min(24, g2[i] + 0.75 * e)); } if (err < 0.05) break; }
    solK = key; solV = g2; return g2;
  }
  /* المخطط */
  let eqOn = false, eqDrag = -1, eqY0 = 0, eqV0 = 0;
  const FR = (() => { const n = 240, a = new Float32Array(n); for (let i = 0; i < n; i++) a[i] = 20 * Math.pow(20000 / 20, i / (n - 1)); return a; })();
  const PADL = 30, PADB = 16, TOP = 10, DB = 15;
  const fx2 = (f, w) => PADL + Math.log(f / 20) / Math.log(1000) * (w - PADL - 8), dbY = (d, h) => TOP + (DB - d) / (2 * DB) * (h - TOP - PADB);
  function eqDraw() {
    const cv = g('plrEq'); if (g('plrAu').hidden || g('auB').hidden) { eqOn = false; return; } const dpr = Math.min(window.devicePixelRatio || 1, 2), w = cv.clientWidth, h = cv.clientHeight; if (!w) { requestAnimationFrame(eqDraw); return; }
    if (cv.width !== Math.round(w * dpr)) { cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr); } const x = cv.getContext('2d'); x.setTransform(dpr, 0, 0, dpr, 0, 0); x.clearRect(0, 0, w, h);
    x.lineWidth = 1; for (let d = -12; d <= 12; d += 3) { x.strokeStyle = d === 0 ? 'rgba(255,255,255,.24)' : d % 6 ? 'rgba(255,255,255,.04)' : 'rgba(255,255,255,.09)'; x.beginPath(); x.moveTo(PADL, Math.round(dbY(d, h)) + 0.5); x.lineTo(w - 8, Math.round(dbY(d, h)) + 0.5); x.stroke(); }
    EQF.forEach((f) => { x.strokeStyle = 'rgba(255,255,255,.07)'; const xx = Math.round(fx2(f, w)) + 0.5; x.beginPath(); x.moveTo(xx, TOP); x.lineTo(xx, h - PADB); x.stroke(); });
    x.fillStyle = 'rgba(255,255,255,.45)'; x.font = '9px Cairo,sans-serif'; x.textAlign = 'right'; x.textBaseline = 'middle'; [12, 6, 0, -6, -12].forEach((d) => x.fillText((d > 0 ? '+' : '') + d, PADL - 5, dbY(d, h)));
    x.textAlign = 'center'; x.textBaseline = 'alphabetic'; EQF.forEach((f, i) => { if (i % 2 === 0 || i === EQF.length - 1) x.fillText(fmtF(f), fx2(f, w), h - 4); });
    if (an && fbuf && useLive) { an.getByteFrequencyData(fbuf); const ny = ac.sampleRate / 2; x.beginPath(); x.moveTo(PADL, h - PADB); for (let i = 0; i < FR.length; i++) { const bi = Math.min(fbuf.length - 1, Math.round(FR[i] / ny * fbuf.length)); x.lineTo(fx2(FR[i], w), (h - PADB) - fbuf[bi] / 255 * (h - PADB - TOP) * 0.9); } x.lineTo(w - 8, h - PADB); x.closePath(); const gr = x.createLinearGradient(0, TOP, 0, h); gr.addColorStop(0, 'rgba(127,224,181,.2)'); gr.addColorStop(1, 'rgba(127,224,181,0)'); x.fillStyle = gr; x.fill(); }
    else if (live && live.pre && !A.paused) { x.beginPath(); x.moveTo(PADL, h - PADB); for (let i = 0; i < FR.length; i++) { const bn = Math.max(0, Math.min(21, Math.round(Math.log(FR[i] / 40) / Math.log(400) * 22))); x.lineTo(fx2(FR[i], w), (h - PADB) - (live.vals[bn] || 0) * (h - PADB - TOP) * 0.9); } x.lineTo(w - 8, h - PADB); x.closePath(); const gr = x.createLinearGradient(0, TOP, 0, h); gr.addColorStop(0, 'rgba(127,224,181,.2)'); gr.addColorStop(1, 'rgba(127,224,181,0)'); x.fillStyle = gr; x.fill(); }
    const gs = eqSolve(st.au.eq), fs = ac ? ac.sampleRate : FS, pa = st.au.preamp;
    x.save(); x.beginPath(); x.rect(PADL, 0, w - PADL - 8, h - PADB); x.clip(); x.beginPath();
    for (let i = 0; i < FR.length; i++) { const yy = dbY(eqResp(gs, FR[i], fs) + pa, h), xx = fx2(FR[i], w); i ? x.lineTo(xx, yy) : x.moveTo(xx, yy); }
    x.strokeStyle = '#E8C468'; x.lineWidth = 2; x.lineJoin = 'round'; x.stroke(); x.lineTo(w - 8, dbY(0, h)); x.lineTo(PADL, dbY(0, h)); x.closePath(); x.fillStyle = 'rgba(232,196,104,.08)'; x.fill(); x.restore();
    EQF.forEach((f, i) => { const xx = fx2(f, w), yy = dbY(st.au.eq[i] + pa, h), a = eqDrag === i; x.beginPath(); x.arc(xx, yy, a ? 7 : 4.5, 0, 7); x.fillStyle = a ? '#fff' : '#E8C468'; x.fill(); x.lineWidth = 1.5; x.strokeStyle = '#0a2019'; x.stroke();
      if (a) { const t = fmtF(f) + 'Hz  ' + (st.au.eq[i] > 0 ? '+' : '') + st.au.eq[i].toFixed(1) + 'dB'; x.font = '700 10px Cairo,sans-serif'; const tw = x.measureText(t).width + 12, bx = Math.max(PADL, Math.min(w - tw - 8, xx - tw / 2)), by = yy < 34 ? yy + 12 : yy - 28; x.fillStyle = 'rgba(0,0,0,.78)'; x.beginPath(); x.roundRect ? x.roundRect(bx, by, tw, 17, 6) : x.rect(bx, by, tw, 17); x.fill(); x.fillStyle = '#fff'; x.textAlign = 'center'; x.fillText(t, bx + tw / 2, by + 12); } });
    requestAnimationFrame(eqDraw);
  }
  function eqStart() { if (!eqOn) { eqOn = true; requestAnimationFrame(eqDraw); } }
  (function () {
    const cv = g('plrEq');
    cv.addEventListener('pointerdown', (e) => { const r = cv.getBoundingClientRect(), px = e.clientX - r.left, py = e.clientY - r.top; let bi = -1, bd = 22 * 22; EQF.forEach((f, i) => { const dx = fx2(f, r.width) - px, dy = dbY(st.au.eq[i] + st.au.preamp, r.height) - py, d = dx * dx + dy * dy; if (d < bd) { bd = d; bi = i; } }); if (bi < 0) return; eqDrag = bi; eqY0 = e.clientY; eqV0 = st.au.eq[bi]; try { cv.setPointerCapture(e.pointerId); } catch (x) {} e.preventDefault(); });
    cv.addEventListener('pointermove', (e) => { if (eqDrag < 0) return; const r = cv.getBoundingClientRect(), pxPerDb = (r.height - TOP - PADB) / (2 * DB); let d = eqV0 + (eqY0 - e.clientY) / pxPerDb; d = Math.max(-12, Math.min(12, Math.round(d * 10) / 10)); if (d !== st.au.eq[eqDrag]) { st.au.eq[eqDrag] = d; const s2 = AU.bandS && AU.bandS[eqDrag]; if (s2) { s2.set(d); s2.sh(); } auMod(true); } });
    const up = () => { eqDrag = -1; }; cv.addEventListener('pointerup', up); cv.addEventListener('pointercancel', up);
  })();
  /* ================= التعليقات العائمة ================= */
  st.cm = Object.assign({ on: true, dens: 2, mode: 'mix', view: 'side' }, st.cm || {}); if (!st.cm.v2) { st.cm.view = 'side'; st.cm.v2 = 1; }
  const CML = 'minbar.cm.local'; let cmList = [], cmPtr = 0, cmLast = -1, cmTrack = null, cmLane = [0, 0, 0, 0, 0], cmTime = null, cmSent = 0;
  const cmS = (on) => { g('plrCm').hidden = !on; g('plrBg').hidden = !on; if (on) cmUi(); };
  g('plrCmB').onclick = () => cmS(g('plrCm').hidden); g('plrCmX').onclick = () => cmS(false);
  const cmBad = (s) => /(https?:|www\.|\.com|\.net|t\.me|@\w)/i.test(s) || /(.)\1{6,}/.test(s);
  /* التفاعلات العائمة عبر المقطع (❤️ 😢 🤲 💔): تُحفظ بلحظتها وتطفو للجميع أثناء التشغيل */
  const RXE = ['❤️'], RXL = 'minbar.rx.local'; let rxList = [], rxPtr = 0, rxLast = 0, rxTrack = null, rxSentAt = {};
  function rxUi() { try { heatUi(); } catch (e) {} const b = g('plrRx'); b.textContent = ''; b.hidden = !st.cm.on; const cnt = {}; rxList.forEach((r) => { cnt[r.e] = (cnt[r.e] || 0) + 1; });
    const e = '❤️', n = rxList.length; const k = el('button', 'rxb rxh'); k.type = 'button'; k.dataset.e = e; k.setAttribute('aria-label', 'إعجاب'); k.innerHTML = '<span><svg viewBox="0 0 24 24" width="24" height="24"><path d="M12 21s-7.5-4.6-9.6-9.2C1 8.6 3 5 6.5 5c2 0 3.6 1.2 4.5 2.6.3.4.7.4 1 0C12.9 6.2 14.5 5 16.5 5 20 5 22 8.6 20.6 11.8 18.5 16.4 12 21 12 21z" fill="currentColor"/></svg></span><small></small>'; k.lastChild.textContent = n ? (n > 999 ? (n / 1000).toFixed(1) + 'k' : n) : ''; k.onclick = () => rxSend(e, k); b.appendChild(k); g('plrFav').dataset.n = n ? (n > 999 ? (n / 1000).toFixed(1) + 'k' : n) : ''; }
  function rxFloat(e, own) { const b = g('plrRx'); if (b.hidden) return; const k = b.querySelector(`[data-e="${e}"]`) || b.firstChild; if (!k) return; const L = el('span', 'rxf' + (own ? ' me' : ''), '❤'); L.style.color = own ? '' : `hsl(${340 + Math.random() * 30},85%,${58 + Math.random() * 12}%)`; const n = own ? 1 : 1; L.style.top = k.offsetTop + 'px'; b.appendChild(L);
    const dx = (Math.random() * 40 - 30), H = Math.min(260, (b.offsetTop || 300) * 0.8), s = 0.8 + Math.random() * 0.5 + (own ? 0.3 : 0);
    const a = L.animate([{ transform: 'translate(0,0) scale(.4)', opacity: 0 }, { transform: `translate(${dx * 0.3}px,-30px) scale(${s})`, opacity: 1, offset: 0.15 }, { transform: `translate(${dx}px,${-H}px) scale(${s * 0.9})`, opacity: 0 }], { duration: 2600 + Math.random() * 900, easing: 'cubic-bezier(.2,.6,.4,1)' }); a.onfinish = () => L.remove(); }
  async function rxLoad(t) { rxTrack = t; rxList = (jget(RXL, {})[t.id] || []).slice(); rxPtr = 0; rxUi(); const db = fdb(); if (!db) return;
    if (rxUn) { try { rxUn(); } catch (e) {} rxUn = null; } let first = true; const me = fuid();
    try { rxUn = db.collection('rx').where('track', '==', t.id).onSnapshot((q) => { if (rxTrack !== t) return;
        if (first) { first = false; const arr = []; q.forEach((d) => { const x = d.data(); if (x && typeof x.t === 'number') arr.push({ t: x.t, e: '❤️', id: d.id }); }); rxList = arr.concat((jget(RXL, {})[t.id] || []).map((x) => ({ t: x.t, e: '❤️' }))).sort((a, b) => a.t - b.t); rxReset(); rxUi(); return; }
        let live = 0; q.docChanges().forEach((c) => { if (c.type !== 'added' || c.doc.metadata.hasPendingWrites) return; const x = c.doc.data(); if (!x || typeof x.t !== 'number' || (me && x.uid === me)) return; if (rxList.some((r) => r.id === c.doc.id)) return; rxList.push({ t: x.t, e: '❤️', id: c.doc.id }); live++; });
        if (live) { for (let i = 0; i < Math.min(live * 2, 6); i++) setTimeout(() => rxFloat('❤️'), i * 140); rxReset(); rxUi(); } }, () => {}); } catch (e) {} }
  let rxUn = null, rxIgnore = false;
  A.addEventListener('loadedmetadata', () => setTimeout(heatUi, 50));
  function rxReset() { rxList.sort((a, b) => a.t - b.t); const now = A.currentTime || 0; rxPtr = 0; while (rxPtr < rxList.length && rxList[rxPtr].t < now) rxPtr++; rxLast = now; }
  let rxBurst = 0;
  function rxTick() { if (!st.cm.on || !rxList.length || A.paused) return; const now = A.currentTime || 0; if (Math.abs(now - rxLast) > 1.5) rxReset(); rxLast = now; const pn = performance.now();
    while (rxPtr < rxList.length && rxList[rxPtr].t <= now) { if (pn - rxBurst > 140) { rxFloat(rxList[rxPtr].e); rxBurst = pn; } rxPtr++; } }
  async function rxSend(e, k) { const t = tracks[cur]; if (!t) return; for (let i = 0; i < 3; i++) setTimeout(() => rxFloat(e, true), i * 120); k.classList.remove('pop'); void k.offsetWidth; k.classList.add('pop'); try { navigator.vibrate && navigator.vibrate(8); } catch (x) {}
    const now = Date.now(); if (now - (rxSentAt[e] || 0) < 250) return; if (!fuid() && !rxSentAt.warn) { rxSentAt.warn = 1; toast('سجّل الدخول ليظهر إعجابك للآخرين'); } rxSentAt[e] = now; const r = { t: r2(A.currentTime || 0), e }; rxList.push(r); rxReset(); rxPtr = Math.max(rxPtr, rxList.indexOf(r) + 1);
    const db = fdb(), u = window.firebase && firebase.auth ? firebase.auth().currentUser : null; let ok = false;
    if (db && u) { try { rxIgnore = true; await db.collection('rx').add({ track: t.id, t: r.t, e, uid: u.uid, at: firebase.firestore.FieldValue.serverTimestamp() }); ok = true; } catch (x) {} }
    if (!ok) { const all = jget(RXL, {}); (all[t.id] = all[t.id] || []).push({ t: r.t, e }); jset(RXL, all); } rxUi(); }
  A.addEventListener('seeked', rxReset);
  async function cmLoad(t) {
    rxLoad(t); cmTrack = t; const loc = (jget(CML, {})[t.id] || []).map((x) => Object.assign({ mine: true }, x)); cmList = loc.slice().sort((a, b) => a.t - b.t); cmReset();
    const db = fdb(); if (!db) return;
    try { const q = await db.collection('cmts').where('track', '==', t.id).get(); if (cmTrack !== t) return; const u = fuid(), arr = []; const adm = isAdm(); q.forEach((d) => { const x = d.data(); if (!x || typeof x.t !== 'number' || !x.text) return; const mine = !!u && x.uid === u, s = x.st || (window.CMF ? CMF.check(x.text).st : 'ok'); if (s === 'block' && !adm) return; if (s === 'review' && !mine && !adm) return; arr.push({ id: d.id, t: x.t, text: String(x.text).slice(0, 70), name: x.name || '', mine, uid: x.uid, st: s }); }); cmList = arr.concat(loc.filter((x) => !x.synced)).sort((a, b) => a.t - b.t); cmReset(); if (!g('plrCm').hidden) cmUi(); } catch (e) {}
  }
  /* عرض ذكي: طابور يوزّع التعليقات على الجانبين بإيقاع هادئ، وعند القفز يعرض ما قيل قبيل الموضع الجديد */
  let cmQ = [], cmSide = 0, cmAt = [0, 0];
  function cmReset() { const L = g('plrCmL'); [...L.children].forEach((d) => { try { d.getAnimations().forEach((a) => a.cancel()); } catch (e) {} d.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 250 }).onfinish = () => d.remove(); });
    const now = A.currentTime || 0; cmPtr = 0; while (cmPtr < cmList.length && cmList[cmPtr].t < now - 3) cmPtr++; cmQ = []; cmLast = now; }
  function cmSpawn(c, own) {
    const L = g('plrCmL'); L.dataset.v = st.cm.view; const max = st.cm.view === 'side' ? 8 : 5; if (!own && L.childElementCount >= max) return;
    const d = el('div', 'cmi' + (own || c.mine ? ' me' : ''), c.text);
    if (st.cm.view === 'side') {
      const sd = own ? 1 : (cmAt[0] <= cmAt[1] ? 0 : 1); cmAt[sd] = performance.now() / 1000; d.classList.add(sd ? 'R' : 'L'); d.style.bottom = '0px'; L.appendChild(d); const H = L.clientHeight || 300;
      const a = d.animate([{ opacity: 0, transform: 'translateY(14px) scale(.94)' }, { opacity: 1, transform: 'translateY(0) scale(1)', offset: 0.08 }, { opacity: 1, transform: `translateY(${-H * 0.62}px)`, offset: 0.8 }, { opacity: 0, transform: `translateY(${-H * 0.85}px)` }], { duration: 9000, easing: 'linear' });
      a.onfinish = () => d.remove(); if (A.paused) a.pause(); return;
    }
    const W = L.clientWidth || 360; let li = 0, lt = Infinity; const nowP = performance.now(); cmLane.forEach((v, i) => { if (v < lt) { lt = v; li = i; } }); if (!own && nowP - lt < 1600) return; cmLane[li] = nowP;
    d.style.top = (li * 30 + 4) + 'px'; L.appendChild(d); const tw = d.offsetWidth || 120;
    const m = ['rtl', 'ltr', 'fade', 'fade'][Math.floor(Math.random() * 4)];
    let kf, dur; if (m === 'fade') { d.style.left = Math.max(6, Math.random() * (W - tw - 12)) + 'px'; kf = [{ opacity: 0, transform: 'translateY(6px)' }, { opacity: 1, transform: 'none', offset: 0.15 }, { opacity: 1, offset: 0.8 }, { opacity: 0, transform: 'translateY(-6px)' }]; dur = 5200; }
    else { d.style.left = '0px'; const a = m === 'rtl' ? W : -tw, b = m === 'rtl' ? -tw : W; kf = [{ transform: `translateX(${a}px)` }, { transform: `translateX(${b}px)` }]; dur = 9000 + Math.random() * 3000; }
    const an2 = d.animate(kf, { duration: dur, easing: m === 'fade' ? 'ease' : 'linear' }); an2.onfinish = () => d.remove(); if (A.paused) an2.pause();
  }

  function cmTick() {
    if (!st.cm.on || !cmList.length) return; const now = A.currentTime || 0;
    if (Math.abs(now - cmLast) > 1.5) cmReset(); cmLast = now; if (A.paused) return;
    while (cmPtr < cmList.length && cmList[cmPtr].t <= now) { cmQ.push(cmList[cmPtr]); cmPtr++; }
    cmQ = cmQ.filter((c) => c.t > now - 7); if (cmQ.length > 12) cmQ = cmQ.slice(-12);
    const gap = 1.6, pn = performance.now() / 1000; if (cmQ.length && pn - Math.max(cmAt[0], cmAt[1]) > gap / 2 && pn - Math.min(cmAt[0], cmAt[1]) > gap) cmSpawn(cmQ.shift());
  }
  ['play', 'pause'].forEach((ev) => A.addEventListener(ev, () => { try { g('plrCmL').getAnimations({ subtree: true }).forEach((a) => ev === 'play' ? a.play() : a.pause()); } catch (e) {} }));
  A.addEventListener('seeked', cmReset);
  g('plrCmI').addEventListener('input', () => { if (cmTime == null) cmTime = A.currentTime || 0; if (!g('plrCmI').value) cmTime = null; });
  g('plrCmI').addEventListener('keydown', (e) => { if (e.key === 'Enter') cmSend(); });
  g('plrCmS').onclick = cmSend;
  g('plrCmI').addEventListener('input', () => { const n = 70 - g('plrCmI').value.length; g('plrCmN').textContent = n; g('plrCmN').classList.toggle('lo', n < 10); });
  /* ---------- مراجعة التعليقات (للمشرف) ---------- */
  async function cmfLoad() { const db = fdb(); if (!db || !window.CMF) return; try { const s = await db.doc('cmfilter/main').get(); if (s.exists) CMF.setExtra(s.data()); } catch (e) {} }
  cmfLoad();
  g('plrCmMod').onclick = () => cmMod('review');
  function cmMod(tab) { const db = fdb(); if (!db) return toast('غير متصل');
    modal('مراجعة التعليقات', async (bx, close) => {
      const tb = el('div', 'seg'); [['review', 'تحتاج مراجعة'], ['block', 'محظورة'], ['ok', 'منشورة'], ['words', 'الكلمات']].forEach(([k, n]) => { const b = el('button', k === tab ? 'on' : '', n); b.type = 'button'; b.onclick = () => { close(); cmMod(k); }; tb.appendChild(b); }); bx.appendChild(tb);
      const L = el('div', 'cmml'); bx.appendChild(L); L.textContent = 'جارٍ التحميل…';
      if (tab === 'words') { L.textContent = ''; let cur0 = { block: [], review: [], allow: [] }; try { const s = await db.doc('cmfilter/main').get(); if (s.exists) cur0 = Object.assign(cur0, s.data()); } catch (e) {}
        const fld = (k, lbl, ph) => { L.appendChild(el('h5', '', lbl)); const ta = el('textarea', 'mdin'); ta.rows = 3; ta.placeholder = ph; ta.value = (cur0[k] || []).join('، '); L.appendChild(ta); return ta; };
        L.appendChild(el('p', 'hint', 'الفلتر يكشف الكلمات حتى لو فُرّقت بمسافات أو نقاط أو رموز، أو تغيّرت همزاتها وحروفها. افصل الكلمات بفاصلة.'));
        const a1 = fld('block', 'كلمات تُحظر مباشرة', 'كلمة، كلمة'), a2 = fld('review', 'كلمات تحتاج مراجعة', 'كلمة، كلمة'), a3 = fld('allow', 'كلمات مسموحة دائماً (استثناء)', 'كلمة، كلمة');
        const sp = (v) => v.split(/[،,\n]+/).map((s) => s.trim()).filter(Boolean);
        const sv = el('button', 'pri', 'حفظ'); sv.type = 'button'; sv.onclick = async () => { const o = { block: sp(a1.value), review: sp(a2.value), allow: sp(a3.value) }; try { await db.doc('cmfilter/main').set(o); CMF.setExtra(o); toast('حُفظ الفلتر'); close(); } catch (e) { toast('تعذّر الحفظ'); } }; bx.appendChild(sv);
        const ts = el('input', 'mdin'); ts.placeholder = 'جرّب نصاً لترى نتيجة الفلتر'; const tr = el('div', 'hint'); ts.oninput = () => { const r = CMF.check(ts.value); tr.textContent = ts.value ? ({ ok: '✓ مسموح', review: '؟ يحتاج مراجعة', block: '✕ محظور' })[r.st] + (r.hit ? ' — «' + r.hit + '»' : '') : ''; }; L.append(ts, tr); return; }
      let q; try { q = tab === 'ok' ? await db.collection('cmts').orderBy('at', 'desc').limit(60).get() : await db.collection('cmts').where('st', '==', tab).limit(60).get(); } catch (e) { L.textContent = 'تعذّر التحميل: ' + (e.code || e.message); return; }
      L.textContent = ''; const rows = []; q.forEach((d) => { const x = d.data(); if (tab === 'ok' && x.st && x.st !== 'ok') return; rows.push([d.id, x]); }); if (!rows.length) { L.appendChild(el('div', 'hint', 'لا يوجد شيء هنا.')); return; }
      rows.forEach(([id, x]) => { const r = el('div', 'cmmr'), tr = byId(x.track), ck = CMF.check(x.text || ''); r.appendChild(el('b', '', x.text || ''));
        r.appendChild(el('small', '', (tr ? tr.title : x.track) + ' · ' + fmt(x.t || 0) + (x.name ? ' · ' + x.name : '') + (ck.hit ? ' · «' + ck.hit + '»' : '')));
        const ac2 = el('div', 'row'); const set = (s) => async () => { try { await db.doc('cmts/' + id).update({ st: s }); r.remove(); toast(s === 'ok' ? 'نُشر' : 'حُظر'); } catch (e) { toast('تعذّر: ' + (e.code || '')); } };
        if (tab !== 'ok') ac2.appendChild(btn('primary', 'سماح', set('ok'))); if (tab !== 'block') ac2.appendChild(btn('', 'حظر', set('block')));
        ac2.appendChild(btn('', 'حذف', async () => { try { await db.doc('cmts/' + id).delete(); r.remove(); } catch (e) { toast('تعذّر الحذف'); } })); r.appendChild(ac2); L.appendChild(r); });
    }); }
  async function cmSend() {
    const t = tracks[cur], inp = g('plrCmI'), txt = inp.value.trim().replace(/\s+/g, ' '); if (!t || !txt) return;
    if (Date.now() - cmSent < 8000) return toast('انتظر قليلاً قبل التعليق التالي');
    const fc = window.CMF ? CMF.check(txt) : { st: cmBad(txt) ? 'block' : 'ok' };
    const tt = r2(cmTime != null ? cmTime : A.currentTime || 0); cmTime = null; inp.value = ''; cmSent = Date.now();
    const u = window.firebase && firebase.auth ? firebase.auth().currentUser : null, c = { t: tt, text: txt.slice(0, 220), name: (u && u.displayName) || '', mine: true, ts: Date.now() };
    c.text = txt.slice(0, 70); c.st = fc.st; const db = fdb(); let ok = false;
    if (fc.st === 'block') { inp.value = ''; if (db && u) { try { await db.collection('cmts').add({ track: t.id, t: c.t, text: c.text, uid: u.uid, name: c.name, st: 'block', at: firebase.firestore.FieldValue.serverTimestamp() }); } catch (e) {} } return toast('التعليق يحتوي ألفاظاً غير لائقة ولن يُنشر'); }
    cmList.push(c); cmList.sort((a, b) => a.t - b.t); cmReset(); if (c.t <= (A.currentTime || 0) + 0.05) cmPtr = Math.max(cmPtr, cmList.indexOf(c) + 1); if (st.cm.on) cmSpawn(c, true);
    if (db && u) { try { const r = await db.collection('cmts').add({ track: t.id, t: c.t, text: c.text, uid: u.uid, name: c.name, st: fc.st, at: firebase.firestore.FieldValue.serverTimestamp() }); c.id = r.id; c.uid = u.uid; ok = true; } catch (e) {} }
    if (fc.st === 'review') { toast('سيظهر تعليقك للجميع بعد المراجعة'); cmUi(); if (!ok) { const all = jget(CML, {}); (all[t.id] = all[t.id] || []).push({ t: c.t, text: c.text, ts: c.ts }); jset(CML, all); } return; }
    if (!ok) { const all = jget(CML, {}); (all[t.id] = all[t.id] || []).push({ t: c.t, text: c.text, ts: c.ts }); jset(CML, all); }
    toast(ok ? 'نُشر تعليقك عند ' + fmt(c.t) : 'حُفظ التعليق على هذا الجهاز' + (u ? '' : ' — سجّل الدخول لنشره للجميع')); cmUi();
  }
  function cmUi() {
    const seg = (id, items, key) => { const b = g(id); b.textContent = ''; items.forEach(([v, n]) => { const x = el('button', st.cm[key] === v ? 'on' : '', n); x.onclick = () => { st.cm[key] = v; save(); if ((key === 'on' && !v) || key === 'view') g('plrCmL').textContent = ''; cmUi(); rxUi(); }; b.appendChild(x); }); };
    seg('plrCmOn', [[true, 'إظهار'], [false, 'إخفاء']], 'on'); seg('plrCmV', [['float', 'عائمة'], ['side', 'جانبية']], 'view'); g('plrCmL').dataset.v = st.cm.view; g('plrCmMod').hidden = !isAdm();
    const box = g('plrCmList'); box.textContent = ''; if (!cmList.length) { box.appendChild(el('div', 'hint', 'لا توجد تعليقات.')); return; }
    const adm = isAdm();
    cmList.forEach((c) => { const r = el('div', 'cmr' + (c.mine ? ' me' : '')), tb = el('button', 'tm', fmt(c.t)); tb.onclick = () => { A.currentTime = Math.max(0, c.t - 1); A.play().catch(() => {}); }; const tx = el('span', '', c.text); r.append(tb, tx); if (c.st === 'review') r.appendChild(el('em', 'cmst', 'بانتظار المراجعة'));
      if ((adm || c.mine)) { const x = el('button', 'x', '×'); x.onclick = async () => { cmList = cmList.filter((y) => y !== c); if (c.id) { try { await fdb().doc('cmts/' + c.id).delete(); } catch (e) { toast('تعذّر الحذف'); } } else { const all = jget(CML, {}); all[tracks[cur].id] = (all[tracks[cur].id] || []).filter((y) => y.ts !== c.ts); jset(CML, all); } cmUi(); }; r.appendChild(x); }
      box.appendChild(r); });
  }
  /* تغيير الغلاف: ضغط مطوّل على الصورة */
  let catCovers = [];
  function coverSheet() {
    const t = tracks[cur]; if (!t) return; g('plrCv').hidden = false; g('plrBg').hidden = false; const G = g('plrCvG'); G.textContent = '';
    const seen = new Set(), list = []; const add = (u, r) => { if (u && !seen.has(u)) { seen.add(u); list.push({ u, r: r || '' }); } };
    catCovers.forEach((c) => { if (!t.reciter || !c.reciter || c.reciter === t.reciter) add(c.url, c.reciter); }); tracks.forEach((x) => { if (x.reciter === t.reciter) add(x.cover, x.reciter); });
    catCovers.forEach((c) => add(c.url, c.reciter)); tracks.forEach((x) => add(x.cover, x.reciter));
    if (!list.length) { G.appendChild(el('div', 'hint', 'لا توجد أغلفة مضافة بعد.')); return; }
    const curC = cov(t); list.forEach((c) => { const b = el('button', 'cvi' + (curC === c.u ? ' on' : '')); b.type = 'button'; const im = document.createElement('img'); im.loading = 'lazy'; im.src = c.u; im.alt = ''; b.appendChild(im); b.onclick = () => cvSet(t, c.u === t.cover ? '' : c.u); G.appendChild(b); });
  }
  const cvClose = () => { g('plrCv').hidden = true; g('plrBg').hidden = true; };
  function cvSet(t, url) { try { if (url) localStorage.setItem(CVK(t), url); else localStorage.removeItem(CVK(t)); } catch (e) { return toast('تعذّر حفظ الغلاف: المساحة غير كافية'); } loadImg(t); bgSet(t); stageBuild(); coverEl(t, g("plrMiniC")); render(); meta(); cvClose(); toast(url ? 'تم تغيير الغلاف' : 'أُعيد الغلاف الأصلي'); }
  function cvShrink(src) { return new Promise((res, rej) => { const im = new Image(); im.onload = () => { const S = 640, c = document.createElement('canvas'); c.width = c.height = S; const x = c.getContext('2d'), m = Math.min(im.width, im.height); x.drawImage(im, (im.width - m) / 2, (im.height - m) / 2, m, m, 0, 0, S, S); try { res(c.toDataURL('image/jpeg', 0.85)); } catch (e) { rej(e); } }; im.onerror = rej; im.src = src; }); }
  g('plrCvX').onclick = cvClose;
  g('plrCvF').onclick = () => g('plrCvIn').click();
  g('plrCvIn').onchange = async () => { const f = g('plrCvIn').files[0], t = tracks[cur]; if (!f || !t) return; const u = URL.createObjectURL(f); try { cvSet(t, await cvShrink(u)); } catch (e) { toast('تعذّر قراءة الصورة'); } URL.revokeObjectURL(u); g('plrCvIn').value = ''; };
  g('plrCvD').onclick = () => { const t = tracks[cur]; if (t) cvSet(t, ''); };
  /* السحب للأسفل للإغلاق */
  function swipe(mv, handles, close, sc) {
    let y0 = 0, x0 = 0, dy = 0, drag = false, t0 = 0, on = false; const IGN = '.sl,.kn,input,textarea,#plrEq' + (mv.id === 'plrFull' ? ',.plrwave,.plrctl,.plrdock,.plrtp,.plrqs,.plrlys,.plrsheetbg' : '');
    const begin = (y, tg, xx) => { if (tg && tg.closest && tg.closest(IGN)) return; on = true; y0 = y; x0 = xx || 0; dy = 0; t0 = Date.now(); drag = false; };
    const move = (y, e, xx) => { if (!on) return; dy = y - y0; if (!drag) { if (xx != null && Math.abs(xx - x0) > Math.abs(dy) && Math.abs(xx - x0) > 8) { on = false; return; } if (dy > 18 && (!sc || sc.scrollTop <= 0)) { drag = true; mv.style.transition = 'none'; } else return; } if (e && e.cancelable) e.preventDefault(); mv.style.transform = `translateY(${Math.max(0, dy)}px)`; };
    const end = () => { on = false; if (!drag) return; drag = false; mv.style.transition = ''; const v = dy / Math.max(1, Date.now() - t0); mv.style.transform = ''; if (dy > 170 || (v > 0.9 && dy > 80)) close(); };
    handles.forEach((h) => {
      h.addEventListener('touchstart', (e) => begin(e.touches[0].clientY, e.target, e.touches[0].clientX), { passive: true });
      h.addEventListener('touchmove', (e) => move(e.touches[0].clientY, e, e.touches[0].clientX), { passive: false });
      h.addEventListener('touchend', end); h.addEventListener('touchcancel', end);
      h.addEventListener('mousedown', (e) => { if (e.target.closest('input,textarea,button:not(.ib)')) return; begin(e.clientY, e.target, e.clientX); const mm = (ev) => move(ev.clientY, ev, ev.clientX), up = () => { document.removeEventListener('mousemove', mm); document.removeEventListener('mouseup', up); end(); }; document.addEventListener('mousemove', mm); document.addEventListener('mouseup', up); });
    });
  }
  swipe(g('plrTp'), [g('plrTp')], () => tp(false), g('plrTp'));  swipe(g('plrAdm'), [g('plrAdm')], () => admShow(false), g('plrAdm')); swipe(g('plrAu'), [g('plrAu').querySelector('.gr'), g('plrAu').querySelector('.auh')], () => au(false)); swipe(g('plrCm'), [g('plrCm')], () => cmS(false), g('plrCmList')); swipe(g('plrCv'), [g('plrCv')], cvClose);
  swipe(g('plrLys'), [g('plrLyH')], closeLys);
  swipe(g('plrFull'), [g('plrFull')], closeFull);
  /* زر الرجوع: يغلق أعلى طبقة مفتوحة، ويرجع true إذا تعامل معها */
  function back() {
    if (root.hidden) return false;
    { const md = document.getElementById('plrMd'); if (md) { md.remove(); return true; } }
    if (hsOn) { hsClose(); return true; }
    if (smpOn) { smpClose(); return true; }
    if (!g('plrAdm').hidden) { admShow(false); return true; }
    if (!g('plrCv').hidden) { cvClose(); return true; }
    if (!g('plrAuPL').hidden) { g('plrAuPL').hidden = true; return true; }
    if (!g('plrAu').hidden) { au(false); return true; }
    if (!g('plrCm').hidden) { cmS(false); return true; }
    { const sh = document.getElementById('plrSh'); if (sh) { sh.remove(); return true; } }
    if (!g('plrTp').hidden) { tp(false); return true; }
    if (!g('plrQs').hidden) { qs(false); return true; }
    if (!g('plrLys').hidden) { closeLys(); return true; }
    if (!g('plrFull').hidden) { closeFull(); return true; }
    if (!g('plrSearch').hidden) { g('plrSearchB').onclick(); return true; }
    if (hsOn) { hsClose(); return true; }
    if (smpOn) { smpClose(); return true; }
    if (tab === 'pls' && plSel) { plSel = null; render(); return true; }
    if (tab === 'lib' && libSel) { libSel = null; render(); return true; }
    if (tab === 'lib' && cat !== 'الكل') { cat = 'الكل'; render(); return true; }
    if (tab === 'lib' && libV !== 'home') { libV = 'home'; render(); return true; }
    if (tab !== 'lib') { tab = 'lib'; cat = 'الكل'; root.querySelectorAll('.plrnav button').forEach((x) => x.classList.toggle('on', x.dataset.t === 'lib')); render(); return true; }
    return false;
  }

  /* لون شريطي النظام حسب الشاشة + ملء الشاشة عند أول لمسة */
  (function () {
    const mt = document.querySelector('meta[name=theme-color]'), set = () => { const full = !root.hidden && !g('plrFull').hidden; if (mt) mt.content = full ? (THC ? THC.B[0] : '#0c4a39') : '#F6F1E6'; document.documentElement.style.background = full ? '#04140f' : '#F6F1E6'; };
    const mo = new MutationObserver(set); mo.observe(root, { attributes: true, attributeFilter: ['hidden'] }); mo.observe(g('plrFull'), { attributes: true, attributeFilter: ['hidden'] }); set();

  })();

  /* بعد إغلاق لوحة المفاتيح: إعادة الصفحة لمكانها حتى لا تنقص من الأعلى */
  document.addEventListener('focusout', () => setTimeout(() => { if (!document.activeElement || !/INPUT|TEXTAREA/.test(document.activeElement.tagName)) { try { window.scrollTo(0, 0); document.scrollingElement && (document.scrollingElement.scrollTop = 0); } catch (e) {} } }, 120));

  /* معاينة التنقّل: وقت كبير فوق خلفية معتمة أثناء سحب شريط التقدّم */
  let scrS = null, scrE = null;
  (function () { const ov = g('plrScr'); let on = false, raf = 0; const up = () => { if (!on) return; ov.firstChild.textContent = fmt(A.currentTime) + '  |  ' + fmt(A.duration || 0); raf = requestAnimationFrame(up); };
    const start = () => { on = true; ov.hidden = false; g('plrFull').classList.add('scr'); requestAnimationFrame(() => ov.classList.add('on')); cancelAnimationFrame(raf); up(); }, stop = () => { if (!on) return; on = false; cancelAnimationFrame(raf); ov.classList.remove('on'); g('plrFull').classList.remove('scr'); setTimeout(() => { if (!on) ov.hidden = true; }, 250); };
    scrS = start; scrE = stop; ['plrWave', 'plrLn'].forEach((id) => { const e = g(id); let t0 = 0; e.addEventListener('pointerdown', () => { t0 = setTimeout(start, 140); }); const end = () => { clearTimeout(t0); stop(); }; e.addEventListener('pointerup', end); e.addEventListener('pointercancel', end); }); })();
  /* قائمة التشغيل: اسحب الرأس للأعلى لتملأ الشاشة، وللأسفل لتصغر ثم تُغلق */
  (function () { const s = g('plrQs'), h = s.querySelector('.qhd'); let y0 = 0, dy = 0, on = false, t0 = 0;
    h.addEventListener('pointerdown', (e) => { if (e.target.closest('button')) return; on = true; y0 = e.clientY; dy = 0; t0 = Date.now(); s.style.transition = 'none'; try { h.setPointerCapture(e.pointerId); } catch (x) {} });
    h.addEventListener('pointermove', (e) => { if (!on) return; dy = e.clientY - y0; if (dy > 0) s.style.transform = `translateY(${dy}px)`; else if (!s.classList.contains('full')) s.style.maxHeight = `calc(88% + ${-dy}px)`; });
    const end = () => { if (!on) return; on = false; s.style.transition = ''; s.style.transform = ''; s.style.maxHeight = ''; const v = dy / Math.max(1, Date.now() - t0);
      if (dy < -50 || v < -0.6) s.classList.add('full'); else if (dy > 60 || v > 0.6) { if (s.classList.contains('full') && dy < 260) s.classList.remove('full'); else { s.classList.remove('full'); qs(false); } } };
    h.addEventListener('pointerup', end); h.addEventListener('pointercancel', end); h.addEventListener('dblclick', () => s.classList.toggle('full')); })();
  /* ======================= الإصدار 3.35: أدوات القصيدة والقوائم والمجلس ======================= */
  const NEWK = 'minbar.seen.335', nw = () => localStorage.getItem(NEWK) !== '1';
  if (nw()) g('plrMore').classList.add('newdot');
  const modal = (title, build) => { const old = document.getElementById('plrMd'); if (old) old.remove(); const w = el('div', 'qmenu'); w.id = 'plrMd'; const bx = el('div', 'qmb md'); if (title) bx.appendChild(el('b', '', title)); build(bx, () => w.remove()); w.appendChild(bx); w.onclick = (e) => { if (e.target === w) w.remove(); }; w.addEventListener('focusin', (e) => { const f = e.target; if (!f || !/TEXTAREA|INPUT|SELECT/.test(f.tagName)) return; setTimeout(() => { try { f.scrollIntoView({ block: 'center', behavior: 'smooth' }); } catch (x) {} }, 350); }); root.appendChild(w); return w; };
  const snack = (msg, act, fn, ms) => { let s = document.getElementById('plrSnack'); if (!s) { s = el('div', 'snack'); s.id = 'plrSnack'; root.appendChild(s); } s.textContent = ''; s.appendChild(el('span', '', msg)); if (act) { const b = el('button', '', act); b.onclick = () => { s.classList.remove('on'); fn(); }; s.appendChild(b); } s.classList.add('on'); clearTimeout(snack.h); snack.h = setTimeout(() => s.classList.remove('on'), ms || 5000); };
  /* ---------- 1) القوائم المحفوظة ---------- */
  const PLK = 'minbar.pls'; let plSel = null; const pls = () => jget(PLK, []), plsSet = (a) => jset(PLK, a);
  function plSave() { const t0 = tracks[cur]; if (!t0) return; qEnsure(t0); modal('حفظ قائمة التشغيل', (bx, close) => { const inp = el('input', 'mdin'); inp.placeholder = 'اسم القائمة، مثل: لطميات محرم'; inp.maxLength = 40; inp.value = Q.src && Q.src !== 'المكتبة' ? Q.src : ''; bx.appendChild(inp); bx.appendChild(el('small', 'mdh', Q.ids.length + ' قصيدة بالترتيب الحالي'));
    const b = el('button', 'pri', 'حفظ'); b.onclick = () => { const n = inp.value.trim(); if (!n) return inp.focus(); const a = pls(); a.unshift({ id: 'p' + Date.now(), name: n, ids: Q.ids.slice(), at: Date.now() }); plsSet(a); close(); toast('حُفظت «' + n + '» في القوائم'); g('plrNavPl').classList.add('newdot'); }; bx.appendChild(b); const c = el('button', 'cn', 'إلغاء'); c.onclick = close; bx.appendChild(c); setTimeout(() => inp.focus(), 80); }); }
  function plRender(body) { const a = pls(); if (!a.length) { const d = el('div', 'hint', 'لا توجد قوائم محفوظة بعد. افتح «القائمة» من المشغّل واضغط «حفظ كقائمة».'); d.style.textAlign = 'center'; body.appendChild(d); return; }
    const L = el('div', 'pllist'); a.forEach((p) => { const r = el('div', 'plc'); const cs = el('div', 'plcv'); p.ids.slice(0, 4).forEach((id) => { const t = byId(id); const c = el('div', 'plrcov'); if (t) coverEl(t, c); cs.appendChild(c); }); const m = el('div', 'plm'); m.append(el('b', '', p.name), el('small', '', p.ids.length + ' قصيدة'));
      const pb = el('button', 'plp'); pb.innerHTML = ic('play', 20); pb.onclick = (e) => { e.stopPropagation(); plPlay(p); }; r.append(cs, m, pb); r.onclick = () => { plSel = p.id; render(); }; L.appendChild(r); }); body.appendChild(L); }
  function plPlay(p, from) { const L = p.ids.map(byId).filter(Boolean); if (!L.length) return; const t = from || L[0]; Q.base = L.map((x) => x.id); Q.ids = st.shuf ? [t.id].concat(shufA(Q.base.filter((x) => x !== t.id))) : Q.base.slice(); Q.src = p.name; qSave(); play(tracks.indexOf(t), true); }
  /* ---------- 2) عن القصيدة ---------- */
  function about() { const t = tracks[cur]; if (!t) return; let du = {}; try { du = JSON.parse(localStorage.getItem(DUK) || '{}'); } catch (e) {} const cnt = {}; rxList.forEach((r) => { cnt[r.e] = (cnt[r.e] || 0) + 1; }); const L = linesOf(t), pk = peakT();
    modal('', (bx, close) => { const h = el('div', 'abh'); const c = el('div', 'plrcov'); coverEl(t, c); const m = el('div', ''); m.append(el('b', '', t.title), el('small', '', [t.reciter, t.poet ? 'كلمات ' + t.poet : ''].filter(Boolean).join(' · '))); h.append(c, m); bx.appendChild(h);
      const gr = el('div', 'abg'); const it = (k, v) => { if (v == null || v === '') return; const d = el('div', ''); d.append(el('small', '', k), el('b', '', String(v))); gr.appendChild(d); };
      it('التصنيف', t.cat); if (t.albumName) it('الإصدار', t.albumName); it('المدة', du[t.id] ? fmt(du[t.id]) : (A.duration ? fmt(A.duration) : '')); it('سنة الإصدار', t.year); it('المناسبة', t.occasion); it('الأبيات', L.length || 'غير متوفرة'); it('التعليقات', cmList.length); it('التفاعلات', rxList.length ? RXE.map((e) => cnt[e] ? e + ' ' + cnt[e] : '').filter(Boolean).join('  ') : '0'); bx.appendChild(gr);
      if (t.about) bx.appendChild(el('p', 'abp', t.about));
      if (pk != null) { const b = el('button', 'pri', 'الانتقال إلى أكثر لحظة تفاعلاً (' + fmt(pk) + ')'); b.onclick = () => { A.currentTime = pk; if (A.paused) fadePlay(); close(); }; bx.appendChild(b); }
      const c2 = el('button', 'cn', 'إغلاق'); c2.onclick = close; bx.appendChild(c2); }); }
  /* ---------- 3) أكثر لحظة تفاعلاً + الخريطة الحرارية ---------- */
  function heat(n) { const d = A.duration || 0; if (!d || !rxList.length) return null; const h = new Float32Array(n); rxList.forEach((r) => { const i = Math.min(n - 1, Math.floor(r.t / d * n)), w = r.e === '😢' ? 2 : 1; for (let k = -2; k <= 2; k++) { const j = i + k; if (j >= 0 && j < n) h[j] += w * (1 - Math.abs(k) * 0.3); } }); let mx = 0; h.forEach((v) => { mx = Math.max(mx, v); }); if (!mx) return null; return h.map((v) => v / mx); }
  function peakT() { const h = heat(120); if (!h) return null; let bi = 0; h.forEach((v, i) => { if (v > h[bi]) bi = i; }); return Math.max(0, bi / 120 * (A.duration || 0) - 2); }
  function heatUi() { const h = heat(40), ln = g('plrLn').querySelector('.lt'); if (!h) { ln.style.background = ''; return; } ln.style.background = 'linear-gradient(90deg,' + Array.from(h).map((v, i) => `rgba(${Math.round(255 - v * 40)},${Math.round(255 - v * 170)},${Math.round(255 - v * 190)},${(0.18 + v * 0.55).toFixed(2)}) ${(i / 39 * 100).toFixed(1)}%`).join(',') + ')'; }
  /* ---------- 4) مشاركة اللحظة ---------- */
  async function shareMoment() { const t = tracks[cur]; if (!t) return; const at = Math.floor(A.currentTime || 0), url = location.origin + location.pathname + '?p=' + encodeURIComponent(t.id) + '&at=' + at; const L = lyLines(); let line = ''; for (const x of L) { if (x.t <= A.currentTime + 0.2) line = x.l; else break; }
    toast('تجهيز صورة المشاركة…'); const c = document.createElement('canvas'); c.width = 1080; c.height = 1350; const x = c.getContext('2d'); const bg = x.createLinearGradient(0, 0, 0, 1350); bg.addColorStop(0, '#0c4a39'); bg.addColorStop(1, '#04140f'); x.fillStyle = bg; x.fillRect(0, 0, 1080, 1350);
    if (curImg && curImg.naturalWidth) { try { x.filter = 'blur(40px) brightness(.45)'; x.drawImage(curImg, -100, -100, 1280, 1280); x.filter = 'none'; } catch (e) {} const s = 620, iw = curImg.naturalWidth, ih = curImg.naturalHeight, m = Math.min(iw, ih); x.save(); x.beginPath(); x.roundRect ? x.roundRect(230, 170, s, s, 40) : x.rect(230, 170, s, s); x.clip(); x.drawImage(curImg, (iw - m) / 2, (ih - m) / 2, m, m, 230, 170, s, s); x.restore(); }
    x.direction = 'rtl'; x.textAlign = 'center'; x.fillStyle = '#F3D88A'; x.font = `700 52px "${st.ly.font}", Cairo, sans-serif`; const wrap = (s, y, mx) => { const ws = s.split(' '); let ln = '', ys = y; ws.forEach((w) => { const tt = ln ? ln + ' ' + w : w; if (x.measureText(tt).width > mx && ln) { x.fillText(ln, 540, ys); ln = w; ys += 70; } else ln = tt; }); if (ln) x.fillText(ln, 540, ys); return ys; };
    let y = 900; if (line) y = wrap('«' + line + '»', 900, 900) + 90; x.fillStyle = '#fff'; x.font = '700 46px Cairo, sans-serif'; x.fillText(t.title, 540, y); x.fillStyle = 'rgba(255,255,255,.7)'; x.font = '36px Cairo, sans-serif'; x.fillText((t.reciter || '') + '  ·  ' + fmt(at), 540, y + 60); x.fillStyle = 'rgba(232,196,104,.85)'; x.font = '700 34px Cairo, sans-serif'; x.fillText('منبر', 540, 1290);
    const blob = await new Promise((r) => c.toBlob(r, 'image/jpeg', 0.9)); const file = new File([blob], 'minbar.jpg', { type: 'image/jpeg' }), text = t.title + (line ? ' — «' + line + '»' : '') + '\n' + url;
    try { if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], text, title: t.title }); return; } if (navigator.share) { await navigator.share({ text, url, title: t.title }); return; } } catch (e) { if (e && e.name === 'AbortError') return; }
    try { await navigator.clipboard.writeText(url); } catch (e) {} const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'minbar.jpg'; a.click(); toast('نُسخ الرابط وحُفظت الصورة'); }
  /* آخر جلسة: يحفظ القصيدة والموضع، ويرجعها متوقفة عند نفس الدقيقة عند فتح التطبيق */
  const LASTK = 'minbar.last'; let lastSv = 0;
  const lastSave = () => { const t = tracks[cur]; if (!t || !A.src) return; try { localStorage.setItem(LASTK, JSON.stringify({ id: t.id, t: Math.floor(A.currentTime || 0), at: Date.now() })); } catch (e) {} };
  A.addEventListener('timeupdate', () => { const n = Date.now(); if (n - lastSv > 3000) { lastSv = n; lastSave(); } }); A.addEventListener('pause', lastSave); A.addEventListener('seeked', lastSave);
  window.addEventListener('pagehide', lastSave); document.addEventListener('visibilitychange', () => { if (document.hidden) lastSave(); });
  function lastRestore() { if (cur >= 0 || deepAt) return; let L = null; try { L = JSON.parse(localStorage.getItem(LASTK) || 'null'); } catch (e) {} if (!L) return; const t = byId(L.id); if (!t) return;
    resumeOk = false; A.__noAuto = true; A.__keepPaused = true; qEnsure(t); play(tracks.indexOf(t), false); seekTo(L.t || 0); setTimeout(() => { A.__keepPaused = false; }, 15000); }
  A.addEventListener('play', () => { A.__keepPaused = false; if (ac && ac.state !== 'running') ac.resume().catch(() => {}); });
  document.addEventListener('visibilitychange', () => { if (document.hidden) return; const t = tracks[cur]; if (t && (!curImg || !curImg.complete || !curImg.naturalWidth)) loadImg(t); setTimeout(() => { try { bgApply(); waveDraw(); vizPills && !g('plrTp').hidden && vizPills(); } catch (e) {} }, 300); });
  let deepAt = null; (function () { try { const u = new URLSearchParams(location.search), p = u.get('p'); if (!p) return; deepAt = { id: p, at: +u.get('at') || 0 }; history.replaceState(null, '', location.pathname); } catch (e) {} })();
  function deepGo() { if (!deepAt || !tracks.length) return; const t = byId(deepAt.id); if (!t) { deepAt = null; return; } const at = deepAt.at; deepAt = null; resumeOk = false; root.hidden = false; qFrom(t, tracks); play(tracks.indexOf(t), true); seekTo(at); toast('فتح اللحظة المشتركة ' + fmt(at)); }
  /* ---------- 5) استئناف القصائد الطويلة ---------- */
  const POSK = 'minbar.pos'; let posSv = 0, resumeOk = true;
  A.addEventListener('timeupdate', () => { const n = Date.now(); if (n - posSv < 5000) return; posSv = n; const t = tracks[cur], d = A.duration || 0; if (!t || d < 180) return; const m = jget(POSK, {}); if (A.currentTime > 20 && A.currentTime < d - 20) m[t.id] = Math.floor(A.currentTime); else delete m[t.id]; const ks = Object.keys(m); if (ks.length > 60) delete m[ks[0]]; jset(POSK, m); });
  A.addEventListener('loadedmetadata', () => { const t = tracks[cur]; if (!t || !resumeOk || deepAt || MJ.on) { resumeOk = true; return; } if (A.__rsm === t.id) return; A.__rsm = t.id; const s = jget(POSK, {})[t.id]; if (MB.want == null && s && s > 15 && s < (A.duration || 0) - 20 && A.currentTime < 2) { if (!A.paused) { A.pause(); A.__rsmPlay = true; const fin = () => { if (!A.__rsmPlay) return; A.__rsmPlay = false; A.play().catch(() => {}); }; A.addEventListener('seeked', fin, { once: true }); setTimeout(fin, 4000); } seekTo(Math.max(0, s - 1.5)); /* مثل يوتيوب: يكمل بصمت بلا رسالة */ } });
  /* ---------- 6) وضع اللطم ---------- */
  let ltV = 0; function latmTick() { if (!st.latm || A.paused || !live || !live.stems) return; const on = live.stems.on || 0, n = performance.now(); if (on > 0.3 && n - ltV > 200) { ltV = n; try { navigator.vibrate && navigator.vibrate(Math.round(18 + on * 30)); } catch (e) {} const f = g('plrFull'); f.classList.remove('lpf'); void f.offsetWidth; f.classList.add('lpf'); } }
  /* ---------- 7) وضع المجلس (مزامنة عدة أجهزة) ---------- */
  /* مزامنة الساعة مع خادم الموقع (دقة ~50ms): نرصد لحظة تغيّر الثانية في ترويسة Date */
  let CLK = { off: 0, ok: false, at: 0 };
  async function clockSync() { if (CLK.ok && Date.now() - CLK.at < 120000) return CLK.off; let prevD = null, prevMid = 0; const ests = [];
    for (let i = 0; i < 40 && ests.length < 3; i++) { const t0 = Date.now(); let r; try { r = await fetch('media/__clk?r=' + Math.random(), { method: 'HEAD', cache: 'no-store' }); } catch (e) { break; } const t1 = Date.now(), D = Date.parse(r.headers.get('date') || ''); if (!isFinite(D)) break; const mid = (t0 + t1) / 2;
      if (prevD != null && D > prevD && t1 - t0 < 400) ests.push(D - (prevMid + mid) / 2); prevD = D; prevMid = mid; await new Promise((z) => setTimeout(z, 60)); }
    if (ests.length) { ests.sort((x, y) => x - y); CLK = { off: ests[Math.floor(ests.length / 2)], ok: true, at: Date.now() }; } return CLK.off; }
  const sNow = () => Date.now() + CLK.off;
  const MJ = { on: false, host: false, code: '', un: null, push: 0, d: null, iv: 0, lastTrack: null, needTap: false };
  function mjUi() { const c = g('plrMj'); c.hidden = !MJ.on; if (MJ.on) c.querySelector('b').textContent = (MJ.host ? 'مجلسك ' : 'مجلس ') + MJ.code; try { toolsUi(); } catch (e) {} }
  function mjPush(force) { if (!MJ.on || !MJ.host) return; const n = Date.now(); if (!force && n - MJ.push < 4000) return; MJ.push = n; const db = fdb(), t = tracks[cur]; if (!db || !t) return; const u0 = fuid(); if (!u0) { toast('سجّل الدخول لتستضيف مجلساً'); mjStop(); return; }
    const o = { uid: u0, ended: false, q: Q.ids.slice(0, 300), qs: Q.src || '', track: t.id, pos: A.currentTime || 0, ref: sNow(), playing: !A.paused, rate: A.playbackRate || 1, at: firebase.firestore.FieldValue.serverTimestamp() };
    if (MJ.lastTrack !== t.id) { MJ.lastTrack = t.id; try { const L = linesOf(t).map((x) => ({ t: r2(x.t), l: x.l })); const s = JSON.stringify(L); o.ly = s.length < 90000 ? s : ''; } catch (e) { o.ly = ''; } }
    db.doc('majlis/' + MJ.code).set(o, { merge: true }).catch(() => toast('تعذّر تحديث المجلس — تحقق من تسجيل الدخول وقواعد Firebase')); }
  ['play', 'pause', 'seeked', 'ratechange'].forEach((ev) => A.addEventListener(ev, () => { if (MJ.on && MJ.host) setTimeout(() => mjPush(true), ev === 'seeked' ? 50 : 0); })); A.addEventListener('timeupdate', () => mjPush(false));
  function mjExpected() { const d = MJ.d; if (!d) return null; return d.pos + (d.playing ? Math.max(0, sNow() - d.ref) / 1000 * (d.rate || 1) : 0); }
  /* الضيف: نقيس الفرق بشكل متوسط (الآيفون يعطي وقتاً متذبذباً)، ونصحح بقفزة واحدة مدروسة بدل تغييرات متكررة تسبب التقطيع */
  const MJIOS = /iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  function mjTick() { if (!MJ.on || MJ.host || !MJ.d) return; const d = MJ.d, t = tracks[cur]; if (!t || t.id !== d.track || A.readyState < 2 || A.seeking) return; const rate = d.rate || 1;
    const e = mjExpected(), lat = ac && ac.outputLatency ? ac.outputLatency : 0, drift = e + lat - A.currentTime, now = Date.now();
    if (!d.playing) { MJ.dq = []; if (!A.paused) fadePause(); if (Math.abs(d.pos - A.currentTime) > 0.3) seekTo(d.pos); if (A.playbackRate !== rate) A.playbackRate = rate; return; }
    if (A.paused) { A.__keepPaused = false; A.__noAuto = false; MB.want = null; A.play().then(() => { MJ.needTap = false; }).catch(() => { if (!MJ.needTap) { MJ.needTap = true; snack('اضغط لتشغيل صوت المجلس', 'تشغيل', () => { A.play().catch(() => {}); }, 15000); } }); return; }
    if (now - (MJ.sk || 0) < 1600) return; /* ننتظر استقرار التشغيل بعد القفزة */
    const q = MJ.dq || (MJ.dq = []); q.push(drift); if (q.length > 5) q.shift(); if (q.length < 3 && Math.abs(drift) < 2) return; const m = q.slice().sort((x, y) => x - y)[q.length >> 1];
    if (MJ.lastSk && now - MJ.lastSk < 6000 && Math.abs(m) < 1.5) MJ.bias = Math.max(-1, Math.min(1, (MJ.bias || 0) + m * 0.7)); /* نتعلّم تأخير القفز بهذا الجهاز */
    const big = MJIOS ? 0.18 : 0.45;
    if (Math.abs(m) > big) { MJ.sk = MJ.lastSk = now; MJ.dq = []; if (A.playbackRate !== rate) A.playbackRate = rate; seekTo(Math.max(0, e + lat + (MJ.bias || 0))); return; }
    MJ.lastSk = 0;
    if (MJIOS) { if (A.playbackRate !== rate) A.playbackRate = rate; return; } /* سفاري يتقطّع مع تغيير السرعة */
    const want = Math.abs(m) > 0.06 ? rate * (1 + Math.max(-0.03, Math.min(0.03, m * 0.4))) : rate; if (Math.abs(A.playbackRate - want) > 0.004) { A.preservesPitch = true; A.playbackRate = want; } }
  function mjFollow(d) { if (!d) return; MJ.d = d; const t = byId(d.track); if (!t) return toast('القصيدة غير موجودة على هذا الجهاز');
    if (d.ly) { try { const L = JSON.parse(d.ly); if (L.length && !linesOf(t).length) { MJLY[t.id] = L; if (tracks[cur] === t) lyrBuild(); } } catch (e) {} }
    if (Array.isArray(d.q) && d.q.length) { const ids = d.q.filter((id) => byId(id)); if (ids.join() !== Q.ids.join()) { Q.ids = ids; Q.base = ids.slice(); Q.src = 'المجلس ' + MJ.code + (d.qs ? ' · ' + d.qs : ''); qSave(); } }
    if (tracks[cur] !== t) { resumeOk = false; A.__noAuto = !d.playing; if (!Q.ids.includes(t.id)) qFrom(t, tracks, 'المجلس ' + MJ.code); play(tracks.indexOf(t), true); }
    if (d.ly && tracks[cur] === t) lyrBuild(); mjTick(); }
  async function mjStart(host, code) { const db = fdb(); if (!db) return toast('وضع المجلس يحتاج اتصالاً بالإنترنت'); const keep = MJ.saved; mjStop({ quiet: true }); if (!host) { MB.want = null; MJ.dq = []; MJ.bias = 0; MJ.sk = 0; MJ.saved = keep || mjSnap(); try { localStorage.setItem(MJSK, JSON.stringify(MJ.saved)); } catch (e) {} } MJ.on = true; MJ.host = host; MJ.code = code; MJ.lastTrack = null; mjUi(); toast('جارٍ ضبط التوقيت…'); await clockSync();
    if (host) { mjPush(true); toast('بدأ المجلس — رمزك ' + code); MJ.sug = []; let first = true; try { MJ.sunsub = db.collection('majlis/' + code + '/sug').onSnapshot((s) => { MJ.sug = s.docs.map((d) => Object.assign({ id: d.id }, d.data())); if (!first && s.docChanges().some((c) => c.type === 'added')) toast('اقتراح جديد من الحضور (' + MJ.sug.length + ')'); first = false; }, () => {}); } catch (e) {} }
    else { MJ.un = db.doc('majlis/' + code).onSnapshot((s) => { if (!s.exists) { toast('لا يوجد مجلس بهذا الرمز'); mjStop(); return; } const d = s.data(); if (d.ended) { toast(MJ.d ? 'انتهى المجلس — رجعناك لقائمتك' : 'هذا المجلس غير نشط حالياً'); mjStop(); return; } if (typeof d.ref !== 'number') return; mjFollow(d); }, () => toast('تعذّر الاتصال بالمجلس')); MJ.iv = setInterval(mjTick, 400); toast('انضممت إلى المجلس ' + code); } }
  const MJSK = 'minbar.mj.saved';
  function mjSnap() { const t = tracks[cur]; let L = null; try { L = JSON.parse(localStorage.getItem(LASTK) || 'null'); } catch (e) {} return { q: JSON.parse(JSON.stringify(Q)), id: t ? t.id : (L && L.id) || '', t: t ? A.currentTime || 0 : (L && L.t) || 0 }; }
  function mjRestore() { const s = MJ.saved; MJ.saved = null; try { localStorage.removeItem(MJSK); } catch (e) {} if (!s) return; A.pause(); if (s.q && Array.isArray(s.q.ids)) { Object.assign(Q, s.q); qSave(); }
    const t = byId(s.id); if (!t) return; resumeOk = false; A.__noAuto = true; A.__keepPaused = true; play(tracks.indexOf(t), false); seekTo(s.t || 0); setTimeout(() => { A.__keepPaused = false; }, 15000); }
  /* لو انسدّ التطبيق أثناء المجلس: نرجّع قائمة الضيف وآخر قصيدة قبل الاستعادة */
  (function () { if (window.__mjCode) return; let s = null; try { s = JSON.parse(localStorage.getItem(MJSK) || 'null'); localStorage.removeItem(MJSK); } catch (e) {} if (!s) return; if (s.q && Array.isArray(s.q.ids)) { Object.assign(Q, s.q); qSave(); } if (s.id) try { localStorage.setItem(LASTK, JSON.stringify({ id: s.id, t: Math.floor(s.t || 0), at: Date.now() })); } catch (e) {} })();
  function mjStop(o) { o = o || {}; if (MJ.sunsub) { try { MJ.sunsub(); } catch (e) {} MJ.sunsub = null; } MJ.sug = []; const wasHost = MJ.on && MJ.host, wasGuest = MJ.on && !MJ.host, code = MJ.code; if (MJ.un) { try { MJ.un(); } catch (e) {} } clearInterval(MJ.iv); MJ.un = null; MJ.d = null; MJ.on = false; A.playbackRate = st.speed || 1; mjUi();
    if (o.quiet) return; if (wasHost) { const db = fdb(); if (db && fuid()) db.doc('majlis/' + code).set({ ended: true, playing: false }, { merge: true }).catch(() => {}); } if (wasGuest) mjRestore(); }
  /* رمز المجلس ثابت لكل مضيف (6 أرقام) + باركود QR للانضمام بالكاميرا */
  const MJK = 'minbar.mj.code'; const myCode = () => { let c = localStorage.getItem(MJK); if (!/^\d{6}$/.test(c || '')) { c = String(Math.floor(100000 + Math.random() * 900000)); try { localStorage.setItem(MJK, c); } catch (e) {} } return c; };
  const mjUrl = (c) => location.origin + location.pathname + '?mj=' + c;
  let qrLib = null; const qrLoad = () => qrLib || (qrLib = new Promise((res, rej) => { if (window.qrcode) return res(window.qrcode); const s = document.createElement('script'); s.src = 'https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js'; s.onload = () => res(window.qrcode); s.onerror = () => { qrLib = null; rej(); }; document.head.appendChild(s); }));
  async function qrDraw(cv, text) { try { const Q2 = await qrLoad(), q = Q2(0, 'M'); q.addData(text); q.make(); const n = q.getModuleCount(), S = 232, m = 2, cell = Math.floor(S / (n + m * 2)), off = Math.floor((S - cell * n) / 2); cv.width = cv.height = S; const x = cv.getContext('2d'); x.fillStyle = '#fff'; x.fillRect(0, 0, S, S); x.fillStyle = '#0b0b0b'; for (let r = 0; r < n; r++) for (let c = 0; c < n; c++) if (q.isDark(r, c)) x.fillRect(off + c * cell, off + r * cell, cell, cell); cv.classList.add('ok'); } catch (e) { cv.replaceWith(el('p', 'abp', 'تعذّر إنشاء الباركود دون اتصال. شارك الرمز أو الرابط.')); } }
  async function mjScan(done) { if (!('BarcodeDetector' in window)) return toast('المسح غير مدعوم هنا — استخدم كاميرا الهاتف أو أدخل الرمز'); let stream; try { stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } }); } catch (e) { return toast('يلزم السماح باستخدام الكاميرا'); }
    const det = new BarcodeDetector({ formats: ['qr_code'] }); let stop = false; const w = modal('مسح باركود المجلس', (bx, close) => { const v = document.createElement('video'); v.className = 'mjv'; v.playsInline = true; v.muted = true; v.srcObject = stream; v.play(); bx.appendChild(v); bx.appendChild(el('small', 'mdh', 'وجّه الكاميرا إلى الباركود الظاهر على جهاز المضيف')); const c = el('button', 'cn', 'إلغاء'); c.onclick = () => { stop = true; close(); }; bx.appendChild(c);
      const loop = async () => { if (stop) return; try { const r = await det.detect(v); const raw = r && r[0] && r[0].rawValue; const m = raw && /(?:mj=)?(\d{6})/.exec(raw); if (m) { stop = true; close(); done(m[1]); return; } } catch (e) {} setTimeout(loop, 250); }; setTimeout(loop, 400); });
    const obs = new MutationObserver(() => { if (!document.body.contains(w)) { stop = true; stream.getTracks().forEach((t) => t.stop()); obs.disconnect(); } }); obs.observe(root, { childList: true }); }
  /* اقتراحات الحضور */
  function mjSuggest(t) { const db = fdb(), u0 = fuid(); if (!db || !u0 || !MJ.on) return toast('سجّل الدخول وانضم لمجلس أولاً'); db.doc('majlis/' + MJ.code + '/sug/' + u0 + '_' + t.id).set({ track: t.id, by: u0, at: firebase.firestore.FieldValue.serverTimestamp() }).then(() => toast('أُرسل اقتراحك للمضيف')).catch(() => toast('تعذّر إرسال الاقتراح — تأكد أن قواعد Firebase محدَّثة')); }
  function mjSugList(bx, rebuild) { const L = (MJ.sug || []).filter((x) => byId(x.track)); if (!L.length) return; bx.appendChild(el('h4', 'qsec', 'اقتراحات الحضور (' + L.length + ')'));
    L.forEach((x) => { const t = byId(x.track), r = el('div', 'bkrow'); r.appendChild(el('span', '', t.title + (t.reciter ? ' — ' + t.reciter : '')));
      const add = btn('primary', 'التالي', () => { const c0 = tracks[cur]; if (c0) qEnsure(c0); Q.ids = Q.ids.filter((id) => id !== t.id); Q.ids.splice(c0 ? Q.ids.indexOf(c0.id) + 1 : Q.ids.length, 0, t.id); qSave(); mjPush(true); const db = fdb(); if (db) db.doc('majlis/' + MJ.code + '/sug/' + x.id).delete().catch(() => {}); MJ.sug = MJ.sug.filter((y) => y.id !== x.id); toast('أُضيفت كقصيدة تالية'); rebuild(); });
      const no = btn('', 'تجاهل', () => { const db = fdb(); if (db) db.doc('majlis/' + MJ.code + '/sug/' + x.id).delete().catch(() => {}); MJ.sug = MJ.sug.filter((y) => y.id !== x.id); rebuild(); }); r.append(add, no); bx.appendChild(r); }); }
  function mjMenu() {
    if (MJ.on) return modal('وضع المجلس', (bx, close) => {
      if (MJ.host) { const cv = document.createElement('canvas'); cv.className = 'mjqr'; bx.appendChild(cv); qrDraw(cv, mjUrl(MJ.code)); const cd = el('div', 'mjcode'); MJ.code.split('').forEach((d) => cd.appendChild(el('span', '', d))); bx.appendChild(cd); bx.appendChild(el('small', 'mdh', 'يمسح الحاضرون الباركود بكاميرا الهاتف، أو يُدخلون الرمز من «وضع المجلس»'));
        const sh = el('button', '', 'مشاركة رابط المجلس'); sh.onclick = async () => { const u = mjUrl(MJ.code); try { if (navigator.share) await navigator.share({ title: 'مجلس منبر', text: 'انضم إلى المجلس برمز ' + MJ.code, url: u }); else { await navigator.clipboard.writeText(u); toast('نُسخ الرابط'); } } catch (e) {} }; bx.appendChild(sh); }
      else bx.appendChild(el('p', 'abp', 'متصل بالمجلس ' + MJ.code + ' — يتبع جهازك المضيف تلقائياً.'));
      if (MJ.host) mjSugList(bx, () => { close(); mjMenu(); });
      const b = el('button', 'pri', MJ.host ? 'إنهاء المجلس' : 'مغادرة المجلس'); b.onclick = () => { mjStop(); close(); }; bx.appendChild(b); const c = el('button', 'cn', 'إغلاق'); c.onclick = close; bx.appendChild(c); });
    modal('وضع المجلس', (bx, close) => { bx.appendChild(el('p', 'abp', 'شغّل القصيدة نفسها على عدة أجهزة في اللحظة نفسها، لتصدح من أكثر من سماعة في المجلس.'));
      const h = el('button', 'pri', 'استضافة مجلس (رمزك ' + myCode() + ')'); h.onclick = () => { if (cur < 0) return toast('شغّل قصيدة أولاً'); close(); mjStart(true, myCode()); setTimeout(mjMenu, 300); }; bx.appendChild(h);
      if ('BarcodeDetector' in window) { const s = el('button', '', 'مسح باركود المجلس'); s.onclick = () => { close(); mjScan((c) => mjStart(false, c)); }; bx.appendChild(s); }
      const row = el('div', 'mjrow'); const inp = el('input', 'mdin'); inp.placeholder = 'أو أدخل رمز المجلس (6 أرقام)'; inp.inputMode = 'numeric'; inp.maxLength = 6; const j = el('button', '', 'انضمام'); j.onclick = () => { const c = inp.value.trim(); if (!/^\d{6}$/.test(c)) return inp.focus(); close(); mjStart(false, c); }; row.append(inp, j); bx.appendChild(row);
      const c = el('button', 'cn', 'إلغاء'); c.onclick = close; bx.appendChild(c); }); }
  (function () { try { const u = new URLSearchParams(location.search), c = u.get('mj'); if (/^\d{6}$/.test(c || '')) { history.replaceState(null, '', location.pathname); const go = () => { const lg = document.getElementById('login'); if (!tracks.length || (lg && lg.classList.contains('show'))) return setTimeout(go, 400); open(); mjStart(false, c); }; setTimeout(go, 800); } } catch (e) {} })();
  /* ---------- 8) التعرّف على القصيدة من الصوت المحيط ---------- */
  async function recognize() { if (!window.LYAI) return toast('محرك التعرّف غير محمّل'); let stream; try { stream = await navigator.mediaDevices.getUserMedia({ audio: true }); } catch (e) { return toast('يلزم السماح باستخدام الميكروفون'); }
    const chunks = [], mr = new MediaRecorder(stream); let stop = false, sec = 10; const w = modal('التعرّف على القصيدة', (bx, close) => { bx.appendChild(el('div', 'rcmic')); const p = el('p', 'abp', 'قرّب الهاتف من الصوت… ' + sec); p.id = 'plrRcP'; bx.appendChild(p); const c = el('button', 'cn', 'إلغاء'); c.onclick = () => { stop = true; try { mr.stop(); } catch (e) {} close(); }; bx.appendChild(c); });
    mr.ondataavailable = (e) => chunks.push(e.data); mr.start(); const iv = setInterval(() => { sec--; const p = document.getElementById('plrRcP'); if (p) p.textContent = sec > 0 ? 'قرّب الهاتف من الصوت… ' + sec : 'جارٍ التحليل…'; if (sec <= 0) { clearInterval(iv); try { mr.stop(); } catch (e) {} } }, 1000);
    await new Promise((r) => { mr.onstop = r; }); clearInterval(iv); stream.getTracks().forEach((x) => x.stop()); if (stop) return;
    try { const url = URL.createObjectURL(new Blob(chunks, { type: mr.mimeType || 'audio/webm' })); const segs = await window.LYAI.transcribe(url, 'fast', (s) => { const p = document.getElementById('plrRcP'); if (p) p.textContent = s; }, () => stop); URL.revokeObjectURL(url);
      const N = window.LYAI.norm, heard = N(segs.map((s) => s.text).join(' ')).split(/\s+/).filter((x) => x.length > 1); if (heard.length < 2) { w.remove(); return toast('لم يُسمع كلام واضح، حاول مرة أخرى'); }
      const STM = (w) => { for (const p of ['وال', 'بال', 'فال', 'كال', 'لل', 'ال']) if (w.startsWith(p) && w.length - p.length >= 2) { w = w.slice(p.length); break; } if (w.length > 3 && /^[وفب]/.test(w)) w = w.slice(1); return w; };
      const NEAR = (a, b) => { if (a === b) return true; if (a.length < 4 || b.length < 4 || Math.abs(a.length - b.length) > 1) return false; let i = 0, j = 0, e = 0; while (i < a.length && j < b.length) { if (a[i] === b[j]) { i++; j++; continue; } if (++e > 1) return false; if (a.length > b.length) i++; else if (b.length > a.length) j++; else { i++; j++; } } return e + (a.length - i) + (b.length - j) <= 1; };
      const H = heard.map(STM); let best = null;
      tracks.forEach((t) => { const L = linesOf(t), LS = L.map((ln) => N(ln.l).split(/\s+/).filter((x) => x.length > 1).map(STM)); L.forEach((ln, i) => { const win = [].concat(LS[i] || [], LS[i + 1] || [], LS[i + 2] || []); if (!win.length) return; let hit = 0, run = 0, bonus = 0; H.forEach((w) => { if (win.some((x) => NEAR(w, x))) { hit++; run++; if (run >= 2) bonus++; } else run = 0; }); const s = hit / H.length + bonus * 0.08; if (s >= 0.34 && (!best || s > best.s)) best = { s, t, ln }; }); });
      w.remove(); if (!best) return toast('لم نتعرّف على القصيدة في المكتبة'); qFrom(best.t, tracks); play(tracks.indexOf(best.t), true); const at = best.ln.t; if (isFinite(at)) seekTo(at); toast('تم التعرّف: ' + best.t.title);
    } catch (e) { w.remove(); toast('تعذّر التعرّف. يلزم اتصال بالإنترنت عند الاستخدام الأول'); } }
  /* ---------- 9) مناسبة اليوم (حسب التقويم الهجري) ---------- */
  function occasion() { let d, m; try { const f = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura', { day: 'numeric', month: 'numeric' }).formatToParts(new Date()); d = +f.find((x) => x.type === 'day').value; m = +f.find((x) => x.type === 'month').value; } catch (e) { return null; }
    const N = ['', 'الأولى', 'الثانية', 'الثالثة', 'الرابعة', 'الخامسة', 'السادسة', 'السابعة', 'الثامنة', 'التاسعة', 'العاشرة'];
    if (m === 1 && d <= 9) return { t: 'الليلة ' + N[d + 1] + ' من محرم', k: ['محرم', 'الحسين', 'عاشوراء', 'كربلاء'] }; if (m === 1 && d === 10) return { t: 'يوم عاشوراء', k: ['عاشوراء', 'الحسين', 'كربلاء', 'محرم'] }; if (m === 1 && d <= 13) return { t: 'أيام محرم', k: ['محرم', 'الحسين', 'كربلاء'] };
    if (m === 2 && d >= 15 && d <= 20) return { t: d === 20 ? 'زيارة الأربعين' : 'أيام المسير إلى الأربعين', k: ['الأربعين', 'زيارة', 'مشاية', 'الحسين'] }; if (m === 2 && d >= 27) return { t: 'ذكرى وفاة النبي ﷺ والإمام الحسن', k: ['النبي', 'الحسن', 'المصطفى'] };
    if ((m === 5 && d >= 12 && d <= 14) || (m === 6 && d >= 2 && d <= 3)) return { t: 'الأيام الفاطمية', k: ['فاطمة', 'الزهراء'] }; if (m === 9 && d >= 19 && d <= 21) return { t: 'ليالي القدر وشهادة الإمام علي', k: ['علي', 'أمير المؤمنين', 'الكوفة'] }; return null; }
  function occRender(body) { if (tab !== 'lib' || q || cat !== 'الكل') return; const o = occasion(); if (!o) return; const L = tracks.filter((t) => o.k.some((k) => [t.title, t.cat, t.poet].join(' ').includes(k))); const b = el('div', 'occ'); b.append(el('small', '', 'مناسبة اليوم'), el('b', '', o.t), el('span', '', L.length ? L.length + ' قصيدة مناسبة' : 'لا توجد قصائد مصنّفة لهذه المناسبة بعد'));
    if (L.length) { const p = el('button', ''); p.innerHTML = ic('play', 18) + '<span>تشغيل</span>'; p.onclick = () => { Q.base = L.map((x) => x.id); Q.ids = Q.base.slice(); Q.src = o.t; qSave(); play(tracks.indexOf(L[0]), true); }; b.appendChild(p); } body.insertBefore(b, body.firstChild); }
  /* ---------- 10) التقديم والترجيع بالضغط المستمر على التالي/السابق ---------- */
  function holdSeek(btn, dir) { let t0 = 0, iv = 0, held = false, st0 = 0;
    const down = (e) => { if (cur < 0) return; held = false; st0 = Date.now(); t0 = setTimeout(() => { held = true; scrS && scrS(); try { navigator.vibrate && navigator.vibrate(10); } catch (x) {} iv = setInterval(() => { const el2 = (Date.now() - st0) / 1000, s = el2 < 1.6 ? 2 : el2 < 3.5 ? 5 : 12; if (A.duration) A.currentTime = Math.max(0, Math.min(A.duration - 0.5, A.currentTime + dir * s)); }, 160); }, 380); };
    const up = () => { clearTimeout(t0); clearInterval(iv); if (held) { scrE && scrE(); btn._held = Date.now(); } held = false; };
    btn.addEventListener('pointerdown', down); ['pointerup', 'pointercancel', 'pointerleave'].forEach((n) => btn.addEventListener(n, up)); btn.addEventListener('contextmenu', (e) => e.preventDefault()); }
  holdSeek(g('plrNext'), 1); holdSeek(g('plrPrev'), -1);
  /* ---------- لوحة «أدوات القصيدة» ---------- */
  /* ---------- رفع القصائد (للمالك) ---------- */
  const CATS0 = ['لطميات', 'قصائد', 'مراثي', 'أناشيد', 'زيارات وأدعية'];
  async function idTok() { const u = firebase.auth().currentUser; if (!u) throw new Error('سجّل الدخول أولاً'); return u.getIdToken(); }
  function upPut(key, body, type, onp) { return idTok().then((tk) => new Promise((ok, no) => { const x = new XMLHttpRequest(); x.open('PUT', 'api/up/' + key); x.setRequestHeader('authorization', 'Bearer ' + tk); x.setRequestHeader('content-type', type || 'application/octet-stream');
      x.upload.onprogress = (e) => { if (e.lengthComputable && onp) onp(e.loaded / e.total); }; x.onload = () => { let j = {}; try { j = JSON.parse(x.responseText); } catch (e) {} if (x.status === 200 && j.ok) ok(j); else no(new Error(j.error || ('فشل الرفع (' + x.status + ')'))); }; x.onerror = () => no(new Error('انقطع الاتصال أثناء الرفع')); x.send(body); })); }
  async function upDelKey(key) { try { const tk = await idTok(); await fetch('api/up/' + key, { method: 'DELETE', headers: { authorization: 'Bearer ' + tk } }); } catch (e) {} }
  async function mgRun() { if (!confirm('نقل كل ملفات القصائد من KV إلى R2؟ لا تغلق التطبيق حتى ينتهي.')) return; let cur = '', c = 0, s = 0, bad = []; try { for (;;) { const tk = await idTok(); const r = await fetch('api/migrate' + (cur ? '?cursor=' + encodeURIComponent(cur) : ''), { method: 'POST', headers: { authorization: 'Bearer ' + tk } }); const j = await r.json(); if (!r.ok || !j.ok) throw new Error(j.error || r.status); c += j.copied; s += j.skipped; bad = bad.concat(j.failed); toast('نقل… نُسخ ' + c + ' · موجود ' + s); if (j.done) break; cur = j.cursor; } toast('انتهى النقل: نُسخ ' + c + ' · موجود ' + s + (bad.length ? ' · فشل ' + bad.length : '')); if (bad.length) console.log('migrate failed', bad); } catch (e) { toast('توقف النقل: ' + e.message); } }
  const keyOf = (url) => ((url || '').match(/media\/u\/(.+)$/) || [])[1];
  /* تحسين الغلاف تلقائياً: قصّ مربع، تكبير ناعم، توازن إضاءة وتباين، تشبّع خفيف وحدّة — حتى يناسب الفلاتر والعرض */
  function enhance(c) { const x = c.getContext('2d', { willReadFrequently: true }), W = c.width, H = c.height, im = x.getImageData(0, 0, W, H), d = im.data, n = W * H;
    const hs = [new Uint32Array(256), new Uint32Array(256), new Uint32Array(256)]; let lum = 0; for (let i = 0; i < d.length; i += 4) { hs[0][d[i]]++; hs[1][d[i + 1]]++; hs[2][d[i + 2]]++; lum += 0.2126 * d[i] + 0.7152 * d[i + 1] + 0.0722 * d[i + 2]; } lum /= n * 255;
    const pc = (h, q) => { let s = 0; for (let v = 0; v < 256; v++) { s += h[v]; if (s >= q * n) return v; } return 255; };
    const lo = Math.min(pc(hs[0], 0.005), pc(hs[1], 0.005), pc(hs[2], 0.005)), hi = Math.max(pc(hs[0], 0.995), pc(hs[1], 0.995), pc(hs[2], 0.995)), sc = Math.min(1.5, 255 / Math.max(40, hi - lo));
    const gm = Math.max(0.8, Math.min(1.25, Math.log(0.46) / Math.log(Math.max(0.05, Math.min(0.95, lum))))), LUT = new Uint8ClampedArray(256);
    for (let v = 0; v < 256; v++) LUT[v] = 255 * Math.pow(Math.max(0, Math.min(1, (v - lo) * sc / 255)), gm);
    for (let i = 0; i < d.length; i += 4) { let r = LUT[d[i]], g2 = LUT[d[i + 1]], b2 = LUT[d[i + 2]]; const l = 0.299 * r + 0.587 * g2 + 0.114 * b2, s = 1.08; d[i] = l + (r - l) * s; d[i + 1] = l + (g2 - l) * s; d[i + 2] = l + (b2 - l) * s; }
    /* حدّة (unsharp خفيف) */
    const src = new Uint8ClampedArray(d), k = 0.38;
    for (let y = 1; y < H - 1; y++) for (let x2 = 1; x2 < W - 1; x2++) { const o = (y * W + x2) * 4; for (let ch = 0; ch < 3; ch++) { const v = src[o + ch], bl = (src[o - 4 + ch] + src[o + 4 + ch] + src[o - W * 4 + ch] + src[o + W * 4 + ch]) / 4; d[o + ch] = v + (v - bl) * k; } }
    x.putImageData(im, 0, 0); }
  function coverJpg(file) { return new Promise((ok, no) => { const i = new Image(); i.onload = () => { const s = Math.min(i.naturalWidth, i.naturalHeight), out = s >= 1000 ? 1100 : Math.min(1000, Math.max(720, Math.round(s * 1.35))), c = document.createElement('canvas'); c.width = c.height = out; const x = c.getContext('2d'); x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high'; x.drawImage(i, (i.naturalWidth - s) / 2, (i.naturalHeight - s) / 2, s, s, 0, 0, out, out); URL.revokeObjectURL(i.src); try { enhance(c); } catch (e) {} c.toBlob((b) => b ? ok(b) : no(new Error('تعذّر تجهيز الغلاف')), 'image/jpeg', 0.9); }; i.onerror = () => no(new Error('صورة الغلاف غير صالحة')); i.src = URL.createObjectURL(file); }); }
  const durOf = (file) => new Promise((ok) => { const a = new Audio(); a.preload = 'metadata'; a.onloadedmetadata = () => { ok(isFinite(a.duration) ? Math.round(a.duration) : 0); URL.revokeObjectURL(a.src); }; a.onerror = () => ok(0); a.src = URL.createObjectURL(file); });
  /* كلمات جماعية: نص واحد لعدة قصائد (كل قصيدة تبدأ بسطر # العنوان) ← مطابقة بالعنوان ← ضبط تلقائي بالخلفية */
  function bulkLyrics() {
    modal('كلمات جماعية', (bx, close) => {
      bx.appendChild(el('p', 'hint', 'الصق عدة قصائد في مربع واحد. ابدأ كل قصيدة بسطر فيه # ثم العنوان، وتحته الأبيات (سطر لكل بيت). يُطابَق العنوان مع قصائدك ثم تُضبط الكلمات تلقائياً بالخلفية.'));
      const ta = el('textarea', 'mdin'); ta.rows = 9; ta.placeholder = '# يا سبع الدجيل\nبيت\nبيت\n\n# خط الشعائر\nبيت\nبيت'; bx.appendChild(ta);
      const out = el('div', 'bkout'); bx.appendChild(out); let found = [];
      const bg = (s) => { s = window.LYAI ? window.LYAI.norm(s).replace(/\s/g, '') : String(s).replace(/\s/g, ''); const m = new Map(); for (let i = 0; i < s.length - 1; i++) { const k = s.slice(i, i + 2); m.set(k, (m.get(k) || 0) + 1); } return [m, Math.max(1, s.length - 1)]; };
      const dice = (a, b) => { const [A, na] = bg(a), [B, nb] = bg(b); let x = 0; A.forEach((v, k) => { x += Math.min(v, B.get(k) || 0); }); return 2 * x / (na + nb); };
      const parse = () => { const blocks = []; let cu = null; ta.value.split(/\r?\n/).forEach((ln) => { const s = ln.trim(); if (/^#/.test(s)) { cu = { title: s.replace(/^#+\s*/, ''), lines: [] }; blocks.push(cu); } else if (s && cu) cu.lines.push(s); }); return blocks.filter((b) => b.title && b.lines.length); };
      const scan = () => { out.textContent = ''; found = []; const bl = parse(); if (!bl.length) return;
        bl.forEach((b) => { let best = null, bs = 0; tracks.forEach((t) => { const d = dice(b.title, t.title || ''); if (d > bs) { bs = d; best = t; } }); const ok = best && bs >= 0.72, has = ok && linesOf(best).length;
          const r = el('div', 'bkrow' + (ok ? '' : ' bad'), (ok ? (has ? '↻ ' : '✓ ') : '✕ ') + b.title + (ok ? ' ← ' + best.title + (has ? ' (له كلمات، ستُستبدل)' : '') : ' — ما لقيت قصيدة بهذا الاسم') + ' · ' + b.lines.length + ' بيت'); out.appendChild(r); if (ok) found.push({ t: best, lines: b.lines }); }); };
      ta.addEventListener('input', () => { clearTimeout(ta._t); ta._t = setTimeout(scan, 400); });
      const go = btn('primary', 'ضبط تلقائي بالخلفية', () => { if (!found.length) return toast('ما اكو قصائد مطابقة'); found.forEach((f) => aqAdd(f.t.id, f.lines)); toast('أُضيف ' + found.length + ' قصيدة لطابور الضبط'); close(); }); go.classList.add('wide'); bx.appendChild(go);
      bx.appendChild(btn('wide', 'إلغاء', close));
    });
  }
  /* حقل باسم مع اقتراحات من الأسماء السابقة (الرواديد/الشعراء) + إمكانية كتابة اسم جديد */
  function pickIn(par, ph, v, k) { const w = el('div', 'pkw'), i = el('input', 'mdin'); i.placeholder = ph; i.value = v || ''; const ch = el('div', 'pkc'); w.append(i, ch); par.appendChild(w);
    const all = [...new Set(tracks.map((x) => (x[k] || '').trim()).filter(Boolean))].sort((a, b) => tracks.filter((x) => x[k] === b).length - tracks.filter((x) => x[k] === a).length);
    const draw = () => { ch.textContent = ''; const q = CMF.norm(i.value.trim()); const L = all.filter((n) => !q || CMF.norm(n).includes(q)); L.slice(0, 10).forEach((n) => { const b = el('button', n === i.value.trim() ? 'on' : '', n); b.type = 'button'; b.onmousedown = (e) => e.preventDefault(); b.onclick = () => { i.value = n; draw(); }; ch.appendChild(b); });
      if (i.value.trim() && !all.includes(i.value.trim())) ch.appendChild(el('span', 'pkn', '＋ اسم جديد: ' + i.value.trim())); ch.hidden = !ch.children.length || document.activeElement !== i; };
    i.addEventListener('input', draw); i.addEventListener('focus', draw); i.addEventListener('blur', () => setTimeout(() => { ch.hidden = true; }, 150)); draw(); return i; }
  /* اسم القصيدة من اسم الملف: بدون الامتداد والأرقام والأقواس والجودة واسم الرادود */
  function cleanName(fn, rec) { let s = fn.replace(/\.[^.]+$/, '').replace(/[_]+/g, ' ');
    s = s.replace(/[\(\[\{（【][^\)\]\}）】]*[\)\]\}）】]/g, ' ').replace(/\b\d+\s*k(bps)?\b/gi, ' ').replace(/[0-9٠-٩]+/g, ' ');
    const names = [...new Set([rec, ...tracks.map((x) => x.reciter)].filter(Boolean).map((x) => x.trim()))]; names.forEach((n) => { s = s.split(n).join(' '); const p = n.split(/\s+/); if (p.length > 1) s = s.split(p.slice(-1)[0]).join(' '); });
    s = s.replace(/[\-–—_\.\|•،,:؛]+/g, ' ').replace(/\b(mp3|m4a|aac|ogg|wav|hq|hd|official|audio)\b/gi, ' ').replace(/\s+/g, ' ').trim(); return s || fn.replace(/\.[^.]+$/, ''); }
  /* ================= رفع إصدار كامل: الرادود والتصنيف والغلاف مشتركة، ولكل قصيدة اسمها وشاعرها وكلماتها ================= */
  function albumUp() { if (!isOwner()) return toast('الإضافة متاحة للمالك فقط');
    modal('رفع إصدار كامل', (bx, close) => {
      bx.appendChild(el('p', 'hint', 'اختر كل ملفات الإصدار مرة واحدة. الرادود والتصنيف والغلاف مشتركة، وتعدّل لكل قصيدة اسمها وشاعرها وكلماتها فقط.'));
      const inp = (ph, v) => { const i = el('input', 'mdin'); i.placeholder = ph; i.value = v || ''; bx.appendChild(i); return i; };
      const als = Object.values(ALB).sort((a, b) => (b.at || 0) - (a.at || 0)); const ab = el('select', 'mdin'); const opt = (v, n) => { const o = el('option', '', n); o.value = v; ab.appendChild(o); };
      opt('+', '＋ إصدار جديد'); als.forEach((a) => opt(a.id, 'إضافة إلى: ' + a.name)); bx.appendChild(ab);
      const anw = inp('اسم الإصدار *'); ab.onchange = () => { anw.hidden = ab.value !== '+'; };
      const cnt = {}; tracks.forEach((x) => { if (x.reciter) cnt[x.reciter] = (cnt[x.reciter] || 0) + 1; }); const topR = Object.keys(cnt).sort((a, b) => cnt[b] - cnt[a])[0] || '';
      const re = pickIn(bx, 'الرادود *', topR, 'reciter');
      const cats = [...new Set(CATS0.concat(tracks.map((x) => x.cat).filter(Boolean)))]; const ca = el('select', 'mdin'); cats.forEach((c) => { const o = el('option', '', c); o.value = c; ca.appendChild(o); }); bx.appendChild(ca);
      const fl = (lbl, acc, multi) => { const w = el('label', 'upf'); const i = el('input'); i.type = 'file'; i.accept = acc; i.multiple = !!multi; const sp = el('span', '', lbl); w.append(i, sp); bx.appendChild(w); return i; };
      const cv = fl('غلاف الإصدار', 'image/*'); cv.onchange = () => { cv.nextSibling.textContent = cv.files[0] ? cv.files[0].name : 'غلاف الإصدار'; cv.parentNode.classList.toggle('on', !!cv.files[0]); };
      const au = fl('ملفات الصوت * (اختر الكل مرة واحدة)', 'audio/*', true);
      const list = el('div', 'abl'); bx.appendChild(list); let rows = [];
      au.onchange = () => { const fs = [...au.files].sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true })); au.nextSibling.textContent = fs.length ? fs.length + ' ملف صوت' : 'ملفات الصوت *'; au.parentNode.classList.toggle('on', !!fs.length); list.textContent = ''; rows = fs.map((f, i) => {
          const r = el('div', 'abr'), hd = el('div', 'abh'); hd.append(el('b', '', String(i + 1)), el('span', '', f.name + ' · ' + (f.size / 1048576).toFixed(1) + ' م.ب')); const stt = el('em', '', ''); hd.appendChild(stt);
          const ti = el('input', 'mdin'); ti.placeholder = 'اسم القصيدة *'; ti.value = cleanName(f.name, re.value.trim());
          const lb = el('button', 'abk', 'كلمات هذه القصيدة ＋'); lb.type = 'button'; const ly = el('textarea', 'mdin lyta'); ly.rows = 5; ly.hidden = true; ly.placeholder = 'الصق كلمات القصيدة — كل بيت بسطر (اختياري)'; lb.onclick = () => { ly.hidden = !ly.hidden; if (!ly.hidden) ly.focus(); }; ly.oninput = () => { const n = ly.value.split(/\n+/).filter((x) => x.trim()).length; lb.textContent = n ? 'الكلمات ✓ (' + n + ' بيت)' : 'كلمات هذه القصيدة ＋'; lb.classList.toggle('on', !!n); };
          r.append(hd, ti); const po = pickIn(r, 'الشاعر', '', 'poet'); r.append(lb, ly); list.appendChild(r); return { f, ti, po, ly, stt, r, done: false }; }); };
      const pr = el('div', 'upp'); pr.innerHTML = '<i></i><span></span>'; pr.hidden = true; bx.appendChild(pr); const setP = (f, m) => { pr.hidden = false; pr.firstChild.style.width = Math.round(f * 100) + '%'; pr.lastChild.textContent = m; };
      const go = el('button', 'pri', 'رفع الإصدار'); go.type = 'button'; bx.appendChild(go); const cn = el('button', 'cn', 'إغلاق'); cn.type = 'button'; cn.onclick = () => { close(); fsLoad(); }; bx.appendChild(cn);
      let alb = '';
      go.onclick = async () => { const Rr = re.value.trim(); if (!Rr) return toast('اكتب اسم الرادود'); const todo = rows.filter((x) => !x.done); if (!todo.length) return toast('اختر ملفات الصوت'); if (todo.some((x) => !x.ti.value.trim())) return toast('اكتب اسم كل قصيدة');
        const db = fdb(); if (!db) return toast('لا يوجد اتصال'); go.disabled = true; let okN = 0, bad = 0;
        try { if (!alb) { if (ab.value === '+') { const n = anw.value.trim(); if (!n) throw new Error('اكتب اسم الإصدار'); alb = 'al' + Date.now().toString(36); await db.collection('albums').doc(alb).set({ name: n, reciter: Rr, at: Date.now() }); ALB[alb] = { id: alb, name: n, reciter: Rr }; } else alb = ab.value; }
          if (cv.files[0] && !cv._up) { setP(0, 'رفع غلاف الإصدار…'); const b = await coverJpg(cv.files[0]); const r = await upPut('c/' + alb + Date.now().toString(36) + '.jpg', b, 'image/jpeg'); await db.collection('albums').doc(alb).set({ cover: r.url.replace(/^\//, '') }, { merge: true }); cv._up = true; }
        } catch (e) { go.disabled = false; setP(0, e.message || 'فشل'); return toast(e.message || 'فشل'); }
        const base = Date.now();
        for (let i = 0; i < rows.length; i++) { const x = rows[i]; if (x.done) continue; const f = x.f, nm = x.ti.value.trim(), tot = rows.length;
          if (f.size > 24 * 1048576) { x.stt.textContent = '✕ أكبر من 24 م.ب'; x.r.classList.add('bad'); bad++; continue; }
          try { x.stt.textContent = '…'; const id = 'k' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6), ext = ((f.name.split('.').pop() || 'mp3').toLowerCase().match(/^(mp3|m4a|aac|ogg|opus|wav)$/) || ['mp3'])[0];
            const r = await upPut('a/' + id + Date.now().toString(36) + '.' + ext, f, f.type || 'audio/mpeg', (p) => setP((i + p * 0.9) / tot, '(' + (i + 1) + '/' + tot + ') ' + nm + ' — ' + Math.round(p * 100) + '%'));
            const o = { title: nm, reciter: Rr, poet: x.po.value.trim(), cat: ca.value, upd: Date.now(), at: base + i, album: alb, audio: r.url.replace(/^\//, ''), size: r.size, dur: await durOf(f) }; let EN = null; try { EN = await energyOf(f); o.sample = bestSegE(EN); } catch (e) {}
            const lines = x.ly.value.split(/\n+/).map((q) => q.replace(/\s+/g, ' ').trim()).filter(Boolean); if (lines.length) { o.lyrics = estLines(lines, o.dur || 300, EN); o.lyrEst = true; o.lyrRaw = x.ly.value.trim(); o.lyrQ = true; /* يُضبط تلقائياً على الخادم */ } else o.lyrics = [];
            await db.collection('tracks').doc(id).set(o, { merge: true });
            x.done = true; x.stt.textContent = '✓ تم'; x.r.classList.add('ok'); [x.ti, x.po, x.ly].forEach((q) => { q.disabled = true; }); okN++;
          } catch (e) { x.stt.textContent = '✕ فشل'; x.r.classList.add('bad'); bad++; } }
        setP(1, 'تم رفع ' + okN + (bad ? ' · فشل ' + bad + ' (اضغط الرفع مرة ثانية لإعادة المحاولة)' : '')); toast(bad ? 'اكتمل مع ' + bad + ' فشل' : 'تم رفع الإصدار كاملاً'); go.disabled = false; go.textContent = bad ? 'إعادة رفع الفاشلة' : 'تم'; if (!bad) { close(); fsLoad(); } };
    }); }
  /* كلمات إصدار: كل قصائد الإصدار بمكان واحد، تلصق كلمات كل وحدة وتُضبط تلقائياً بالخلفية */
  function albumLyrics() { if (!isOwner()) return toast('متاح للمالك فقط');
    modal('إدارة الإصدار', (bx, close) => {
      const als = Object.values(ALB).sort((a, b) => (b.at || 0) - (a.at || 0)); if (!als.length) { bx.appendChild(el('p', 'hint', 'لا توجد إصدارات بعد.')); bx.appendChild(btn('wide', 'إغلاق', close)); return; }
      const ab = el('select', 'mdin'); als.forEach((a) => { const o = el('option', '', a.name); o.value = a.id; ab.appendChild(o); }); bx.appendChild(ab);
      bx.appendChild(el('p', 'hint', 'عدّل اسم كل قصيدة وشاعرها مباشرة، واضغط «الكلمات» لتلصق كلماتها (كل بيت بسطر) — تُضبط تلقائياً بالخلفية.'));
      const list = el('div', 'abl'); bx.appendChild(list); let rows = [];
      const draw = () => { list.textContent = ''; rows = tracks.filter((x) => x.album === ab.value).sort((a, b) => (a.at || 0) - (b.at || 0)).map((t, i) => { const cu = linesOf(t), orig = cu.map((x) => x.l).join('\n');
          const r = el('div', 'abr'), hd = el('div', 'abh'); hd.append(el('b', '', String(i + 1)), el('span', '', t.title + (t.poet ? ' · ' + t.poet : ''))); const stt = el('em', '', cu.length ? '✓ ' + cu.length + ' بيت' : 'بدون كلمات'); hd.appendChild(stt); if (!cu.length) r.classList.add('bad');
          const ti = el('input', 'mdin'); ti.placeholder = 'اسم القصيدة'; ti.value = t.title || ''; const lb = el('button', 'abk', 'الكلمات'); lb.type = 'button';
          const ly = el('textarea', 'mdin lyta'); ly.rows = 6; ly.hidden = true; ly.value = orig; ly.placeholder = 'الصق كلمات القصيدة — كل بيت بسطر'; lb.onclick = () => { ly.hidden = !ly.hidden; if (!ly.hidden) ly.focus(); }; ly.oninput = () => { stt.textContent = ly.value.trim() !== orig.trim() ? '● معدّلة' : (cu.length ? '✓ ' + cu.length + ' بيت' : 'بدون كلمات'); };
          r.append(hd, ti); const po = pickIn(r, 'الشاعر', t.poet || '', 'poet'); r.append(lb, ly); list.appendChild(r); return { t, ly, orig, ti, po }; }); if (!rows.length) list.appendChild(el('p', 'hint', 'لا توجد قصائد بهذا الإصدار.')); };
      ab.onchange = draw; draw();
      const go = el('button', 'pri', 'حفظ التعديلات'); go.type = 'button'; bx.appendChild(go); const cn = el('button', 'cn', 'إغلاق'); cn.type = 'button'; cn.onclick = close; bx.appendChild(cn);
      go.onclick = async () => { const ch = rows.filter((x) => x.ly.value.trim() && x.ly.value.trim() !== x.orig.trim()), mt = rows.filter((x) => x.ti.value.trim() && (x.ti.value.trim() !== (x.t.title || '') || x.po.value.trim() !== (x.t.poet || ''))); if (!ch.length && !mt.length) return toast('ما اكو تغيير'); const db = fdb(); if (!db) return toast('لا يوجد اتصال'); go.disabled = true; let n = 0, m = 0;
        for (const x of mt) { try { await db.collection('tracks').doc(x.t.id).set({ title: x.ti.value.trim(), poet: x.po.value.trim(), upd: Date.now() }, { merge: true }); m++; } catch (e) {} }
        for (const x of ch) { try { const lines = x.ly.value.split(/\n+/).map((q) => q.replace(/\s+/g, ' ').trim()).filter(Boolean), est = estLines(lines, x.t.dur || 300, null); await db.collection('tracks').doc(x.t.id).set({ lyrics: est, lyrEst: true, lyrRaw: x.ly.value.trim(), lyrQ: true, upd: Date.now() }, { merge: true }); try { await applyGlobal(x.t, est, true); } catch (e) {} n++; } catch (e) {} }
        toast((m ? 'عُدّلت بيانات ' + m + ' قصيدة' : '') + (m && n ? ' · ' : '') + (n ? 'حُفظت كلمات ' + n + ' — تُضبط تلقائياً خلال نصف ساعة تقريباً' : '')); close(); fsLoad(); };
    }); }
  function upMenu(t) { if (!isOwner()) return toast('الإضافة متاحة للمالك فقط'); const ed = !!t;
    modal(ed ? 'تعديل القصيدة' : 'إضافة قصيدة', (bx, close) => {
      if (!ed) { bx.appendChild(btn('wide primary', 'رفع إصدار كامل (عدة قصائد مرة واحدة)', () => { close(); albumUp(); })); bx.appendChild(btn('wide', 'إدارة إصدار (أسماء وشعراء وكلمات قصائده)', () => { close(); albumLyrics(); })); const bk = btn('wide', 'كلمات جماعية لعدة قصائد', () => { close(); bulkLyrics(); }); bx.appendChild(bk); }
      const inp = (ph, v) => { const i = el('input', 'mdin'); i.placeholder = ph; i.value = v || ''; bx.appendChild(i); return i; };
      /* اختيار من القائمة (الرواديد/الشعراء السابقين) مع إمكانية كتابة اسم جديد */
      const pick = (ph, v, k) => { const w = el('div', 'pkw'), i = el('input', 'mdin'); i.placeholder = ph + ' — اختر أو اكتب اسماً جديداً'; i.value = v || ''; const ch = el('div', 'pkc'); w.append(i, ch); bx.appendChild(w);
        const all = [...new Set(tracks.map((x) => (x[k] || '').trim()).filter(Boolean))].sort((a, b) => tracks.filter((x) => x[k] === b).length - tracks.filter((x) => x[k] === a).length);
        const draw = () => { ch.textContent = ''; const q = CMF.norm(i.value.trim()); const L = all.filter((n) => !q || CMF.norm(n).includes(q)); L.slice(0, 12).forEach((n) => { const b = el('button', n === i.value.trim() ? 'on' : '', n); b.type = 'button'; b.onmousedown = (e) => e.preventDefault(); b.onclick = () => { i.value = n; draw(); }; ch.appendChild(b); });
          if (i.value.trim() && !all.includes(i.value.trim())) ch.appendChild(el('span', 'pkn', '＋ اسم جديد: ' + i.value.trim())); ch.hidden = !ch.children.length; };
        i.addEventListener('input', draw); draw(); return i; };
      const ti = inp('اسم القصيدة *', t && t.title), re = pick('الرادود *', t && t.reciter, 'reciter'), po = pick('الشاعر', t && t.poet, 'poet');
      const cats = [...new Set(CATS0.concat(tracks.map((x) => x.cat).filter(Boolean)))]; const ca = el('select', 'mdin'); cats.forEach((c) => { const o = el('option', '', c); o.value = c; ca.appendChild(o); }); ca.value = (t && t.cat) || cats[0]; bx.appendChild(ca);
      const als = Object.values(ALB).sort((a, b) => (b.at || 0) - (a.at || 0)); const ab = el('select', 'mdin'); const opt = (v, n) => { const o = el('option', '', n); o.value = v; ab.appendChild(o); };
      opt('', 'بدون إصدار'); als.forEach((a) => opt(a.id, 'الإصدار: ' + a.name + (a.reciter ? ' — ' + a.reciter : ''))); opt('+', '＋ إصدار جديد'); ab.value = (t && t.album && ALB[t.album]) ? t.album : ''; bx.appendChild(ab);
      const anw = el('input', 'mdin'); anw.placeholder = 'اسم الإصدار الجديد *'; anw.hidden = true; bx.appendChild(anw);
      const fl = (lbl, acc) => { const w = el('label', 'upf'); const i = el('input'); i.type = 'file'; i.accept = acc; const s = el('span', '', lbl); w.append(i, s); i.onchange = () => { s.textContent = i.files[0] ? i.files[0].name + ' · ' + (i.files[0].size / 1048576).toFixed(1) + ' م.ب' : lbl; w.classList.toggle('on', !!i.files[0]); }; bx.appendChild(w); return i; };
      const acv = fl('غلاف الإصدار', 'image/*'); const au = fl(ed ? 'استبدال ملف الصوت (اختياري)' : 'ملف الصوت * (حتى 24 م.ب)', 'audio/*'), cv = fl('', 'image/*');
      const abUi = () => { const v = ab.value, a = ALB[v]; anw.hidden = v !== '+'; acv.parentNode.hidden = !v; const s1 = acv.nextSibling; if (!acv.files[0]) s1.textContent = v === '+' ? 'غلاف الإصدار (يُستخدم لكل قصائده)' : (a && a.cover ? 'استبدال غلاف الإصدار (اختياري)' : 'غلاف الإصدار (اختياري)');
        const s2 = cv.nextSibling; if (!cv.files[0]) s2.textContent = v ? 'غلاف خاص بهذه القصيدة (اختياري — وإلا غلاف الإصدار)' : (ed ? 'استبدال الغلاف (اختياري)' : 'صورة الغلاف (اختياري)'); }; ab.onchange = abUi; abUi();
      const lyT = el('textarea', 'mdin lyta'); lyT.rows = 6; lyT.placeholder = 'كلمات القصيدة (اختياري) — الصق النص كاملاً، كل بيت بسطر.\nتظهر فوراً بتوقيت تقريبي، ثم تُضبط تلقائياً بالخلفية.'; const curL = t ? linesOf(t) : []; lyT.value = curL.map((x) => x.l).join('\n'); bx.appendChild(lyT); const lyOrig = lyT.value.trim();
      const smI = inp('بداية العينة (اختياري، مثل 1:25)', t && t.sample ? fmt(t.sample.a) : '');
      const pr = el('div', 'upp'); pr.innerHTML = '<i></i><span></span>'; pr.hidden = true; bx.appendChild(pr);
      const setP = (f, m) => { pr.hidden = false; pr.firstChild.style.width = Math.round(f * 100) + '%'; pr.lastChild.textContent = m; };
      const go = el('button', 'pri', ed ? 'حفظ التعديلات' : 'رفع القصيدة'); go.type = 'button'; bx.appendChild(go); const cn = el('button', 'cn', 'إلغاء'); cn.type = 'button'; cn.onclick = close; bx.appendChild(cn);
      go.onclick = async () => { const T = ti.value.trim(), Rr = re.value.trim(); if (!T || !Rr) return toast('اكتب اسم القصيدة والرادود'); const af = au.files[0], cf = cv.files[0];
        if (!ed && !af) return toast('اختر ملف الصوت'); if (af && af.size > 24 * 1048576) return toast('ملف الصوت أكبر من 24 ميغابايت — صغّر جودته أولاً');
        const db = fdb(); if (!db) return toast('لا يوجد اتصال'); go.disabled = true; cn.disabled = true;
        let EN = null; const id = ed ? t.id : 'k' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6), o = { title: T, reciter: Rr, poet: po.value.trim(), cat: ca.value, upd: Date.now() }; const old = [];
        try { if (af) { const ext = ((af.name.split('.').pop() || 'mp3').toLowerCase().match(/^(mp3|m4a|aac|ogg|opus|wav)$/) || ['mp3'])[0], v = Date.now().toString(36); setP(0, 'رفع الصوت…');
            const r = await upPut('a/' + id + v + '.' + ext, af, af.type || 'audio/mpeg', (f) => setP(f * 0.85, 'رفع الصوت… ' + Math.round(f * 100) + '%')); if (ed && keyOf(t.audio)) old.push(keyOf(t.audio)); o.audio = r.url.replace(/^\//, ''); o.size = r.size; o.dur = await durOf(af); setP(0.86, 'تحليل الصوت…'); try { EN = await energyOf(af); o.sample = bestSegE(EN); } catch (e) {} }
          const mt = /^(\d+):(\d{1,2})$/.exec(smI.value.trim()); if (mt) o.sample = { a: +mt[1] * 60 + +mt[2], d: (o.sample && o.sample.d) || (t && t.sample && t.sample.d) || 45, man: 1 };
          let alb = ab.value; if (alb === '+') { const n = anw.value.trim(); if (!n) throw new Error('اكتب اسم الإصدار الجديد'); alb = 'al' + Date.now().toString(36); await db.collection('albums').doc(alb).set({ name: n, reciter: Rr, at: Date.now() }); ALB[alb] = { id: alb, name: n, reciter: Rr }; ab.value = alb; }
          const acf = acv.files[0]; if (alb && acf) { setP(0.86, 'رفع غلاف الإصدار…'); const b = await coverJpg(acf); const r = await upPut('c/' + alb + Date.now().toString(36) + '.jpg', b, 'image/jpeg'); if (keyOf(ALB[alb] && ALB[alb].cover)) old.push(keyOf(ALB[alb].cover)); await db.collection('albums').doc(alb).set({ cover: r.url.replace(/^\//, '') }, { merge: true }); }
          o.album = alb || '';
          if (cf) { setP(0.88, 'رفع الغلاف…'); const b = await coverJpg(cf); const r = await upPut('c/' + id + Date.now().toString(36) + '.jpg', b, 'image/jpeg'); if (ed && keyOf(t.ownCover)) old.push(keyOf(t.ownCover)); o.cover = r.url.replace(/^\//, ''); }
          const lyN = lyT.value.trim(), lyCh = lyN !== lyOrig || (af && lyN); let lyLines = null;
          if (lyCh && lyN) { lyLines = lyN.split(/\n+/).map((s) => s.replace(/\s+/g, ' ').trim()).filter(Boolean); o.lyrics = estLines(lyLines, o.dur || (t && t.dur) || 300, EN); o.lyrEst = true; o.lyrRaw = lyN; o.lyrQ = true; } else if (!ed) o.lyrics = [];
          setP(0.95, 'حفظ البيانات…'); if (!ed) o.at = Date.now(); await db.collection('tracks').doc(id).set(o, { merge: true }); old.forEach(upDelKey);
          if (lyLines) { if (ed) { try { await applyGlobal(Object.assign({}, t), o.lyrics, true); } catch (e) {} } }
          setP(1, 'تم'); toast(ed ? 'حُفظت التعديلات' : 'أُضيفت القصيدة'); close(); fsLoad(); } catch (e) { go.disabled = false; cn.disabled = false; setP(0, e.message || 'فشل الرفع'); toast(e.message || 'فشل الرفع'); } };
    }); }
  /* أقوى 45 ثانية في القصيدة (طاقة صوتية + بداية بيت) لتكون العينة */
  /* طاقة الصوت لكل ثانية (للعينة والتوقيت التقريبي للكلمات) */
  async function energyOf(file) { const ab = await file.arrayBuffer(); const oc = new OfflineAudioContext(1, 1, 8000), bf = await oc.decodeAudioData(ab), d = bf.getChannelData(0), sr = bf.sampleRate;
    const sec = Math.floor(d.length / sr), e = new Float32Array(sec); for (let i = 0; i < sec; i++) { let s = 0; const a = Math.floor(i * sr), b = Math.floor((i + 1) * sr); for (let j = a; j < b; j += 8) s += d[j] * d[j]; e[i] = Math.sqrt(s / ((b - a) / 8)); } return e; }
  function bestSegE(e) { const sec = e.length, D = Math.min(45, Math.max(20, Math.round(sec * 0.25))); let best = -1, bi = Math.round(sec * 0.3); for (let i = Math.round(sec * 0.08); i + D < sec * 0.95; i++) { let s = 0; for (let j = i; j < i + D; j++) s += e[j]; if (s > best) { best = s; bi = i; } }
    let lo = bi; for (let j = bi; j > Math.max(0, bi - 6); j--) if (e[j] < e[lo]) lo = j; return { a: lo, d: D }; }
  /* توقيت تقريبي فوري: نوزّع الأبيات على منطقة الإنشاد حسب طول كل بيت */
  function estLines(lines, dur, e) { let a = Math.min(8, dur * 0.03), b = dur - Math.min(6, dur * 0.02);
    if (e && e.length > 10) { let mx = 0; for (const v of e) mx = Math.max(mx, v); const th = mx * 0.3; let i = 0; while (i < e.length && e[i] < th) i++; let j = e.length - 1; while (j > i && e[j] < th) j--; a = Math.max(0, i - 0.5); b = Math.max(a + lines.length * 2, j); }
    const w = lines.map((l) => Math.max(6, l.length)), W = w.reduce((s, x) => s + x, 0); let t = a; return lines.map((l, k) => { const r = { t: r2(t), l }; t += (b - a) * w[k] / W; return r; }); }
  /* ================= طابور الضبط التلقائي بالخلفية (على جهاز المالك) ================= */
  const AQK = 'minbar.lyr.queue', LOWK = 'minbar.lyr.low'; let aqBusy = false, aqStopF = false;
  function aqAdd(id, lines) { const q = jget(AQK, []).filter((x) => x.id !== id); q.push({ id, lines, at: Date.now() }); jset(AQK, q); aqUi(); setTimeout(aqRun, 1500); }
  function aqUi() { const q = jget(AQK, []), c = g('plrAq'); if (!c) return; c.hidden = !q.length || !isOwner(); if (!q.length) return; c.querySelector('b').textContent = aqBusy ? 'ضبط الكلمات… (' + q.length + ')' : 'بانتظار ضبط الكلمات (' + q.length + ')'; c.classList.toggle('on', aqBusy); }
  async function aqRun() { if (aqBusy || aiBusy || !isOwner() || document.hidden || !A.paused || !window.LYAI) return; const q = jget(AQK, []); if (!q.length) return aqUi(); const it = q[0], t = byId(it.id); if (!t) { jset(AQK, q.slice(1)); return aqRun(); }
    /* لا يشتغل الضبط التلقائي (ثقيل على الذاكرة) والمحرر مفتوح، وإذا أسقط الصفحة مرتين على نفس القصيدة تُترك للضبط اليدوي */
    if (!g('plrLys').hidden) { setTimeout(aqRun, 20000); return; }
    { const c = jget('minbar.aq.crash', {}); if (c.id === it.id && c.n >= 2) { jset(AQK, q.slice(1)); jset('minbar.aq.crash', {}); toast('تعذّر الضبط التلقائي لـ«' + t.title + '» على هذا الجهاز — اضبطها يدوياً'); return aqRun(); } jset('minbar.aq.crash', { id: it.id, n: (c.id === it.id ? c.n : 0) + 1 }); }
    aqBusy = true; aqStopF = false; aqUi(); const PK = 'minbar.asr.part.' + t.id + '.good';
    try { const part = { get: () => JSON.parse(localStorage.getItem(PK) || 'null'), put: (o) => { try { localStorage.setItem(PK, JSON.stringify(o)); } catch (e) {} } };
      const segs = await window.LYAI.transcribe(t.audio, 'good', (s, v) => { const c = g('plrAq'); if (c) c.querySelector('small').textContent = Math.round(v * 100) + '% · ' + t.title; }, () => aqStopF || document.hidden, part);
      try { localStorage.removeItem(PK); localStorage.setItem(ASRK(t, 'good'), JSON.stringify(segs.map((x) => [r2(x.t0), r2(x.t1), x.text]))); } catch (e) {}
      const r = window.LYAI.alignP(it.lines, segs, { base: 0.35 }), rows = r.out.filter((x) => !x.del && x.l && x.l.trim()), arr = rows.map((x) => ({ t: r2(x.t), l: x.l.trim() })), low = rows.map((x, k) => x.conf < 0.45 ? k : -1).filter((k) => k >= 0);
      await applyGlobal(t, arr, true); const db = fdb(); if (db && t.fs) { try { await db.collection('tracks').doc(t.id).set({ lyrEst: false }, { merge: true }); } catch (e) {} }
      const lw = jget(LOWK, {}); if (low.length) lw[t.id] = low; else delete lw[t.id]; jset(LOWK, lw); jset(AQK, jget(AQK, []).filter((x) => x.id !== it.id));
      snack('ضُبطت كلمات «' + t.title + '»' + (low.length ? ' — ' + low.length + ' بيت يحتاج مراجعة' : ' بدقة جيدة'), low.length ? 'مراجعة' : 'تشغيل', () => lyrReview(t), 10000);
    } catch (e) { if (!(e && e.message === 'cancel')) { const q2 = jget(AQK, []); const x = q2.find((y) => y.id === it.id); if (x) { x.fail = (x.fail || 0) + 1; if (x.fail > 2) q2.splice(q2.indexOf(x), 1); jset(AQK, q2); } } }
    aqBusy = false; jset('minbar.aq.crash', {}); try { window.LYAI.free(); } catch (e) {} aqUi(); if (!aqStopF) setTimeout(aqRun, 3000); }
  function lyrReview(t) { qFrom(t, tracks); play(tracks.indexOf(t), true); setTimeout(() => { openFull(); g('plrLyT').querySelectorAll('button').forEach((x) => x.classList.toggle('on', x.dataset.k === 'edit')); openLys(); }, 400); }
  document.addEventListener('visibilitychange', () => { if (!document.hidden) setTimeout(aqRun, 2000); });
  A.addEventListener('play', () => { if (aqBusy) { aqStopF = true; } }); /* لا نزاحم التشغيل بالتحليل الثقيل */
  setTimeout(() => { aqUi(); aqRun(); }, 6000);
  async function upDel(t) { if (!confirm('حذف «' + t.title + '» نهائياً؟')) return; const db = fdb(); try { await db.collection('tracks').doc(t.id).delete(); [keyOf(t.audio), keyOf(t.ownCover)].filter(Boolean).forEach(upDelKey); toast('حُذفت القصيدة'); fsLoad(); } catch (e) { toast('تعذّر الحذف: ' + (e.code || e.message)); } }
  g('plrAddB').onclick = () => upMenu(null);
  g('plrAq').onclick = () => { const q = jget(AQK, []); sheet((bx, close) => { bx.appendChild(el('b', 'sht', 'ضبط الكلمات التلقائي')); bx.appendChild(el('p', 'hint', 'يعمل على جهازك وأنت داخل التطبيق، قصيدة بعد قصيدة. الكلمات تظهر للجميع بتوقيت تقريبي حتى ينتهي الضبط.'));
      const L = el('div', 'shl'); q.forEach((x, i) => { const t = byId(x.id); if (!t) return; const b = el('div', 'sha'); b.innerHTML = ic(i === 0 && aqBusy ? 'spark' : 'timer', 20) + '<span></span>'; b.lastChild.textContent = t.title + (i === 0 && aqBusy ? ' — جارٍ' : '') + (x.fail ? ' (محاولة ' + (x.fail + 1) + ')' : ''); L.appendChild(b); }); bx.appendChild(L);
      const lw = jget(LOWK, {}), rv = Object.keys(lw).map(byId).filter(Boolean); if (rv.length) { bx.appendChild(el('b', 'sht', 'تحتاج مراجعة')); const L2 = el('div', 'shl'); rv.forEach((t) => { const b = el('button', 'sha'); b.type = 'button'; b.innerHTML = ic('text', 20) + '<span></span>'; b.lastChild.textContent = t.title + ' — ' + lw[t.id].length + ' بيت'; b.onclick = () => { close(); lyrReview(t); }; L2.appendChild(b); }); bx.appendChild(L2); }
      const r = el('div', 'row'); r.appendChild(btn('', aqBusy ? 'إيقاف مؤقت' : 'تشغيل الآن', () => { if (aqBusy) { aqStopF = true; toast('سيتوقف بعد المقطع الحالي'); } else aqRun(); close(); })); r.appendChild(btn('', 'مسح الطابور', () => { if (confirm('مسح طابور الضبط؟ الكلمات تبقى بتوقيتها التقريبي.')) { aqStopF = true; jset(AQK, []); aqUi(); close(); } })); bx.appendChild(r); }); };
  try { firebase.auth().onAuthStateChanged(() => { g('plrAddB').hidden = !isOwner(); fsLoad(); }); } catch (e) {}
  /* ================= المكتبة: القصائد · الإصدارات · الرواديد ================= */
  let libV = 'home', libSel = null; /* libSel: {k:'alb'|'rec', id} */
  const durOfT = (t) => { try { return (JSON.parse(localStorage.getItem(DUK) || '{}'))[t.id] || t.dur || 0; } catch (e) { return t.dur || 0; } };
  function libTabs(body) {
    const w = el('div', 'libtabs'), hd = g('plrLt'); hd.textContent = ''; hd.hidden = false; [['home', 'الرئيسية'], ['all', 'القصائد'], ['alb', 'الإصدارات'], ['rec', 'الرواديد']].forEach(([k, n]) => { const b = el('button', libV === k ? 'on' : '', n); b.type = 'button'; b.onclick = () => { libV = k; libSel = null; render(); }; w.appendChild(b); });
    hd.appendChild(w);
  }
  function trackRow(t, list) {
    const r = el('div', 'trow' + (cur >= 0 && tracks[cur] === t ? ' on' : '')), cv = el('div', 'plrcov'); coverEl(t, cv);
    const m = el('div', 'trm'); m.append(el('b', '', t.title), el('small', '', [t.reciter, durOfT(t) ? fmt(durOfT(t)) : ''].filter(Boolean).join(' · ')));
    const mo = el('button', 'tmo'); mo.type = 'button'; mo.innerHTML = ic('more', 20); mo.onclick = (e) => { e.stopPropagation(); qMenu(t); };
    r.append(cv, m, mo); r.onclick = () => { if (r._lp) { r._lp = 0; return; } qFrom(t, list); play(tracks.indexOf(t), true); }; lpMenu(r, t); return r;
  }
  function groupPage(body, title, sub, coverT, list) {
    const hd = el('div', 'grph'); const bk = el('button', 'ib'); bk.type = 'button'; bk.innerHTML = ic('back', 20); bk.onclick = () => { libSel = null; render(); };
    const cv = el('div', 'plrcov'); if (coverT) coverEl(coverT, cv); const tx = el('div', 'grt'); tx.append(el('b', '', title), el('small', '', sub));
    const pa = el('button', 'btn primary small', 'تشغيل الكل'); pa.type = 'button'; pa.onclick = () => { if (!list.length) return; qFrom(list[0], list); play(tracks.indexOf(list[0]), true); };
    const sh = el('button', 'btn small', 'عشوائي'); sh.type = 'button'; sh.onclick = () => { if (!list.length) return; const t = list[Math.floor(Math.random() * list.length)]; if (!st.shuf) g('plrShuf').click(); qFrom(t, list); play(tracks.indexOf(t), true); };
    const ac2 = el('div', 'row'); ac2.append(pa, sh); hd.append(bk, cv, tx, ac2); body.appendChild(hd);
    const L = el('div', 'tlist'); list.forEach((t) => L.appendChild(trackRow(t, list))); body.appendChild(L);
  }
  function albOf(t) { return t.album ? t.album : ''; }
  function libRender(body) {
    libTabs(body); if (libV === 'home') { homeRender(body); return true; }
    if (libV === 'alb') {
      const map = new Map(); tracks.forEach((t) => { const k = albOf(t); if (!k) return; if (!map.has(k)) map.set(k, []); map.get(k).push(t); });
      if (libSel && libSel.k === 'alb') { const L = map.get(libSel.id) || []; const a = ALB[libSel.id] || {}; groupPage(body, a.name || 'إصدار', [a.reciter, L.length + ' قصيدة'].filter(Boolean).join(' · '), L[0], L); return true; }
      if (!map.size) { body.appendChild(el('div', 'hint cen', 'لا توجد إصدارات بعد')); return true; }
      const G = el('div', 'albgrid'); [...map.entries()].sort((a, b) => ((ALB[b[0]] || {}).at || 0) - ((ALB[a[0]] || {}).at || 0)).forEach(([k, L]) => { const a = ALB[k] || {}; const c = el('button', 'albc'); c.type = 'button'; const cv = el('div', 'plrcov'); coverEl(L[0], cv); c.append(cv, el('b', '', a.name || 'إصدار'), el('small', '', (a.reciter || L[0].reciter || '') + ' · ' + L.length + ' قصيدة')); c.onclick = () => { libSel = { k: 'alb', id: k }; render(); g('plrBody').scrollTop = 0; }; G.appendChild(c); });
      body.appendChild(G); return true;
    }
    if (libV === 'rec') {
      const map = new Map(); tracks.forEach((t) => { const k = (t.reciter || 'غير معروف').trim(); if (!map.has(k)) map.set(k, []); map.get(k).push(t); });
      if (libSel && libSel.k === 'rec') { const L = map.get(libSel.id) || []; const na = new Set(L.map(albOf).filter(Boolean)).size; groupPage(body, libSel.id, L.length + ' قصيدة' + (na ? ' · ' + na + ' إصدار' : ''), L[0], L); const fb = el('button', 'btn small' + (isFol(libSel.id) ? '' : ' primary'), isFol(libSel.id) ? '✓ تتابعه' : '＋ متابعة'); fb.type = 'button'; const id0 = libSel.id; fb.onclick = () => folToggle(id0); const rw = body.querySelector('.grph .row'); if (rw) rw.appendChild(fb); return true; }
      const R2 = el('div', 'reclist'); [...map.entries()].sort((a, b) => b[1].length - a[1].length).forEach(([k, L]) => { const r = el('button', 'recr'); r.type = 'button'; const cv = el('div', 'plrcov'); coverEl(L[0], cv); const tx = el('div', 'trm'); tx.append(el('b', '', k), el('small', '', L.length + ' قصيدة')); r.append(cv, tx); r.insertAdjacentHTML('beforeend', ic('fwd', 18)); r.onclick = () => { libSel = { k: 'rec', id: k }; render(); g('plrBody').scrollTop = 0; }; R2.appendChild(r); });
      body.appendChild(R2); return true;
    }
    return false;
  }
  /* ================= قائمة إجراءات القصيدة (ورقة سفلية) ================= */
  function sheet(build) { const old = document.getElementById('plrSh'); if (old) old.remove(); const w = el('div', 'shw'); w.id = 'plrSh'; const bx = el('div', 'shb'); bx.appendChild(el('i', 'gr')); w.appendChild(bx);
    const close = () => { w.classList.add('out'); setTimeout(() => w.remove(), 220); }; w.onclick = (e) => { if (e.target === w) close(); }; build(bx, close); root.appendChild(w); requestAnimationFrame(() => w.classList.add('in')); return close; }
  function qMenu(t) {
    sheet((bx, close) => {
      const hd = el('div', 'shh'), cv = el('div', 'plrcov'); coverEl(t, cv); const tx = el('div', 'trm'); tx.append(el('b', '', t.title), el('small', '', [t.reciter, t.poet].filter(Boolean).join(' · '))); hd.append(cv, tx); bx.appendChild(hd);
      const L = el('div', 'shl'); bx.appendChild(L); const cur0 = tracks[cur];
      const act = (icn, n, f, cls) => { const b = el('button', 'sha' + (cls ? ' ' + cls : '')); b.type = 'button'; b.innerHTML = ic(icn, 20) + '<span></span>'; b.lastChild.textContent = n; b.onclick = () => { close(); f(); }; L.appendChild(b); };
      const q2 = el('div', 'shq'); const qb = (icn, n, f) => { const b = el('button', ''); b.type = 'button'; b.innerHTML = ic(icn, 20) + '<span></span>'; b.lastChild.textContent = n; b.onclick = () => { close(); f(); }; q2.appendChild(b); };
      qb('play', 'تشغيل الآن', () => { qFrom(t, view.length ? view : tracks); play(tracks.indexOf(t), true); });
      if (cur0 && cur0 !== t) { qb('queue', 'التالي', () => { qEnsure(cur0); Q.ids = Q.ids.filter((id) => id !== t.id); Q.ids.splice(Q.ids.indexOf(cur0.id) + 1, 0, t.id); qSave(); toast('ستُشغَّل بعد الحالية'); });
        qb('plist', 'آخر القائمة', () => { qEnsure(cur0); Q.ids = Q.ids.filter((id) => id !== t.id); Q.ids.push(t.id); qSave(); toast('أُضيفت إلى قائمة التشغيل'); }); }
      bx.insertBefore(q2, L);
      act('heart', st.fav.includes(t.id) ? 'إزالة من المفضلة' : 'إضافة للمفضلة', () => { tog(t.id); render(); });
      act('plist', 'إضافة إلى قائمة', () => plPick(t));
      act('share', 'مشاركة', () => shareSheet(t, 0));
      if (MJ.on && !MJ.host) act('users', 'اقتراح للمجلس', () => mjSuggest(t));
      if (offHas(t.id)) act('down', 'حذف التنزيل', () => offDel(t)); else act('down', 'تنزيل للاستماع بدون إنترنت', () => offSave(t));
      if (t.album && ALB[t.album]) act('lib', 'الذهاب للإصدار', () => { goLib('alb', t.album); });
      if (t.reciter) act('users', 'الذهاب للرادود', () => { goLib('rec', t.reciter.trim()); });
      if (t.fs && isOwner()) { act('text', 'تعديل بيانات القصيدة', () => upMenu(t)); act('x', 'حذف القصيدة', () => upDel(t), 'dang'); }
    });
  }
  function goLib(k, id) { tab = 'lib'; document.querySelectorAll('.plrnav button').forEach((b) => b.classList.toggle('on', b.dataset.t === 'lib')); libV = k; libSel = { k, id }; if (!g('plrFull').hidden) g('plrClose').click(); render(); g('plrBody').scrollTop = 0; }
  function plPick(t) { const a = pls(); sheet((bx, close) => { bx.appendChild(el('b', 'sht', 'إضافة «' + t.title + '» إلى')); const L = el('div', 'shl'); bx.appendChild(L);
      const nb = el('button', 'sha'); nb.type = 'button'; nb.innerHTML = ic('plus', 20) + '<span>قائمة جديدة</span>'; nb.onclick = () => { close(); modal('قائمة جديدة', (b2, c2) => { const inp = el('input', 'mdin'); inp.placeholder = 'اسم القائمة'; b2.appendChild(inp); const ok = el('button', 'pri', 'إنشاء وإضافة'); ok.type = 'button'; ok.onclick = () => { const n = inp.value.trim(); if (!n) return; const a2 = pls(); a2.unshift({ id: 'p' + Date.now().toString(36), name: n, ids: [t.id], at: Date.now() }); plsSet(a2); c2(); toast('أُنشئت القائمة'); }; b2.appendChild(ok); setTimeout(() => inp.focus(), 50); }); }; L.appendChild(nb);
      a.forEach((p) => { const b = el('button', 'sha'); b.type = 'button'; b.innerHTML = ic('plist', 20) + '<span></span>'; b.lastChild.textContent = p.name + ' (' + p.ids.length + ')'; b.onclick = () => { close(); const a2 = pls(), x = a2.find((y) => y.id === p.id); if (!x) return; if (x.ids.includes(t.id)) return toast('موجودة في القائمة'); x.ids.push(t.id); plsSet(a2); toast('أُضيفت إلى «' + x.name + '»'); }; L.appendChild(b); }); }); }
  /* ================= المشاركة: رابط + رمز QR لمن بجانبك + صورة اللحظة ================= */
  function shareSheet(t, at) { const url = location.origin + location.pathname + '?p=' + encodeURIComponent(t.id) + (at ? '&at=' + Math.floor(at) : '');
    sheet((bx, close) => { bx.appendChild(el('b', 'sht', 'مشاركة «' + t.title + '»' + (at ? ' من ' + fmt(at) : '')));
      const qw = el('div', 'shqr'), cv = document.createElement('canvas'); qw.append(cv, el('small', '', 'لمن بجانبك: يمسح الرمز بكاميرته ويفتح القصيدة مباشرة')); bx.appendChild(qw); qrDraw(cv, url);
      const L = el('div', 'shq'); const b = (icn, n, f) => { const x = el('button', ''); x.type = 'button'; x.innerHTML = ic(icn, 20) + '<span></span>'; x.lastChild.textContent = n; x.onclick = f; L.appendChild(x); };
      b('share', 'إرسال', async () => { try { await navigator.share({ title: t.title, text: t.title + (t.reciter ? ' — ' + t.reciter : '') + ' | منبر', url }); } catch (e) { if (e && e.name !== 'AbortError') { try { await navigator.clipboard.writeText(url); toast('نُسخ الرابط'); } catch (x) {} } } });
      b('check', 'نسخ الرابط', async () => { try { await navigator.clipboard.writeText(url); toast('نُسخ الرابط'); } catch (e) { toast(url); } });
      if (tracks[cur] === t) b('color', 'صورة اللحظة', () => { close(); shareMoment(); });
      bx.appendChild(L); }); }
  /* ================= عينات: أجمل مقطع من كل قصيدة، تمرير عمودي ================= */
  const SA = new Audio(); SA.preload = 'auto'; let smpOn = false, smpIdx = -1, smpList = [], smpObs = null, smpRaf = 0;
  function smpSeg(t) { const d0 = durOfT(t) || 300; if (t.sample && typeof t.sample.a === 'number') return { a: t.sample.a, d: Math.min(55, t.sample.d || 45) };
    const env = ENV.get(t.id); let a = d0 * 0.3, D = Math.min(45, Math.max(20, d0 * 0.25));
    if (env && env.length) { const B = env.length, w = Math.max(2, Math.round(D / d0 * B)); let best = -1, bi = 0; for (let i = Math.round(B * 0.08); i + w < B * 0.95; i++) { let s = 0; for (let j = i; j < i + w; j++) s += env[j]; if (s > best) { best = s; bi = i; } } a = bi / B * d0; }
    const h = rxList && rxTrack === t && rxList.length > 6 ? rxList.slice().sort((x, y) => x.t - y.t) : null; if (h) { let bb = 0, bt = a; for (let i = 0; i < h.length; i++) { let n = 0; for (let j = i; j < h.length && h[j].t < h[i].t + D; j++) n++; if (n > bb) { bb = n; bt = h[i].t; } } a = bt; }
    const L = linesOf(t); if (L.length) { const ln = L.filter((x) => x.t <= a + 2).pop(); if (ln && a - ln.t < 6) a = ln.t; } return { a: Math.max(0, a), d: D }; }
  const SMF = 'F10';
  function smpOpen() { if (smpOn) return; const L = tracks.filter((t) => t.audio); if (!L.length) return toast('لا توجد قصائد بعد'); if (!A.paused) fadePause(); smpOn = true; try { document.fonts.load('700 40px ' + SMF, 'قصيدة'); } catch (e) {}
    smpList = L.slice().sort((a, b) => (b.at || 0) - (a.at || 0)); const w = g('plrSmp'); w.hidden = false; const sc = g('plrSmpL'); sc.textContent = '';
    smpList.forEach((t, i) => { const it = el('section', 'smi'); it.dataset.i = i; it.innerHTML = '<div class="smbg"></div><div class="smgr"></div><div class="smcol"><div class="plrcov"></div><b class="smt"></b><small class="sms"></small><div class="smly"></div></div><div class="smside"></div><div class="smft"><div class="smtop"><i></i><b class="smtt"></b></div><button class="smgo" type="button"></button></div><div class="smpz" hidden></div>';
      const bg = it.querySelector('.smbg'), cu = cov(t); if (cu) bg.style.backgroundImage = 'url("' + cu + '")'; else { const c = gOf(t); bg.style.background = `radial-gradient(120% 90% at 30% 20%,${c[0]},${c[1]})`; }
      it.style.setProperty('--smh', String(hash(t.id) % 360));
      coverEl(t, it.querySelector('.smcol .plrcov')); it.querySelector('.smt').textContent = t.title; it.querySelector('.sms').textContent = [t.reciter, t.poet].filter(Boolean).join(' · ');
      const bar = it.querySelector('.smtop'), tt = bar.querySelector('.smtt'), mm = (x) => { x = Math.max(0, Math.round(x)); return String(Math.floor(x / 60)).padStart(2, '0') + ':' + String(x % 60).padStart(2, '0'); };
      const bf = (e) => { const r = bar.getBoundingClientRect(); return Math.max(0, Math.min(1, (e.clientX - r.left) / (r.width || 1))); };
      bar.onclick = (e) => e.stopPropagation();
      bar.onpointerdown = (e) => { if (smpIdx !== i) return; e.stopPropagation(); bar.setPointerCapture(e.pointerId); bar.classList.add('drag'); bar._f = bf(e); const sg = smpSeg(t); tt.textContent = mm(bar._f * sg.d) + ' / ' + mm(sg.d); bar.firstChild.style.transform = 'scaleX(' + bar._f + ')'; };
      bar.onpointermove = (e) => { if (!bar.classList.contains('drag')) return; bar._f = bf(e); const sg = smpSeg(t); tt.textContent = mm(bar._f * sg.d) + ' / ' + mm(sg.d); bar.firstChild.style.transform = 'scaleX(' + bar._f + ')'; };
      bar.onpointerup = bar.onpointercancel = () => { if (!bar.classList.contains('drag')) return; bar.classList.remove('drag'); const sg = smpSeg(t); try { SA.currentTime = sg.a + bar._f * sg.d; } catch (e) {} };
      const go = it.querySelector('.smgo'); go.innerHTML = ic('play', 18) + '<span>استمع كاملة</span>'; go.onclick = (e) => { e.stopPropagation(); smpClose(); qFrom(t, tracks); play(tracks.indexOf(t), true); };
      const sd = it.querySelector('.smside'); const sb = (icn, n, f) => { const b = el('button', 'smb'); b.type = 'button'; b.innerHTML = '<i>' + ic(icn, 24) + '</i><span></span>'; b.lastChild.textContent = n; b.onclick = (e) => { e.stopPropagation(); f(b); }; sd.appendChild(b); };
      sb('heart', 'أعجبني', (b) => { b.classList.toggle('on'); const on = b.classList.contains('on'); if (on !== st.fav.includes(t.id)) tog(t.id); if (on) { toast('أُضيفت للمفضلة'); b.animate([{ transform: 'scale(1)' }, { transform: 'scale(1.35)' }, { transform: 'scale(1)' }], { duration: 350 }); } });
      if (st.fav.includes(t.id)) sd.firstChild.classList.add('on');
      sb('dl', 'تنزيل', () => smpRender(t)); sb('share', 'مشاركة', () => shareSheet(t, smpSeg(t).a)); sb('more', 'خيارات', () => qMenu(t));
      it.onclick = () => { if (smpIdx !== i) return; const pz = it.querySelector('.smpz'); if (SA.paused) { SA.play().catch(() => {}); pz.hidden = true; } else { SA.pause(); pz.hidden = false; } };
      sc.appendChild(it); });
    smpObs = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting && e.intersectionRatio > 0.6) smpGo(+e.target.dataset.i); }), { root: sc, threshold: [0.6] });
    sc.querySelectorAll('.smi').forEach((x) => smpObs.observe(x)); sc.scrollTop = 0; smpGo(0); smpLoop(); }
  /* سطر الكلمات: يدخل كلمةً كلمة (صعود + وضوح من الضباب)، ويتلوّن تدريجياً مع الإنشاد، ويخرج للأعلى بتلاشٍ */
  function smpLine(box, text) { [...box.children].forEach((o) => { o.classList.add('out'); setTimeout(() => o.remove(), 450); }); if (!text) return null;
    const ln = el('p', 'sl'); text.split(/\s+/).forEach((w, i) => { const s = el('span', '', w); s.style.animationDelay = (i * 70) + 'ms'; ln.appendChild(s); ln.appendChild(document.createTextNode(' ')); }); box.appendChild(ln); return ln; }
  function smpGo(i) { if (i === smpIdx) return; smpIdx = i; const t = smpList[i]; if (!t) return; const sg = smpSeg(t); SA.__seg = sg; SA.__t = t;
    g('plrSmpL').querySelectorAll('.smi').forEach((x) => x.classList.toggle('act', +x.dataset.i === i)); const it = g('plrSmpL').children[i]; it.querySelector('.smpz').hidden = true;
    const src = new URL(t.audio, location.href).href; if (SA.src !== src) SA.src = t.audio; const go = () => { try { SA.currentTime = sg.a; } catch (e) {} SA.play().catch(() => { it.querySelector('.smpz').hidden = false; }); };
    if (SA.readyState >= 1) go(); else SA.addEventListener('loadedmetadata', go, { once: true });
    envLoad(t); const nx = smpList[i + 1]; if (nx) { const l = document.createElement('link'); l.rel = 'prefetch'; l.href = nx.audio; document.head.appendChild(l); } }
  function smpLoop() { cancelAnimationFrame(smpRaf); if (!smpOn) return; smpRaf = requestAnimationFrame(smpLoop); const t = SA.__t, sg = SA.__seg; if (!t || !sg) return; const it = g('plrSmpL').children[smpIdx]; if (!it) return;
    const p = (SA.currentTime - sg.a) / sg.d; if (SA.currentTime >= sg.a + sg.d || SA.currentTime < sg.a - 1) { try { SA.currentTime = sg.a; } catch (e) {} }
    if (!it.querySelector('.smtop').classList.contains('drag')) it.querySelector('.smtop i').style.transform = 'scaleX(' + Math.max(0, Math.min(1, p)).toFixed(4) + ')';
    const L = linesOf(t), now = SA.currentTime; let k = -1; for (let j = 0; j < L.length; j++) { if (L[j].t <= now + 0.12) k = j; else break; }
    if (it._k !== k) { it._k = k; it._ln = smpLine(it.querySelector('.smly'), k >= 0 ? L[k].l : ''); }
    const ln = it._ln; if (ln && k >= 0) { const end = L[k + 1] ? L[k + 1].t : L[k].t + 5, f = Math.max(0, Math.min(1, (now - L[k].t) / Math.max(0.8, (end - L[k].t) * 0.85))), ws = ln.querySelectorAll('span'), n = Math.ceil(f * ws.length);
      if (ln._n !== n) { ln._n = n; ws.forEach((s, i) => s.classList.toggle('on', i < n)); } } }
  function smpClose() { if (!smpOn) return; smpOn = false; SA.pause(); cancelAnimationFrame(smpRaf); try { smpObs && smpObs.disconnect(); } catch (e) {} g('plrSmp').hidden = true; g('plrSmpL').textContent = ''; smpIdx = -1;
    document.querySelectorAll('.plrnav button').forEach((b) => b.classList.toggle('on', b.dataset.t === tab)); }
  document.addEventListener('visibilitychange', () => { if (document.hidden && smpOn) SA.pause(); });
  /* تنزيل العينة فيديو بعلامة منبر المائية (يُسجَّل بزمنه الحقيقي) */
  let smpBusy = false;
  async function smpRender(t) { if (smpBusy) return toast('جارٍ تجهيز مقطع آخر'); if (!window.MediaRecorder || !HTMLCanvasElement.prototype.captureStream) return toast('جهازك لا يدعم تصدير الفيديو من المتصفح');
    smpBusy = true; const sg = smpSeg(t); const pz = el('div', 'smrend'); pz.innerHTML = '<b>تجهيز المقطع…</b><div class="bar"><i></i></div><small>يُسجَّل المقطع بزمنه الحقيقي (' + Math.round(sg.d) + ' ثانية)</small>'; const cx = el('button', 'btn small', 'إلغاء'); let stop = false; cx.onclick = () => { stop = true; }; pz.appendChild(cx); g('plrSmp').appendChild(pz); SA.pause();
    let actx = null;
    try { const W = 720, H = 1280, c = document.createElement('canvas'); c.width = W; c.height = H; const x = c.getContext('2d');
      const im = await new Promise((ok) => { const cu = cov(t); if (!cu) return ok(null); const i2 = new Image(); i2.crossOrigin = 'anonymous'; i2.onload = () => ok(i2); i2.onerror = () => ok(null); i2.src = cu; });
      const logo = await new Promise((ok) => { const i2 = new Image(); i2.onload = () => ok(i2); i2.onerror = () => ok(null); i2.src = 'icons/brand-mark.png'; });
      const ab = await (await fetch(t.audio)).arrayBuffer(); actx = new (window.AudioContext || window.webkitAudioContext)(); const buf = await actx.decodeAudioData(ab);
      const dst = actx.createMediaStreamDestination(), src = actx.createBufferSource(); src.buffer = buf; const gn = actx.createGain(); src.connect(gn); gn.connect(dst); gn.gain.setValueAtTime(0, actx.currentTime); gn.gain.linearRampToValueAtTime(1, actx.currentTime + 0.6); gn.gain.setValueAtTime(1, actx.currentTime + sg.d - 1.2); gn.gain.linearRampToValueAtTime(0, actx.currentTime + sg.d);
      const vs = c.captureStream(30), ms = new MediaStream([vs.getVideoTracks()[0], dst.stream.getAudioTracks()[0]]);
      const mime = ['video/mp4;codecs=avc1.42E01E,mp4a.40.2', 'video/mp4', 'video/webm;codecs=vp9,opus', 'video/webm;codecs=vp8,opus', 'video/webm'].find((m) => MediaRecorder.isTypeSupported(m)) || '';
      const rec = new MediaRecorder(ms, mime ? { mimeType: mime, videoBitsPerSecond: 3500000 } : {}), parts = []; rec.ondataavailable = (e) => { if (e.data && e.data.size) parts.push(e.data); };
      const L = linesOf(t), hue = hash(t.id) % 360; let T0 = performance.now();
      try { await document.fonts.load('700 60px ' + SMF, 'قصيدة'); await document.fonts.load('800 30px F0', 'منبر'); } catch (e) {} T0 = performance.now();
      const segs = []; /* {k, t0} لتحريك دخول السطر */ let lastK = -2, kT = 0;
      const frame = () => { const el2 = (performance.now() - T0) / 1000, now = sg.a + el2;
        x.fillStyle = '#05120e'; x.fillRect(0, 0, W, H);
        if (im) { const m = Math.min(im.naturalWidth, im.naturalHeight), z = 1.04 + 0.1 * (el2 / sg.d), sw = m * (W / H) / z, sh = m / z, sx = (im.naturalWidth - sw) / 2 + Math.sin(el2 * 0.12) * sw * 0.03, sy = (im.naturalHeight - sh) / 2; x.save(); x.filter = 'brightness(.72) contrast(1.06) saturate(1.12)'; x.drawImage(im, sx, sy, sw, sh, 0, 0, W, H); x.restore(); }
        const gr = x.createLinearGradient(0, 0, 0, H); gr.addColorStop(0, 'rgba(0,0,0,.45)'); gr.addColorStop(0.18, 'rgba(0,0,0,0)'); gr.addColorStop(0.5, `hsla(${hue},45%,10%,.12)`); gr.addColorStop(0.72, 'rgba(0,0,0,.55)'); gr.addColorStop(1, 'rgba(0,0,0,.92)'); x.fillStyle = gr; x.fillRect(0, 0, W, H);
        let k = -1; for (let j = 0; j < L.length; j++) { if (L[j].t <= now + 0.1) k = j; else break; } if (k !== lastK) { lastK = k; kT = el2; }
        if (k >= 0) { const ws = L[k].l.split(/\s+/), end = L[k + 1] ? L[k + 1].t : L[k].t + 5, f = Math.max(0, Math.min(1, (now - L[k].t) / Math.max(0.8, (end - L[k].t) * 0.85))), lit = Math.ceil(f * ws.length);
          x.font = `700 58px ${SMF}, F8, serif`; x.textAlign = 'right'; x.direction = 'rtl'; const rows = []; let row = []; ws.forEach((w2) => { const tt = row.concat(w2).join(' '); if (x.measureText(tt).width > W - 120 && row.length) { rows.push(row); row = [w2]; } else row.push(w2); }); if (row.length) rows.push(row);
          let wi = 0, y0 = 930 - (rows.length - 1) * 84; rows.forEach((r2, ri) => { const lw = x.measureText(r2.join(' ')).width; let xx = W / 2 + lw / 2; r2.forEach((w2) => { const ww = x.measureText(w2).width, sp = x.measureText(' ').width, a = Math.max(0, Math.min(1, (el2 - kT - wi * 0.07) / 0.35)), on = wi < lit;
              x.save(); x.globalAlpha = a; x.shadowColor = on ? 'rgba(232,196,104,.55)' : 'rgba(0,0,0,.7)'; x.shadowBlur = on ? 22 : 14; x.fillStyle = on ? '#fff' : 'rgba(255,255,255,.5)'; x.fillText(w2, xx, y0 + ri * 84 + (1 - a) * 22); x.restore(); xx -= ww + sp; wi++; }); }); }
        /* شريط القصيدة */
        const py = H - 150; x.save(); x.fillStyle = 'rgba(255,255,255,.12)'; x.beginPath(); x.roundRect ? x.roundRect(36, py, W - 72, 92, 24) : x.rect(36, py, W - 72, 92); x.fill(); x.restore();
        if (im) { const m = Math.min(im.naturalWidth, im.naturalHeight); x.save(); x.beginPath(); x.roundRect ? x.roundRect(W - 52 - 68, py + 12, 68, 68, 14) : x.rect(W - 120, py + 12, 68, 68); x.clip(); x.drawImage(im, (im.naturalWidth - m) / 2, (im.naturalHeight - m) / 2, m, m, W - 120, py + 12, 68, 68); x.restore(); }
        x.textAlign = 'right'; x.font = '800 30px F0, Cairo, sans-serif'; x.fillStyle = '#fff'; x.fillText(t.title, W - 136, py + 42); x.font = '600 22px F0, Cairo, sans-serif'; x.fillStyle = 'rgba(255,255,255,.7)'; x.fillText([t.reciter, t.poet].filter(Boolean).join(' · '), W - 136, py + 74);
        x.fillStyle = 'rgba(255,255,255,.22)'; x.fillRect(36, 34, W - 72, 4); x.fillStyle = '#fff'; const pw = (W - 72) * Math.min(1, el2 / sg.d); x.fillRect(W - 36 - pw, 34, pw, 4);
        x.globalAlpha = 0.9; if (logo) x.drawImage(logo, W - 92, 58, 50, 50); x.font = '800 30px F0, Cairo, sans-serif'; x.textAlign = 'right'; x.fillStyle = '#E8C468'; x.fillText('منبر', W - 102, 94); x.font = '600 16px F0, Cairo, sans-serif'; x.fillStyle = 'rgba(255,255,255,.75)'; x.fillText('استمع للقصيدة كاملة في منبر', W - 36, 130); x.globalAlpha = 1;
        pz.querySelector('i').style.width = Math.min(100, el2 / sg.d * 100) + '%'; };
      frame(); rec.start(500); src.start(0, sg.a, sg.d); const tick = setInterval(frame, 1000 / 30);
      await new Promise((ok) => { const chk = setInterval(() => { if (stop || (performance.now() - T0) / 1000 >= sg.d) { clearInterval(chk); ok(); } }, 100); });
      clearInterval(tick); try { src.stop(); } catch (e) {} const done = new Promise((ok) => { rec.onstop = ok; }); rec.stop(); await done;
      if (!stop) { const type = (rec.mimeType || mime || 'video/webm').split(';')[0], blob = new Blob(parts, { type }), ext = /mp4/.test(type) ? 'mp4' : 'webm', name = 'منبر - ' + t.title + '.' + ext;
        const file = new File([blob], name, { type }); let shared = false; try { if (navigator.canShare && navigator.canShare({ files: [file] })) { await navigator.share({ files: [file], title: t.title }); shared = true; } } catch (e) {}
        if (!shared) { const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = name; document.body.appendChild(a); a.click(); setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 4000); } toast('جاهز — ' + name); }
    } catch (e) { console.warn(e); toast('تعذّر تجهيز المقطع'); }
    try { actx && actx.close(); } catch (e) {} pz.remove(); smpBusy = false; if (smpOn) SA.play().catch(() => {}); }
  g('plrSmpX').onclick = () => smpClose();
  /* ================= الصفحة الرئيسية ================= */
  const FOLK = 'minbar.follow', SEENK = 'minbar.seen.ids', OFFK = 'minbar.offline';
  const follows = () => jget(FOLK, []), isFol = (r) => follows().includes(r);
  function hsec(body, title, items, mk, more) { if (!items.length) return; const s = el('section', 'hsec'), h = el('div', 'hsh'); h.appendChild(el('b', '', title)); if (more) { const m = el('button', 'hsm', 'الكل'); m.type = 'button'; m.onclick = more; h.appendChild(m); } const row = el('div', 'hrow'); items.forEach((x) => row.appendChild(mk(x))); s.append(h, row); body.appendChild(s); }
  function hcard(t, sub, prog) { const c = el('button', 'hcd'); c.type = 'button'; const cv = el('div', 'plrcov'); coverEl(t, cv); c.appendChild(cv); if (prog != null) { const p = el('i', 'hpr'); p.style.setProperty('--p', prog); cv.appendChild(p); } if (offHas(t.id)) cv.appendChild(el('em', 'hoff', '⬇')); c.append(el('b', '', t.title), el('small', '', sub != null ? sub : (t.reciter || ''))); c.onclick = () => { qFrom(t, tracks); play(tracks.indexOf(t), true); }; lpMenu(c, t); return c; }
  let HOT = { at: 0, plays: [], likes: [] };
  async function hotLoad() { const db = fdb(); if (!db || Date.now() - HOT.at < 10 * 60000) return; HOT.at = Date.now();
    try { const s = await db.collection('stats').orderBy('plays', 'desc').limit(12).get(); HOT.plays = []; s.forEach((d) => HOT.plays.push([d.id, d.data().plays || 0])); } catch (e) {}
    try { const wk = firebase.firestore.Timestamp.fromMillis(Date.now() - 7 * 864e5), s = await db.collection('rx').where('at', '>=', wk).limit(800).get(), c = {}; s.forEach((d) => { const x = d.data(); c[x.track] = (c[x.track] || 0) + 1; }); HOT.likes = Object.entries(c).sort((a, b) => b[1] - a[1]).slice(0, 12); } catch (e) {}
    if (tab === 'lib' && libV === 'home') render(); }
  function homeRender(body) {
    occRender(body); const nx = occNext(); if (nx && !occasion()) { const b = el('div', 'occ soon'); b.append(el('small', '', 'مناسبة قادمة'), el('b', '', nx.t), el('span', '', nx.d === 1 ? 'غداً' : 'بعد ' + nx.d + ' أيام')); body.appendChild(b); }
    const pos = jget(POSK, {}), du = (() => { try { return JSON.parse(localStorage.getItem(DUK) || '{}'); } catch (e) { return {}; } })();
    hsec(body, 'أكمل الاستماع', Object.keys(pos).reverse().map(byId).filter(Boolean).slice(0, 10), (t) => hcard(t, du[t.id] ? 'متبقٍ ' + fmt(du[t.id] - pos[t.id]) : 'من ' + fmt(pos[t.id]), du[t.id] ? (pos[t.id] / du[t.id]).toFixed(3) : 0));
    const fol = follows(); if (fol.length) hsec(body, 'من رواديد تتابعهم', tracks.filter((t) => fol.includes((t.reciter || '').trim())).sort((a, b) => (b.at || 0) - (a.at || 0)).slice(0, 12), (t) => hcard(t));
    const albs = Object.values(ALB).filter((a) => tracks.some((t) => t.album === a.id)).sort((a, b) => (b.at || 0) - (a.at || 0)).slice(0, 10);
    hsec(body, 'جديد الإصدارات', albs, (a) => { const L = tracks.filter((t) => t.album === a.id), c = el('button', 'hcd'); c.type = 'button'; const cv = el('div', 'plrcov'); coverEl(L[0], cv); c.append(cv, el('b', '', a.name), el('small', '', (a.reciter || '') + ' · ' + L.length + ' قصيدة')); c.onclick = () => { libV = 'alb'; libSel = { k: 'alb', id: a.id }; render(); g('plrBody').scrollTop = 0; }; return c; }, () => { libV = 'alb'; render(); });
    hsec(body, 'أُضيفت حديثاً', tracks.filter((t) => t.at).sort((a, b) => b.at - a.at).slice(0, 12), (t) => hcard(t));
    hsec(body, 'الأكثر إعجاباً هذا الأسبوع', HOT.likes.map(([id, n]) => [byId(id), n]).filter((x) => x[0]), ([t, n]) => hcard(t, '❤ ' + n));
    hsec(body, 'الأكثر استماعاً', HOT.plays.map(([id, n]) => [byId(id), n]).filter((x) => x[0]), ([t, n]) => hcard(t, n + ' استماع'));
    hsec(body, 'التنزيلات (بدون إنترنت)', jget(OFFK, []).map(byId).filter(Boolean), (t) => hcard(t));
    if (!body.querySelector('.hsec')) { const h = el('div', 'hint cen', tracks.length ? 'ابدأ الاستماع لتظهر هنا اقتراحاتك' : 'لا توجد قصائد بعد'); body.appendChild(h); }
    hotLoad(); }
  /* المناسبة القادمة (خلال 10 أيام) */
  function occNext() { for (let i = 1; i <= 10; i++) { const d = new Date(Date.now() + i * 864e5); let dd, mm; try { const f = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura', { day: 'numeric', month: 'numeric' }).formatToParts(d); dd = +f.find((x) => x.type === 'day').value; mm = +f.find((x) => x.type === 'month').value; } catch (e) { return null; }
      const M = [[1, 1, 'محرم الحرام'], [2, 15, 'المسير إلى الأربعين'], [2, 20, 'زيارة الأربعين'], [2, 28, 'وفاة النبي ﷺ والإمام الحسن'], [5, 13, 'الأيام الفاطمية'], [6, 3, 'الأيام الفاطمية الثانية'], [9, 19, 'ليالي القدر وشهادة الإمام علي']]; const m = M.find((x) => x[0] === mm && x[1] === dd); if (m) return { t: m[2], d: i }; } return null; }
  /* ================= متابعة الرواديد + تنبيه بالجديد ================= */
  function folToggle(r) { let a = follows(); if (a.includes(r)) { a = a.filter((x) => x !== r); toast('ألغيت متابعة ' + r); } else { a.push(r); toast('تتابع ' + r + ' — ننبهك بإصداراته الجديدة'); try { if (window.Notification && Notification.permission === 'default') Notification.requestPermission(); } catch (e) {} } jset(FOLK, a); render(); }
  function newCheck() { const seen = jget(SEENK, null), ids = tracks.map((t) => t.id); if (!seen) { jset(SEENK, ids); return; } const fol = follows(), nw = tracks.filter((t) => !seen.includes(t.id));
    jset(SEENK, ids); const mine = nw.filter((t) => fol.includes((t.reciter || '').trim())); if (!mine.length) return; const t = mine[0], msg = 'جديد من ' + t.reciter + ': «' + t.title + '»' + (mine.length > 1 ? ' و' + (mine.length - 1) + ' غيرها' : '');
    snack(msg, 'استمع', () => { qFrom(t, tracks); play(tracks.indexOf(t), true); }, 12000); document.querySelector('.plrnav [data-t=lib]').classList.add('newdot');
    try { if (window.Notification && Notification.permission === 'granted' && document.hidden) navigator.serviceWorker.ready.then((r) => r.showNotification('منبر', { body: msg, icon: 'icons/icon-192.png', tag: 'minbar-new' })); } catch (e) {} }
  /* ================= التنزيل للاستماع بدون إنترنت ================= */
  const offHas = (id) => jget(OFFK, []).includes(id);
  const offPing = () => { try { navigator.serviceWorker.controller && navigator.serviceWorker.controller.postMessage('off'); } catch (e) {} };
  async function offSave(t) { if (offHas(t.id)) return; toast('جارٍ تنزيل «' + t.title + '»…'); try { try { navigator.storage && navigator.storage.persist && navigator.storage.persist(); } catch (e) {} const c = await caches.open('mbr-offline'); const au = new URL(t.audio, location.href).href, r = await fetch(au); if (!r.ok) throw 0; await c.put(au, r);
      if (cov(t)) { try { const cu = new URL(cov(t), location.href).href, r2 = await fetch(cu); if (r2.ok) await c.put(cu, r2); } catch (e) {} } const a = jget(OFFK, []); a.push(t.id); jset(OFFK, a); offPing(); toast('نُزّلت — تعمل بدون إنترنت'); render(); } catch (e) { toast('تعذّر التنزيل'); } }
  async function offDel(t) { try { const c = await caches.open('mbr-offline'); await c.delete(new URL(t.audio, location.href).href); if (cov(t)) await c.delete(new URL(cov(t), location.href).href); } catch (e) {} jset(OFFK, jget(OFFK, []).filter((x) => x !== t.id)); offPing(); toast('حُذف التنزيل'); render(); }
  /* ================= عدّاد الاستماع (بعد 30 ثانية استماع فعلي) ================= */
  let plCnt = { id: null, s: 0, done: {} };
  A.addEventListener('timeupdate', () => { const t = tracks[cur]; if (!t || A.paused || MJ.on && !MJ.host) return; if (plCnt.id !== t.id) { plCnt.id = t.id; plCnt.s = 0; plCnt.lt = A.currentTime; return; } const d = A.currentTime - (plCnt.lt || 0); plCnt.lt = A.currentTime; if (d > 0 && d < 2) plCnt.s += d;
    if (plCnt.s >= 30 && !plCnt.done[t.id] && t.fs) { plCnt.done[t.id] = 1; const db = fdb(); if (db) db.doc('stats/' + t.id).set({ plays: firebase.firestore.FieldValue.increment(1) }, { merge: true }).catch(() => {}); } });
  async function statsPanel() { const db = fdb(); if (!db) return toast('غير متصل'); modal('إحصائيات القصائد', async (bx) => { const L = el('div', 'stl'); L.textContent = 'جارٍ التحميل…'; bx.appendChild(L);
      try { const [s, c] = await Promise.all([db.collection('stats').orderBy('plays', 'desc').limit(60).get(), db.collection('rx').limit(2000).get()]); const lk = {}; c.forEach((d) => { const x = d.data(); lk[x.track] = (lk[x.track] || 0) + 1; }); L.textContent = ''; let tot = 0;
        const rows = []; s.forEach((d) => { const t = byId(d.id); if (t) { rows.push([t, d.data().plays || 0]); tot += d.data().plays || 0; } }); tracks.filter((t) => t.fs && !rows.some((r) => r[0] === t)).forEach((t) => rows.push([t, 0]));
        L.appendChild(el('div', 'stt', 'مجموع الاستماعات: ' + tot + ' · القصائد: ' + tracks.filter((t) => t.fs).length)); const mx = Math.max(1, ...rows.map((r) => r[1]));
        rows.forEach(([t, n]) => { const r = el('div', 'str'); const cv = el('div', 'plrcov'); coverEl(t, cv); const m = el('div', 'trm'); m.append(el('b', '', t.title), el('small', '', n + ' استماع · ❤ ' + (lk[t.id] || 0))); const bar = el('i', 'stb'); bar.style.setProperty('--p', (n / mx).toFixed(3)); m.appendChild(bar); r.append(cv, m); L.appendChild(r); });
      } catch (e) { L.textContent = 'تعذّر التحميل: ' + (e.code || e.message); } }); }
  /* ================= وضع الحسينية: كلمات كبيرة للعرض على شاشة أو بروجكتر ================= */
  let hsOn = false, hsRaf = 0, hsWl = null;
  async function hsOpen() { const t = tracks[cur]; if (!t) return; if (!linesOf(t).length) return toast('لا توجد كلمات لهذه القصيدة'); hsOn = true; const w = g('plrHs'); w.hidden = false; w.querySelector('.hst').textContent = t.title + (t.reciter ? ' — ' + t.reciter : ''); w.style.setProperty('--hsf', `"${st.ly.font}", F8, serif`);
    try { hsWl = await navigator.wakeLock.request('screen'); } catch (e) {} try { if (w.requestFullscreen) await w.requestFullscreen(); } catch (e) {} if (A.paused) fadePlay(); hsLoop(); }
  function hsClose() { hsOn = false; cancelAnimationFrame(hsRaf); g('plrHs').hidden = true; try { hsWl && hsWl.release(); } catch (e) {} hsWl = null; try { if (document.fullscreenElement) document.exitFullscreen(); } catch (e) {} }
  function hsLoop() { if (!hsOn) return; hsRaf = requestAnimationFrame(hsLoop); const t = tracks[cur], w = g('plrHs'); if (!t) return; const L = linesOf(t), now = A.currentTime; let k = -1; for (let j = 0; j < L.length; j++) { if (L[j].t <= now + 0.1) k = j; else break; }
    if (w._k !== k) { w._k = k; const c = w.querySelector('.hsc'), n = w.querySelector('.hsn'); c.textContent = k >= 0 ? L[k].l : '…'; n.textContent = L[k + 1] ? L[k + 1].l : ''; c.classList.remove('in'); void c.offsetWidth; c.classList.add('in'); }
    w.querySelector('.hsp i').style.transform = 'scaleX(' + (A.duration ? (now / A.duration).toFixed(4) : 0) + ')'; }
  g('plrHs').onclick = (e) => { if (e.target.closest('.hsx')) return hsClose(); if (e.target.closest('.hspp')) { toggle(); return; } g('plrHs').classList.toggle('ui'); };
  document.addEventListener('fullscreenchange', () => { if (!document.fullscreenElement && hsOn) { /* يبقى الوضع، فقط خرج من ملء الشاشة */ } });
  function toolsUi() { const b = g('plrTools'); if (!b) return; b.textContent = ''; const seen = jget('minbar.seen.tools', {});
    [['sleep', 'moon', 'مؤقت النوم', sleepT ? 'مفعّل — اضغط للتغيير' : 'إيقاف التشغيل بعد مدة', () => { g('plrSlB').click(); toolsUi(); }], ['ver', 'info', 'الإصدار ' + APPV, 'اضغط للتحقق من التحديث', () => { toast('جارٍ التحقق من التحديث…'); const go = () => setTimeout(() => location.reload(), 1200); try { navigator.serviceWorker.getRegistration().then((r) => (r ? r.update() : 0)).then(go, go); } catch (e) { go(); } }], ['about', 'info', 'عن القصيدة', 'الرادود والتفاصيل', about], ['share', 'share', 'مشاركة اللحظة', 'من الدقيقة الحالية', shareMoment], ['peak', 'flame', 'الذروة', rxList.length ? 'أكثر لحظة إعجاباً' : 'لا إعجابات', () => { const p = peakT(); if (p == null) return toast('لا توجد تفاعلات بعد على هذه القصيدة'); A.currentTime = p; if (A.paused) fadePlay(); tp(false); }],
      ['majlis', 'users', 'المجلس', MJ.on ? 'مفعّل · ' + MJ.code : 'استماع مشترك', mjMenu], ['husn', 'text', 'وضع الحسينية', 'كلمات كبيرة للشاشة', () => { tp(false); hsOpen(); }], ...(isOwner() ? [['adm', 'users', 'لوحة الإدارة', 'قبول طلبات الدخول والاستبيانات', () => { tp(false); try { MinbarAuth.openAdmin(); } catch (e) { toast('تعذّر فتح اللوحة'); } }]] : []), ...(isOwner() ? [['mig', 'eq', 'نقل الملفات إلى R2', 'نسخ القصائد القديمة من KV', mgRun]] : []), ...(isOwner() ? [['anl', 'pulse', 'تحليل الصوت', anPending().length ? anPending().length + ' قصيدة بانتظار التحليل' : 'كل القصائد محلَّلة', () => anRun(true)]] : []), ['latm', 'pulse', 'وضع اللطم', st.latm ? 'مفعّل' : 'اهتزاز مع الإيقاع', () => { st.latm = !st.latm; save(); toolsUi(); toast(st.latm ? 'وضع اللطم: يهتز الهاتف مع إيقاع اللطم' : 'أُوقف وضع اللطم'); }]].concat(isOwner() ? [['stats', 'eq', 'الإحصائيات', 'الاستماعات والإعجابات', statsPanel]] : []).forEach(([k, icn, n, s, f]) => {
      const t = el('button', 'ptl' + ((k === 'latm' && st.latm) || (k === 'majlis' && MJ.on) ? ' on' : '')); t.type = 'button'; t.innerHTML = '<i class="pci">' + ic(icn, 18) + '</i><span></span><small></small>'; t.children[1].textContent = n; t.children[2].textContent = s; if (!seen[k]) t.appendChild(el('i', 'nb', 'جديد')); t.onclick = () => { const sn = jget('minbar.seen.tools', {}); sn[k] = 1; jset('minbar.seen.tools', sn); f(); toolsUi(); }; t.dataset.k = k; if (k === 'latm' || k === 'perf') t.classList.add('sw'); if (k === 'perf' && !st.fx) t.classList.add('on'); b.appendChild(t); });
    [['القصيدة', ['sleep', 'about', 'share', 'peak', 'stats']], ['الجهاز', ['ver']], ['المالك', ['adm', 'mig', 'anl']]].forEach(([gn, ks]) => { const items = ks.map((q) => b.querySelector('[data-k="' + q + '"]')).filter(Boolean); if (!items.length) return; b.appendChild(el('h5', 'tgh', gn)); const L2 = el('div', 'tlist'); items.forEach((it) => L2.appendChild(it)); b.appendChild(L2); });
    [...b.querySelectorAll(':scope > .ptl')].forEach((it) => { if (['majlis', 'husn', 'latm'].includes(it.dataset.k)) { it.remove(); return; } /* موجودة بزر الأجواء */ const L3 = b.querySelector('.tlist:last-of-type'); if (L3) L3.appendChild(it); }); }

  function modesSheet() { sheet((bx, close) => { bx.classList.add('mdsh');
      const h = el('div', 'mdh'); h.innerHTML = '<b>' + ic('arch', 22) + '<span>أجواء الاستماع</span></b><small>اختر الجو المناسب لمكان استماعك</small>'; bx.appendChild(h);
      const gr = el('div', 'mdg'); bx.appendChild(gr);
      const card = (icn, n, sb, f, on) => { const c = el('button', 'mdc' + (on ? ' on' : '')); c.type = 'button'; c.innerHTML = '<span class="mdt"><i>' + ic(icn, 21) + '</i>' + (on != null ? '<em>' + (on ? 'مفعّل' : 'متوقف') + '</em>' : '') + '</span><b></b><small></small>'; c.querySelector('b').textContent = n; c.querySelector('small').textContent = sb; c.onclick = () => f(c); gr.appendChild(c); };
      card('text', 'وضع الحسينية', 'كلمات كبيرة على شاشة سوداء للعرض بالمجلس', () => { close(); tp(false); setTimeout(() => hsOpen(), 60); });
      card('hand', 'وضع اللطم', 'يهتز الهاتف مع إيقاع اللطمية', (c) => { st.latm = !st.latm; save(); toolsUi(); c.classList.toggle('on', st.latm); c.querySelector('em').textContent = st.latm ? 'مفعّل' : 'متوقف'; g('plrMdB').classList.toggle('on', !!st.latm); }, !!st.latm);
      card('users', 'المجلس', MJ.on ? 'مفعّل · ' + MJ.code : 'استماع مشترك بنفس اللحظة', () => { close(); mjMenu(); });
    }); }
  function fitUI() { const f = g('plrFull'); if (!f) return; let s = Math.min(innerWidth / 392, innerHeight / 800); s = Math.max(0.8, Math.min(1.2, s)); if (Math.abs(s - 1) < 0.03) s = 1; f.style.setProperty('--fs', s.toFixed(3)); f.classList.toggle('fsx', s !== 1); }
  addEventListener('resize', fitUI); fitUI();
  g('plrMdB').onclick = modesSheet; g('plrMdB').classList.toggle('on', !!st.latm);
  g('plrRecB').onclick = recognize; g('plrMj').onclick = () => mjMenu(); g('plrTitle').onclick = about; g('plrTitle').style.cursor = 'pointer';
  window.PLR = { open, close: () => { root.hidden = true; }, audio: A, playing: () => !A.paused, back, visible: () => !root.hidden, level: () => { if (!an) return -1; an.getByteFrequencyData(fbuf); let s = 0; for (let i = 0; i < fbuf.length; i++) s += fbuf[i]; return s / fbuf.length; } };
  lyStyle(); ui(); loadCatalog();
})();
