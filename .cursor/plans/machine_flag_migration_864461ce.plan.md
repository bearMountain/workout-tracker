---
name: Machine Flag Migration
overview: "Formalize the new exercise-level `isMachine` field as a real cross-stack migration: explicit SwiftData versioning on iOS, explicit SQL migration(s) on the backend, and compatibility-safe sync behavior during rollout."
todos:
  - id: native-versioned-schema
    content: Design and add SwiftData V1/V2 schema snapshots plus a migration plan for Exercise.isMachine
    status: completed
  - id: server-migration-system
    content: Introduce ordered SQL migrations and migrate exercises.is_machine with add/backfill/enforce steps
    status: completed
  - id: sync-compat-window
    content: Make exercise sync tolerate missing remote is_machine during rollout instead of coercing to false
    status: completed
  - id: migration-tests
    content: Add native migration verification and server migration smoke coverage for the new field
    status: completed
isProject: false
---

# Exercise Machine Flag Migration

## Scope

Replace the ad hoc `Exercise.isMachine` rollout with the migration process required by [docs/data_structure_migration.md](/Users/gizmo/Documents/Code/workout-tracker/docs/data_structure_migration.md).

## Current Gaps

- Native still boots SwiftData from a raw schema in [WorkoutTracker/WorkoutTrackerApp.swift](/Users/gizmo/Documents/Code/workout-tracker/WorkoutTracker/WorkoutTrackerApp.swift) instead of `VersionedSchema` + `SchemaMigrationPlan`.
- Server still relies on `initializeDatabase()` in [lib/db.ts](/Users/gizmo/Documents/Code/workout-tracker/lib/db.ts) and [scripts/setup-db.ts](/Users/gizmo/Documents/Code/workout-tracker/scripts/setup-db.ts) instead of ordered migrations.
- Sync currently treats missing remote `is_machine` as `false` in [WorkoutTracker/Services/SyncEngine.swift](/Users/gizmo/Documents/Code/workout-tracker/WorkoutTracker/Services/SyncEngine.swift), which is not a safe rollout-window behavior.

## Native Migration Plan

- Create explicit SwiftData schema snapshots for the last shipped store and the new store shape:
  - `WorkoutTrackerSchemaV1` without `Exercise.isMachine`
  - `WorkoutTrackerSchemaV2` with additive `Exercise.isMachine` defaulting to `false`
- Add `WorkoutTrackerMigrationPlan` with a `V1 -> V2` migration stage and switch [WorkoutTracker/WorkoutTrackerApp.swift](/Users/gizmo/Documents/Code/workout-tracker/WorkoutTracker/WorkoutTrackerApp.swift) to initialize the container from the versioned schema + migration plan.
- Stop using `SyncMetadataMigration.backfill(...)` in app startup as the primary safety net. Keep any needed helpers only as migration-stage utilities.
- Update previews/tests that still create raw containers so they use the new schema setup or dedicated in-memory latest-schema containers.
- Add at least one migration test that opens a V1-style store and verifies upgrade to V2 without data loss.

## Server Migration Plan

- Introduce a real `migrations/` directory and a minimal migration runner instead of using only `initializeDatabase()`.
- Implement ordered SQL migrations for `exercises.is_machine` following the doc’s rollout order:
  1. add nullable column
  2. backfill historical rows
  3. enforce `NOT NULL DEFAULT FALSE` only after backfill
- Keep backend exercise handlers compatible during rollout:
  - tolerate missing `is_machine` while old DBs are still possible
  - only depend on the new column after migration application is guaranteed
- Update the DB setup/bootstrap path so new environments still initialize correctly, but production deploys use the ordered migration path first.

## Sync Compatibility Changes

- During rollout, change the exercise merge path in [WorkoutTracker/Services/SyncEngine.swift](/Users/gizmo/Documents/Code/workout-tracker/WorkoutTracker/Services/SyncEngine.swift) so missing remote `is_machine` does not overwrite a local true value.
- Keep `APIExercise.isMachine` optional in [WorkoutTracker/Services/APIModels.swift](/Users/gizmo/Documents/Code/workout-tracker/WorkoutTracker/Services/APIModels.swift) until all backend environments are upgraded.
- After migrations are fully deployed everywhere, remove temporary compatibility logic.

## Backfill Strategy

- Prefer semantic backfill on the server: infer `exercises.is_machine = true` when existing `workout_logs` for that exercise have `is_machine = true`; otherwise backfill `false`.
- Native migration for old local stores should default the new field to `false`, since local exercise records currently have no better persisted source.

## Verification

- Native: app launch on an older store, edit exercise machine toggle, log a set, sync pull/push, and verify no store-load failures.
- Server: run migrations against a pre-change schema, verify create/update/read for exercises before and after backfill.
- End-to-end: confirm old rows survive, new machine exercises sync correctly, and `LogWorkoutSheet` inherits the exercise machine flag without being reset by pull sync.

## Rollout Order

1. Add migration framework on both sides.
2. Deploy DB migration first.
3. Deploy backend compatibility code.
4. Ship native schema migration + compatibility-safe sync.
5. Backfill and verify.
6. Remove temporary compatibility code later.

