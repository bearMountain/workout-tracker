import { sql } from '@vercel/postgres';

export { sql };

export async function initializeDatabase() {
  await sql`
    CREATE TABLE IF NOT EXISTS exercises (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      target_weight DECIMAL(10, 2) NOT NULL DEFAULT 0,
      target_reps INTEGER NOT NULL DEFAULT 0,
      notes TEXT DEFAULT '',
      workout_type VARCHAR(1) NOT NULL CHECK (workout_type IN ('A', 'B')),
      order_index INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  `;
  
  await sql`
    ALTER TABLE exercises
    ADD COLUMN IF NOT EXISTS client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE exercises
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE
  `;
  
  await sql`
    ALTER TABLE exercises
    ADD COLUMN IF NOT EXISTS server_version INTEGER NOT NULL DEFAULT 1
  `;
  
  await sql`
    ALTER TABLE exercises
    ADD COLUMN IF NOT EXISTS last_idempotency_key UUID
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS workout_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
      date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
      actual_weight DECIMAL(10, 2) NOT NULL,
      actual_reps INTEGER NOT NULL,
      is_machine BOOLEAN NOT NULL DEFAULT FALSE,
      feeling INTEGER NOT NULL CHECK (feeling >= 1 AND feeling <= 4),
      notes TEXT DEFAULT '',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP WITH TIME ZONE,
      server_version INTEGER NOT NULL DEFAULT 1,
      last_idempotency_key UUID
    )
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS is_machine BOOLEAN NOT NULL DEFAULT FALSE
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS server_version INTEGER NOT NULL DEFAULT 1
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS last_idempotency_key UUID
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS content_notes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      body TEXT DEFAULT '',
      url VARCHAR(500) DEFAULT '',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP WITH TIME ZONE,
      server_version INTEGER NOT NULL DEFAULT 1,
      last_idempotency_key UUID
    )
  `;
  
  await sql`
    ALTER TABLE content_notes
    ADD COLUMN IF NOT EXISTS client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE content_notes
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE
  `;
  
  await sql`
    ALTER TABLE content_notes
    ADD COLUMN IF NOT EXISTS server_version INTEGER NOT NULL DEFAULT 1
  `;
  
  await sql`
    ALTER TABLE content_notes
    ADD COLUMN IF NOT EXISTS last_idempotency_key UUID
  `;

  await sql`
    CREATE INDEX IF NOT EXISTS idx_exercises_workout_type ON exercises(workout_type)
  `;

  await sql`
    CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise_id ON workout_logs(exercise_id)
  `;

  await sql`
    CREATE INDEX IF NOT EXISTS idx_workout_logs_date ON workout_logs(date DESC)
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS body_weights (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      date TIMESTAMP WITH TIME ZONE NOT NULL,
      weight DECIMAL(10, 2) NOT NULL,
      notes TEXT DEFAULT '',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      deleted_at TIMESTAMP WITH TIME ZONE,
      server_version INTEGER NOT NULL DEFAULT 1,
      last_idempotency_key UUID
    )
  `;
  
  await sql`
    ALTER TABLE body_weights
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE body_weights
    ADD COLUMN IF NOT EXISTS client_updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  `;
  
  await sql`
    ALTER TABLE body_weights
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE
  `;
  
  await sql`
    ALTER TABLE body_weights
    ADD COLUMN IF NOT EXISTS server_version INTEGER NOT NULL DEFAULT 1
  `;
  
  await sql`
    ALTER TABLE body_weights
    ADD COLUMN IF NOT EXISTS last_idempotency_key UUID
  `;

  await sql`
    CREATE INDEX IF NOT EXISTS idx_body_weights_date ON body_weights(date DESC)
  `;
  
  await sql`
    CREATE INDEX IF NOT EXISTS idx_exercises_updated_at ON exercises(updated_at DESC)
  `;
  
  await sql`
    CREATE INDEX IF NOT EXISTS idx_workout_logs_updated_at ON workout_logs(updated_at DESC)
  `;
  
  await sql`
    CREATE INDEX IF NOT EXISTS idx_content_notes_updated_at ON content_notes(updated_at DESC)
  `;
  
  await sql`
    CREATE INDEX IF NOT EXISTS idx_body_weights_updated_at ON body_weights(updated_at DESC)
  `;
}

export function formatResponse<T>(data: T, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function errorResponse(message: string, status = 400) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function normalizeSyncFields(row: any) {
  return {
    client_updated_at: row.client_updated_at,
    updated_at: row.updated_at,
    created_at: row.created_at,
    deleted_at: row.deleted_at,
    server_version: Number(row.server_version),
    last_idempotency_key: row.last_idempotency_key,
  };
}

// Convert Postgres DECIMAL strings to numbers to match TypeScript types
export function normalizeExercise(row: any) {
  return {
    ...row,
    target_weight: Number(row.target_weight),
    target_reps: Number(row.target_reps),
    is_machine: Boolean(row.is_machine),
    order_index: Number(row.order_index),
    ...normalizeSyncFields(row),
  };
}

export function normalizeWorkoutLog(row: any) {
  return {
    ...row,
    actual_weight: Number(row.actual_weight),
    actual_reps: Number(row.actual_reps),
    is_machine: Boolean(row.is_machine),
    feeling: Number(row.feeling),
    ...normalizeSyncFields(row),
  };
}

export function normalizeBodyWeight(row: any) {
  return {
    ...row,
    weight: Number(row.weight),
    ...normalizeSyncFields(row),
  };
}

export function normalizeContentNote(row: any) {
  return {
    ...row,
    ...normalizeSyncFields(row),
  };
}
