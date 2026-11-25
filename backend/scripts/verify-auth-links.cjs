// Read-only production check: deliberately invalid, non-user OTPs; sends no email.
const assert = require('node:assert/strict');
const base = 'https://mapo-experiencias-api.vercel.app/auth/callback';
(async () => {
  for (const [type, flow] of [['signup','signup'],['recovery','recovery'],['email_change','email_change']]) {
    const url = new URL('https://affhiuzxhejwolcoivnf.supabase.co/auth/v1/verify');
    url.searchParams.set('token', '0'.repeat(64));
    url.searchParams.set('type', type);
    url.searchParams.set('redirect_to', `${base}?flow=${flow}`);
    const response = await fetch(url, { redirect:'manual', signal:AbortSignal.timeout(15000) });
    assert.ok([302,303].includes(response.status));
    const destination = new URL(response.headers.get('location'));
    assert.equal(destination.origin + destination.pathname, base);
    assert.equal(destination.searchParams.get('flow'), flow);
    assert.match(destination.hash, /error/);
    const page = await fetch(destination, { signal:AbortSignal.timeout(15000) });
    assert.equal(page.status,200);
    assert.match(page.headers.get('content-type'), /text\/html/);
    const html = await page.text();
    assert.match(html, /Este enlace ya no está disponible/);
    assert.match(html, /No automatic custom-scheme navigation/);
    console.log(JSON.stringify({type,status:response.status,landingStatus:page.status,httpsLanding:true,errorDelivered:true}));
  }
})().catch(() => {console.error('Falló la comprobación del enlace de autenticación.');process.exitCode=1;});
