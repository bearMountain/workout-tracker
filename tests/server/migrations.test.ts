import test from 'node:test';
import assert from 'node:assert/strict';

import {
  applyMigrations,
  loadMigrations,
  splitSqlStatements,
} from '../../lib/migrations.js';

test('splitSqlStatements separates multi-statement migration files', () => {
  const statements = splitSqlStatements(`
    UPDATE exercises SET is_machine = FALSE WHERE is_machine IS NULL;
    ALTER TABLE exercises ALTER COLUMN is_machine SET NOT NULL;
  `);

  assert.deepEqual(statements, [
    'UPDATE exercises SET is_machine = FALSE WHERE is_machine IS NULL',
    'ALTER TABLE exercises ALTER COLUMN is_machine SET NOT NULL',
  ]);
});

test('loadMigrations returns schema migrations in order', async () => {
  const migrations = await loadMigrations();

  assert.deepEqual(
    migrations.map((migration) => migration.id),
    [
      '001_add_exercises_is_machine_nullable.sql',
      '002_backfill_exercises_is_machine.sql',
      '003_enforce_exercises_is_machine_not_null.sql',
      '004_add_exercises_progressive_overload.sql',
    ],
  );

  assert.match(migrations[1].sql, /workout_logs/i);
  assert.match(migrations[2].sql, /SET NOT NULL/i);
  assert.match(migrations[3].sql, /SET NOT NULL/i);
  for (const name of ['Squats', 'Dead Lift', 'Leg Extensions', 'Pec Deck', 'Bench Press']) {
    assert.match(migrations[3].sql, new RegExp(name));
  }
  assert.match(migrations[3].sql, /updated_at = CURRENT_TIMESTAMP/i);
});

test('applyMigrations records migrations after executing statements in order', async () => {
  const executed: string[] = [];

  const fakeExecutor = {
    async query(text: string, values?: unknown[]) {
      const normalized = text.replace(/\s+/g, ' ').trim();
      executed.push(values ? `${normalized} ${JSON.stringify(values)}` : normalized);

      if (normalized.startsWith('SELECT id FROM schema_migrations')) {
        return { rows: [] };
      }

      return { rows: [] };
    },
  };

  const migrations = [
    {
      id: '001_add_exercises_is_machine_nullable.sql',
      sql: 'ALTER TABLE exercises ADD COLUMN IF NOT EXISTS is_machine BOOLEAN;',
    },
    {
      id: '002_backfill_exercises_is_machine.sql',
      sql: 'UPDATE exercises SET is_machine = FALSE WHERE is_machine IS NULL;',
    },
  ];

  const applied = await applyMigrations(fakeExecutor, migrations);

  assert.deepEqual(applied, [
    '001_add_exercises_is_machine_nullable.sql',
    '002_backfill_exercises_is_machine.sql',
  ]);
  assert.equal(executed.filter((statement) => statement === 'BEGIN').length, 2);
  assert.equal(executed.filter((statement) => statement === 'COMMIT').length, 2);
  assert.ok(
    executed.some((statement) =>
      statement.startsWith('INSERT INTO schema_migrations (id) VALUES ($1) ["001_add_exercises_is_machine_nullable.sql"]'),
    ),
  );
});
