import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db.js';
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

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'PUT') {
      const body = req.body as UpdateContentNoteInput;
      
      const existing = await sql<ContentNote>`
        SELECT * FROM content_notes WHERE id = ${id}
      `;

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Note not found' });
      }

      const current = existing.rows[0];

      const result = await sql<ContentNote>`
        UPDATE content_notes SET
          title = ${body.title ?? current.title},
          body = ${body.body ?? current.body},
          url = ${body.url ?? current.url},
          updated_at = CURRENT_TIMESTAMP
        WHERE id = ${id}
        RETURNING *
      `;

      return res.status(200).json(result.rows[0]);
    }

    if (req.method === 'DELETE') {
      const result = await sql`
        DELETE FROM content_notes WHERE id = ${id} RETURNING id
      `;

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Note not found' });
      }

      return res.status(200).json({ deleted: true, id });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in note handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
