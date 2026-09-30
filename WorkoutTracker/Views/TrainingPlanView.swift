import SwiftUI

struct TrainingPlanView: View {
    private let referenceDate: Date
    private let calendar: Calendar
    @State private var adjustments: Set<CircuitAdjustment>

    init(date: Date = .now, calendar: Calendar = .current) {
        self.referenceDate = date
        self.calendar = calendar
        let weekday = TrainingWeekday.from(date: date, calendar: calendar)
        _adjustments = State(initialValue: CircuitAdjustment.suggested(on: weekday))
    }

    private var weekday: TrainingWeekday {
        TrainingWeekday.from(date: referenceDate, calendar: calendar)
    }

    private var today: ScheduledSession {
        TrainingPlan.session(on: weekday)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                    todaySection
                    weekSection
                    circuitSection
                    nutritionSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Today")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            TodaySessionCard(session: today)
        }
    }

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Week")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 0) {
                ForEach(TrainingPlan.week) { session in
                    WeekSessionRow(session: session, isToday: session.weekday == weekday)
                    if session.weekday != TrainingPlan.week.last?.weekday {
                        Rectangle()
                            .fill(AppTheme.cardBorder)
                            .frame(height: 1)
                    }
                }
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .accessibilityIdentifier("weekly-schedule")
        }
    }

    private var circuitSection: some View {
        let guidance = DailyCircuit.guidance(for: adjustments)

        return VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Daily circuit")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                Text("\(DailyCircuit.cadence) · \(DailyCircuit.duration)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(DailyCircuit.reserveGuidance)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityIdentifier("circuit-reserve-guidance")

                if let sectionNote = guidance.sectionNote {
                    Text(sectionNote)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warning)
                        .accessibilityIdentifier("circuit-one-round")
                }

                ForEach(DailyCircuit.exercises) { exercise in
                    CircuitExerciseRow(
                        exercise: exercise,
                        note: guidance.exerciseNotes[exercise.id]
                    )
                }

                if guidance.showsFieldAlternatives {
                    Text("Field alternative")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textMuted)
                        .padding(.top, 4)

                    ForEach(DailyCircuit.fieldAlternatives) { exercise in
                        CircuitExerciseRow(exercise: exercise, note: nil)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            .accessibilityIdentifier("daily-circuit")

            modifications
        }
    }

    private var modifications: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Modifications")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Selectable guidance. Logged workouts stay as you record them.")
                .font(.caption)
                .foregroundStyle(AppTheme.textMuted)

            VStack(alignment: .leading, spacing: AppTheme.spacingLarge) {
                ForEach(CircuitAdjustment.allCases) { adjustment in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 8) {
                            Text(adjustment.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.textPrimary)

                            if adjustment.applies(on: weekday) {
                                Text("TODAY")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.background)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.accent)
                                    .clipShape(Capsule())
                            }

                            Spacer(minLength: 8)

                            Toggle(
                                adjustment.title,
                                isOn: binding(for: adjustment)
                            )
                            .labelsHidden()
                            .tint(AppTheme.accent)
                            .accessibilityIdentifier("circuit-adjustment-\(adjustment.id)")
                        }

                        Text(adjustment.detail)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if adjustment == .noPullUpBar {
                            ForEach(DailyCircuit.fieldAlternatives) { alternative in
                                Text("\(alternative.name): \(alternative.prescription)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .accessibilityIdentifier("circuit-modifications")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing) {
            Text("Nutrition")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Daily targets")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(NutritionGuide.summary)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("nutrition-summary")

                ForEach(NutritionGuide.targets) { target in
                    HStack {
                        Text(target.label)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Spacer()
                        Text(target.value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .accessibilityIdentifier("nutrition-target-\(target.id)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                Text("Meal timing")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(NutritionGuide.meals) { meal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(meal.window)
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        Text(meal.guidance)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityIdentifier("nutrition-meal-\(meal.id)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            VStack(alignment: .leading, spacing: AppTheme.spacing) {
                Text("Carb sources")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(NutritionGuide.carbSources) { group in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(group.pace) (\(group.when))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(group.sources)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityIdentifier("nutrition-carbs-\(group.id)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .accessibilityIdentifier("nutrition-guide")
    }

    private func binding(for adjustment: CircuitAdjustment) -> Binding<Bool> {
        Binding(
            get: { adjustments.contains(adjustment) },
            set: { isOn in
                if isOn {
                    adjustments.insert(adjustment)
                } else {
                    adjustments.remove(adjustment)
                }
            }
        )
    }
}

struct TodaySessionCard: View {
    let session: ScheduledSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.weekday.fullName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.accent)

            Text(session.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .accessibilityIdentifier("today-session-name")

            Label(session.duration, systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityIdentifier("today-session-duration")

            Label(session.intensity, systemImage: "bolt")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityIdentifier("today-session-intensity")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-session")
    }
}

private struct WeekSessionRow: View {
    let session: ScheduledSession
    let isToday: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing) {
            Text(session.weekday.shortName)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(isToday ? AppTheme.accent : AppTheme.textMuted)
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(session.duration)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(session.intensity)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)

            if isToday {
                Text("TODAY")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.background)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.cardPadding)
        .background(isToday ? AppTheme.accent.opacity(0.08) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("schedule-\(session.weekday.shortName.lowercased())")
    }
}

private struct CircuitExerciseRow: View {
    let exercise: CircuitExercise
    let note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
            Text(exercise.prescription)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("circuit-exercise-\(exercise.id)")
    }
}

#Preview {
    TrainingPlanView()
        .preferredColorScheme(.dark)
}
