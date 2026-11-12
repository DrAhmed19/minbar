// يكتب رقم آخر بناء في config/app.apkBuild حتى يعرف التطبيق بوجود تحديث (بدون الاعتماد على GitHub)
import { GoogleAuth } from 'google-auth-library';
const P = 'minbar-8f037', n = process.argv[2];
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/datastore', 'https://www.googleapis.com/auth/cloud-platform'] });
const c = await auth.getClient();
const url = `https://firestore.googleapis.com/v1/projects/${P}/databases/(default)/documents/config/app?updateMask.fieldPaths=apkBuild&updateMask.fieldPaths=apkUrl`;
await c.request({ url, method: 'PATCH', data: { fields: { apkBuild: { integerValue: String(n) }, apkUrl: { stringValue: 'https://github.com/DrAhmed19/minbar-releases/raw/main/minbar.apk' } } } })
  .then(() => console.log('✓ apkBuild =', n))
  .catch((e) => { console.error('تعذّر تحديث apkBuild:', JSON.stringify(e.response && e.response.data || e.message)); process.exit(1); });
