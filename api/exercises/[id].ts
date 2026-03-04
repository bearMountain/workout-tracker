import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db.js';
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

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateExerciseInput;
      
      const existing = await sql<Exercise>`
        SELECT * FROM exercises WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Exercise not found' });
      }

      const current = existing.rows[0];

      if (body.workout_type && body.workout_type !== 'A' && body.workout_type !== 'B') {
        return res.status(400).json({ error: 'workout_type must be A or B' });
      }

      const result = await sql<Exercise>`
        UPDATE exercises SET
          name = ${body.name ?? current.name},
          target_weight = ${body.target_weight ?? current.target_weight},
          target_reps = ${body.target_reps ?? current.target_reps},
          notes = ${body.notes ?? current.notes},
          workout_type = ${body.workout_type ?? current.workout_type},
          order_index = ${body.order_index ?? current.order_index},
          updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const result = await sql`
        DELETE FROM exercises WHERE id = ${id} RETURNING id
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Exercise not found' });
      }

      return res.status(200).json({ deleted: true, id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in exercise handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
