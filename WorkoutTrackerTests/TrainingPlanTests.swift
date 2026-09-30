import XCTest
@testable import WorkoutTracker

final class TrainingPlanTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        self.calendar = calendar
    }

    func testWeekFollowsMondayThroughSundaySpec() {
        let sessions = TrainingPlan.week
        XCTAssertEqual(sessions.map(\.weekday), TrainingWeekday.displayOrder)

        XCTAssertEqual(sessions.map(\.name), [
            "Heavy HIT, A Day (Legs)",
            "Run",
            "Animal Flow Yoga",
            "Heavy HIT, B Day (Upper + Deadlift)",
            "Calisthenics",
            "Tai Chi",
            "Rest"
        ])
        XCTAssertEqual(sessions.map(\.duration), [
            "45–60 min",
            "20–40 min",
            "20–30 min",
            "45–60 min",
            "20–30 min",
            "20–25 min",
            "Rest"
        ])
        XCTAssertEqual(sessions.map(\.intensity), [
            "one set to failure",
            "conversational pace",
            "light and controlled",
            "one set to failure",
            "stop well short of failure",
            "slow follow-along video",
            "Rest"
        ])
    }

    func testTodaySessionUsesCalendarWeekday() {
        let wednesday = date(year: 2026, month: 9, day: 30)
        let session = TrainingPlan.session(on: wednesday, calendar: calendar)

        XCTAssertEqual(session.weekday, .wednesday)
        XCTAssertEqual(session.name, "Animal Flow Yoga")
        XCTAssertEqual(session.duration, "20–30 min")
        XCTAssertEqual(session.intensity, "light and controlled")
    }

    func testDailyCircuitListsSpecPrescriptionsEveryDay() {
        XCTAssertEqual(DailyCircuit.cadence, "Every day")
        XCTAssertEqual(DailyCircuit.duration, "about 10 min")
        XCTAssertEqual(DailyCircuit.reserveGuidance, "Stop with 4–5 reps left in reserve")
        XCTAssertEqual(DailyCircuit.exercises.map(\.name), [
            "Push-ups",
            "Air squats",
            "Dead hang",
            "Glute bridges",
            "Dead bugs"
        ])
        XCTAssertEqual(DailyCircuit.exercises.map(\.prescription), [
            "2 sets of 8–10",
            "2 sets of 8–10",
            "2 sets of 15–20 sec",
            "2 sets of 8–10",
            "2 sets of 8–10"
        ])
    }

    func testCircuitModificationsAndFieldAlternatives() {
        XCTAssertEqual(CircuitAdjustment.allCases.map(\.title), [
            "Monday morning",
            "Thursday morning",
            "Day after a heavy session",
            "No pull-up bar"
        ])
        XCTAssertEqual(
            CircuitAdjustment.mondayMorning.detail,
            "Skip air squats and bridges, or do 1 easy set"
        )
        XCTAssertEqual(
            CircuitAdjustment.thursdayMorning.detail,
            "Skip push-ups, or do 1 easy set"
        )
        XCTAssertEqual(
            CircuitAdjustment.dayAfterHeavy.detail,
            "One round only if feeling cooked"
        )
        XCTAssertEqual(
            CircuitAdjustment.noPullUpBar.detail,
            "Doorframe rows or inverted rows (2 sets of 8–10), or prone Y-T-W raises (2 sets of 8 each)"
        )
        XCTAssertEqual(DailyCircuit.fieldAlternatives.map(\.name), [
            "Doorframe rows or inverted rows",
            "Prone Y-T-W raises"
        ])
        XCTAssertEqual(DailyCircuit.fieldAlternatives.map(\.prescription), [
            "2 sets of 8–10",
            "2 sets of 8 each"
        ])

        let monday = DailyCircuit.guidance(for: [.mondayMorning])
        XCTAssertEqual(monday.exerciseNotes["air-squats"], CircuitAdjustment.mondayMorning.detail)
        XCTAssertEqual(monday.exerciseNotes["glute-bridges"], CircuitAdjustment.mondayMorning.detail)
        XCTAssertNil(monday.exerciseNotes["push-ups"])
        XCTAssertFalse(monday.showsFieldAlternatives)

        let thursday = DailyCircuit.guidance(for: [.thursdayMorning])
        XCTAssertEqual(thursday.exerciseNotes["push-ups"], CircuitAdjustment.thursdayMorning.detail)
        XCTAssertNil(thursday.exerciseNotes["air-squats"])

        let cooked = DailyCircuit.guidance(for: [.dayAfterHeavy])
        XCTAssertEqual(cooked.sectionNote, "One round only if feeling cooked")

        let noBar = DailyCircuit.guidance(for: [.noPullUpBar])
        XCTAssertTrue(noBar.showsFieldAlternatives)
        XCTAssertEqual(noBar.exerciseNotes["dead-hang"], "No pull-up bar: use a field alternative")

        XCTAssertEqual(CircuitAdjustment.suggested(on: .monday), [.mondayMorning])
        XCTAssertEqual(CircuitAdjustment.suggested(on: .thursday), [.thursdayMorning])
        XCTAssertTrue(CircuitAdjustment.suggested(on: .wednesday).isEmpty)
        XCTAssertTrue(CircuitAdjustment.dayAfterHeavy.applies(on: .tuesday))
        XCTAssertTrue(CircuitAdjustment.dayAfterHeavy.applies(on: .friday))
        XCTAssertFalse(CircuitAdjustment.dayAfterHeavy.applies(on: .wednesday))
    }

    func testNutritionTargetsMealTimingAndCarbSources() {
        XCTAssertEqual(NutritionGuide.summary, "~3,000 cal, 180g protein, 70g fat, 340g carbs")
        XCTAssertEqual(NutritionGuide.targets.map(\.value), [
            "~3,000 cal",
            "180g protein",
            "70g fat",
            "340g carbs"
        ])

        XCTAssertEqual(NutritionGuide.meals.map(\.name), [
            "Pre-workout",
            "Post-workout",
            "Evening meal",
            "Optional before bed"
        ])
        XCTAssertEqual(NutritionGuide.meals.map(\.window), [
            "60–90 min before",
            "within 30–60 min",
            "2–3 hrs later",
            "before bed"
        ])
        XCTAssertEqual(
            NutritionGuide.meals[0].guidance,
            "Oats + fruit + protein shake (½ cup dry oats, 1 banana, 1 scoop protein, 1 cup water or almond milk; ~380–420 cal, 30–35g protein, 55–65g carbs)"
        )
        XCTAssertEqual(NutritionGuide.meals[1].guidance, "50–60g protein + 80–100g carbs")
        XCTAssertEqual(NutritionGuide.meals[2].guidance, "40–50g protein + 60–80g carbs")
        XCTAssertEqual(
            NutritionGuide.meals[3].guidance,
            "Casein shake, cottage cheese, or Greek yogurt"
        )

        XCTAssertEqual(NutritionGuide.carbSources.map(\.pace), ["Fast", "Moderate", "Slower"])
        XCTAssertEqual(NutritionGuide.carbSources.map(\.when), [
            "pre-work or training",
            "workday",
            "evening"
        ])
        XCTAssertEqual(NutritionGuide.carbSources.map(\.sources), [
            "white rice, rice cakes, bananas, white potatoes, honey",
            "oats, sweet potatoes, fruit, bread",
            "brown rice, quinoa, beans, whole grain pasta"
        ])
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components)!
    }
}
