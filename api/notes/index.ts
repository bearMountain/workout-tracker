import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeContentNote } from '../../lib/db.js';
import type { CreateContentNoteInput, ContentNote } from '../../lib/types.js';

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

      const result = await sql<ContentNote>`
        SELECT * FROM content_notes
        WHERE (${sinceValue}::timestamptz IS NULL OR updated_at >= ${sinceValue}::timestamptz)
        ORDER BY updated_at DESC
        LIMIT ${limitNum} OFFSET ${offsetNum}
      `;
      
      return res.status(200).json(result.rows.map(normalizeContentNote));
    }

    if (req.method === 'POST') {
      const body = req.body as CreateContentNoteInput;
      
      if (!body.title || !body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'title, client_updated_at, and idempotency_key are required' });
      }

      const existing = body.id
        ? await sql<ContentNote>`SELECT * FROM content_notes WHERE id = ${body.id}`
        : { rows: [] as ContentNote[] };
      const current = existing.rows[0];

      if (current?.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeContentNote(current));
      }

      if (current && new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeContentNote(current));
      }

      const result = current
        ? await sql<ContentNote>`
            UPDATE content_notes SET
              title = ${body.title},
              body = ${body.body || ''},
              url = ${body.url || ''},
              client_updated_at = ${body.client_updated_at},
              deleted_at = ${body.deleted_at ?? null},
              last_idempotency_key = ${body.idempotency_key},
              server_version = content_notes.server_version + 1,
              updated_at = CURRENT_TIMESTAMP
            WHERE id = ${current.id}
            RETURNING *
          `
        : await sql<ContentNote>`
            INSERT INTO content_notes (id, title, body, url, client_updated_at, deleted_at, server_version, last_idempotency_key)
            VALUES (
              COALESCE(${body.id ?? null}, gen_random_uuid()),
              ${body.title},
              ${body.body || ''},
              ${body.url || ''},
              ${body.client_updated_at},
              ${body.deleted_at ?? null},
              1,
              ${body.idempotency_key}
            )
            RETURNING *
          `;

      return res.status(201).json(normalizeContentNote(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in notes handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
