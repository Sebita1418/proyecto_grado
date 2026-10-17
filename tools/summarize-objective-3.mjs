import {readFile,writeFile} from 'node:fs/promises';
const folder=process.argv[2];
if(!folder)throw Error('Usage: node tools/summarize-objective-3.mjs evidence-directory');
const readJson=async name=>JSON.parse(await readFile(`${folder}/${name}`,'utf8'));
const requests=await readJson('provider-requests.json'),comparisons=await readJson('comparisons.json');
const rows=[];
for(const request of requests){
 if(request.status!==200||request.code!=='Ok')continue;
 const body=await readJson(request.file),base=body.routes[0];
 for(const [index,route]of body.routes.entries())rows.push({
  id:request.id,mode:request.mode,alternative:index+1,distanceMeters:route.distance,durationSeconds:route.duration,
  distanceDifferenceMeters:route.distance-base.distance,distanceDifferencePercent:100*(route.distance-base.distance)/base.distance,
  durationDifferenceSeconds:route.duration-base.duration,durationDifferencePercent:100*(route.duration-base.duration)/base.duration,
  queryMilliseconds:request.elapsedMilliseconds,
 });
}
const summary={executedAt:new Date().toISOString(),
 realRequests:requests.length,realSuccessfulRequests:requests.filter(r=>r.status===200&&r.code==='Ok').length,
 realRouteAlternatives:rows.length,comparedRecommendationScenarios:comparisons.length,
 explainableScenarios:comparisons.filter(c=>c.explainable).length,
 explainablePercent:comparisons.length?100*comparisons.filter(c=>c.explainable).length/comparisons.length:null,
 realTrafficRequests:0,trafficStatus:'BLOCKED: user has no key; client disabled; no provider coverage measured',
 warning:'Recommendation scenarios combine explicitly labelled controlled fixtures and captured real OSRM. Replay uses mock HTTP transport with original bytes. Timings are single local test executions, not a statistical benchmark, device latency, observed travel times or real savings.'};
await writeFile(folder+'/real-mode-comparison.json',JSON.stringify(rows,null,2)+'\n');
const columns=Object.keys(rows[0]??{});
await writeFile(folder+'/real-mode-comparison.csv',columns.join(',')+'\n'+rows.map(r=>columns.map(c=>r[c]).join(',')).join('\n')+'\n');
await writeFile(folder+'/quantitative-summary.json',JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
