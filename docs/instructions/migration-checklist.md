# Migration Checklist

This project now has a lightweight migration workflow for persistent schema changes.

## Migration Scripts

- `npm run db:migrate`
  Runs `node scripts/migrate.js` against the current environment file.
- `npm run db:migrate:verify`
  Runs `node scripts/migrate.js verify` and fails if there are pending or orphaned migrations.
- `npm run db:check-export`
  Runs `node scripts/check-export-fields.js` to verify the database columns still match the API contract fields used by this repo.
- `npm run db:migrate:prod`
  Pulls production env vars with Vercel, runs migrations, then deletes `.env.production`.
- `npm run db:migrate:prod:verify`
  Pulls production env vars with Vercel, verifies migration status, then deletes `.env.production`.

## Workflow For A New Column

1. Create a SQL migration file in `migrations/`, named like `0XX_descriptive_name.sql`.
2. Update the API/shared type contract in `lib/types.ts`.
3. Update normalization or bootstrap behavior in `lib/db.ts` if the new field changes response normalization.
4. Update affected API endpoints under `api/`.
5. Update iOS/frontend models and views if needed.
6. Run `npm run db:migrate`.
7. Run `npm run db:migrate:verify`.
8. Run `npm run db:check-export`.

## Workflow For A New Table

1. Create the migration with table definition, indexes, foreign keys, and comments if needed.
2. Add the table to `scripts/check-export-fields.js` so the DB contract check covers it.
3. Add or update shared contract types in `lib/types.ts`.
4. Update `lib/db.ts` normalization helpers if the table is returned by API handlers.
5. Update API endpoints under `api/` for create/read/update/delete as needed.
6. Run `npm run db:migrate`.
7. Run `npm run db:migrate:verify`.
8. Run `npm run db:check-export`.

## What `db:migrate:verify` Must Confirm

- the new migration file is marked as executed
- there are no unexpected pending migrations
- there are no orphaned migration records needing investigation

## Common Gotchas

- forgetting to update `lib/types.ts`
- forgetting to update API endpoint SQL for the affected table
- forgetting to update normalization in `lib/db.ts`
- column name typos, which `npm run db:check-export` can catch
- not running `npm run db:migrate:verify` after applying migrations
- `ECONNREFUSED` or connection failures during verify usually mean the DB env vars are wrong or the target database is unavailable

## Files To Remember

- `migrations/`
- `lib/types.ts`
- `lib/db.ts`
- `api/`
- `scripts/migrate.js`
- `scripts/check-export-fields.js`
- `docs/data_structure_migration.md`
