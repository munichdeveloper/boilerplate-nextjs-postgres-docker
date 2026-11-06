function databaseUrl(env) {
  if (env.DATABASE_URL) return env.DATABASE_URL;
  for (const key of ['DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    if (!env[key]) throw new Error(`${key} is required`);
  }
  return `postgresql://${encodeURIComponent(env.DB_USER)}:${encodeURIComponent(env.DB_PASSWORD)}@${env.DB_HOST || 'postgres'}:5432/${encodeURIComponent(env.DB_NAME)}`;
}
module.exports = { databaseUrl };
