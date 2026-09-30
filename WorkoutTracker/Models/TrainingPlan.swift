import Foundation

/// Reference copy of the Zeigler weekly schedule, daily circuit, and nutrition targets.
/// Guidance only: nothing here writes logs or changes progressive overload.
enum TrainingPlan {
    static let week: [ScheduledSession] = TrainingWeekday.displayOrder.map(session(on:))

    static func session(on date: Date, calendar: Calendar = .current) -> ScheduledSession {
        session(on: TrainingWeekday.from(date: date, calendar: calendar))
    }

    static func session(on weekday: TrainingWeekday) -> ScheduledSession {
        switch weekday {
        case .monday:
            return ScheduledSession(
                weekday: .monday,
                name: "Heavy HIT, A Day (Legs)",
                duration: "45–60 min",
                intensity: "one set to failure"
            )
        case .tuesday:
            return ScheduledSession(
                weekday: .tuesday,
                name: "Run",
                duration: "20–40 min",
                intensity: "conversational pace"
            )
        case .wednesday:
            return ScheduledSession(
                weekday: .wednesday,
                name: "Animal Flow Yoga",
                duration: "20–30 min",
                intensity: "light and controlled"
            )
        case .thursday:
            return ScheduledSession(
                weekday: .thursday,
                name: "Heavy HIT, B Day (Upper + Deadlift)",
                duration: "45–60 min",
                intensity: "one set to failure"
            )
        case .friday:
            return ScheduledSession(
                weekday: .friday,
                name: "Calisthenics",
                duration: "20–30 min",
                intensity: "stop well short of failure"
            )
        case .saturday:
            return ScheduledSession(
                weekday: .saturday,
                name: "Tai Chi",
                duration: "20–25 min",
                intensity: "slow follow-along video"
            )
        case .sunday:
            return ScheduledSession(
                weekday: .sunday,
                name: "Rest",
                duration: "Rest",
                intensity: "Rest"
            )
        }
    }
}

enum TrainingWeekday: Int, CaseIterable, Identifiable, Hashable {
    /// Gregorian weekday values: Sunday = 1 … Saturday = 7.
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    static let displayOrder: [TrainingWeekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var id: Int { rawValue }

    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    static func from(date: Date, calendar: Calendar = .current) -> TrainingWeekday {
        let weekday = calendar.component(.weekday, from: date)
        return TrainingWeekday(rawValue: weekday) ?? .sunday
    }
}

struct ScheduledSession: Equatable, Identifiable {
    let weekday: TrainingWeekday
    let name: String
    let duration: String
    let intensity: String

    var id: TrainingWeekday { weekday }
}

enum DailyCircuit {
    static let cadence = "Every day"
    static let duration = "about 10 min"
    static let reserveGuidance = "Stop with 4–5 reps left in reserve"

    static let exercises: [CircuitExercise] = [
        CircuitExercise(id: "push-ups", name: "Push-ups", prescription: "2 sets of 8–10"),
        CircuitExercise(id: "air-squats", name: "Air squats", prescription: "2 sets of 8–10"),
        CircuitExercise(id: "dead-hang", name: "Dead hang", prescription: "2 sets of 15–20 sec"),
        CircuitExercise(id: "glute-bridges", name: "Glute bridges", prescription: "2 sets of 8–10"),
        CircuitExercise(id: "dead-bugs", name: "Dead bugs", prescription: "2 sets of 8–10")
    ]

    static let fieldAlternatives: [CircuitExercise] = [
        CircuitExercise(
            id: "doorframe-rows",
            name: "Doorframe rows or inverted rows",
            prescription: "2 sets of 8–10"
        ),
        CircuitExercise(
            id: "prone-ytw",
            name: "Prone Y-T-W raises",
            prescription: "2 sets of 8 each"
        )
    ]

