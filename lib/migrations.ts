import { db } from '@vercel/postgres';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

export interface SqlExecutor {
  query: (text: string, values?: unknown[]) => Promise<{ rows?: Array<Record<string, unknown>> }>;
}

export interface Migration {
  id: string;
  sql: string;
}

const currentDir = path.dirname(fileURLToPath(import.meta.url));
export const defaultMigrationsDirectory = path.resolve(currentDir, '../migrations');

export async function loadMigrations(directory = defaultMigrationsDirectory): Promise<Migration[]> {
  const entries = await fs.readdir(directory, { withFileTypes: true });

  const migrations = await Promise.all(
    entries
      .filter((entry) => entry.isFile() && entry.name.endsWith('.sql'))
      .sort((left, right) => left.name.localeCompare(right.name))
      .map(async (entry) => ({
        id: entry.name,
        sql: await fs.readFile(path.join(directory, entry.name), 'utf8'),
      })),
  );

  return migrations;
}

export function splitSqlStatements(sqlText: string): string[] {
  return sqlText
    .split(/;\s*(?:\r?\n|$)/)
    .map((statement) => statement.trim())
    .filter(Boolean);
}

export async function ensureMigrationTable(executor: SqlExecutor): Promise<void> {
  await executor.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id TEXT PRIMARY KEY,
      applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

export async function appliedMigrationIds(executor: SqlExecutor): Promise<Set<string>> {
  const result = await executor.query('SELECT id FROM schema_migrations ORDER BY id');
  const rows = result.rows ?? [];
  return new Set(rows.map((row) => String(row.id)));
}

export async function applyMigrations(executor: SqlExecutor, migrations: Migration[]): Promise<string[]> {
  await ensureMigrationTable(executor);

  const applied = await appliedMigrationIds(executor);
  const newlyApplied: string[] = [];

  for (const migration of migrations) {
    if (applied.has(migration.id)) {
      continue;
    }

    await executor.query('BEGIN');
    try {
      for (const statement of splitSqlStatements(migration.sql)) {
        await executor.query(statement);
      }

      await executor.query('INSERT INTO schema_migrations (id) VALUES ($1)', [migration.id]);
      await executor.query('COMMIT');
      newlyApplied.push(migration.id);
    } catch (error) {
      await executor.query('ROLLBACK');
      throw error;
    }
  }

  return newlyApplied;
}

function hasDatabaseUrl(): boolean {
  return Boolean(
    process.env.POSTGRES_URL ||
      process.env.POSTGRES_PRISMA_URL ||
      process.env.POSTGRES_URL_NON_POOLING,
  );
}

export async function runMigrations(directory = defaultMigrationsDirectory): Promise<string[]> {
  if (!hasDatabaseUrl()) {
    console.warn('Skipping DB migrations because no Postgres connection string is configured.');
    return [];
  }

  const client = await db.connect();

  try {
    const migrations = await loadMigrations(directory);
    return await applyMigrations(client as SqlExecutor, migrations);
  } finally {
    client.release();
  }
}
