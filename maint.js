/* وضع الصيانة للنسخة التجريبية فقط (بدون تسجيل Google). التفعيل: maint.json ← {"on":true} ، الإيقاف ← {"on":false} */
window.MAINT = {
  on: () => fetch('maint.json?t=' + Date.now(), { cache: 'no-store' }).then((r) => r.ok ? r.json() : null).then((j) => !!(j && j.on)).catch(() => false),
  show: () => {
    if (document.getElementById('maintBox')) return;
    const d = document.createElement('div'); d.id = 'maintBox';
    d.style.cssText = 'position:fixed;inset:0;z-index:99999;display:flex;align-items:center;justify-content:center;padding:28px;text-align:center;direction:rtl;color:#f3f6f4;font-family:Cairo,system-ui,sans-serif;background:radial-gradient(circle at 50% 30%,#12503e,#07130e 70%)';
    d.innerHTML = '<div style="max-width:340px"><img src="icons/brand-mark.png" alt="" style="width:84px;height:84px;margin-bottom:14px"><h1 style="margin:0 0 10px;font-size:26px;color:#E8C468">منبر</h1><div style="font-size:19px;font-weight:700;margin-bottom:10px">نعمل على تحديث التطبيق</div><p style="margin:0 0 16px;line-height:1.9;color:#cfe0d8;font-size:15px">النسخة التجريبية مغلقة مؤقتاً للصيانة وإضافة ميزات جديدة، وسنعيد فتحها قريباً بإذن الله.<br>نعتذر عن الإزعاج، وشكراً لصبركم.</p><button id="mtBack" style="padding:11px 26px;border-radius:14px;border:0;background:#E8C468;color:#2a2106;font:inherit;font-weight:700">رجوع</button></div>';
    document.body.appendChild(d); d.querySelector('#mtBack').onclick = () => d.remove();
  }
};