    static func guidance(for adjustments: Set<CircuitAdjustment>) -> CircuitGuidance {
        var notes: [String: String] = [:]
        if adjustments.contains(.mondayMorning) {
            notes["air-squats"] = CircuitAdjustment.mondayMorning.detail
            notes["glute-bridges"] = CircuitAdjustment.mondayMorning.detail
        }
        if adjustments.contains(.thursdayMorning) {
            notes["push-ups"] = CircuitAdjustment.thursdayMorning.detail
        }
        if adjustments.contains(.noPullUpBar) {
            notes["dead-hang"] = "No pull-up bar: use a field alternative"
        }

        return CircuitGuidance(
            exerciseNotes: notes,
            sectionNote: adjustments.contains(.dayAfterHeavy) ? CircuitAdjustment.dayAfterHeavy.detail : nil,
            showsFieldAlternatives: adjustments.contains(.noPullUpBar)
        )
    }
}

struct CircuitExercise: Equatable, Identifiable {
    let id: String
    let name: String
    let prescription: String
}

struct CircuitGuidance: Equatable {
    let exerciseNotes: [String: String]
    let sectionNote: String?
    let showsFieldAlternatives: Bool
}

enum CircuitAdjustment: String, CaseIterable, Identifiable, Hashable {
    case mondayMorning
    case thursdayMorning
    case dayAfterHeavy
    case noPullUpBar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mondayMorning: return "Monday morning"
        case .thursdayMorning: return "Thursday morning"
        case .dayAfterHeavy: return "Day after a heavy session"
        case .noPullUpBar: return "No pull-up bar"
        }
    }

    var detail: String {
        switch self {
        case .mondayMorning:
            return "Skip air squats and bridges, or do 1 easy set"
        case .thursdayMorning:
            return "Skip push-ups, or do 1 easy set"
        case .dayAfterHeavy:
            return "One round only if feeling cooked"
        case .noPullUpBar:
            return "Doorframe rows or inverted rows (2 sets of 8–10), or prone Y-T-W raises (2 sets of 8 each)"
        }
    }

    func applies(on weekday: TrainingWeekday) -> Bool {
        switch self {
        case .mondayMorning:
            return weekday == .monday
        case .thursdayMorning:
            return weekday == .thursday
        case .dayAfterHeavy:
            return weekday == .tuesday || weekday == .friday
        case .noPullUpBar:
            return false
        }
    }

    static func suggested(on weekday: TrainingWeekday) -> Set<CircuitAdjustment> {
        switch weekday {
        case .monday:
            return [.mondayMorning]
        case .thursday:
            return [.thursdayMorning]
        default:
            return []
        }
    }
}

enum NutritionGuide {
    static let summary = "~3,000 cal, 180g protein, 70g fat, 340g carbs"

    static let targets: [NutritionTarget] = [
        NutritionTarget(id: "calories", label: "Calories", value: "~3,000 cal"),
        NutritionTarget(id: "protein", label: "Protein", value: "180g protein"),
        NutritionTarget(id: "fat", label: "Fat", value: "70g fat"),
        NutritionTarget(id: "carbs", label: "Carbs", value: "340g carbs")
    ]

    static let meals: [MealTiming] = [
        MealTiming(
            id: "pre-workout",
            name: "Pre-workout",
            window: "60–90 min before",
            guidance: "Oats + fruit + protein shake (½ cup dry oats, 1 banana, 1 scoop protein, 1 cup water or almond milk; ~380–420 cal, 30–35g protein, 55–65g carbs)"
        ),
        MealTiming(
            id: "post-workout",
            name: "Post-workout",
            window: "within 30–60 min",
            guidance: "50–60g protein + 80–100g carbs"
        ),
        MealTiming(
            id: "evening",
            name: "Evening meal",
            window: "2–3 hrs later",
            guidance: "40–50g protein + 60–80g carbs"
        ),
        MealTiming(
            id: "before-bed",
            name: "Optional before bed",
            window: "before bed",
            guidance: "Casein shake, cottage cheese, or Greek yogurt"
        )
    ]

    static let carbSources: [CarbSourceGroup] = [
        CarbSourceGroup(
            id: "fast",
            pace: "Fast",
            when: "pre-work or training",
            sources: "white rice, rice cakes, bananas, white potatoes, honey"
        ),
        CarbSourceGroup(
            id: "moderate",
            pace: "Moderate",
            when: "workday",
            sources: "oats, sweet potatoes, fruit, bread"
        ),
        CarbSourceGroup(
            id: "slower",
            pace: "Slower",
            when: "evening",
            sources: "brown rice, quinoa, beans, whole grain pasta"
        )
    ]
}

struct NutritionTarget: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
}

struct MealTiming: Equatable, Identifiable {
    let id: String
    let name: String
    let window: String
    let guidance: String
}

struct CarbSourceGroup: Equatable, Identifiable {
    let id: String
    let pace: String
    let when: String
    let sources: String
}
