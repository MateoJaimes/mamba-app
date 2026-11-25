require('reflect-metadata');
const test=require('node:test');
const assert=require('node:assert/strict');
const {ConfigService}=require('@nestjs/config');
const {SupabaseService}=require('../dist/supabase.service');
const {GatewayController,allowedResource}=require('../dist/gateway.controller');

test('gateway never exposes writes to trusted role and approval tables',()=>{
  assert.equal(allowedResource('user_roles','POST'),false);
  assert.equal(allowedResource('host_profiles','PATCH'),false);
  assert.equal(allowedResource('experiences','POST'),false);
  assert.equal(allowedResource('host_applications','PATCH'),false);
  assert.equal(allowedResource('profiles','PATCH'),true);
  assert.equal(allowedResource('account_identity','GET'),false);
});
test('private reads reject the APK anonymous transport marker',async()=>{
  const gateway=new GatewayController({request(){throw new Error('must not call');}});
  await assert.rejects(gateway.data('user_roles',{method:'GET',header:()=> 'Bearer sb_publishable_mapo_frontend'}, {},undefined),/Inicia sesión/);
});
test('unknown RPC is rejected before accessing provider',async()=>{
  const gateway=new GatewayController({user(){throw new Error('must not call');}});
  await assert.rejects(gateway.rpc('grant_admin',{method:'POST'}, {},{action:'grant_admin'}),/Acción no disponible/);
});
test('server injects provider key and strips frontend marker',async()=>{
  const original=global.fetch;
  const service=new SupabaseService(new ConfigService({SUPABASE_URL:'https://test.supabase.co',SUPABASE_PUBLISHABLE_KEY:'sb_publishable_server'}));
  global.fetch=async(url,options)=>{assert.equal(options.headers.apikey,'sb_publishable_server');assert.equal(options.headers.Authorization,undefined);return Response.json([]);};
  try {await service.request('/rest/v1/experience_feed','GET','Bearer sb_publishable_mapo_frontend');}finally{global.fetch=original;}
});
test('provider transport keeps user JWT for database row security',async()=>{
  const original=global.fetch;
  const service=new SupabaseService(new ConfigService({SUPABASE_URL:'https://test.supabase.co',SUPABASE_PUBLISHABLE_KEY:'sb_publishable_server'}));
  global.fetch=async(url,options)=>{assert.equal(options.headers.Authorization,'Bearer user-session');return Response.json([]);};
  try {await service.request('/rest/v1/profiles','GET','Bearer user-session');}finally{global.fetch=original;}
});
