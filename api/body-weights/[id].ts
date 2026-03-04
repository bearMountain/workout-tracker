import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeBodyWeight } from '../../lib/db.js';
import type { BodyWeight, UpdateBodyWeightInput } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Invalid body weight ID' });
  }

  try {
    if (req.method === 'GET') {
      const result = await sql<BodyWeight>`
        SELECT * FROM body_weights WHERE id = ${id}
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Body weight entry not found' });
      }

      return res.status(200).json(normalizeBodyWeight(result.rows[0]));
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateBodyWeightInput;
      
      const existing = await sql<BodyWeight>`
        SELECT * FROM body_weights WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Body weight entry not found' });
      }

      const current = existing.rows[0];

      if (body.weight !== undefined && body.weight <= 0) {
        return res.status(400).json({ error: 'weight must be positive' });
      }

      const result = await sql<BodyWeight>`
        UPDATE body_weights SET
          date = ${body.date ?? current.date},
          weight = ${body.weight ?? current.weight},
          notes = ${body.notes ?? current.notes}
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeBodyWeight(result.rows[0]));
    }

    if (req.method === 'DELETE') {
      const result = await sql`
        DELETE FROM body_weights WHERE id = ${id} RETURNING id
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Body weight entry not found' });
      }

      return res.status(200).json({ deleted: true, id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in body-weight handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
