require('reflect-metadata');
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { GatewayController } = require('../dist/gateway.controller');
const { AUTH_CALLBACK_URL } = require('../dist/auth-redirect');
const html = fs.readFileSync('public/auth/callback.html', 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
function render(suffix, historyThrows = false) {
  const url = new URL(AUTH_CALLBACK_URL + suffix), elements = {};
  ['title','message','next','status','open'].forEach(id => elements[id] = { textContent: '', href: id==='open' ? 'mapo://auth-callback' : '' });
  const location = { search:url.search, hash:url.hash, pathname:url.pathname };
  vm.runInNewContext(script, { URLSearchParams, location, history: { replaceState() { if(historyThrows)throw Error('blocked'); } }, document: { getElementById: id => elements[id] } });
  return elements;
}
test('signup PKCE callback retains its code, has useful content, and has no automatic app redirect', () => {
  const e = render('?flow=signup&code=example&redirect_to=https://untrusted.example');
  assert.match(e.title.textContent, /parche/);
  assert.equal(e.open.href, 'mapo://auth-callback?code=example');
  assert.doesNotMatch(script, /location\.(?:href|assign|replace)\s*[=(]/);
  assert.match(html, /<noscript>/);
});
test('recovery works for PKCE and legacy implicit links', () => {
  assert.match(render('?flow=recovery&code=example').title.textContent, /contraseña/);
  const e = render('#access_token=example&refresh_token=refresh&expires_in=3600&token_type=bearer&type=recovery');
  const parameters = new URLSearchParams(new URL(e.open.href).hash.slice(1));
  assert.equal(parameters.get('access_token'), 'example');
  assert.equal(parameters.get('type'), 'recovery');
  assert.match(e.open.textContent, /Cambiar contraseña/);
});
test('expired, reused and malformed links never forward errors or claim success', () => {
  for (const suffix of ['?flow=signup#error_code=otp_expired&error_description=%3Cscript%3Ebad%3C/script%3E', '?code=example&error=access_denied', '#error_description=invalid']) {
    const e = render(suffix);
    assert.equal(e.open.href, 'mapo://auth-callback');
    assert.match(e.message.textContent, /solicita un correo nuevo/);
    assert.doesNotMatch(e.message.textContent, /<script>/);
  }
});
test('empty links, blocked history, email change and invitation keep a usable page', () => {
  assert.match(render('').next.textContent, /mensaje más reciente/);
  assert.equal(render('?code=example', true).open.href, 'mapo://auth-callback?code=example');
  assert.match(render('?flow=email_change&code=example').title.textContent, /nuevo correo/);
  for(const type of ['invite','magiclink'])assert.match(render(`#access_token=example&refresh_token=refresh&type=${type}`).open.href,/^mapo:\/\/auth-callback#/);
});
test('all email actions override legacy or hostile destinations and keep PKCE bodies intact', async () => {
  for (const [action, method, body, flow] of [
    ['signup','POST',{email:'test@example.com',code_challenge:'pkce'},'signup'],
    ['recover','POST',{email:'test@example.com',code_challenge:'pkce'},'recovery'],
    ['resend','POST',{email:'test@example.com',type:'signup'},'signup'],
    ['user','PUT',{email:'new@example.com'},'email_change'],
  ]) {
    for (const query of ['', '?redirect_to=mapo://auth-callback', '?redirect_to=https://untrusted.example']) {
      let called = false;
      const gateway = new GatewayController({ async request(p,m,token,data) {
        called = true; const u = new URL('https://test.supabase.co'+p);
        assert.equal(u.searchParams.get('redirect_to'), `${AUTH_CALLBACK_URL}?flow=${flow}`);
        assert.deepEqual(data,body); return Response.json({});
      }});
      const res = {setHeader(){},status(){return this;},send(){return this;}};
      await gateway.auth(action,{method,originalUrl:`/auth/v1/${action}${query}`,header(){}},res,body);
      assert.equal(called,true);
    }
  }
});
test('refresh and PKCE code exchange keep their grant type and are not turned into email actions', async () => {
  const gateway = new GatewayController({async request(p){assert.equal(p,'/auth/v1/token?grant_type=pkce');return Response.json({});}});
  await gateway.auth('token',{method:'POST',originalUrl:'/auth/v1/token?grant_type=pkce',header(){}},{setHeader(){},status(){return this;},send(){}},{auth_code:'example',code_verifier:'example'});
});
