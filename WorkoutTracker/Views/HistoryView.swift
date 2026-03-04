import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.logs.isEmpty {
                        emptyState
                    } else {
                        logsList(viewModel: viewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .background(AppTheme.background)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            } else {
                viewModel?.fetchLogs()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.textMuted)
            
            Text("No workout history yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)
            
            Text("Your logged workouts will appear here")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func logsList(viewModel: HistoryViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacingLarge) {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: AppTheme.spacing) {
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        ForEach(viewModel.logs(for: date)) { log in
                            LogRow(log: log) {
                                viewModel.deleteLog(log)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct LogRow: View {
    let log: WorkoutLog
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let exercise = log.exercise {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text(exercise.workoutType.displayName)
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.accent.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(Int(log.actualWeight)) lbs", systemImage: "scalemass")
                    Label("\(log.actualReps) reps", systemImage: "repeat")
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                
                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(log.feelingEmoji)
                    .font(.title2)
                
                if log.metTarget {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                }
            }
        }
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self], inMemory: true)
}
