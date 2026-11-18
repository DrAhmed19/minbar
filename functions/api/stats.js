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
  const run = (m, b) => fetch(base + ':' + m, { method: 'POST', headers: H, body: JSON.stringify(b) }).then((r) => r.json());
  try {
    const [rt, ser, tot, cty] = await Promise.all([
      run('runRealtimeReport', { metrics: [{ name: 'activeUsers' }] }),
      run('runReport', { dateRanges: [{ startDate: '13daysAgo', endDate: 'today' }], dimensions: [{ name: 'date' }], metrics: [{ name: 'activeUsers' }, { name: 'newUsers' }, { name: 'sessions' }], orderBys: [{ dimension: { dimensionName: 'date' } }] }),
      run('runReport', { dateRanges: [{ startDate: 'today', endDate: 'today', name: 't' }, { startDate: '6daysAgo', endDate: 'today', name: 'w' }, { startDate: '29daysAgo', endDate: 'today', name: 'm' }], metrics: [{ name: 'activeUsers' }, { name: 'newUsers' }] }),
      run('runReport', { dateRanges: [{ startDate: '29daysAgo', endDate: 'today' }], dimensions: [{ name: 'country' }], metrics: [{ name: 'activeUsers' }], orderBys: [{ metric: { metricName: 'activeUsers' }, desc: true }], limit: 6 }),
    ]);
    if (rt.error || ser.error) return J({ error: (rt.error || ser.error).message || 'خطأ من Analytics' }, 502);
    const n = (x) => +x || 0, tt = {}, nw = {};
    (tot.rows || []).forEach((r) => { const k = (r.dimensionValues[0] || {}).value; tt[k] = n(r.metricValues[0].value); nw[k] = n(r.metricValues[1].value); });
    return J({
      now: n((((rt.rows || [])[0] || {}).metricValues || [{}])[0].value),
      users: { t: tt.t || 0, w: tt.w || 0, m: tt.m || 0 }, fresh: { t: nw.t || 0, w: nw.w || 0, m: nw.m || 0 },
      series: (ser.rows || []).map((r) => ({ d: r.dimensionValues[0].value, u: n(r.metricValues[0].value), n: n(r.metricValues[1].value), s: n(r.metricValues[2].value) })),
      countries: (cty.rows || []).map((r) => [r.dimensionValues[0].value, n(r.metricValues[0].value)]),
    });
  } catch (e) { return J({ error: 'تعذّر قراءة الإحصائيات' }, 502); }
}
