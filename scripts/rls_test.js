const { Client } = require('pg');

const conn = process.env.CONN_STRING || 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

async function run() {
  const client = new Client({ connectionString: conn });
  await client.connect();

  // Helper to run a query with simulated JWT
  async function withClaims(claimsJson, query) {
    // use a transaction and set the local request.jwt.claims
    await client.query('begin');
    await client.query(`set local request.jwt.claims = '${claimsJson.replace(/'/g, "''")}'`);
    const res = await client.query(query);
    await client.query('rollback');
    return res;
  }

  console.log('RLS test: valid org claims (should return rows for org1)');
  const valid = await withClaims('{"sub":"33333333-3333-3333-3333-333333333333","org_id":"11111111-1111-1111-1111-111111111111"}', 'select count(*)::int as cnt from jobs');
  console.log('jobs count for valid org:', valid.rows[0].cnt);

  console.log('RLS test: other org claims (should return 0)');
  const invalid = await withClaims('{"sub":"deadbeef-dead-beef-dead-beefdeadbeef","org_id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}', 'select count(*)::int as cnt from jobs');
  console.log('jobs count for other org:', invalid.rows[0].cnt);

  console.log('RLS test: second org claims (should return rows for org2)');
  const valid2 = await withClaims('{"sub":"44444444-4444-4444-4444-444444444444","org_id":"22222222-1111-2222-1111-222222222222"}', 'select count(*)::int as cnt from jobs');
  console.log('jobs count for org2:', valid2.rows[0].cnt);

  await client.end();
}

run().catch(e => { console.error(e); process.exit(1); });
