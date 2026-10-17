import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHandler,insideGeometry} from './handler.mjs';
const req = point => new Request('http://local/traffic-flow',{method:'POST',headers:{Authorization:'Bearer test'},body:JSON.stringify(point??{latitude:7.1,longitude:-73.1})});
const defaults = {key:'TEST_ONLY_NOT_A_CREDENTIAL',authenticate:async()=> 'test-user',consumeQuota:async()=>true,contains:()=>true};
test('proxy fails closed without credentials, auth, quota, or territorial match',async()=>{
  for(const [change,status] of [[{key:undefined},503],[{authenticate:async()=>null},401],[{consumeQuota:async()=>false},429],[{contains:()=>false},422]]) {
    const handler=createHandler({...defaults,...change,fetcher:()=>assert.fail('No provider call expected')});
    assert.equal((await handler(req())).status,status);
  }
});
test('proxy bounded cache and redaction preserve observation timestamp',async()=>{
  let calls=0;
  const handler=createHandler({...defaults,fetcher:async()=>{calls++;return Response.json({flowSegmentData:{confidence:.9}});},clock:()=>new Date('2026-10-16T23:00:00Z')});
  const a=await(await handler(req())).json(), b=await(await handler(req())).json();
  assert.equal(calls,1);assert.equal(b.code,'CACHED');assert.equal(a.queriedAt,b.queriedAt);
  assert.ok(!JSON.stringify(a).includes(defaults.key));
});
test('provider failure exposes no secret, URL or provider body',async()=>{
  const handler=createHandler({...defaults,fetcher:async()=>{throw Error(defaults.key);}});
  const result=await handler(req());assert.equal(result.status,503);assert.ok(!(await result.text()).includes(defaults.key));
});
test('server polygon excludes holes and outside points',()=>{
 const geometry={type:'Polygon',coordinates:[[[0,0],[4,0],[4,4],[0,4],[0,0]],[[1,1],[2,1],[2,2],[1,2],[1,1]]]};
 assert.equal(insideGeometry(.5,.5,geometry),true);assert.equal(insideGeometry(1.5,1.5,geometry),false);assert.equal(insideGeometry(5,5,geometry),false);
});
