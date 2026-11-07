/* التحقق من رمز دخول Firebase داخل Cloudflare (بدون مكتبات) */
const PROJECT = 'minbar-8f037', OWNER = 'ahmad1999199919999@gmail.com';
let JWKS = null, JWKS_AT = 0;
const b64u = (s) => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(s.length / 4) * 4, '=')), (c) => c.charCodeAt(0));
async function keys() {
  if (JWKS && Date.now() - JWKS_AT < 3600e3) return JWKS;
  const r = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
  JWKS = (await r.json()).keys; JWKS_AT = Date.now(); return JWKS;
}
export async function ownerFrom(request) {
  const h = request.headers.get('authorization') || '', tok = h.replace(/^Bearer\s+/i, '');
  const p = tok.split('.'); if (p.length !== 3) return null;
  let head, body; try { head = JSON.parse(new TextDecoder().decode(b64u(p[0]))); body = JSON.parse(new TextDecoder().decode(b64u(p[1]))); } catch (e) { return null; }
  const now = Date.now() / 1000;
  if (head.alg !== 'RS256' || body.aud !== PROJECT || body.iss !== 'https://securetoken.google.com/' + PROJECT || !(body.exp > now) || !(body.iat < now + 60)) return null;
  const jwk = (await keys()).find((k) => k.kid === head.kid); if (!jwk) return null;
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64u(p[2]), new TextEncoder().encode(p[0] + '.' + p[1]));
  if (!ok || body.email !== OWNER || body.email_verified !== true) return null;
  return body;
}
export const json = (o, s) => new Response(JSON.stringify(o), { status: s || 200, headers: { 'content-type': 'application/json; charset=utf-8' } });
