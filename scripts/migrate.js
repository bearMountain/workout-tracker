import { config } from 'dotenv';
import { db } from '@vercel/postgres';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const envPath = process.env.DOTENV_CONFIG_PATH ?? '.env.local';
config({ path: envPath });

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.resolve(currentDir, '../migrations');
const mode = process.argv[2] ?? 'apply';

function hasDatabaseUrl() {
  return Boolean(
    process.env.POSTGRES_URL ||
      process.env.POSTGRES_PRISMA_URL ||
      process.env.POSTGRES_URL_NON_POOLING,
  );
}

async function loadMigrationFiles() {
  const entries = await fs.readdir(migrationsDir, { withFileTypes: true });

  return Promise.all(
    entries
      .filter((entry) => entry.isFile() && entry.name.endsWith('.sql'))
      .sort((left, right) => left.name.localeCompare(right.name))
      .map(async (entry) => ({
        id: entry.name,
        sql: await fs.readFile(path.join(migrationsDir, entry.name), 'utf8'),
      })),
  );
}

function splitStatements(sqlText) {
  return sqlText
    .split(/;\s*(?:\r?\n|$)/)
    .map((statement) => statement.trim())
    .filter(Boolean);
}

async function ensureMigrationTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id TEXT PRIMARY KEY,
      applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

async function getAppliedMigrations(client) {
  const result = await client.query('SELECT id, applied_at FROM schema_migrations ORDER BY id');
  return result.rows ?? [];
}

function summarizeStatus(migrationFiles, appliedRows) {
  const fileIds = migrationFiles.map((migration) => migration.id);
  const appliedIds = appliedRows.map((row) => String(row.id));

  const pending = fileIds.filter((id) => !appliedIds.includes(id));
  const orphaned = appliedIds.filter((id) => !fileIds.includes(id));

  return {
    fileIds,
    appliedIds,
    pending,
    orphaned,
  };
}

async function applyMigrations(client, migrationFiles, appliedIds) {
  const newlyApplied = [];

  for (const migration of migrationFiles) {
    if (appliedIds.includes(migration.id)) {
      continue;
    }

    await client.query('BEGIN');
    try {
      for (const statement of splitStatements(migration.sql)) {
        await client.query(statement);
      }

      await client.query('INSERT INTO schema_migrations (id) VALUES ($1)', [migration.id]);
      await client.query('COMMIT');
      newlyApplied.push(migration.id);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    }
  }

  return newlyApplied;
}

function printStatus(status) {
  console.log(`Executed migrations: ${status.appliedIds.length}`);
  console.log(`Pending migrations: ${status.pending.length}`);
  console.log(`Orphaned migration records: ${status.orphaned.length}`);

  if (status.pending.length > 0) {
    console.log(`Pending: ${status.pending.join(', ')}`);
  }

  if (status.orphaned.length > 0) {
    console.log(`Orphaned: ${status.orphaned.join(', ')}`);
  }
}

async function main() {
  if (!hasDatabaseUrl()) {
    console.error(`No Postgres connection string found in ${envPath}.`);
    process.exit(1);
  }

  if (!['apply', 'verify'].includes(mode)) {
    console.error(`Unknown mode "${mode}". Use "verify" or no argument.`);
    process.exit(1);
  }

  const client = await db.connect();

  try {
    await ensureMigrationTable(client);
    const migrationFiles = await loadMigrationFiles();
    const beforeApplied = await getAppliedMigrations(client);

    if (mode === 'apply') {
      const newlyApplied = await applyMigrations(
        client,
        migrationFiles,
        beforeApplied.map((row) => String(row.id)),
      );

      if (newlyApplied.length === 0) {
        console.log('No pending migrations.');
      } else {
        console.log(`Applied migrations: ${newlyApplied.join(', ')}`);
      }
    }

    const afterApplied = await getAppliedMigrations(client);
    const status = summarizeStatus(migrationFiles, afterApplied);

    if (mode === 'verify') {
      printStatus(status);

      if (status.pending.length > 0 || status.orphaned.length > 0) {
        process.exit(1);
      }

      console.log('Migration verification passed.');
    }
  } finally {
    client.release();
  }
}

main().catch((error) => {
  console.error('Migration command failed:', error);
  process.exit(1);
});
