# Data Structure Migration Plan

## Why This Exists

We hit migration issues on both sides of the app:

- Native: SwiftData model changes caused store-loading failures and fragile backfill behavior.
- Server: API handlers expected columns that did not yet exist in the live Postgres schema.

Going forward, any persistent data structure change must follow an explicit migration process. We should never again rely on "the code probably matches production" for either the local SwiftData store or the remote database.

## Core Rules

1. Treat any persisted field change as a migration.
2. Native schema changes and server schema changes must be planned together.
3. Database migrations must happen before server code depends on new columns.
4. App code must remain backward-compatible during rollout windows.
5. Every migration must be testable on an older store / older database.
6. If a change is risky, prefer additive changes first and cleanup later.

## What Counts As A Migration

These changes require a migration plan:

- Adding, removing, or renaming any persisted property
- Changing nullability / optionality
- Changing default values that matter for existing rows
- Adding uniqueness constraints or indexes with behavioral impact
- Changing relationships
- Splitting one model into multiple models
- Merging multiple models into one
- Changing API response fields that the app decodes
- Adding server-side columns used by sync logic

These usually do not require a migration plan:

- Pure UI changes
- Computed properties
- Derived formatting helpers
- Non-persisted state

## Native Plan

### Current Problem

Right now the app creates a `Schema(...)` directly and relies on lightweight behavior plus `SyncMetadataMigration.backfill(...)`. That is not enough for repeated structural changes.

### Going Forward

We will move to explicit SwiftData versioning:

- Introduce `VersionedSchema` versions for persisted model changes
- Introduce a `SchemaMigrationPlan`
- Create a new schema version for every breaking persisted change
- Keep declaration-time defaults for new non-optional fields
- Avoid adding unique constraints in-place without a dedicated migration step
- Use backfill helpers only as part of a known versioned migration strategy, not as the primary safety net

### Native Rollout Rules

For each persisted model change:

1. Decide whether the change is additive or breaking.
2. Create a new schema version if the store layout changes.
3. Define how old rows will be transformed.
4. Add migration tests that open realistic old data.
5. Verify app launch on an upgraded store before shipping.

### Native Safety Guidelines

- Prefer additive fields with safe defaults over immediate destructive changes.
- Prefer deprecating old fields first, then removing them in a later version.
- Never assume SwiftData automatic migration will handle uniqueness, relationship, or required-field changes safely.
- Keep one fixture store per important app version once we start versioning schemas.

## Server Plan

### Current Problem

The API code assumed columns like `updated_at`, `client_updated_at`, `server_version`, and `last_idempotency_key` existed everywhere, but production tables had not been fully migrated yet.

### Going Forward

We will move to explicit database migrations:

- Add a real migration directory with ordered SQL migrations
- Record applied migrations in the database
- Make deploys run migrations before new API handlers go live
- Stop relying on a broad "setup" script as the main production migration mechanism

### Server Rollout Rules

For each database change:

1. Write a migration script for the schema change.
2. Make the migration idempotent when possible.
3. Deploy the migration first.
4. Deploy API code only after the migration is applied.
5. Remove backward-compatibility code only after all environments are upgraded.

### Server Compatibility Guidelines

- Add new nullable columns first.
- Backfill data second.
- Make columns required only after backfill is complete.
- Avoid server code that hard-fails if one new column is missing during rollout.
- Prefer compatibility windows where reads tolerate old rows and writes populate both old and new fields if needed.

## Shared Contract Plan

The app and backend need one migration contract, not two independent ones.

For every persistent change we should answer these questions before coding:

- What changes locally in SwiftData?
- What changes remotely in Postgres?
- What changes in API request/response payloads?
- Can old app versions still talk to the new backend?
- Can the new app tolerate old server payloads during rollout?
- What data must be backfilled?

## Preferred Rollout Order

For changes that affect app + API + database:

1. Design the target schema and compatibility window.
2. Ship database migration first.
3. Ship backend code that can handle both old and new shapes.
4. Ship app code that can decode both old and new payloads when practical.
5. Backfill data if required.
6. Remove temporary compatibility code in a later cleanup release.

This order is important:

- Database first avoids server crashes on missing columns.
- Backend compatibility avoids breaking older app versions.
- App decode tolerance avoids failures during staged rollout.

## Migration Checklist

Before merging a persistent data structure change:

- Native migration path defined
- Server migration path defined
- API compatibility reviewed
- Backfill strategy defined
- Rollout order written down
- Test plan written down
- Rollback plan written down

Before deploying:

- Production migration script reviewed
- Production backup / restore path understood
- App handles missing new fields if rollout is staged
- Backend handles legacy rows if rollout is staged
- Manual verification steps prepared

After deploying:

- Verify app launch on upgraded local store
- Verify create / update / delete for affected models
- Verify sync from old records and new records
- Verify logs show no decode errors or missing-column errors

## Testing Standard

Every non-trivial migration should have:

- Native migration test from an older persisted schema or fixture store
- Backend migration verification against a realistic production-like schema
- End-to-end test for create, pull, update, and delete on the changed model
- A manual smoke test in simulator / device after deployment

## Practical Default Strategy

When in doubt, use this sequence:

1. Add new optional field / nullable column.
2. Teach app and API to tolerate both old and new data.
3. Backfill existing records.
4. Start writing the new field everywhere.
5. Only later make the field required or remove the old one.

This is slower than "just change the struct/model," but it is much safer.

## Immediate Follow-Ups For This Project

To make this plan real, we should implement these next:

- Add explicit SwiftData `VersionedSchema` and `SchemaMigrationPlan`
- Create a real server migration system under something like `migrations/`
- Add a database schema version check during backend startup / deploy
- Add migration fixtures/tests for at least one older app store and one older database state
- Document each future migration in this file or a linked migration log

## Current Status

The project now has an initial migration workflow in place:

- Native uses explicit SwiftData `VersionedSchema` and `SchemaMigrationPlan`
- Server uses ordered SQL migration files under `migrations/`
- Deploys run `npm run db:migrate` before backend build
- The repo includes `npm run db:migrate:verify`
- The repo includes `npm run db:check-export` as a DB contract sanity check
- There is an implementation checklist in `docs/instructions/migration-checklist.md`

This is an improvement, but not the end state:

- We still need to keep documenting each persistent change explicitly
- We should keep adding migration verification coverage as schema complexity grows
- Any new persistent field must follow the checklist, not just the code path

## Decision Rule

If a change touches persisted data and we have to ask "will existing users survive this?", it is a migration and must follow this document.
