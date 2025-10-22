const { Client } = require('pg');

const conn = process.env.CONN_STRING || 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

async function run() {
  const client = new Client({ connectionString: conn });
  await client.connect();

  console.log('Jobs:');
  const jobs = await client.query('select id, title, created_at from jobs order by created_at desc limit 10');
  console.table(jobs.rows);

  console.log('\nMatches:');
  const matches = await client.query("select m.id, j.title as job_title, c.name as candidate_name, m.score, m.recommendation from matches m left join jobs j on m.job_id = j.id left join candidate_profiles c on m.candidate_id = c.id order by m.score desc limit 20;");
  console.table(matches.rows);

  await client.end();
}

run().catch(err => { console.error(err); process.exit(1); });
