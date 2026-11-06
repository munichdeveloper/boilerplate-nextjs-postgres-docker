import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import config from './database-url.cjs';
const client = postgres(config.databaseUrl(process.env), { max: 1, connect_timeout: 10 });
try {
  if (!process.env.APP_DB_PASSWORD || process.env.APP_DB_PASSWORD === process.env.DB_PASSWORD) {
    throw new Error("Set a distinct APP_DB_PASSWORD");
  }
  // Serialize cooperating migration jobs. Never run migrations in each web replica.
  await client`select pg_advisory_lock(280016)`;
  await migrate(drizzle(client), { migrationsFolder: './drizzle' });
  if (!process.env.APP_DB_PASSWORD) throw new Error('APP_DB_PASSWORD is required');
  if (!(await client`select 1 from pg_roles where rolname = 'app'`).length) {
    await client`create role app login nosuperuser nocreatedb nocreaterole`;
  }
  // postgres.js identifier/literal escaping, including quotes in passwords.
  await client.unsafe(`ALTER ROLE app PASSWORD '${process.env.APP_DB_PASSWORD.replaceAll("'", "''")}'`);
  await client`grant usage on schema public to app`;
  await client`grant select, insert, update, delete on all tables in schema public to app`;
  await client`grant usage, select on all sequences in schema public to app`;
  await client`revoke create on schema public from public`;
  console.log('Migrations and application grants complete');
} finally {
  await client`select pg_advisory_unlock(280016)`.catch(() => {});
  await client.end();
}
