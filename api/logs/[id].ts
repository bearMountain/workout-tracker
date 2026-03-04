import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeWorkoutLog } from '../../lib/db.js';
import type { UpdateWorkoutLogInput, WorkoutLog } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Invalid log ID' });
  }

  try {
    if (req.method === 'GET') {
      const result = await sql<WorkoutLog>`
        SELECT wl.*, e.name as exercise_name, e.workout_type
        FROM workout_logs wl
        JOIN exercises e ON wl.exercise_id = e.id
        WHERE wl.id = ${id}
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Workout log not found' });
      }

      return res.status(200).json(normalizeWorkoutLog(result.rows[0]));
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateWorkoutLogInput;
      
      const existing = await sql<WorkoutLog>`
        SELECT * FROM workout_logs WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Workout log not found' });
      }

      const current = existing.rows[0];

      if (body.feeling !== undefined && (body.feeling < 1 || body.feeling > 5)) {
        return res.status(400).json({ error: 'feeling must be between 1 and 5' });
      }

      const result = await sql<WorkoutLog>`
        UPDATE workout_logs SET
          date = ${body.date ?? current.date},
          actual_weight = ${body.actual_weight ?? current.actual_weight},
          actual_reps = ${body.actual_reps ?? current.actual_reps},
          feeling = ${body.feeling ?? current.feeling},
          notes = ${body.notes ?? current.notes}
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeWorkoutLog(result.rows[0]));
    }

    if (req.method === 'DELETE') {
      const result = await sql`
        DELETE FROM workout_logs WHERE id = ${id} RETURNING id
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Workout log not found' });
      }

      return res.status(200).json({ deleted: true, id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in log handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
