import BackgroundTasks
import Foundation
import Network
import SwiftData

protocol APIClientProtocol: Sendable {
    func fetchExercises(workoutType: String?, since: String?) async throws -> [APIExercise]
    func fetchLogs(exerciseId: String?, limit: Int, since: String?) async throws -> [APIWorkoutLog]
    func fetchBodyWeights(limit: Int, since: String?) async throws -> [APIBodyWeight]
    func fetchNotes(limit: Int, since: String?) async throws -> [APIContentNote]
    
    func createExercise(_ input: CreateExerciseRequest) async throws -> APIExercise
    func createLog(_ input: CreateWorkoutLogRequest) async throws -> APIWorkoutLog
    func createBodyWeight(_ input: CreateBodyWeightRequest) async throws -> APIBodyWeight
    func createNote(_ input: CreateContentNoteRequest) async throws -> APIContentNote
    
    func updateExercise(id: String, _ input: UpdateExerciseRequest) async throws -> APIExercise
    func updateLog(id: String, _ input: UpdateWorkoutLogRequest) async throws -> APIWorkoutLog
    func updateBodyWeight(id: String, _ input: UpdateBodyWeightRequest) async throws -> APIBodyWeight
    func updateNote(id: String, _ input: UpdateContentNoteRequest) async throws -> APIContentNote
    
    func deleteExercise(id: String) async throws
    func deleteLog(id: String) async throws
    func deleteBodyWeight(id: String) async throws
    func deleteNote(id: String) async throws
}

extension APIClient: APIClientProtocol {}

enum SyncIndicatorState {
    case synced
    case pending
    case error
}

@Observable
@MainActor
final class SyncEngine {
    static private(set) weak var shared: SyncEngine?
    
