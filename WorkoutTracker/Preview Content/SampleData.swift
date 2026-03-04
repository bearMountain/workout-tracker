import Foundation
import SwiftData

enum SampleData {
    static func seedExercises(context: ModelContext) {
        let workoutAExercises = [
            Exercise(
                name: "Squats",
                targetWeight: 185,
                targetReps: 8,
                notes: "Go to parallel or below. Control the descent.",
                workoutType: .a,
                orderIndex: 0
            ),
            Exercise(
                name: "Calf Raises",
                targetWeight: 150,
                targetReps: 12,
                notes: "Full stretch at bottom, pause at top.",
                workoutType: .a,
                orderIndex: 1
            )
        ]
        
        let workoutBExercises = [
            Exercise(
                name: "Pull-ups (narrow grip, palms up)",
                targetWeight: 0,
                targetReps: 8,
                notes: "Full hang at bottom, chin over bar at top. Add weight when needed.",
                workoutType: .b,
                orderIndex: 0
            ),
            Exercise(
                name: "Dips",
                targetWeight: 0,
                targetReps: 10,
                notes: "Lean slightly forward for chest emphasis. Full lockout at top.",
                workoutType: .b,
                orderIndex: 1
            ),
            Exercise(
                name: "Overhead Press",
                targetWeight: 95,
                targetReps: 8,
                notes: "Strict form, no leg drive. Lock out at top.",
                workoutType: .b,
                orderIndex: 2
            )
        ]
        
        for exercise in workoutAExercises + workoutBExercises {
            context.insert(exercise)
        }
        
        try? context.save()
    }
    
    static func seedSampleNotes(context: ModelContext) {
        let notes = [
            ContentNote(
                title: "Mentzer's Training Philosophy",
                body: "High intensity, low volume. One working set to failure per exercise. Full recovery between workouts (7-10 days). Progressive overload is key.",
                urlString: ""
            ),
            ContentNote(
                title: "Form Cues - Squats",
                body: "Break at hips first, knees track over toes, chest up, brace core. Descend under control, drive through midfoot.",
                urlString: ""
            )
        ]
        
        for note in notes {
            context.insert(note)
        }
        
        try? context.save()
    }
}
