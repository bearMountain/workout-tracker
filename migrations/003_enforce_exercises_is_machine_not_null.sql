UPDATE exercises
SET is_machine = FALSE
WHERE is_machine IS NULL;

ALTER TABLE exercises
ALTER COLUMN is_machine SET DEFAULT FALSE;

ALTER TABLE exercises
ALTER COLUMN is_machine SET NOT NULL;
