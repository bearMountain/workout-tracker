import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workoutType: WorkoutType
    @Bindable var viewModel: WorkoutViewModel
    
    @State private var exerciseToLog: Exercise?
    @State private var showingAddSheet = false
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
        .sheet(item: $exerciseToLog) { exercise in
            LogWorkoutSheet(exercise: exercise, viewModel: viewModel) {
                exerciseToLog = nil
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ExerciseEditorSheet(workoutType: workoutType, viewModel: viewModel) {
                showingAddSheet = false
            }
        }
        .sheet(item: $exerciseToEdit) { exercise in
            ExerciseEditorSheet(workoutType: workoutType, exercise: exercise, viewModel: viewModel) {
                exerciseToEdit = nil
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
        EmptyView()
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
                    exerciseToLog = exercise
                }
                .contextMenu {
                    Button {
                        exerciseToEdit = exercise
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
    let container = try! ModelContainer(for: Exercise.self, WorkoutLog.self)
    let context = container.mainContext
    let syncEngine = SyncEngine(modelContext: context)
    return NavigationStack {
        WorkoutDetailView(
            workoutType: .a,
            viewModel: WorkoutViewModel(modelContext: context, syncEngine: syncEngine)
        )
    }
}
