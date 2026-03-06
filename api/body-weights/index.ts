import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeBodyWeight } from '../../lib/db.js';
import type { BodyWeight, CreateBodyWeightInput } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { limit, offset } = req.query;
      
      const limitNum = Math.min(parseInt(limit as string) || 50, 100);
      const offsetNum = parseInt(offset as string) || 0;

      const result = await sql<BodyWeight>`
        SELECT *
        FROM body_weights
        ORDER BY date DESC
        LIMIT ${limitNum} OFFSET ${offsetNum}
      `;
      
      return res.status(200).json(result.rows.map(normalizeBodyWeight));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateBodyWeightInput;
      
      if (body.weight === undefined) {
        return res.status(400).json({ error: 'weight is required' });
      }

      if (body.weight <= 0) {
        return res.status(400).json({ error: 'weight must be positive' });
      }

      let result;
      if (body.id) {
        result = await sql<BodyWeight>`
          INSERT INTO body_weights (id, date, weight, notes)
          VALUES (
            ${body.id},
            ${body.date || new Date().toISOString()},
            ${body.weight},
            ${body.notes || ''}
          )
          ON CONFLICT (id) DO UPDATE SET
            date = EXCLUDED.date,
            weight = EXCLUDED.weight,
            notes = EXCLUDED.notes
          RETURNING *
        `;
      } else {
        result = await sql<BodyWeight>`
          INSERT INTO body_weights (date, weight, notes)
          VALUES (
            ${body.date || new Date().toISOString()},
            ${body.weight},
            ${body.notes || ''}
          )
          RETURNING *
        `;
      }

      return res.status(201).json(normalizeBodyWeight(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in body-weights handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
