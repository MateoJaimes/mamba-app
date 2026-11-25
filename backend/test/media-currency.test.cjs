require('reflect-metadata');
const test=require('node:test');
const assert=require('node:assert/strict');
const sharp=require('sharp');
const {MediaController}=require('../dist/media.controller');
const {CurrencyController}=require('../dist/currency.controller');

test('photo upload verifies session before processing or storing media',async()=>{
  const media=new MediaController({user:async()=>{throw Error('invalid session')},uploadPhoto:()=>{throw Error('must not upload')}});
  await assert.rejects(media.upload('Bearer invalid',{buffer:Buffer.from('x')}),/invalid session/);
});
test('photo upload rejects non-image content and strips metadata into bounded WebP',async()=>{
  let stored;
  const media=new MediaController({user:async()=>({id:'owner'}),uploadPhoto:async(id,token,bytes,name)=>{stored={id,bytes,name};return 'https://test/photo.webp'}});
  await assert.rejects(media.upload('Bearer user',{buffer:Buffer.from('<svg onload="alert(1)"></svg>')}),/JPG, PNG o WebP/);
  const buffer=await sharp({create:{width:2000,height:1000,channels:3,background:'#123456'}}).jpeg().toBuffer();
  const result=await media.upload('Bearer user',{buffer});
  const info=await sharp(stored.bytes).metadata();
  assert.equal(result.url,'https://test/photo.webp');assert.equal(info.format,'webp');assert.equal(info.width,1600);assert.equal(info.height,800);assert.equal(info.exif,undefined);assert.equal(stored.id,'owner');
});

test('private photo response forwards the viewer session and forbids shared caching', async () => {
  const owner = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const file = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb.webp';
  const headers = {};
  const response = {
    setHeader(name, value) { headers[name] = value; },
    type(value) { this.mime = value; return this; },
    send(value) { this.body = value; return this; },
  };
  const media = new MediaController({
    async downloadPhoto(actualOwner, actualFile, token) {
      assert.deepEqual([actualOwner, actualFile, token], [owner, file, 'Bearer viewer']);
      return new Response('webp');
    },
  });
  await media.download(owner, file, 'Bearer viewer', response);
  assert.equal(headers['Cache-Control'], 'private, no-store');
  assert.equal(response.mime, 'image/webp');
  assert.equal(response.body.toString(), 'webp');
});
test('currency quotes preserve original COP and reject unsupported currency',async()=>{
  const currency=new CurrencyController();
  const cop=await currency.quote('COP');assert.equal(cop.rate,1);assert.equal(cop.approximate,false);
  await assert.rejects(currency.quote('FAKE'),/Divisa no disponible/);
});
