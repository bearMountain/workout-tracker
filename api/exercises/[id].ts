import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeExercise } from '../../lib/db.js';
import type { UpdateExerciseInput, Exercise } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Invalid exercise ID' });
  }

  try {
    if (req.method === 'GET') {
      const result = await sql<Exercise>`
        SELECT * FROM exercises WHERE id = ${id}
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Exercise not found' });
      }

      return res.status(200).json(normalizeExercise(result.rows[0]));
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateExerciseInput;
      if (!body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'client_updated_at and idempotency_key are required' });
      }
      
      const existing = await sql<Exercise>`
        SELECT * FROM exercises WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Exercise not found' });
      }

      const current = existing.rows[0];
      if (current.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeExercise(current));
      }

      if (new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeExercise(current));
      }

      if (body.workout_type && body.workout_type !== 'A' && body.workout_type !== 'B') {
        return res.status(400).json({ error: 'workout_type must be A or B' });
      }

      const result = await sql<Exercise>`
        UPDATE exercises SET
          name = ${body.name ?? current.name},
          target_weight = ${body.target_weight ?? current.target_weight},
          target_reps = ${body.target_reps ?? current.target_reps},
          is_machine = ${body.is_machine ?? current.is_machine},
          notes = ${body.notes ?? current.notes},
          workout_type = ${body.workout_type ?? current.workout_type},
          order_index = ${body.order_index ?? current.order_index},
          client_updated_at = ${body.client_updated_at},
          deleted_at = ${body.deleted_at ?? current.deleted_at ?? null},
          last_idempotency_key = ${body.idempotency_key},
          server_version = exercises.server_version + 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeExercise(result.rows[0]));
    }

    if (req.method === 'DELETE') {
      const existing = await sql<Exercise>`
        SELECT * FROM exercises WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Exercise not found' });
      }

      const result = await sql<Exercise>`
        UPDATE exercises SET
          deleted_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP,
          client_updated_at = CURRENT_TIMESTAMP,
          server_version = exercises.server_version + 1
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeExercise(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in exercise handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
