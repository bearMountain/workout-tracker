import SwiftUI
import SwiftData

struct LogWorkoutSheet: View {
    let exercise: Exercise
    @Bindable var viewModel: WorkoutViewModel
    let onDismiss: () -> Void
    
    @State private var weightText: String
    @State private var reps: Int
    @State private var feeling: Int = 3
    @State private var notes: String = ""
    @State private var isMachine = false
    @FocusState private var isWeightFieldFocused: Bool
    
    init(exercise: Exercise, viewModel: WorkoutViewModel, onDismiss: @escaping () -> Void) {
        self.exercise = exercise
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        
        if let bestLog = exercise.bestLog {
            _weightText = State(initialValue: Self.weightText(for: bestLog.actualWeight))
            _reps = State(initialValue: bestLog.actualReps)
            _isMachine = State(initialValue: exercise.isMachine || bestLog.isMachine)
        } else {
            _weightText = State(initialValue: Self.weightText(for: exercise.targetWeight))
            _reps = State(initialValue: exercise.targetReps)
            _isMachine = State(initialValue: exercise.isMachine)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: AppTheme.spacingLarge) {
                        targetSection
                        inputSection
                        feelingSection
                        notesSection
                    }
                    .padding()
                    .padding(.bottom, 140)
                }

                floatingSaveButton
                    .padding(.trailing, 24)
                    .padding(.bottom, 50)
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
            }
            .onAppear {
                if parsedWeight == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isWeightFieldFocused = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.textPrimary)
            
            HStack(spacing: 16) {
                Label("Target: \(targetWeightLabel)", systemImage: "target")
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
                        let nextWeight = max(parsedWeight - 5, 0)
                        weightText = Self.weightText(for: nextWeight)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    ZStack {
                        TextField("Weight", text: $weightText)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .focused($isWeightFieldFocused)
                            .opacity(showsBodyWeightBadge ? 0.02 : 1)
                        
                        if showsBodyWeightBadge {
                            Text("BW")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    Button {
                        weightText = Self.weightText(for: parsedWeight + 5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
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
                    .font(.subheadline)
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
            
            VStack(spacing: 8) {
                ForEach(feelingOptions, id: \.value) { option in
                    Button {
                        feeling = option.value
                    } label: {
                        Text(option.label)
                            .font(.subheadline)
                            .fontWeight(feeling == option.value ? .semibold : .regular)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(feeling == option.value ? AppTheme.accent.opacity(0.2) : AppTheme.cardBorder.opacity(0.3))
                            .foregroundStyle(feeling == option.value ? AppTheme.accent : AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var feelingOptions: [(value: Int, label: String)] {
        [
            (1, "warmup"),
            (2, "medium"),
            (3, "hard"),
            (4, "0 RIR")
        ]
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            TextField("", text: $notes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(3...6)
        }
        .cardStyle()
    }
    
    private var parsedWeight: Double {
        Double(weightText) ?? 0
    }
    
    private var showsBodyWeightBadge: Bool {
        !isWeightFieldFocused && parsedWeight == 0 && !weightText.isEmpty
    }
    
    private var canSave: Bool {
        !weightText.isEmpty && Double(weightText) != nil && reps > 0
    }
    
    private var targetWeightLabel: String {
        let baseLabel = exercise.targetWeight == 0 ? "BW" : Self.weightText(for: exercise.targetWeight) + " lbs"
        return exercise.isMachine ? "\(baseLabel) (Machine)" : baseLabel
    }
    
    private var floatingSaveButton: some View {
        Button {
            saveLog()
        } label: {
            Image(systemName: "checkmark")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.background)
                .frame(width: 56, height: 56)
                .background(canSave ? AppTheme.accent : AppTheme.textMuted)
                .clipShape(Circle())
                .shadow(color: AppTheme.background.opacity(0.35), radius: 16, x: 0, y: 10)
        }
        .disabled(!canSave)
    }
    
    private func saveLog() {
        guard canSave, let weight = Double(weightText) else { return }
        viewModel.logWorkout(
            for: exercise,
            weight: weight,
            reps: reps,
            feeling: feeling,
            notes: notes,
            isMachine: isMachine
        )
        onDismiss()
    }
    
    private static func weightText(for weight: Double) -> String {
        if weight.rounded(.towardZero) == weight {
            return String(Int(weight))
        }
        return String(format: "%.1f", weight)
    }
}

#Preview {
    let exercise = Exercise(
        name: "Squats",
        targetWeight: 225,
        targetReps: 8,
        workoutType: .a
    )
    
    let container = try! WorkoutTrackerModelContainerFactory.makeInMemoryContainer()
    let context = container.mainContext
    let syncEngine = SyncEngine(modelContext: context)
    LogWorkoutSheet(
        exercise: exercise,
        viewModel: WorkoutViewModel(modelContext: context, syncEngine: syncEngine)
    ) {}
}
