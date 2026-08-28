/**
 * ExploreMate Backend - Entry Point
 * Boots the Express HTTP server and ensures DB connectivity.
 */
require('dotenv').config();

const app = require('./src/app');
const { pool, isMemory } = require('./src/config/database');
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 5000;

(async () => {
  try {
    // Test DB connection at startup
    await pool.query('SELECT 1');
    logger.info(isMemory ? 'In-memory development database ready' : 'PostgreSQL connection successful');
  } catch (err) {
    logger.error(`PostgreSQL connection failed: ${err.message}`);
    // Do not exit in dev - allow the server to start so endpoints can return helpful errors.
    if (process.env.NODE_ENV === 'production') process.exit(1);
  }

  const server = app.listen(PORT, () => {
    logger.info(`ExploreMate API running on port ${PORT} (${process.env.NODE_ENV || 'development'})`);
  });

  const shutdown = async (signal) => {
    logger.info(`Received ${signal}. Shutting down gracefully...`);
    server.close(async () => {
      await pool.end().catch(() => {});
      process.exit(0);
    });
    // Force-exit if it hangs
    setTimeout(() => process.exit(1), 10_000).unref();
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('unhandledRejection', (err) => logger.error(`Unhandled Rejection: ${err}`));
  process.on('uncaughtException', (err) => logger.error(`Uncaught Exception: ${err.message}`));
})();
