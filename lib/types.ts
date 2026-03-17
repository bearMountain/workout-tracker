export type WorkoutType = 'A' | 'B';

export interface Exercise {
  id: string;
  name: string;
  target_weight: number;
  target_reps: number;
  notes: string;
  workout_type: WorkoutType;
  order_index: number;
  created_at: string;
  updated_at: string;
}

export interface CreateExerciseInput {
  id?: string;
  name: string;
  target_weight: number;
  target_reps: number;
  notes?: string;
  workout_type: WorkoutType;
  order_index?: number;
}

export interface UpdateExerciseInput {
  name?: string;
  target_weight?: number;
  target_reps?: number;
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
  created_at: string;
}

export interface CreateWorkoutLogInput {
  id?: string;
  exercise_id: string;
  date?: string;
  actual_weight: number;
  actual_reps: number;
  is_machine?: boolean;
  feeling: number;
  notes?: string;
}

export interface UpdateWorkoutLogInput {
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
  created_at: string;
  updated_at: string;
}

export interface CreateContentNoteInput {
  title: string;
  body?: string;
  url?: string;
}

export interface UpdateContentNoteInput {
  title?: string;
  body?: string;
  url?: string;
}

export interface BodyWeight {
  id: string;
  date: string;
  weight: number;
  notes: string;
  created_at: string;
}

export interface CreateBodyWeightInput {
  id?: string;
  date?: string;
  weight: number;
  notes?: string;
}

export interface UpdateBodyWeightInput {
  date?: string;
  weight?: number;
  notes?: string;
}
