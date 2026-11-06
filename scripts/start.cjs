const { databaseUrl } = require('./database-url.cjs');
process.env.DATABASE_URL = databaseUrl(process.env);
require('../server.js');
