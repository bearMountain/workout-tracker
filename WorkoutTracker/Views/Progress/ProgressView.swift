import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProgressViewModel?
    @State private var selectedExerciseIndex = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: AppTheme.spacingLarge) {
                            dateRangePicker(viewModel: viewModel)
                            
                            exerciseProgressSection(viewModel: viewModel)
                            
                            bodyWeightSection(viewModel: viewModel)
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.syncFromAPI()
                        viewModel.fetchData()
                    }
                } else {
                    ProgressView()
                        .tint(AppTheme.accent)
                }
            }
            .navigationTitle("Progress")
            .onAppear {
                if viewModel == nil {
                    viewModel = ProgressViewModel(modelContext: modelContext)
                }
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
    
    private func exerciseProgressSection(viewModel: ProgressViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            HStack {
                Text("Exercise Progress")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                if !viewModel.exercises.isEmpty {
                    Menu {
                        ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                            Button {
                                selectedExerciseIndex = index
                                viewModel.selectedExercise = exercise
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                    if viewModel.selectedExercise?.id == exercise.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedExercise?.name ?? "Select")
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            
            if let exercise = viewModel.selectedExercise {
                ExerciseChartView(
                    exercise: exercise,
                    data: viewModel.chartData(for: exercise),
                    personalBest: viewModel.personalBest(for: exercise),
                    isNewPR: viewModel.isNewPersonalBest(for: exercise),
                    weightTrend: viewModel.weightTrend(for: exercise),
                    repsTrend: viewModel.repsTrend(for: exercise),
                    motivationalMessage: viewModel.motivationalMessage(for: exercise)
                )
            } else if viewModel.exercises.isEmpty {
                emptyExercisesView
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
                motivationalMessage: viewModel.bodyWeightMotivationalMessage
            )
        }
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(for: [Exercise.self, WorkoutLog.self, BodyWeightEntry.self], inMemory: true)
}
