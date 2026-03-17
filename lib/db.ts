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
    CREATE TABLE IF NOT EXISTS workout_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
      date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
      actual_weight DECIMAL(10, 2) NOT NULL,
      actual_reps INTEGER NOT NULL,
      is_machine BOOLEAN NOT NULL DEFAULT FALSE,
      feeling INTEGER NOT NULL CHECK (feeling >= 1 AND feeling <= 5),
      notes TEXT DEFAULT '',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  `;
  
  await sql`
    ALTER TABLE workout_logs
    ADD COLUMN IF NOT EXISTS is_machine BOOLEAN NOT NULL DEFAULT FALSE
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS content_notes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title VARCHAR(255) NOT NULL,
      body TEXT DEFAULT '',
      url VARCHAR(500) DEFAULT '',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
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
      created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
  `;

  await sql`
    CREATE INDEX IF NOT EXISTS idx_body_weights_date ON body_weights(date DESC)
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

// Convert Postgres DECIMAL strings to numbers to match TypeScript types
export function normalizeExercise(row: Record<string, unknown>) {
  return {
    ...row,
    target_weight: Number(row.target_weight),
    target_reps: Number(row.target_reps),
    order_index: Number(row.order_index),
  };
}

export function normalizeWorkoutLog(row: Record<string, unknown>) {
  return {
    ...row,
    actual_weight: Number(row.actual_weight),
    actual_reps: Number(row.actual_reps),
    is_machine: Boolean(row.is_machine),
    feeling: Number(row.feeling),
  };
}

export function normalizeBodyWeight(row: Record<string, unknown>) {
  return {
    ...row,
    weight: Number(row.weight),
  };
}
