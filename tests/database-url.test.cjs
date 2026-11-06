const { test } = require('node:test');
const assert = require('node:assert/strict');
const { databaseUrl } = require('../scripts/database-url.cjs');
test('credentials cannot change connection URL structure', () => {
  const env = { DB_USER: 'a@b', DB_PASSWORD: "p:/?#$' @", DB_NAME: 'my/db' };
  const url = new URL(databaseUrl(env));
  assert.equal(decodeURIComponent(url.password), env.DB_PASSWORD);
  assert.equal(decodeURIComponent(url.username), env.DB_USER);
  assert.equal(url.hostname, 'postgres');
  assert.equal(url.pathname, '/my%2Fdb');
});
test('local DATABASE_URL remains supported; missing production values fail closed', () => {
  assert.equal(databaseUrl({ DATABASE_URL: 'postgresql://local' }), 'postgresql://local');
  for (const key of ['DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    const env = { DB_USER: 'app', DB_PASSWORD: 'test', DB_NAME: 'app' };
    delete env[key];
    assert.throws(() => databaseUrl(env), new RegExp(key));
  }
});
