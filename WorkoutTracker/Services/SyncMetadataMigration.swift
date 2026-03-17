import Foundation
import SwiftData

enum SyncMetadataMigration {
    @MainActor
    static func backfill(context: ModelContext) {
        var didChange = false
        
        didChange = backfillExercises(context: context) || didChange
        didChange = backfillWorkoutLogs(context: context) || didChange
        didChange = backfillBodyWeights(context: context) || didChange
        didChange = backfillNotes(context: context) || didChange
        
        if didChange {
            try? context.save()
        }
    }
    
    private static func backfillExercises(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Exercise>()
        let items = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for item in items {
            if item.localID != item.id {
                item.localID = item.id
                changed = true
            }
            if item.remoteID == nil {
                item.remoteID = item.id.uuidString
                changed = true
            }
            if item.serverVersion == 0 {
                item.isDirty = true
                changed = true
            }
            if item.lastModifiedAt.timeIntervalSince1970 <= 0 {
                item.lastModifiedAt = Date()
                changed = true
            }
        }
        return changed
    }
    
    private static func backfillWorkoutLogs(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<WorkoutLog>()
        let items = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for item in items {
            if item.localID != item.id {
                item.localID = item.id
                changed = true
            }
            if item.remoteID == nil {
                item.remoteID = item.id.uuidString
                changed = true
            }
            if item.serverVersion == 0 {
                item.isDirty = true
                changed = true
            }
            if item.lastModifiedAt.timeIntervalSince1970 <= 0 {
                item.lastModifiedAt = Date()
                changed = true
            }
        }
        return changed
    }
    
    private static func backfillBodyWeights(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<BodyWeightEntry>()
        let items = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for item in items {
            if item.localID != item.id {
                item.localID = item.id
                changed = true
            }
            if item.remoteID == nil {
                item.remoteID = item.id.uuidString
                changed = true
            }
            if item.serverVersion == 0 {
                item.isDirty = true
                changed = true
            }
            if item.lastModifiedAt.timeIntervalSince1970 <= 0 {
                item.lastModifiedAt = Date()
                changed = true
            }
        }
        return changed
    }
    
    private static func backfillNotes(context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ContentNote>()
        let items = (try? context.fetch(descriptor)) ?? []
        var changed = false
        for item in items {
            if item.localID != item.id {
                item.localID = item.id
                changed = true
            }
            
            if item.remoteID == nil {
                item.remoteID = item.id.uuidString
                changed = true
            }
            
            if item.serverVersion == 0 {
                item.isDirty = true
                changed = true
            }
            
            if item.lastModifiedAt.timeIntervalSince1970 <= 0 {
                item.lastModifiedAt = Date()
                changed = true
            }
        }
        return changed
    }
}
