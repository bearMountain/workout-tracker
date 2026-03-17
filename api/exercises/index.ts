import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeExercise } from '../../lib/db.js';
import type { CreateExerciseInput, Exercise } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { workout_type, since } = req.query;
      const sinceValue = typeof since === 'string' ? since : null;
      
      let result;
      if (workout_type && (workout_type === 'A' || workout_type === 'B')) {
        result = await sql<Exercise>`
          SELECT * FROM exercises 
          WHERE workout_type = ${workout_type}
            AND (${sinceValue}::timestamptz IS NULL OR updated_at >= ${sinceValue}::timestamptz)
          ORDER BY order_index ASC
        `;
      } else {
        result = await sql<Exercise>`
          SELECT * FROM exercises 
          WHERE (${sinceValue}::timestamptz IS NULL OR updated_at >= ${sinceValue}::timestamptz)
          ORDER BY workout_type, order_index ASC
        `;
      }
      
      return res.status(200).json(result.rows.map(normalizeExercise));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateExerciseInput;
      
      if (!body.name || !body.workout_type || !body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'name, workout_type, client_updated_at, and idempotency_key are required' });
      }

      if (body.workout_type !== 'A' && body.workout_type !== 'B') {
        return res.status(400).json({ error: 'workout_type must be A or B' });
      }

      const existing = body.id
        ? await sql<Exercise>`SELECT * FROM exercises WHERE id = ${body.id}`
        : { rows: [] as Exercise[] };
      const current = existing.rows[0];

      if (current?.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeExercise(current));
      }

      if (current && new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeExercise(current));
      }

      let result;
      if (current) {
        result = await sql<Exercise>`
          UPDATE exercises SET
            name = ${body.name},
            target_weight = ${body.target_weight || 0},
            target_reps = ${body.target_reps || 0},
            notes = ${body.notes || ''},
            workout_type = ${body.workout_type},
            order_index = ${body.order_index || 0},
            client_updated_at = ${body.client_updated_at},
            deleted_at = ${body.deleted_at ?? null},
            last_idempotency_key = ${body.idempotency_key},
            server_version = exercises.server_version + 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ${current.id}
          RETURNING *
        `;
      } else {
        result = await sql<Exercise>`
          INSERT INTO exercises (id, name, target_weight, target_reps, notes, workout_type, order_index, client_updated_at, deleted_at, server_version, last_idempotency_key)
          VALUES (
            COALESCE(${body.id ?? null}, gen_random_uuid()),
            ${body.name},
            ${body.target_weight || 0},
            ${body.target_reps || 0},
            ${body.notes || ''},
            ${body.workout_type},
            ${body.order_index || 0},
            ${body.client_updated_at},
            ${body.deleted_at ?? null},
            1,
            ${body.idempotency_key}
          )
          RETURNING *
        `;
      }

      return res.status(201).json(normalizeExercise(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in exercises handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
