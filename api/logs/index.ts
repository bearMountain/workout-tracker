import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeWorkoutLog } from '../../lib/db.js';
import type { CreateWorkoutLogInput, WorkoutLog } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { exercise_id, limit, offset, since } = req.query;
      
      const limitNum = Math.min(parseInt(limit as string) || 50, 100);
      const offsetNum = parseInt(offset as string) || 0;
      const sinceValue = typeof since === 'string' ? since : null;

      let result;
      if (exercise_id && typeof exercise_id === 'string') {
        result = await sql<WorkoutLog>`
          SELECT wl.*, e.name as exercise_name, e.workout_type
          FROM workout_logs wl
          JOIN exercises e ON wl.exercise_id = e.id
          WHERE wl.exercise_id = ${exercise_id}
            AND (${sinceValue}::timestamptz IS NULL OR wl.updated_at >= ${sinceValue}::timestamptz)
          ORDER BY wl.date DESC
          LIMIT ${limitNum} OFFSET ${offsetNum}
        `;
      } else {
        result = await sql<WorkoutLog>`
          SELECT wl.*, e.name as exercise_name, e.workout_type
          FROM workout_logs wl
          JOIN exercises e ON wl.exercise_id = e.id
          WHERE (${sinceValue}::timestamptz IS NULL OR wl.updated_at >= ${sinceValue}::timestamptz)
          ORDER BY wl.date DESC
          LIMIT ${limitNum} OFFSET ${offsetNum}
        `;
      }
      
      return res.status(200).json(result.rows.map(normalizeWorkoutLog));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateWorkoutLogInput;
      
      if (!body.exercise_id || body.actual_weight === undefined || 
          body.actual_reps === undefined || body.feeling === undefined ||
          !body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ 
          error: 'exercise_id, actual_weight, actual_reps, feeling, client_updated_at, and idempotency_key are required' 
        });
      }

      if (body.feeling < 1 || body.feeling > 4) {
        return res.status(400).json({ error: 'feeling must be between 1 and 4' });
      }

      const exerciseExists = await sql`
        SELECT id FROM exercises WHERE id = ${body.exercise_id}
      `;

      if (exerciseExists.rows.length === 0) {
        return res.status(400).json({ error: 'Exercise not found' });
      }

      const existing = body.id
        ? await sql<WorkoutLog>`SELECT * FROM workout_logs WHERE id = ${body.id}`
        : { rows: [] as WorkoutLog[] };
      const current = existing.rows[0];

      if (current?.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeWorkoutLog(current));
      }

      if (current && new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeWorkoutLog(current));
      }

      let result;
      if (current) {
        result = await sql<WorkoutLog>`
          UPDATE workout_logs SET
            exercise_id = ${body.exercise_id},
            date = ${body.date || current.date},
            actual_weight = ${body.actual_weight},
            actual_reps = ${body.actual_reps},
            is_machine = ${body.is_machine ?? false},
            feeling = ${body.feeling},
            notes = ${body.notes || ''},
            client_updated_at = ${body.client_updated_at},
            deleted_at = ${body.deleted_at ?? null},
            last_idempotency_key = ${body.idempotency_key},
            server_version = workout_logs.server_version + 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ${current.id}
          RETURNING *
        `;
      } else {
        result = await sql<WorkoutLog>`
          INSERT INTO workout_logs (id, exercise_id, date, actual_weight, actual_reps, is_machine, feeling, notes, client_updated_at, deleted_at, server_version, last_idempotency_key)
          VALUES (
            COALESCE(${body.id ?? null}, gen_random_uuid()),
            ${body.exercise_id},
            ${body.date || new Date().toISOString()},
            ${body.actual_weight},
            ${body.actual_reps},
            ${body.is_machine ?? false},
            ${body.feeling},
            ${body.notes || ''},
            ${body.client_updated_at},
            ${body.deleted_at ?? null},
            1,
            ${body.idempotency_key}
          )
          RETURNING *
        `;
      }

      return res.status(201).json(normalizeWorkoutLog(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in logs handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
