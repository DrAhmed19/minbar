/* إحصائيات منبر للأدمن: GET /api/stats (Authorization: Bearer <Firebase ID token>)
   يتحقق أن المستخدم أدمن (قراءة waitlist مسموحة للأدمن فقط بالقواعد) ثم يقرأ Google Analytics Data API بحساب الخدمة. */
const PROP = '564949306', PID = 'minbar-8f037';
const J = (o, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' } });
const b64u = (b) => btoa(String.fromCharCode(...new Uint8Array(b))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const enc = (o) => b64u(new TextEncoder().encode(JSON.stringify(o)));

async function gToken(key) {
  const now = Math.floor(Date.now() / 1000), head = enc({ alg: 'RS256', typ: 'JWT' });
  const body = enc({ iss: key.client_email, scope: 'https://www.googleapis.com/auth/analytics.readonly', aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 3000 });
  const pem = key.private_key.replace(/-----[A-Z ]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const k = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', k, new TextEncoder().encode(head + '.' + body));
  const r = await fetch('https://oauth2.googleapis.com/token', { method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body: 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + head + '.' + body + '.' + b64u(sig) });
  const j = await r.json(); if (!j.access_token) throw new Error('token');
  return j.access_token;
}

export async function onRequestGet({ request, env }) {
  const au = request.headers.get('authorization') || '';
  if (!/^Bearer .{20,}/.test(au)) return J({ error: 'سجّل الدخول' }, 401);
  try { const r = await fetch('https://firestore.googleapis.com/v1/projects/' + PID + '/databases/(default)/documents/waitlist?pageSize=1', { headers: { authorization: au } }); if (!r.ok) return J({ error: 'للأدمن فقط' }, 403); } catch (e) { return J({ error: 'تعذّر التحقق' }, 502); }
  if (!env.GA_KEY) return J({ error: 'GA_KEY غير مضاف' }, 500);
  let tk;
  try { tk = await gToken(JSON.parse(env.GA_KEY)); } catch (e) { return J({ error: 'مفتاح الإحصائيات غير صالح' }, 500); }
  const H = { authorization: 'Bearer ' + tk, 'content-type': 'application/json' }, base = 'https://analyticsdata.googleapis.com/v1beta/properties/' + PROP;
  const url = new URL(request.url), ck = new Request('https://stats.cache/v2'), cache = caches.default;
  if (!url.searchParams.get('fresh')) { const hit = await cache.match(ck); if (hit) return hit; }
  const run = (m, b) => fetch(base + ':' + m, { method: 'POST', headers: H, body: JSON.stringify(b) }).then((r) => r.json()).catch(() => ({}));
  const R = (dims, mets, extra) => Object.assign({ dateRanges: [{ startDate: '29daysAgo', endDate: 'today' }], dimensions: dims.map((name) => ({ name })), metrics: mets.map((name) => ({ name })) }, extra || {});
  const top = (m, n) => ({ orderBys: [{ metric: { metricName: m }, desc: true }], limit: n });
  const MET = ['activeUsers', 'newUsers', 'sessions', 'screenPageViews', 'userEngagementDuration'];
  const n = (x) => +x || 0, rows = (r) => r.rows || [], dv = (r, i = 0) => (r.dimensionValues[i] || {}).value || '', mv = (r, i = 0) => n((r.metricValues[i] || {}).value);
  const pairs = (rep, i = 0) => rows(rep).map((r) => [dv(r) === '(not set)' ? 'غير معروف' : dv(r), mv(r, i)]);
  try {
    const [rtP, rtC, ser, k1, k2, plat, dev, os, appv, model, cty, city, hour, scr, evt, nvr, lang] = await Promise.all([
      run('runRealtimeReport', { dimensions: [{ name: 'platform' }], metrics: [{ name: 'activeUsers' }] }),
      run('runRealtimeReport', { dimensions: [{ name: 'city' }], metrics: [{ name: 'activeUsers' }], limit: 6 }),
      run('runReport', R(['date'], MET, { orderBys: [{ dimension: { dimensionName: 'date' } }] })),
      run('runReport', { dateRanges: [{ startDate: 'today', endDate: 'today', name: 't' }, { startDate: 'yesterday', endDate: 'yesterday', name: 'y' }, { startDate: '6daysAgo', endDate: 'today', name: 'w' }, { startDate: '13daysAgo', endDate: '7daysAgo', name: 'pw' }], metrics: MET.map((name) => ({ name })) }),
      run('runReport', { dateRanges: [{ startDate: '29daysAgo', endDate: 'today', name: 'm' }, { startDate: '59daysAgo', endDate: '30daysAgo', name: 'pm' }], metrics: MET.map((name) => ({ name })) }),
      run('runReport', R(['platform'], ['activeUsers', 'sessions'], top('activeUsers', 5))),
      run('runReport', R(['deviceCategory'], ['activeUsers'], top('activeUsers', 4))),
      run('runReport', R(['operatingSystemWithVersion'], ['activeUsers'], top('activeUsers', 6))),
      run('runReport', R(['appVersion'], ['activeUsers'], top('activeUsers', 5))),
      run('runReport', R(['mobileDeviceModel'], ['activeUsers'], top('activeUsers', 6))),
      run('runReport', R(['country'], ['activeUsers'], top('activeUsers', 8))),
      run('runReport', R(['city'], ['activeUsers'], top('activeUsers', 8))),
      run('runReport', R(['hour'], ['sessions'])),
      run('runReport', R(['unifiedScreenName'], ['screenPageViews'], top('screenPageViews', 8))),
      run('runReport', R(['eventName'], ['eventCount'], top('eventCount', 8))),
      run('runReport', R(['newVsReturning'], ['activeUsers'])),
      run('runReport', R(['language'], ['activeUsers'], top('activeUsers', 5))),
    ]);
    if (ser.error) return J({ error: ser.error.message || 'خطأ من Analytics' }, 502);
    const kpi = {};
    [k1, k2].forEach((rep) => rows(rep).forEach((r) => { const k = dv(r); kpi[k] = { u: mv(r, 0), n: mv(r, 1), s: mv(r, 2), v: mv(r, 3), e: mv(r, 4) }; }));
    const hrs = Array(24).fill(0); rows(hour).forEach((r) => { hrs[+dv(r)] = mv(r); });
    const nv = {}; rows(nvr).forEach((r) => { nv[dv(r)] = mv(r); });
    /* أكثر القصائد استماعاً من Firestore بصلاحية الأدمن نفسه */
    let tops = [];
    try {
      const fb = 'https://firestore.googleapis.com/v1/projects/' + PID + '/databases/(default)/documents', fh = { authorization: au, 'content-type': 'application/json' };
      const q = await (await fetch(fb + ':runQuery', { method: 'POST', headers: fh, body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'stats' }], orderBy: [{ field: { fieldPath: 'plays' }, direction: 'DESCENDING' }], limit: 10 } }) })).json();
      const L = (Array.isArray(q) ? q : []).filter((x) => x.document).map((x) => ({ id: x.document.name.split('/').pop(), plays: n((x.document.fields.plays || {}).integerValue || (x.document.fields.plays || {}).doubleValue) }));
      if (L.length) {
        const g = await (await fetch(fb + ':batchGet', { method: 'POST', headers: fh, body: JSON.stringify({ documents: L.map((x) => fb.replace('https://firestore.googleapis.com/v1/', '') + '/tracks/' + x.id) }) })).json();
        const M = {}; (Array.isArray(g) ? g : []).forEach((x) => { if (x.found) M[x.found.name.split('/').pop()] = x.found.fields; });
        tops = L.map((x) => ({ id: x.id, plays: x.plays, title: ((M[x.id] || {}).title || {}).stringValue || '', reciter: ((M[x.id] || {}).reciter || {}).stringValue || '' })).filter((x) => x.title);
      }
    } catch (e) {}
    const out = J({
      now: { total: rows(rtP).reduce((a, r) => a + mv(r), 0), platforms: pairs(rtP), cities: pairs(rtC) },
      kpi, series: rows(ser).map((r) => ({ d: dv(r), u: mv(r, 0), n: mv(r, 1), s: mv(r, 2), v: mv(r, 3), e: mv(r, 4) })),
      platform: rows(plat).map((r) => [dv(r), mv(r, 0), mv(r, 1)]), device: pairs(dev), os: pairs(os), appv: pairs(appv), model: pairs(model),
      country: pairs(cty), city: pairs(city), hour: hrs, screens: pairs(scr), events: pairs(evt), nvr: { n: nv.new || 0, r: nv.returning || 0 }, lang: pairs(lang), top: tops, at: Date.now(),
    });
    const res = new Response(out.body, { headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'max-age=120' } });
    await cache.put(ck, res.clone());
    return res;
  } catch (e) { return J({ error: 'تعذّر قراءة الإحصائيات' }, 502); }
}
