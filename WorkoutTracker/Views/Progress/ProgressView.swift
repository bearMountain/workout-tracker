import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncEngine.self) private var syncEngine: SyncEngine?
    @State private var viewModel: ProgressViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingLarge) {
                            dateRangePicker(viewModel: viewModel)

                            bodyWeightSection(viewModel: viewModel)

                            weightliftingSection(viewModel: viewModel)
                        }
                        .padding()
                    }
                    .refreshable {
                        await syncEngine?.syncAll()
                        viewModel.fetchData()
                    }
                } else {
                    ProgressView()
                        .tint(AppTheme.accent)
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SyncStatusIndicator()
                }
            }
            .onAppear {
                if viewModel == nil, let syncEngine {
                    viewModel = ProgressViewModel(modelContext: modelContext, syncEngine: syncEngine)
                }
                viewModel?.fetchData()
            }
            .onChange(of: syncEngine?.lastSyncDate) {
                viewModel?.fetchData()
            }
        }
    }

    private func dateRangePicker(viewModel: ProgressViewModel) -> some View {
        HStack(spacing: 8) {
            ForEach(DateRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedDateRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(
                            viewModel.selectedDateRange == range
                                ? AppTheme.background
                                : AppTheme.textSecondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedDateRange == range
                                ? AppTheme.accent
                                : AppTheme.cardBackground
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func weightliftingSection(viewModel: ProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Weightlifting")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            if viewModel.exercises.isEmpty {
                emptyExercisesView
            } else {
                ForEach(WorkoutType.allCases, id: \.self) { workoutType in
                    WorkoutDayProgressChart(
                        workoutType: workoutType,
                        exercises: viewModel.exercises(for: workoutType),
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textMuted)

            Text("No exercises yet")
                .font(.headline)
                .foregroundStyle(AppTheme.textSecondary)

            Text("Add exercises from the Home tab to start tracking progress")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardStyle()
    }

    private func bodyWeightSection(viewModel: ProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Body Weight")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.textPrimary)

            BodyWeightChartView(
                data: viewModel.bodyWeightChartData,
                latestWeight: viewModel.latestBodyWeight?.weight,
                trend: viewModel.bodyWeightTrend,
                lowestWeight: viewModel.lowestBodyWeight,
                highestWeight: viewModel.highestBodyWeight,
                entryCount: viewModel.bodyWeightEntryCount,
                motivationalMessage: viewModel.bodyWeightMotivationalMessage
            )
        }
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, BodyWeightEntry.self], inMemory: true)
}
