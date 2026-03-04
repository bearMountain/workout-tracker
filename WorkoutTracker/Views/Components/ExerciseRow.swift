import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    let onLog: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
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
                
                if let latestLog = exercise.latestLog {
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
                    Text("Log Set")
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardStyle()
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
