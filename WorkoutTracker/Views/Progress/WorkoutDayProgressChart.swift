import SwiftUI
import Charts

struct WorkoutDayProgressChart: View {
    let workoutType: WorkoutType
    let exercises: [Exercise]
    let viewModel: ProgressViewModel

    /// Exercises that use added weight; `targetWeight == 0` is bodyweight-only (tracked on Body Weight chart).
    private var chartExercises: [Exercise] {
        exercises.filter { $0.targetWeight > 0 }
    }

    /// Distinct hues so adjacent exercises don’t look like duplicate greens (avoids accent + success both reading as “green”).
    private static let seriesColors: [Color] = [
        Color(red: 0.42, green: 0.82, blue: 0.52),
        Color(red: 0.38, green: 0.62, blue: 0.98),
        Color(red: 0.98, green: 0.52, blue: 0.38),
        Color(red: 0.78, green: 0.48, blue: 0.98),
        Color(red: 0.98, green: 0.82, blue: 0.28),
        Color(red: 0.42, green: 0.88, blue: 0.88),
        Color(red: 0.98, green: 0.45, blue: 0.62),
        Color(red: 0.62, green: 0.78, blue: 0.38)
    ]

    private func color(at index: Int) -> Color {
        Self.seriesColors[index % Self.seriesColors.count]
    }

    private var hasAnyChartData: Bool {
        chartExercises.contains { !viewModel.chartData(for: $0).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text(workoutType.displayName)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if exercises.isEmpty {
                emptyNoExercisesView
            } else if chartExercises.isEmpty {
                emptyBodyweightOnlyView
            } else if !hasAnyChartData {
                emptyNoDataView
            } else {
                chartSection
                legendSection
            }
        }
        .cardStyle()
    }

    private var emptyNoExercisesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell")
                .font(.title2)
                .foregroundStyle(AppTheme.textMuted)
            Text("No exercises for this day yet")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Add exercises from the Home tab")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var emptyNoDataView: some View {
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

    private var emptyBodyweightOnlyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundStyle(AppTheme.textMuted)
            Text("No weighted exercises for this day")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Text("Bodyweight movements use the Body Weight chart above")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(chartExercises, id: \.id) { exercise in
                    let data = viewModel.chartData(for: exercise)
                    let seriesID = exercise.id.uuidString
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(by: .value("Exercise", seriesID))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(by: .value("Exercise", seriesID))
                        .symbolSize(36)
                    }
                }
            }
            .chartForegroundStyleScale(
                domain: chartExercises.map(\.id.uuidString),
                range: chartExercises.indices.map { color(at: $0) }
            )
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppTheme.cardBorder)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
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
            .chartYScale(domain: viewModel.yAxisDomain(for: chartExercises))
            .chartLegend(.hidden)
            .frame(height: 200)

            Text("Weight (lbs)")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
    }

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(chartExercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: 8) {
                    Circle()
                        .fill(color(at: index))
                        .frame(width: 8, height: 8)
                    Text(exercise.name)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.top, 4)
    }
}