    private let modelContext: ModelContext
    private let apiClient: any APIClientProtocol
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "SyncEngine.PathMonitor")
    private let enableBackgroundScheduling: Bool
    
    private let maxRetryAttempts = 5
    private let baseRetryDelay: TimeInterval = 30
    private var lastPullDate: Date?
    
    private(set) var isSyncing = false
    private(set) var syncError: String?
    private(set) var pendingChangesCount = 0
    private(set) var isOnline = false
    var lastSyncDate: Date?
    var lastSuccessfulSyncDate: Date?
    var persistentBannerMessage: String?
    
    var indicatorState: SyncIndicatorState {
        if persistentBannerMessage != nil || syncError != nil {
            return .error
        }
        if isSyncing || pendingChangesCount > 0 || !isOnline {
            return .pending
        }
        return .synced
    }
    
    init(
        modelContext: ModelContext,
        apiClient: any APIClientProtocol = APIClient.shared,
        enablePathMonitoring: Bool = true,
        initialOnlineState: Bool = false,
        enableBackgroundScheduling: Bool = true
    ) {
        self.modelContext = modelContext
        self.apiClient = apiClient
        self.isOnline = initialOnlineState
        self.enableBackgroundScheduling = enableBackgroundScheduling
        SyncEngine.shared = self
        if enablePathMonitoring {
            startPathMonitoring()
        }
        refreshPendingCount()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    func syncAll() async {
        await syncNow()
    }
    
    func syncNow() async {
        guard !isSyncing else { return }
        guard isOnline else {
            refreshPendingCount()
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            try await pullLatestFromServer()
            try await processPendingChanges()
            try await pullLatestFromServer()
            lastSyncDate = Date()
            lastSuccessfulSyncDate = Date()
            persistentBannerMessage = nil
        } catch {
            syncError = error.localizedDescription
        }
        
        isSyncing = false
        refreshPendingCount()
    }
    
    func queueForSync(_ model: any SyncableModel) {
        model.markDirty()
        saveContext()
        refreshPendingCount()
        scheduleBackgroundSync()
        
        guard isOnline else { return }
        Task { [weak self] in
            await self?.syncNow()
        }
    }
    
    func queueForDeletion(_ model: any SyncableModel) {
        model.markDeleted()
        saveContext()
        refreshPendingCount()
        scheduleBackgroundSync()
        
        guard isOnline else { return }
        Task { [weak self] in
            await self?.syncNow()
        }
    }
    
    func processPendingChanges() async throws {
        try await pushPendingExercises()
        try await pushPendingNotes()
        try await pushPendingBodyWeights()
        try await pushPendingWorkoutLogs()
        refreshPendingCount()
    }
    
    func pullLatestFromServer() async throws {
        let since = lastPullDate.flatMap { APIClient.dateFormatter.string(from: $0) }
        
        let exercises = try await apiClient.fetchExercises(workoutType: nil, since: since)
        let notes = try await apiClient.fetchNotes(limit: 500, since: since)
        let bodyWeights = try await apiClient.fetchBodyWeights(limit: 500, since: since)
        let logs = try await apiClient.fetchLogs(exerciseId: nil, limit: 500, since: since)
        
        merge(exercises: exercises)
        merge(notes: notes)
        merge(bodyWeights: bodyWeights)
        merge(logs: logs)
        
        saveContext()
        lastPullDate = Date()
        refreshPendingCount()
    }
    
    private func startPathMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied
                if self.isOnline && wasOffline {
                    await self.syncNow()
                }
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }
    
    func handleSceneDidBecomeActive() async {
        refreshPendingCount()
        guard isOnline else { return }
        await syncNow()
    }
    
    func scheduleBackgroundSync() {
        guard enableBackgroundScheduling else { return }
        guard pendingChangesCount > 0 else { return }
        let request = BGProcessingTaskRequest(identifier: WorkoutTrackerAppDelegate.syncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error.localizedDescription)")
        }
    }
    
    func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        scheduleBackgroundSync()
        task.expirationHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.syncError = "Background sync expired"
            }
        }
        
        Task { @MainActor [weak self] in
            guard let self else {
                task.setTaskCompleted(success: false)
                return
            }
            await self.syncNow()
            task.setTaskCompleted(success: self.syncError == nil)
        }
    }
    
    private func pushPendingExercises() async throws {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.isDirty == true },
            sortBy: [SortDescriptor(\.lastModifiedAt)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for item in items where canAttemptSync(item) {
            do {
                let response = try await apiClient.createExercise(CreateExerciseRequest(
                    id: item.effectiveRemoteID,
                    name: item.name,
                    targetWeight: item.targetWeight,
                    targetReps: item.targetReps,
                    notes: item.notes,
                    workoutType: item.workoutType.rawValue,
                    orderIndex: item.orderIndex,
                    clientUpdatedAt: APIClient.dateFormatter.string(from: item.lastModifiedAt),
                    idempotencyKey: item.idempotencyKey.uuidString,
                    deletedAt: item.deletedAt.flatMap { APIClient.dateFormatter.string(from: $0) }
                ))
                apply(response, to: item)
                saveContext()
            } catch {
                handlePushFailure(item, error: error)
            }
        }
    }
    
    private func pushPendingNotes() async throws {
        let descriptor = FetchDescriptor<ContentNote>(
            predicate: #Predicate { $0.isDirty == true },
            sortBy: [SortDescriptor(\.lastModifiedAt)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for item in items where canAttemptSync(item) {
            do {
                let response = try await apiClient.createNote(CreateContentNoteRequest(
                    id: item.effectiveRemoteID,
                    title: item.title,
                    body: item.body,
                    url: item.urlString,
                    clientUpdatedAt: APIClient.dateFormatter.string(from: item.lastModifiedAt),
                    idempotencyKey: item.idempotencyKey.uuidString,
                    deletedAt: item.deletedAt.flatMap { APIClient.dateFormatter.string(from: $0) }
                ))
                apply(response, to: item)
                saveContext()
            } catch {
                handlePushFailure(item, error: error)
            }
        }
    }
    
    private func pushPendingBodyWeights() async throws {
        let descriptor = FetchDescriptor<BodyWeightEntry>(
            predicate: #Predicate { $0.isDirty == true },
            sortBy: [SortDescriptor(\.lastModifiedAt)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for item in items where canAttemptSync(item) {
            do {
                let response = try await apiClient.createBodyWeight(CreateBodyWeightRequest(
                    id: item.effectiveRemoteID,
                    date: APIClient.dateFormatter.string(from: item.date),
                    weight: item.weight,
                    notes: item.notes,
                    clientUpdatedAt: APIClient.dateFormatter.string(from: item.lastModifiedAt),
                    idempotencyKey: item.idempotencyKey.uuidString,
                    deletedAt: item.deletedAt.flatMap { APIClient.dateFormatter.string(from: $0) }
                ))
                apply(response, to: item)
                saveContext()
            } catch {
                handlePushFailure(item, error: error)
            }
        }
    }
    
    private func pushPendingWorkoutLogs() async throws {
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.isDirty == true },
            sortBy: [SortDescriptor(\.lastModifiedAt)]
        )
        let items = (try? modelContext.fetch(descriptor)) ?? []
        for item in items where canAttemptSync(item) {
            guard let exercise = item.exercise else { continue }
            do {
                let response = try await apiClient.createLog(CreateWorkoutLogRequest(
                    id: item.effectiveRemoteID,
                    exerciseId: exercise.effectiveRemoteID,
                    date: APIClient.dateFormatter.string(from: item.date),
                    actualWeight: item.actualWeight,
                    actualReps: item.actualReps,
                    isMachine: item.isMachine,
                    feeling: item.feeling,
                    notes: item.notes,
                    clientUpdatedAt: APIClient.dateFormatter.string(from: item.lastModifiedAt),
                    idempotencyKey: item.idempotencyKey.uuidString,
                    deletedAt: item.deletedAt.flatMap { APIClient.dateFormatter.string(from: $0) }
                ))
                apply(response, to: item)
                saveContext()
            } catch {
                handlePushFailure(item, error: error)
            }
        }
    }
    
    private func merge(exercises: [APIExercise]) {
        for remote in exercises {
            let remoteUpdatedAt = parsedDate(remote.updatedAt)
            if let existing = fetchExercise(remoteID: remote.id) {
                if existing.isDirty && existing.lastModifiedAt > remoteUpdatedAt {
                    print("Skipping stale exercise pull for \(remote.id)")
                    continue
                }
                
                existing.name = remote.name
                existing.targetWeight = remote.targetWeight
                existing.targetReps = remote.targetReps
                existing.notes = remote.notes
                existing.workoutType = WorkoutType(rawValue: remote.workoutType) ?? .a
                existing.orderIndex = remote.orderIndex
                existing.remoteID = remote.id
                existing.isDeleted = remote.deletedAt != nil
                existing.deletedAt = parsedOptionalDate(remote.deletedAt)
                existing.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt ?? remote.createdAt)
                existing.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? max(existing.serverVersion, 1), at: Date())
            } else {
                let exercise = Exercise(
                    id: UUID(uuidString: remote.id) ?? UUID(),
                    name: remote.name,
                    targetWeight: remote.targetWeight,
                    targetReps: remote.targetReps,
                    notes: remote.notes,
                    workoutType: WorkoutType(rawValue: remote.workoutType) ?? .a,
                    orderIndex: remote.orderIndex
                )
                exercise.remoteID = remote.id
                exercise.isDeleted = remote.deletedAt != nil
                exercise.deletedAt = parsedOptionalDate(remote.deletedAt)
                exercise.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt)
                exercise.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? 1, at: Date())
                modelContext.insert(exercise)
            }
        }
    }
    
    private func merge(notes: [APIContentNote]) {
        for remote in notes {
            if let existing = fetchContentNote(remoteID: remote.id) {
                if existing.isDirty && existing.lastModifiedAt > parsedDate(remote.updatedAt) {
                    print("Skipping stale note pull for \(remote.id)")
                    continue
                }
                
                existing.title = remote.title
                existing.body = remote.body
                existing.urlString = remote.url
                existing.createdAt = parsedDate(remote.createdAt)
                existing.updatedAt = parsedDate(remote.updatedAt)
                existing.remoteID = remote.id
                existing.isDeleted = remote.deletedAt != nil
                existing.deletedAt = parsedOptionalDate(remote.deletedAt)
                existing.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt)
                existing.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? max(existing.serverVersion, 1), at: Date())
            } else {
                let note = ContentNote(
                    id: UUID(uuidString: remote.id) ?? UUID(),
                    title: remote.title,
                    body: remote.body,
                    urlString: remote.url
                )
                note.createdAt = parsedDate(remote.createdAt)
                note.updatedAt = parsedDate(remote.updatedAt)
                note.remoteID = remote.id
                note.isDeleted = remote.deletedAt != nil
                note.deletedAt = parsedOptionalDate(remote.deletedAt)
                note.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt)
                note.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? 1, at: Date())
                modelContext.insert(note)
            }
        }
    }
    
    private func merge(bodyWeights: [APIBodyWeight]) {
        for remote in bodyWeights {
            if let existing = fetchBodyWeightEntry(remoteID: remote.id) {
                if existing.isDirty && existing.lastModifiedAt > parsedDate(remote.updatedAt, fallback: remote.createdAt) {
                    print("Skipping stale body-weight pull for \(remote.id)")
                    continue
                }
                
                existing.date = parsedDate(remote.date)
                existing.weight = remote.weight
                existing.notes = remote.notes
                existing.remoteID = remote.id
                existing.isDeleted = remote.deletedAt != nil
                existing.deletedAt = parsedOptionalDate(remote.deletedAt)
                existing.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt ?? remote.createdAt)
                existing.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? max(existing.serverVersion, 1), at: Date())
            } else {
                let entry = BodyWeightEntry(
                    id: UUID(uuidString: remote.id) ?? UUID(),
                    date: parsedDate(remote.date),
                    weight: remote.weight,
                    notes: remote.notes
                )
                entry.remoteID = remote.id
                entry.isDeleted = remote.deletedAt != nil
                entry.deletedAt = parsedOptionalDate(remote.deletedAt)
                entry.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt ?? remote.createdAt)
                entry.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? 1, at: Date())
                modelContext.insert(entry)
            }
        }
    }
    
    private func merge(logs: [APIWorkoutLog]) {
        for remote in logs {
            let exercise = fetchExercise(remoteID: remote.exerciseId)
            if let existing = fetchWorkoutLog(remoteID: remote.id) {
                if existing.isDirty && existing.lastModifiedAt > parsedDate(remote.updatedAt, fallback: remote.createdAt) {
                    print("Skipping stale workout-log pull for \(remote.id)")
                    continue
                }
                
                existing.date = parsedDate(remote.date)
                existing.actualWeight = remote.actualWeight
                existing.actualReps = remote.actualReps
                existing.isMachine = remote.isMachine ?? false
                existing.feeling = remote.feeling
                existing.notes = remote.notes
                existing.exercise = exercise
                existing.remoteID = remote.id
                existing.isDeleted = remote.deletedAt != nil
                existing.deletedAt = parsedOptionalDate(remote.deletedAt)
                existing.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt ?? remote.createdAt)
                existing.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? max(existing.serverVersion, 1), at: Date())
            } else {
                let log = WorkoutLog(
                    id: UUID(uuidString: remote.id) ?? UUID(),
                    date: parsedDate(remote.date),
                    actualWeight: remote.actualWeight,
                    actualReps: remote.actualReps,
                    isMachine: remote.isMachine ?? false,
                    feeling: remote.feeling,
                    notes: remote.notes,
                    exercise: exercise
                )
                log.remoteID = remote.id
                log.isDeleted = remote.deletedAt != nil
                log.deletedAt = parsedOptionalDate(remote.deletedAt)
                log.lastModifiedAt = parsedDate(remote.clientUpdatedAt, fallback: remote.updatedAt ?? remote.createdAt)
                log.markSynced(remoteID: remote.id, serverVersion: remote.serverVersion ?? 1, at: Date())
                modelContext.insert(log)
            }
        }
    }
    
    private func apply(_ response: APIExercise, to model: Exercise) {
        model.remoteID = response.id
        model.serverVersion = response.serverVersion ?? max(model.serverVersion, 1)
        model.isDeleted = response.deletedAt != nil
        model.deletedAt = parsedOptionalDate(response.deletedAt)
        model.lastModifiedAt = parsedDate(response.clientUpdatedAt, fallback: response.updatedAt)
        model.markSynced(remoteID: response.id, serverVersion: response.serverVersion ?? max(model.serverVersion, 1), at: Date())
    }
    
    private func apply(_ response: APIWorkoutLog, to model: WorkoutLog) {
        model.remoteID = response.id
        model.serverVersion = response.serverVersion ?? max(model.serverVersion, 1)
        model.isDeleted = response.deletedAt != nil
        model.deletedAt = parsedOptionalDate(response.deletedAt)
        model.lastModifiedAt = parsedDate(response.clientUpdatedAt, fallback: response.updatedAt ?? response.createdAt)
        model.markSynced(remoteID: response.id, serverVersion: response.serverVersion ?? max(model.serverVersion, 1), at: Date())
    }
    
    private func apply(_ response: APIBodyWeight, to model: BodyWeightEntry) {
        model.remoteID = response.id
        model.serverVersion = response.serverVersion ?? max(model.serverVersion, 1)
        model.isDeleted = response.deletedAt != nil
        model.deletedAt = parsedOptionalDate(response.deletedAt)
        model.lastModifiedAt = parsedDate(response.clientUpdatedAt, fallback: response.updatedAt ?? response.createdAt)
        model.markSynced(remoteID: response.id, serverVersion: response.serverVersion ?? max(model.serverVersion, 1), at: Date())
    }
    
    private func apply(_ response: APIContentNote, to model: ContentNote) {
        model.remoteID = response.id
        model.serverVersion = response.serverVersion ?? max(model.serverVersion, 1)
        model.isDeleted = response.deletedAt != nil
        model.deletedAt = parsedOptionalDate(response.deletedAt)
        model.createdAt = parsedDate(response.createdAt)
        model.updatedAt = parsedDate(response.updatedAt)
        model.lastModifiedAt = parsedDate(response.clientUpdatedAt, fallback: response.updatedAt)
        model.markSynced(remoteID: response.id, serverVersion: response.serverVersion ?? max(model.serverVersion, 1), at: Date())
    }
    
    private func handlePushFailure(_ model: any SyncableModel, error: Error) {
        model.markSyncAttemptFailed(error.localizedDescription)
        if model.retryCount >= maxRetryAttempts {
            persistentBannerMessage = "Sync failed - will retry"
        }
        syncError = error.localizedDescription
        saveContext()
        refreshPendingCount()
    }
    
    private func canAttemptSync(_ model: any SyncableModel) -> Bool {
        guard model.retryCount < maxRetryAttempts else { return false }
        guard let lastAttempt = model.lastSyncAttempt else { return true }
        let delay = baseRetryDelay * pow(2, Double(max(model.retryCount - 1, 0)))
        return Date().timeIntervalSince(lastAttempt) >= delay
    }
    
    func refreshPendingCount() {
        let exerciseCount = (try? modelContext.fetchCount(FetchDescriptor<Exercise>(predicate: #Predicate { $0.isDirty == true }))) ?? 0
        let logCount = (try? modelContext.fetchCount(FetchDescriptor<WorkoutLog>(predicate: #Predicate { $0.isDirty == true }))) ?? 0
        let bodyWeightCount = (try? modelContext.fetchCount(FetchDescriptor<BodyWeightEntry>(predicate: #Predicate { $0.isDirty == true }))) ?? 0
        let noteCount = (try? modelContext.fetchCount(FetchDescriptor<ContentNote>(predicate: #Predicate { $0.isDirty == true }))) ?? 0
        pendingChangesCount = exerciseCount + logCount + bodyWeightCount + noteCount
    }
    
    private func saveContext() {
        try? modelContext.save()
    }
    
    private func parsedDate(_ value: String) -> Date {
        APIClient.dateFormatter.date(from: value) ?? Date()
    }
    
    private func parsedDate(_ value: String?, fallback: String) -> Date {
        if let value, let parsed = APIClient.dateFormatter.date(from: value) {
            return parsed
        }
        return parsedDate(fallback)
    }
    
    private func parsedOptionalDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        return APIClient.dateFormatter.date(from: value)
    }
    
    private func fetchExercise(remoteID: String) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.remoteID == remoteID })
        return try? modelContext.fetch(descriptor).first
    }
    
    private func fetchWorkoutLog(remoteID: String) -> WorkoutLog? {
        let descriptor = FetchDescriptor<WorkoutLog>(predicate: #Predicate { $0.remoteID == remoteID })
        return try? modelContext.fetch(descriptor).first
    }
    
    private func fetchBodyWeightEntry(remoteID: String) -> BodyWeightEntry? {
        let descriptor = FetchDescriptor<BodyWeightEntry>(predicate: #Predicate { $0.remoteID == remoteID })
        return try? modelContext.fetch(descriptor).first
    }
    
    private func fetchContentNote(remoteID: String) -> ContentNote? {
        let descriptor = FetchDescriptor<ContentNote>(predicate: #Predicate { $0.remoteID == remoteID })
        return try? modelContext.fetch(descriptor).first
    }
}
