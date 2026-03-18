import SwiftUI
import SwiftData

struct ExerciseEditorSheet: View {
    let workoutType: WorkoutType
    let exercise: Exercise?
    @Bindable var viewModel: WorkoutViewModel
    let onDismiss: () -> Void
    
    @State private var name: String
    @State private var targetWeight: Double
    @State private var targetReps: Int
    @State private var isMachine: Bool
    @State private var notes: String
    
    var isEditing: Bool { exercise != nil }
    
    init(workoutType: WorkoutType, exercise: Exercise? = nil, viewModel: WorkoutViewModel, onDismiss: @escaping () -> Void) {
        self.workoutType = workoutType
        self.exercise = exercise
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        _name = State(initialValue: exercise?.name ?? "")
        _targetWeight = State(initialValue: exercise?.targetWeight ?? 0)
        _targetReps = State(initialValue: exercise?.targetReps ?? 8)
        _isMachine = State(initialValue: exercise?.isMachine ?? false)
        _notes = State(initialValue: exercise?.notes ?? "")
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLarge) {
                    nameSection
                    targetSection
                    equipmentSection
                    notesSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle(isEditing ? "Edit Exercise" : "Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? AppTheme.accent : AppTheme.textMuted)
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Button {
                isMachine.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isMachine ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isMachine ? AppTheme.accent : AppTheme.textMuted)
                    Text("Machine")
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                }
                .font(.body)
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise Name")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("e.g., Squats", text: $name)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textPrimary)
                .textFieldStyle(.plain)
        }
        .cardStyle()
    }
    
    private var targetSection: some View {
        VStack(spacing: AppTheme.spacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Weight (lbs)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                
                HStack {
                    Button {
                        if targetWeight >= 5 { targetWeight -= 5 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    TextField("Weight", value: $targetWeight, format: .number)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                    
                    Button {
                        targetWeight += 5
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            
            Divider()
                .background(AppTheme.cardBorder)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Reps")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                
                HStack {
                    Button {
                        if targetReps > 1 { targetReps -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    TextField("Reps", value: $targetReps, format: .number)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                    
                    Button {
                        targetReps += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("Form cues, tips, etc.", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3...6)
        }
        .cardStyle()
    }
    
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        if let exercise = exercise {
            viewModel.updateExercise(exercise, name: trimmedName, targetWeight: targetWeight, targetReps: targetReps, isMachine: isMachine, notes: notes)
        } else {
            viewModel.addExercise(name: trimmedName, targetWeight: targetWeight, targetReps: targetReps, isMachine: isMachine, notes: notes, workoutType: workoutType)
        }
        
        onDismiss()
    }
}

#Preview {
    let container = try! WorkoutTrackerModelContainerFactory.makeInMemoryContainer()
    let context = container.mainContext
    let syncEngine = SyncEngine(modelContext: context)
    return ExerciseEditorSheet(
        workoutType: .a,
        viewModel: WorkoutViewModel(modelContext: context, syncEngine: syncEngine)
    ) {}
}
