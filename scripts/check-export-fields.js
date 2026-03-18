import { config } from 'dotenv';
import { db } from '@vercel/postgres';

const envPath = process.env.DOTENV_CONFIG_PATH ?? '.env.local';
config({ path: envPath });

const TABLES_TO_CHECK = {
  exercises: [
    'id',
    'name',
    'target_weight',
    'target_reps',
    'is_machine',
    'notes',
    'workout_type',
    'order_index',
    'client_updated_at',
    'created_at',
    'updated_at',
    'deleted_at',
    'server_version',
    'last_idempotency_key',
  ],
  workout_logs: [
    'id',
    'exercise_id',
    'date',
    'actual_weight',
    'actual_reps',
    'is_machine',
    'feeling',
    'notes',
    'client_updated_at',
    'created_at',
    'updated_at',
    'deleted_at',
    'server_version',
    'last_idempotency_key',
  ],
  content_notes: [
    'id',
    'title',
    'body',
    'url',
    'client_updated_at',
    'created_at',
    'updated_at',
    'deleted_at',
    'server_version',
    'last_idempotency_key',
  ],
  body_weights: [
    'id',
    'date',
    'weight',
    'notes',
    'client_updated_at',
    'created_at',
    'updated_at',
    'deleted_at',
    'server_version',
    'last_idempotency_key',
  ],
};

function hasDatabaseUrl() {
  return Boolean(
    process.env.POSTGRES_URL ||
      process.env.POSTGRES_PRISMA_URL ||
      process.env.POSTGRES_URL_NON_POOLING,
  );
}

async function fetchTableColumns(client, tableName) {
  const result = await client.query(
    `
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = $1
      ORDER BY ordinal_position
    `,
    [tableName],
  );

  return new Set((result.rows ?? []).map((row) => String(row.column_name)));
}

async function main() {
  if (!hasDatabaseUrl()) {
    console.error(`No Postgres connection string found in ${envPath}.`);
    process.exit(1);
  }

  const client = await db.connect();

  try {
    const failures = [];

    for (const [tableName, expectedColumns] of Object.entries(TABLES_TO_CHECK)) {
      const actualColumns = await fetchTableColumns(client, tableName);
      const missingColumns = expectedColumns.filter((column) => !actualColumns.has(column));

      if (missingColumns.length > 0) {
        failures.push(`${tableName}: missing ${missingColumns.join(', ')}`);
      }
    }

    if (failures.length > 0) {
      failures.forEach((failure) => console.error(failure));
      process.exit(1);
    }

    console.log('Database contract check passed.');
  } finally {
    client.release();
  }
}

main().catch((error) => {
  console.error('Export field check failed:', error);
  process.exit(1);
});
