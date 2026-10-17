import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';

export const datasetUrl = 'https://www.datos.gov.co/resource/7cci-nqqb.json?$select=orden,fecha,hora,gravedad,nombrecomuna,automovil,moto,bicicleta,peaton&$order=orden&$limit=50000';
export function aggregate(rows) {
  const seen = new Set(), groups = new Map(), discarded = {};
  let valid = 0, first = null, last = null;
  const reject = reason => discarded[reason] = (discarded[reason] ?? 0) + 1;
  for (const row of rows) {
    const dateMatch = /^(\d{4}-\d{2}-\d{2})T00:00:00(?:\.000)?$/.exec(row.fecha ?? '');
    const hourMatch = /T(\d{2}):(\d{2}):(\d{2})(?:\.000)?$/.exec(row.hora ?? '');
    if (!dateMatch || !hourMatch || +hourMatch[1] > 23 || +hourMatch[2] > 59 || +hourMatch[3] > 59) { reject('invalid_date_or_hour'); continue; }
    const date = dateMatch[1], parsed = new Date(date + 'T00:00:00Z');
    if (!Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== date || date < '2000-01-01' || date > '2026-10-16') { reject('invalid_date'); continue; }
    if (!row.orden || seen.has(row.orden)) { reject('missing_or_duplicate_id'); continue; }
    const counts = ['automovil', 'moto', 'bicicleta', 'peaton'].map(key => /^\d+$/.test(row[key] ?? '') ? Number(row[key]) : NaN);
    if (counts.some(n => !Number.isSafeInteger(n))) { reject('invalid_actor_count'); continue; }
    const commune = String(row.nombrecomuna ?? '').trim().toUpperCase();
    const severity = String(row.gravedad ?? '').trim().toLowerCase();
    if (!commune || !['con heridos', 'solo daños', 'con muertos'].includes(severity)) { reject('missing_or_unknown_category'); continue; }
    seen.add(row.orden); valid++;
    first = first === null || date < first ? date : first;
    last = last === null || date > last ? date : last;
    // Local civil hour is explicit in source; the 1899 date in hora is a placeholder.
    const dimensions = { month: date.slice(0, 7), weekday: String((parsed.getUTCDay() + 6) % 7 + 1), hour: hourMatch[1], commune, severity };
    for (const [dimension, value] of Object.entries(dimensions)) {
      const key = `${dimension}|${value}`;
      groups.set(key, (groups.get(key) ?? 0) + 1);
    }
  }
  return { received: rows.length, valid, discarded: rows.length - valid, discardedReasons: discarded,
    dateRange: { first, last }, variables: ['orden','fecha','hora','gravedad','nombrecomuna','automovil','moto','bicicleta','peaton'],
    groups: [...groups.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([key, count]) => { const [dimension, value] = key.split('|'); return { dimension, value, count }; }),
    interpretation: 'Historical crash counts, not traffic speeds, exposure-adjusted risk, corridor demand, or optimal departure times. No current route ranking derived from these counts.' };
}

async function main() {
  const [source, output] = process.argv.slice(2);
  if (!source || !output) throw new Error('Usage: node tools/mobility-history.mjs source.json output-directory');
  const started = performance.now(), bytes = await readFile(source);
  const rows = JSON.parse(bytes.toString('utf8'));
  if (!Array.isArray(rows)) throw new Error('Expected Socrata array');
  const result = aggregate(rows);
  result.processingMilliseconds = performance.now() - started;
  result.executedAt = new Date().toISOString();
  result.source = { url: datasetUrl, sha256: createHash('sha256').update(bytes).digest('hex'), bytes: bytes.length,
    publisher: 'Alcaldía de Bucaramanga, Santander', datasetId: '7cci-nqqb',
    license: 'CC BY-SA 4.0', licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
    scope: 'One bounded request, limit 50000; does not assert portal completeness. Derived aggregates shared under CC BY-SA 4.0.' };
  await mkdir(output, { recursive: true });
  await writeFile(output + '/historical-analysis.json', JSON.stringify(result, null, 2) + '\n');
  await writeFile(output + '/historical-groups.csv', 'dimension,value,count\n' + result.groups.map(g => `${g.dimension},"${g.value.replaceAll('"','""')}",${g.count}`).join('\n') + '\n');
  console.log(JSON.stringify({ ...result, groups: `${result.groups.length} aggregates written` }, null, 2));
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) await main();
