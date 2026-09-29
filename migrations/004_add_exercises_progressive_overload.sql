ALTER TABLE exercises
ADD COLUMN IF NOT EXISTS progressive_overload BOOLEAN;

-- Seed defaults for the live heavy lifts only. Later cue / highlight / +5 behavior reads this flag, not the names.
-- Bump updated_at so already-synced phones pull the new value.
UPDATE exercises
SET
  progressive_overload = TRUE,
  server_version = server_version + 1,
  updated_at = CURRENT_TIMESTAMP
WHERE deleted_at IS NULL
  AND name IN ('Squats', 'Dead Lift', 'Leg Extensions', 'Pec Deck', 'Bench Press')
  AND COALESCE(progressive_overload, FALSE) = FALSE;

UPDATE exercises
SET progressive_overload = FALSE
WHERE progressive_overload IS NULL;

ALTER TABLE exercises
ALTER COLUMN progressive_overload SET DEFAULT FALSE;

ALTER TABLE exercises
ALTER COLUMN progressive_overload SET NOT NULL;
