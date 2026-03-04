import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workoutType: WorkoutType
    @Bindable var viewModel: WorkoutViewModel
    
    @State private var selectedExercise: Exercise?
    @State private var showingLogSheet = false
    @State private var showingAddSheet = false
    @State private var showingEditSheet = false
    @State private var exerciseToEdit: Exercise?
    @State private var showingDeleteConfirmation = false
    @State private var exerciseToDelete: Exercise?
    
    var exercises: [Exercise] {
        viewModel.exercises(for: workoutType)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing) {
                headerSection
                
                if exercises.isEmpty {
                    emptyState
                } else {
                    exercisesList
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(workoutType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            if let exercise = selectedExercise {
                LogWorkoutSheet(exercise: exercise, viewModel: viewModel) {
                    showingLogSheet = false
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ExerciseEditorSheet(workoutType: workoutType, viewModel: viewModel) {
                showingAddSheet = false
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let exercise = exerciseToEdit {
                ExerciseEditorSheet(workoutType: workoutType, exercise: exercise, viewModel: viewModel) {
                    showingEditSheet = false
                    exerciseToEdit = nil
                }
            }
        }
        .alert("Delete Exercise?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    viewModel.deleteExercise(exercise)
                }
                exerciseToDelete = nil
            }
        } message: {
            if let exercise = exerciseToDelete {
                Text("Are you sure you want to delete \"\(exercise.name)\"? This will also delete all logged workouts for this exercise.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workoutType.iconName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                
                Text(workoutType.description)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            
            Text("Perform each exercise to failure with perfect form. Rest 2-3 minutes between exercises.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textMuted)
            
            Text("No exercises yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("Exercises will appear here once seeded")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    private var exercisesList: some View {
        VStack(spacing: AppTheme.spacing) {
            ForEach(exercises) { exercise in
                ExerciseRow(exercise: exercise) {
                    selectedExercise = exercise
                    showingLogSheet = true
                }
                .contextMenu {
                    Button {
                        exerciseToEdit = exercise
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        exerciseToDelete = exercise
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(
            workoutType: .a,
            viewModel: WorkoutViewModel(modelContext: try! ModelContainer(for: Exercise.self, WorkoutLog.self).mainContext)
        )
    }
}
