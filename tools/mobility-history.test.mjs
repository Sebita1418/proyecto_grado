import { test } from 'node:test';
import assert from 'node:assert/strict';
import { aggregate } from './mobility-history.mjs';

const row = { orden:'1',fecha:'2012-01-01T00:00:00.000',hora:'1899-12-31T12:15:00.000',gravedad:'Con heridos',nombrecomuna:'17. MUTIS',automovil:'1',moto:'0',bicicleta:'0',peaton:'0' };
test('historical parser uses civil hour, validates dates, counts duplicates and omissions', () => {
  const result = aggregate([row, row, {...row,orden:'2',fecha:'2012-02-30T00:00:00.000'}, {...row,orden:'3',hora:'1899-12-31T25:00:00.000'}, {...row,orden:'4',moto:'-1'}]);
  assert.equal(result.received, 5); assert.equal(result.valid, 1); assert.equal(result.discarded, 4);
  assert.deepEqual(result.dateRange, {first:'2012-01-01',last:'2012-01-01'});
  assert.equal(result.groups.find(g => g.dimension === 'hour').value, '12');
  assert.equal(result.groups.find(g => g.dimension === 'weekday').value, '7');
});
test('historical aggregates conserve valid records in every dimension', () => {
  const result = aggregate([row, {...row,orden:'2',hora:'1899-12-31T08:00:00.000'}]);
  for (const dimension of ['month','weekday','hour','commune','severity']) {
    assert.equal(result.groups.filter(g=>g.dimension===dimension).reduce((n,g)=>n+g.count,0), 2);
  }
});
