export type WorkoutType = 'A' | 'B';

export interface SyncFields {
  id: string;
  server_version: number;
  client_updated_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  last_idempotency_key: string | null;
}

export interface SyncMutationInput {
  id?: string;
  client_updated_at: string;
  idempotency_key: string;
  deleted_at?: string | null;
}

export interface Exercise {
  id: string;
  name: string;
  target_weight: number;
  target_reps: number;
  is_machine: boolean;
  notes: string;
  workout_type: WorkoutType;
  order_index: number;
  client_updated_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  server_version: number;
  last_idempotency_key: string | null;
}

export interface CreateExerciseInput extends SyncMutationInput {
  name: string;
  target_weight: number;
  target_reps: number;
  is_machine?: boolean;
  notes?: string;
  workout_type: WorkoutType;
  order_index?: number;
}

export interface UpdateExerciseInput extends SyncMutationInput {
  name?: string;
  target_weight?: number;
  target_reps?: number;
  is_machine?: boolean;
  notes?: string;
  workout_type?: WorkoutType;
  order_index?: number;
}

export interface WorkoutLog {
  id: string;
  exercise_id: string;
  date: string;
  actual_weight: number;
  actual_reps: number;
  is_machine: boolean;
  feeling: number;
  notes: string;
  client_updated_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  server_version: number;
  last_idempotency_key: string | null;
  exercise_name?: string;
  workout_type?: WorkoutType;
}

export interface CreateWorkoutLogInput extends SyncMutationInput {
  exercise_id: string;
  date?: string;
  actual_weight: number;
  actual_reps: number;
  is_machine?: boolean;
  feeling: number;
  notes?: string;
}

export interface UpdateWorkoutLogInput extends SyncMutationInput {
  date?: string;
  actual_weight?: number;
  actual_reps?: number;
  is_machine?: boolean;
  feeling?: number;
  notes?: string;
}

export interface ContentNote {
  id: string;
  title: string;
  body: string;
  url: string;
  client_updated_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  server_version: number;
  last_idempotency_key: string | null;
}

export interface CreateContentNoteInput extends SyncMutationInput {
  title: string;
  body?: string;
  url?: string;
}

export interface UpdateContentNoteInput extends SyncMutationInput {
  title?: string;
  body?: string;
  url?: string;
}

export interface BodyWeight {
  id: string;
  date: string;
  weight: number;
  notes: string;
  client_updated_at: string;
  created_at: string;
  updated_at: string;
  deleted_at: string | null;
  server_version: number;
  last_idempotency_key: string | null;
}

export interface CreateBodyWeightInput extends SyncMutationInput {
  date?: string;
  weight: number;
  notes?: string;
}

export interface UpdateBodyWeightInput extends SyncMutationInput {
  date?: string;
  weight?: number;
  notes?: string;
}
