import type { VercelRequest, VercelResponse } from '@vercel/node';
import { sql } from '../../lib/db.js';
import type { CreateContentNoteInput, ContentNote } from '../../lib/types.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      const { limit, offset } = req.query;
      
      const limitNum = Math.min(parseInt(limit as string) || 50, 100);
      const offsetNum = parseInt(offset as string) || 0;

      const result = await sql<ContentNote>`
        SELECT * FROM content_notes
        ORDER BY updated_at DESC
        LIMIT ${limitNum} OFFSET ${offsetNum}
      `;
      
      return res.status(200).json(result.rows);
    }

    if (req.method === 'POST') {
      const body = req.body as CreateContentNoteInput;
      
      if (!body.title) {
        return res.status(400).json({ error: 'title is required' });
      }

      const result = await sql<ContentNote>`
        INSERT INTO content_notes (title, body, url)
        VALUES (
          ${body.title},
          ${body.body || ''},
          ${body.url || ''}
        )
        RETURNING *
      `;

      return res.status(201).json(result.rows[0]);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error in notes handler:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
