import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeWorkoutLog } from '../../lib/db.js';
import type { CreateWorkoutLogInput, WorkoutLog } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { exercise_id, limit, offset } = req.query;
      
      const limitNum = Math.min(parseInt(limit as string) || 50, 100);
      const offsetNum = parseInt(offset as string) || 0;

      let result;
      if (exercise_id && typeof exercise_id === 'string') {
        result = await sql<WorkoutLog>`
          SELECT wl.*, e.name as exercise_name, e.workout_type
          FROM workout_logs wl
          JOIN exercises e ON wl.exercise_id = e.id
          WHERE wl.exercise_id = ${exercise_id}
          ORDER BY wl.date DESC
          LIMIT ${limitNum} OFFSET ${offsetNum}
        `;
      } else {
        result = await sql<WorkoutLog>`
          SELECT wl.*, e.name as exercise_name, e.workout_type
          FROM workout_logs wl
          JOIN exercises e ON wl.exercise_id = e.id
          ORDER BY wl.date DESC
          LIMIT ${limitNum} OFFSET ${offsetNum}
        `;
      }
      
      return res.status(200).json(result.rows.map(normalizeWorkoutLog));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateWorkoutLogInput;
      
      if (!body.exercise_id || body.actual_weight === undefined || 
          body.actual_reps === undefined || body.feeling === undefined) {
        return res.status(400).json({ 
          error: 'exercise_id, actual_weight, actual_reps, and feeling are required' 
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

      let result;
      if (body.id) {
        result = await sql<WorkoutLog>`
          INSERT INTO workout_logs (id, exercise_id, date, actual_weight, actual_reps, is_machine, feeling, notes)
          VALUES (
            ${body.id},
            ${body.exercise_id},
            ${body.date || new Date().toISOString()},
            ${body.actual_weight},
            ${body.actual_reps},
            ${body.is_machine ?? false},
            ${body.feeling},
            ${body.notes || ''}
          )
          ON CONFLICT (id) DO UPDATE SET
            exercise_id = EXCLUDED.exercise_id,
            date = EXCLUDED.date,
            actual_weight = EXCLUDED.actual_weight,
            actual_reps = EXCLUDED.actual_reps,
            is_machine = EXCLUDED.is_machine,
            feeling = EXCLUDED.feeling,
            notes = EXCLUDED.notes
          RETURNING *
        `;
      } else {
        result = await sql<WorkoutLog>`
          INSERT INTO workout_logs (exercise_id, date, actual_weight, actual_reps, is_machine, feeling, notes)
          VALUES (
            ${body.exercise_id},
            ${body.date || new Date().toISOString()},
            ${body.actual_weight},
            ${body.actual_reps},
            ${body.is_machine ?? false},
            ${body.feeling},
            ${body.notes || ''}
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
