import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    let onLog: () -> Void
    
    private var todaysLogs: [WorkoutLog] {
        exercise.todaysLogs
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
                    Label("\(Int(exercise.targetWeight)) lbs", systemImage: "scalemass")
                    Label("\(exercise.targetReps) reps", systemImage: "repeat")
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            if todaysLogs.isEmpty, let latestLog = exercise.latestLog {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last:")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                    
                    Text("\(Int(latestLog.actualWeight)) × \(latestLog.actualReps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(latestLog.metTarget ? AppTheme.success : AppTheme.textSecondary)
                    
                    Text(latestLog.feelingEmoji)
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
                    
                    Text("\(Int(log.actualWeight)) × \(log.actualReps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(log.metTarget ? AppTheme.success : AppTheme.textPrimary)
                    
                    Text(log.feelingEmoji)
                        .font(.caption)
                    
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(AppTheme.cardBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let exercise = Exercise(
        name: "Squats",
        targetWeight: 225,
        targetReps: 8,
        workoutType: .a
    )
    
    return ExerciseRow(exercise: exercise) {}
        .padding()
        .background(AppTheme.background)
}
