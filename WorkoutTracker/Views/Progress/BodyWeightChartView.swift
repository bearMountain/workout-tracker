import SwiftUI
import Charts

struct BodyWeightChartView: View {
    let data: [BodyWeightDataPoint]
    let latestWeight: Double?
    let trend: Double?
    let lowestWeight: Double?
    let highestWeight: Double?
    let entryCount: Int
    let motivationalMessage: String?
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !data.isEmpty else { return 0...100 }
        let weights = data.map(\.weight)
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100
        let range = maxWeight - minWeight
        let padding = max(range * 0.2, 2)
        return (minWeight - padding)...(maxWeight + padding)
    }
    
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
                Text("Body Weight")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                
                if let latest = latestWeight {
                    Text("\(String(format: "%.1f", latest)) lbs")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.accentSecondary)
                }
            }
            
            Spacer()
            
            if let trend = trend {
                trendBadge(trend: trend)
            }
        }
    }
    
    private func trendBadge(trend: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trend <= 0 ? "arrow.down.right" : "arrow.up.right")
            Text(String(format: "%.1f%%", abs(trend)))
        }
        .font(.caption.bold())
        .foregroundStyle(trend <= 0 ? AppTheme.success : AppTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            (trend <= 0 ? AppTheme.success : AppTheme.textSecondary).opacity(0.15)
        )
        .clipShape(Capsule())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "scalemass")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textMuted)
            
            Text("No weight entries yet")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("Log your weight to track progress!")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var chartSection: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(AppTheme.accentSecondary)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.accentSecondary.opacity(0.3), AppTheme.accentSecondary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(AppTheme.accentSecondary)
                .symbolSize(50)
            }
        }
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
        .chartYScale(domain: yAxisDomain)
        .frame(height: 200)
    }
    
    private var statsSection: some View {
        VStack(spacing: AppTheme.spacing) {
            HStack(spacing: AppTheme.spacingLarge) {
                if let lowest = lowestWeight {
                    statItem(
                        title: "Lowest",
                        value: String(format: "%.1f lbs", lowest),
                        icon: "arrow.down.circle.fill",
                        color: AppTheme.success
                    )
                }
                
                if let highest = highestWeight {
                    statItem(
                        title: "Highest",
                        value: String(format: "%.1f lbs", highest),
                        icon: "arrow.up.circle.fill",
                        color: AppTheme.accentSecondary
                    )
                }
                
                statItem(
                    title: "Entries",
                    value: "\(entryCount)",
                    icon: "calendar",
                    color: AppTheme.textSecondary
                )
            }
            
            if let message = motivationalMessage {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(AppTheme.accentSecondary)
                    Text(message)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppTheme.accentSecondary.opacity(0.1))
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
        BodyWeightChartView(
            data: [
                BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 28), weight: 185),
                BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 21), weight: 183),
                BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 14), weight: 182),
                BodyWeightDataPoint(date: Date().addingTimeInterval(-86400 * 7), weight: 180),
                BodyWeightDataPoint(date: Date(), weight: 178)
            ],
            latestWeight: 178,
            trend: -3.8,
            lowestWeight: 178,
            highestWeight: 185,
            entryCount: 5,
            motivationalMessage: "Making progress!"
        )
        .padding()
    }
    .background(AppTheme.background)
}
