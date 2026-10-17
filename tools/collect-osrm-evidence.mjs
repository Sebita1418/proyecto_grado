import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {insideGeometry} from '../supabase/functions/traffic-flow/handler.mjs';
const output=process.argv[2];
if(!output)throw Error('Usage: node tools/collect-osrm-evidence.mjs output-directory');
await mkdir(output,{recursive:true});
const references=JSON.parse(await readFile('test/fixtures/boundary-reference-points.json','utf8'));
const points=references.slice(0,4).map(r=>({label:r.query,latitude:+r.results[0].lat,longitude:+r.results[0].lon}));
const geometries=[];
for(const file of ['bucaramanga','giron','floridablanca']){
 const data=JSON.parse(await readFile(`assets/geo/${file}-mgn2024.geojson`,'utf8'));
 geometries.push(...data.features.map(f=>f.geometry));
}
const pairs=[[points[0],points[1]],[points[2],points[1]],[points[3],points[1]]];
const endpoints={driving:'https://router.project-osrm.org',walking:'https://routing.openstreetmap.de/routed-foot',cycling:'https://routing.openstreetmap.de/routed-bike'};
const records=[];
for(let i=0;i<pairs.length;i++)for(const[mode,endpoint]of Object.entries(endpoints)){
 const[origin,destination]=pairs[i];
 if(![origin,destination].every(p=>geometries.some(g=>insideGeometry(p.latitude,p.longitude,g))))throw Error('Endpoint outside verified polygons');
 const url=`${endpoint}/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?alternatives=true&steps=true&overview=full&geometries=geojson`;
 const queriedAt=new Date().toISOString(),start=performance.now();
 const record={id:`real-${i+1}-${mode}`,mode,origin,destination,url,queriedAt,dataNature:'real OSRM provider response; estimated metrics, no observed traffic'};
 try{
  const response=await fetch(url,{headers:{'User-Agent':'TransporteInteligente-AcademicValidation/1.0'},signal:AbortSignal.timeout(15000)});
  const bytes=Buffer.from(await response.arrayBuffer());
  record.status=response.status;record.elapsedMilliseconds=performance.now()-start;
  record.sha256=createHash('sha256').update(bytes).digest('hex');record.file=`${record.id}.json`;
  await writeFile(`${output}/${record.file}`,bytes);
  let body;try{body=JSON.parse(bytes.toString());}catch{}
  record.routeCount=body?.routes?.length??0;record.code=body?.code??null;
 }catch(error){record.status='NETWORK_ERROR';record.elapsedMilliseconds=performance.now()-start;record.error=error.name;}
 records.push(record);console.log(JSON.stringify(record));
 await writeFile(output+'/provider-requests.json',JSON.stringify(records,null,2)+'\n');
 await new Promise(resolve=>setTimeout(resolve,1100));
}
