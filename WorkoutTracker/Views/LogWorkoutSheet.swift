import SwiftUI
import SwiftData

struct LogWorkoutSheet: View {
    let exercise: Exercise
    @Bindable var viewModel: WorkoutViewModel
    let onDismiss: () -> Void
    
    @State private var weight: Double
    @State private var reps: Int
    @State private var feeling: Int = 3
    @State private var notes: String = ""
    
    init(exercise: Exercise, viewModel: WorkoutViewModel, onDismiss: @escaping () -> Void) {
        self.exercise = exercise
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        if let lastLog = exercise.latestLog {
            _weight = State(initialValue: lastLog.actualWeight)
            _reps = State(initialValue: lastLog.actualReps)
        } else {
            _weight = State(initialValue: exercise.targetWeight)
            _reps = State(initialValue: exercise.targetReps)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLarge) {
                    targetSection
                    inputSection
                    feelingSection
                    notesSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Log Set")
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
                        saveLog()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            HStack(spacing: 16) {
                Label("Target: \(Int(exercise.targetWeight)) lbs", systemImage: "target")
                Label("\(exercise.targetReps) reps", systemImage: "repeat")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var inputSection: some View {
        VStack(spacing: AppTheme.spacing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight (lbs)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                
                HStack {
                    Button {
                        if weight >= 5 { weight -= 5 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    TextField("Weight", value: $weight, format: .number)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                    
                    Button {
                        weight += 5
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
                Text("Reps")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                
                HStack {
                    Button {
                        if reps > 1 { reps -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    TextField("Reps", value: $reps, format: .number)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                    
                    Button {
                        reps += 1
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
    
    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did it feel?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            HStack(spacing: 0) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        feeling = level
                    } label: {
                        Text(feelingEmoji(for: level))
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(feeling == level ? AppTheme.cardBorder : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            
            TextField("How was your form? Any adjustments?", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3...6)
        }
        .cardStyle()
    }
    
    private func feelingEmoji(for level: Int) -> String {
        switch level {
        case 1: return "😫"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "💪"
        default: return "😐"
        }
    }
    
    private func saveLog() {
        viewModel.logWorkout(for: exercise, weight: weight, reps: reps, feeling: feeling, notes: notes)
        onDismiss()
    }
}

#Preview {
    let exercise = Exercise(
        name: "Squats",
        targetWeight: 225,
        targetReps: 8,
        workoutType: .a
    )
    
    LogWorkoutSheet(
        exercise: exercise,
        viewModel: WorkoutViewModel(modelContext: try! ModelContainer(for: Exercise.self, WorkoutLog.self).mainContext)
    ) {}
}
