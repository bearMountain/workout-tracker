import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeBodyWeight } from '../../lib/db.js';
import type { BodyWeight, CreateBodyWeightInput } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { limit, offset, since } = req.query;
      
      const limitNum = Math.min(parseInt(limit as string) || 50, 100);
      const offsetNum = parseInt(offset as string) || 0;
      const sinceValue = typeof since === 'string' ? since : null;

      const result = await sql<BodyWeight>`
        SELECT *
        FROM body_weights
        WHERE (${sinceValue}::timestamptz IS NULL OR updated_at >= ${sinceValue}::timestamptz)
        ORDER BY date DESC
        LIMIT ${limitNum} OFFSET ${offsetNum}
      `;
      
      return res.status(200).json(result.rows.map(normalizeBodyWeight));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateBodyWeightInput;
      
      if (body.weight === undefined || !body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'weight, client_updated_at, and idempotency_key are required' });
      }

      if (body.weight <= 0) {
        return res.status(400).json({ error: 'weight must be positive' });
      }

      const existing = body.id
        ? await sql<BodyWeight>`SELECT * FROM body_weights WHERE id = ${body.id}`
        : { rows: [] as BodyWeight[] };
      const current = existing.rows[0];

      if (current?.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeBodyWeight(current));
      }

      if (current && new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeBodyWeight(current));
      }

      let result;
      if (current) {
        result = await sql<BodyWeight>`
          UPDATE body_weights SET
            date = ${body.date || current.date},
            weight = ${body.weight},
            notes = ${body.notes || ''},
            client_updated_at = ${body.client_updated_at},
            deleted_at = ${body.deleted_at ?? null},
            last_idempotency_key = ${body.idempotency_key},
            server_version = body_weights.server_version + 1,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = ${current.id}
          RETURNING *
        `;
      } else {
        result = await sql<BodyWeight>`
          INSERT INTO body_weights (id, date, weight, notes, client_updated_at, deleted_at, server_version, last_idempotency_key)
          VALUES (
            COALESCE(${body.id ?? null}, gen_random_uuid()),
            ${body.date || new Date().toISOString()},
            ${body.weight},
            ${body.notes || ''},
            ${body.client_updated_at},
            ${body.deleted_at ?? null},
            1,
            ${body.idempotency_key}
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
