import SwiftUI
import Charts

struct ExerciseChartView: View {
    let exercise: Exercise
    let data: [ExerciseDataPoint]
    let personalBest: (weight: Double, reps: Int)?
    let isNewPR: Bool
    let weightTrend: Double?
    let repsTrend: Double?
    let motivationalMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            headerSection
            
            if data.isEmpty {
                emptyStateView
            } else {
                chartSection
                statsSection
            }
        }
        .cardStyle()
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(exercise.workoutType.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            if isNewPR {
                prBadge
            }
        }
    }
    
    private var prBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
            Text("NEW PR!")
        }
        .font(.caption.bold())
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [Color.yellow, Color.orange, Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: Color.orange.opacity(0.5), radius: 8, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textMuted)
            
            Text("No workout data yet")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("Log some sets to see your progress!")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .symbolSize(40)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppTheme.cardBorder)
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppTheme.cardBorder)
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(height: 200)
            
            Text("Weight (lbs)")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: AppTheme.spacing) {
            HStack(spacing: AppTheme.spacingLarge) {
                if let pb = personalBest {
                    statItem(
                        title: "Personal Best",
                        value: "\(Int(pb.weight)) lbs x \(pb.reps)",
                        icon: "star.fill",
                        color: Color.yellow
                    )
                }
                
                if let trend = weightTrend {
                    statItem(
                        title: "Weight Trend",
                        value: String(format: "%+.1f%%", trend),
                        icon: trend >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: trend >= 0 ? AppTheme.success : AppTheme.warning
                    )
                }
                
                if let trend = repsTrend {
                    statItem(
                        title: "Reps Trend",
                        value: String(format: "%+.1f%%", trend),
                        icon: trend >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: trend >= 0 ? AppTheme.success : AppTheme.warning
                    )
                }
            }
            
            if let message = motivationalMessage {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.accent)
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

#Preview {
    ScrollView {
        ExerciseChartView(
            exercise: Exercise(
                name: "Bench Press",
                targetWeight: 135,
                targetReps: 8,
                workoutType: .a
            ),
            data: [
                ExerciseDataPoint(date: Date().addingTimeInterval(-86400 * 21), weight: 115, reps: 8),
                ExerciseDataPoint(date: Date().addingTimeInterval(-86400 * 14), weight: 120, reps: 8),
                ExerciseDataPoint(date: Date().addingTimeInterval(-86400 * 7), weight: 125, reps: 7),
                ExerciseDataPoint(date: Date(), weight: 130, reps: 8)
            ],
            personalBest: (130, 8),
            isNewPR: true,
            weightTrend: 13.0,
            repsTrend: 0.0,
            motivationalMessage: "New Personal Best!"
        )
        .padding()
    }
    .background(AppTheme.background)
}
