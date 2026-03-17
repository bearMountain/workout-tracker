import SwiftUI
import SwiftData

struct BodyWeightCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var bodyWeightEntries: [BodyWeightEntry]
    @State private var showAddSheet = false
    var syncEngine: SyncEngine?
    
    private var visibleEntries: [BodyWeightEntry] {
        bodyWeightEntries.filter { !$0.isDeleted }
    }
    
    private var latestEntry: BodyWeightEntry? {
        visibleEntries.first
    }
    
    private var trend: Double? {
        guard visibleEntries.count >= 2 else { return nil }
        let sorted = visibleEntries.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last else { return nil }
        guard first.weight > 0 else { return nil }
        return ((last.weight - first.weight) / first.weight) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(AppTheme.accentSecondary)
                        Text("Body Weight")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    if let entry = latestEntry {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", entry.weight))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("lbs")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        HStack(spacing: 8) {
                            Text(entry.formattedDate)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textMuted)
                            
                            if let trend = trend {
                                trendIndicator(trend: trend)
                            }
                        }
                    } else {
                        Text("No entries yet")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
                
                Spacer()
                
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.accentSecondary)
                }
            }
        }
        .cardStyle()
        .sheet(isPresented: $showAddSheet) {
            AddBodyWeightSheet(syncEngine: syncEngine)
        }
    }
    
    private func trendIndicator(trend: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend <= 0 ? "arrow.down.right" : "arrow.up.right")
                .font(.caption2)
            Text(String(format: "%.1f%%", abs(trend)))
                .font(.caption2.bold())
        }
        .foregroundStyle(trend <= 0 ? AppTheme.success : AppTheme.textSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            (trend <= 0 ? AppTheme.success : AppTheme.textSecondary).opacity(0.15)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        BodyWeightCard()
    }
    .padding()
    .background(AppTheme.background)
    .modelContainer(for: [BodyWeightEntry.self], inMemory: true)
}
