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
      if (!body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'client_updated_at and idempotency_key are required' });
      }
      
      const existing = await sql<BodyWeight>`
        SELECT * FROM body_weights WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Body weight entry not found' });
      }

      const current = existing.rows[0];
      if (current.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeBodyWeight(current));
      }

      if (new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeBodyWeight(current));
      }

      if (body.weight !== undefined && body.weight <= 0) {
        return res.status(400).json({ error: 'weight must be positive' });
      }

      const result = await sql<BodyWeight>`
        UPDATE body_weights SET
          date = ${body.date ?? current.date},
          weight = ${body.weight ?? current.weight},
          notes = ${body.notes ?? current.notes},
          client_updated_at = ${body.client_updated_at},
          deleted_at = ${body.deleted_at ?? current.deleted_at ?? null},
          last_idempotency_key = ${body.idempotency_key},
          server_version = body_weights.server_version + 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeBodyWeight(result.rows[0]));
    }

    if (req.method === 'DELETE') {
      const existing = await sql<BodyWeight>`
        SELECT * FROM body_weights WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Body weight entry not found' });
      }

      const result = await sql<BodyWeight>`
        UPDATE body_weights SET
          deleted_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP,
          client_updated_at = CURRENT_TIMESTAMP,
          server_version = body_weights.server_version + 1
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeBodyWeight(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in body-weight handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
