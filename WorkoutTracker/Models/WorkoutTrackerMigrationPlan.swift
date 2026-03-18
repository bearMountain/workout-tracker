import Foundation
import SwiftData

enum WorkoutTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WorkoutTrackerSchemaV1.self, WorkoutTrackerSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: WorkoutTrackerSchemaV1.self, toVersion: WorkoutTrackerSchemaV2.self)
        ]
    }
}

enum WorkoutTrackerModelContainerFactory {
    static let latestSchema = Schema(versionedSchema: WorkoutTrackerSchemaV2.self)

    static func makeSharedContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: latestSchema, isStoredInMemoryOnly: false)
        return try ModelContainer(
            for: latestSchema,
            migrationPlan: WorkoutTrackerMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: latestSchema, isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: latestSchema,
            migrationPlan: WorkoutTrackerMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeContainer(url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: latestSchema, url: url)
        return try ModelContainer(
            for: latestSchema,
            migrationPlan: WorkoutTrackerMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
