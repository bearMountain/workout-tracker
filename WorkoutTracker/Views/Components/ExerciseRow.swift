import SwiftData
import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    let isReordering: Bool
    let onLog: () -> Void
    let onDeleteLog: (WorkoutLog) -> Void

    @State private var logPendingDelete: WorkoutLog?

    /// Live-updating logs for this exercise (SwiftData does not reliably refresh views that read `exercise.logs` when a related log changes).
    @Query private var logsForExercise: [WorkoutLog]

    init(exercise: Exercise, isReordering: Bool, onLog: @escaping () -> Void, onDeleteLog: @escaping (WorkoutLog) -> Void) {
        self.exercise = exercise
        self.isReordering = isReordering
        self.onLog = onLog
        self.onDeleteLog = onDeleteLog
        let exerciseId = exercise.id
        _logsForExercise = Query(
            filter: #Predicate<WorkoutLog> { log in
                log.exercise?.id == exerciseId && log.deletedAt == nil
            },
            sort: [SortDescriptor(\.date, order: .forward)]
        )
    }

    private var todaysLogs: [WorkoutLog] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return logsForExercise.filter { cal.isDate($0.date, inSameDayAs: today) }
    }

    private var bestLogFromLastWorkoutDay: WorkoutLog? {
        Exercise.bestLogFromLastWorkoutDay(in: logsForExercise)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            headerSection

            if !todaysLogs.isEmpty {
                todaysSetsSection
            }

            if exercise.hasImproved {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Improved from last session")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.success)
            }

            Button(action: onLog) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(todaysLogs.isEmpty ? "Log Set" : "Log Set \(todaysLogs.count + 1)")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isReordering)
            .opacity(isReordering ? 0.5 : 1)
        }
        .cardStyle()
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 12) {
                    Label(targetWeightLabel, systemImage: "scalemass")
                    Label("\(exercise.targetReps) reps", systemImage: "repeat")
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if todaysLogs.isEmpty, let lastWorkoutBestLog = bestLogFromLastWorkoutDay {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last:")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)

                    Text(lastWorkoutBestLog.formattedSetLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(lastWorkoutBestLog.metTarget ? AppTheme.success : AppTheme.textSecondary)

                    Text(lastWorkoutBestLog.feelingLabel)
                        .font(.caption)
                }
            }
        }
    }

    private var todaysSetsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Sets")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textMuted)

            ForEach(Array(todaysLogs.enumerated()), id: \.element.id) { index, log in
                HStack(spacing: 8) {
                    Text("Set \(index + 1)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 44, alignment: .leading)

                    Text(log.formattedSetLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(log.metTarget ? AppTheme.success : AppTheme.textPrimary)

                    Text(log.feelingLabel)
                        .font(.caption)

                    Spacer()

                    if !isReordering {
                        Button {
                            logPendingDelete = log
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete set")
                    }
                }
            }
        }
        .padding(10)
        .background(AppTheme.cardBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .confirmationDialog(
            "Delete this set?",
            isPresented: Binding(
                get: { logPendingDelete != nil },
                set: { if !$0 { logPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let log = logPendingDelete {
                    onDeleteLog(log)
                }
                logPendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                logPendingDelete = nil
            }
        }
    }

    private var targetWeightLabel: String {
        let baseLabel = exercise.targetWeight.rounded(.towardZero) == exercise.targetWeight
            ? "\(Int(exercise.targetWeight)) lbs"
            : String(format: "%.1f lbs", exercise.targetWeight)
        return exercise.isMachine ? "\(baseLabel) (M)" : baseLabel
    }
}

#Preview {
    let container = try! WorkoutTrackerModelContainerFactory.makeInMemoryContainer()
    let context = container.mainContext
    let exercise = Exercise(
        name: "Squats",
        targetWeight: 225,
        targetReps: 8,
        workoutType: .a
    )
    context.insert(exercise)
    try? context.save()

    return NavigationStack {
        ExerciseRow(
            exercise: exercise,
            isReordering: false,
            onLog: {},
            onDeleteLog: { _ in }
        )
        .padding()
        .background(AppTheme.background)
    }
    .modelContainer(container)
}
