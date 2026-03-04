import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?
    @State private var hasInitialSynced = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.isSyncing && viewModel.logs.isEmpty {
                        VStack(spacing: AppTheme.spacing) {
                            ProgressView()
                                .tint(AppTheme.accent)
                            Text("Loading history...")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.logs.isEmpty {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel?.syncFromAPI()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppTheme.accent)
                    }
                    .disabled(viewModel?.isSyncing ?? false)
                }
            }
            .refreshable {
                await viewModel?.syncFromAPI()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            } else {
                viewModel?.fetchLogs()
            }
        }
        .task {
            if !hasInitialSynced {
                hasInitialSynced = true
                await viewModel?.syncFromAPI()
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
                ForEach(viewModel.sessions) { session in
                    SessionCard(
                        session: session,
                        onDeleteLog: { log in
                            viewModel.deleteLog(log)
                        },
                        onDeleteSession: {
                            viewModel.deleteSession(session)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct SessionCard: View {
    let session: WorkoutSession
    let onDeleteLog: (WorkoutLog) -> Void
    let onDeleteSession: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            headerSection
            
            ForEach(session.exercises) { exerciseSets in
                ExerciseSetsRow(exerciseSets: exerciseSets, onDeleteLog: onDeleteLog)
            }
        }
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Entire Session", systemImage: "trash")
            }
        }
        .alert("Delete Session?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDeleteSession()
            }
        } message: {
            Text("This will delete all \(session.totalSets) sets from this workout. This cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.formattedDate)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            
            HStack(spacing: 8) {
                if let workoutType = session.workoutType {
                    Text(workoutType.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.accent.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Text("\(session.exercises.count) exercises · \(session.totalSets) sets")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
    }
}

struct ExerciseSetsRow: View {
    let exerciseSets: ExerciseSets
    let onDeleteLog: (WorkoutLog) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exerciseSets.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                Text("Target: \(Int(exerciseSets.targetWeight))×\(exerciseSets.targetReps)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            
            VStack(spacing: 4) {
                ForEach(Array(exerciseSets.sets.enumerated()), id: \.element.id) { index, log in
                    HStack(spacing: 8) {
                        Text("Set \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("\(Int(log.actualWeight)) × \(log.actualReps)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(log.metTarget ? AppTheme.success : AppTheme.textSecondary)
                        
                        Text(log.feelingEmoji)
                            .font(.caption)
                        
                        if log.metTarget {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.success)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            onDeleteLog(log)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }
            }
            .padding(8)
            .background(AppTheme.cardBorder.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self], inMemory: true)
}
