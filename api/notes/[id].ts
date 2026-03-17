import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql, normalizeContentNote } from '../../lib/db.js';
import type { UpdateContentNoteInput, ContentNote } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    return res.status(400).json({ error: 'Invalid note ID' });
  }

  try {
    if (req.method === 'GET') {
      const result = await sql<ContentNote>`
        SELECT * FROM content_notes WHERE id = ${id}
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Note not found' });
      }

      return res.status(200).json(normalizeContentNote(result.rows[0]));
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateContentNoteInput;
      if (!body.client_updated_at || !body.idempotency_key) {
        return res.status(400).json({ error: 'client_updated_at and idempotency_key are required' });
      }
      
      const existing = await sql<ContentNote>`
        SELECT * FROM content_notes WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Note not found' });
      }

      const current = existing.rows[0];
      if (current.last_idempotency_key === body.idempotency_key) {
        return res.status(200).json(normalizeContentNote(current));
      }

      if (new Date(String(current.updated_at)).getTime() > new Date(body.client_updated_at).getTime()) {
        return res.status(200).json(normalizeContentNote(current));
      }

      const result = await sql<ContentNote>`
        UPDATE content_notes SET
          title = ${body.title ?? current.title},
          body = ${body.body ?? current.body},
          url = ${body.url ?? current.url},
          client_updated_at = ${body.client_updated_at},
          deleted_at = ${body.deleted_at ?? current.deleted_at ?? null},
          last_idempotency_key = ${body.idempotency_key},
          server_version = content_notes.server_version + 1,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeContentNote(result.rows[0]));
    }

    if (req.method === 'DELETE') {
      const existing = await sql<ContentNote>`
        SELECT * FROM content_notes WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Note not found' });
      }

      const result = await sql<ContentNote>`
        UPDATE content_notes SET
          deleted_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP,
          client_updated_at = CURRENT_TIMESTAMP,
          server_version = content_notes.server_version + 1
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(normalizeContentNote(result.rows[0]));
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in note handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
