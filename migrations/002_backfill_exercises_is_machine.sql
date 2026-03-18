UPDATE exercises AS exercise
SET is_machine = TRUE
WHERE EXISTS (
  SELECT 1
  FROM workout_logs AS log
  WHERE log.exercise_id = exercise.id
    AND log.is_machine = TRUE
);

UPDATE exercises
SET is_machine = FALSE
WHERE is_machine IS NULL;
