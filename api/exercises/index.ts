import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db.js';
import type { CreateExerciseInput, Exercise } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { workout_type } = req.query;
      
      let result;
      if (workout_type && (workout_type === 'A' || workout_type === 'B')) {
        result = await sql<Exercise>`
          SELECT * FROM exercises 
          WHERE workout_type = ${workout_type}
          ORDER BY order_index ASC
        `;
      } else {
        result = await sql<Exercise>`
          SELECT * FROM exercises 
          ORDER BY workout_type, order_index ASC
        `;
      }
      
      return res.status(200).json(result.rows);
    }

    if (req.method === 'POST') {
      const body = req.body as CreateExerciseInput;
      
      if (!body.name || !body.workout_type) {
        return res.status(400).json({ error: 'name and workout_type are required' });
      }

      if (body.workout_type !== 'A' && body.workout_type !== 'B') {
        return res.status(400).json({ error: 'workout_type must be A or B' });
      }

      const result = await sql<Exercise>`
        INSERT INTO exercises (name, target_weight, target_reps, notes, workout_type, order_index)
        VALUES (
          ${body.name},
          ${body.target_weight || 0},
          ${body.target_reps || 0},
          ${body.notes || ''},
          ${body.workout_type},
          ${body.order_index || 0}
        )
        RETURNING *
      `;

      return res.status(201).json(result.rows[0]);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in exercises handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
