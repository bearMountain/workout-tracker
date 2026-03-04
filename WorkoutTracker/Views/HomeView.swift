import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var selectedWorkout: WorkoutType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spacingLarge) {
                    statusSection
                    workoutsSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Heavy Duty")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedWorkout) { workoutType in
                WorkoutDetailView(workoutType: workoutType, viewModel: viewModel!)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WorkoutViewModel(modelContext: modelContext)
            }
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            if let viewModel = viewModel {
                if let days = viewModel.daysSinceLastWorkout {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isWorkoutDue ? "exclamationmark.circle.fill" : "clock")
                            .foregroundStyle(viewModel.isWorkoutDue ? AppTheme.warning : AppTheme.textSecondary)
                        
                        Text(days == 0 ? "Worked out today" : "\(days) days since last workout")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    if let nextDate = viewModel.nextWorkoutDate {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundStyle(AppTheme.textMuted)
                            
                            Text("Next: \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(AppTheme.accent)
                        
                        Text("Ready to start your training")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Workouts")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
            
            if let viewModel = viewModel {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    WorkoutCard(
                        workoutType: type,
                        exerciseCount: viewModel.exercises(for: type).count,
                        isNext: type == viewModel.nextWorkoutType
                    ) {
                        selectedWorkout = type
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, ContentNote.self], inMemory: true)
}
