// ينشر firestore.rules مباشرة عبر Firebase Rules API (بدون firebase-tools)
import { readFileSync } from 'fs';
import { GoogleAuth } from 'google-auth-library';
const P = 'minbar-8f037', API = 'https://firebaserules.googleapis.com/v1/projects/' + P;
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase'] });
const c = await auth.getClient();
const src = readFileSync('firestore.rules', 'utf8');
const rs = await c.request({ url: API + '/rulesets', method: 'POST', data: { source: { files: [{ name: 'firestore.rules', content: src }] } } }).catch((e) => { console.error('فشل رفع القواعد:', JSON.stringify(e.response && e.response.data || e.message)); process.exit(1); });
const name = rs.data.name; console.log('ruleset', name);
await c.request({ url: API + '/releases/cloud.firestore', method: 'PATCH', data: { release: { name: `projects/${P}/releases/cloud.firestore`, rulesetName: name } } }).catch((e) => { console.error('فشل التفعيل:', JSON.stringify(e.response && e.response.data || e.message)); process.exit(1); });
console.log('✓ تم تفعيل القواعد');
