import SwiftUI

struct WorkoutCard: View {
    let workoutType: WorkoutType
    let exerciseCount: Int
    let isNext: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spacing) {
                Image(systemName: workoutType.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(isNext ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(workoutType.displayName)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        if isNext {
                            Text("NEXT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        WorkoutCard(workoutType: .a, exerciseCount: 3, isNext: true) {}
        WorkoutCard(workoutType: .b, exerciseCount: 3, isNext: false) {}
    }
    .padding()
    .background(AppTheme.background)
}
