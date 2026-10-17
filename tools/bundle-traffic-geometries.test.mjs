import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { generateModule, geometryInputs, outputUrl } from './bundle-traffic-geometries.mjs';
import { insideGeometry } from '../supabase/functions/traffic-flow/handler.mjs';

const moduleText = await readFile(outputUrl, 'utf8');
// The .ts module deliberately contains JS-compatible literal exports only.
// Import the actual generated contents; no regex extraction or coordinate conversion.
const bundled = await import(`data:text/javascript;base64,${Buffer.from(moduleText).toString('base64')}`);
const original = [];
for (const input of geometryInputs) {
  const bytes = await readFile(new URL(`../assets/geo/${input.asset}`, import.meta.url));
  const geometries = JSON.parse(bytes.toString('utf8')).features.map(f => f.geometry);
  original.push({ ...input, bytes, geometries });
}
const hash = bytes => createHash('sha256').update(bytes).digest('hex');

test('generated module is deterministic and contains exactly all original geometries', async () => {
  assert.equal(moduleText, await generateModule());
  assert.deepEqual(bundled.geometries, original.flatMap(m => m.geometries));
  assert.equal(bundled.geometrySources.length, 3);
});

for (const [index, municipality] of original.entries()) {
  test(`${municipality.name}: source bytes, numeric coordinates, rings and hashes unchanged`, async () => {
    const descriptor = bundled.geometrySources[index];
    assert.equal(descriptor.code, municipality.code);
    assert.equal(descriptor.originalSha256, hash(municipality.bytes));
    assert.equal(descriptor.geometriesSha256, hash(JSON.stringify(municipality.geometries)));
    const preservedServerCopy = await readFile(new URL(`../supabase/functions/traffic-flow/geo/${municipality.asset}`, import.meta.url));
    assert.deepEqual(preservedServerCopy, municipality.bytes);
  });
}

test('known interior municipalities and exterior Piedecuesta/Bogotá keep identical decisions', async () => {
  const references = JSON.parse(await readFile(new URL('../test/fixtures/boundary-reference-points.json', import.meta.url), 'utf8'));
  const expected = [[true,false,false], [true,false,false], [false,false,true], [false,true,false], [false,false,false]];
  const old = original.flatMap(m => m.geometries);
  for (const [index, record] of references.entries()) {
    const point = record.results[0];
    const previous = old.map(g => insideGeometry(+point.lat, +point.lon, g));
    const current = bundled.geometries.map(g => insideGeometry(+point.lat, +point.lon, g));
    assert.deepEqual(current, previous, record.query);
    assert.deepEqual(current, expected[index], record.query);
  }
  assert.equal(bundled.geometries.some(g => insideGeometry(4.711,-74.072,g)), false);
});

test('municipal grid and ring boundary probes give identical old/new containment', () => {
  const previous = original.flatMap(m => m.geometries);
  for (const [index, geometry] of previous.entries()) {
    const rings = geometry.type === 'Polygon' ? geometry.coordinates : geometry.coordinates.flat();
    const coordinates = rings.flat();
    const xs = coordinates.map(p=>p[0]), ys = coordinates.map(p=>p[1]);
    const west=Math.min(...xs),east=Math.max(...xs),south=Math.min(...ys),north=Math.max(...ys);
    const points=[];
    for(let x=0;x<=20;x++) for(let y=0;y<=20;y++) {
      points.push([west+(east-west)*x/20,south+(north-south)*y/20]);
    }
    points.push([west-.01,south-.01],[east+.01,north+.01]);
    for(const ring of rings) for(const point of [ring[0],ring[Math.floor(ring.length/2)],ring.at(-1)]) {
      points.push(point,[point[0]+1e-8,point[1]],[point[0]-1e-8,point[1]]);
    }
    for(const [lon,lat] of points) {
      assert.equal(insideGeometry(lat,lon,bundled.geometries[index]),insideGeometry(lat,lon,geometry),`${index}: ${lat},${lon}`);
    }
  }
});

test('entrypoint imports local bundle only; JWT and security implementation preserved', async () => {
  const index = await readFile(new URL('../supabase/functions/traffic-flow/index.ts', import.meta.url), 'utf8');
  const config = await readFile(new URL('../supabase/config.toml', import.meta.url), 'utf8');
  assert.match(index, /import \{ geometries \} from ['"]\.\/geometries\.generated\.ts['"]/);
  assert.doesNotMatch(index, /Deno\.readTextFile|\.\/geo\//);
  assert.doesNotMatch(config, /static_files/);
  assert.match(config, /verify_jwt\s*=\s*true/);
  assert.match(index, /\/auth\/v1\/user/);
  assert.match(index, /\/rest\/v1\/rpc\/consume_traffic_quota/);
  assert.match(index, /Deno\.env\.get\('TOMTOM_API_KEY'\)/);
});
