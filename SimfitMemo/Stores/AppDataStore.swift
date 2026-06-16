import Combine
import Foundation
import SwiftData

@Model
final class PersistedAppSnapshot {
    @Attribute(.unique) var key: String
    @Attribute(.externalStorage) var exercisesData: Data
    @Attribute(.externalStorage) var routinesData: Data
    @Attribute(.externalStorage) var historyData: Data
    @Attribute(.externalStorage) var activeWorkoutData: Data?
    var updatedAt: Date

    init(
        key: String = PersistedAppSnapshot.defaultKey,
        exercisesData: Data = Data(),
        routinesData: Data = Data(),
        historyData: Data = Data(),
        activeWorkoutData: Data? = nil,
        updatedAt: Date = Date()
    ) {
        self.key = key
        self.exercisesData = exercisesData
        self.routinesData = routinesData
        self.historyData = historyData
        self.activeWorkoutData = activeWorkoutData
        self.updatedAt = updatedAt
    }

    static let defaultKey = "default"
}

@MainActor
final class AppDataStore: ObservableObject {
    @Published private(set) var exercises: [Exercise] = MockFitnessData.exercises
    @Published private(set) var routines: [Routine] = MockFitnessData.routines
    @Published private(set) var history: [WorkoutSessionRecord] = []
    @Published private(set) var activeWorkout: ActiveWorkoutState?
    @Published private(set) var lastFinishedRecord: WorkoutSessionRecord?
    @Published var lastErrorMessage: String?

    private var modelContext: ModelContext?
    private var snapshot: PersistedAppSnapshot?
    private var isConfigured = false
    private let seedService: ExerciseSeedService
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let restTimer = RestTimerCalculator()

    init(seedService: ExerciseSeedService = ExerciseSeedService()) {
        self.seedService = seedService
        encoder.outputFormatting = [.sortedKeys]
    }

    func configure(modelContext: ModelContext) {
        guard !isConfigured else {
            return
        }

        self.modelContext = modelContext
        isConfigured = true
        loadOrCreateSnapshot()
    }

    @discardableResult
    func addCustomExercise(name: String, bodyPart: BodyPart, now: Date = Date()) -> Exercise {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let exercise = Exercise(
            name: trimmedName,
            localizedName: trimmedName,
            bodyPart: bodyPart,
            primaryMuscles: [bodyPart.displayName],
            equipment: "사용자 지정",
            category: "custom",
            isCustom: true,
            createdAt: now,
            updatedAt: now
        )

        exercises.insert(exercise, at: 0)
        persist()
        return exercise
    }

    func toggleBookmark(exerciseID: UUID, now: Date = Date()) {
        guard let index = exercises.firstIndex(where: { $0.id == exerciseID }) else {
            return
        }

        exercises[index].isBookmarked.toggle()
        exercises[index].updatedAt = now
        persist()
    }

    @discardableResult
    func createRoutine(name: String, exercises selectedExercises: [Exercise], now: Date = Date()) -> Routine? {
        guard let routine = makeRoutineDraft(name: name, exercises: selectedExercises, now: now) else {
            return nil
        }

        routines.insert(routine, at: 0)
        persist()
        return routine
    }

    func makeRoutineDraft(name: String, exercises selectedExercises: [Exercise], now: Date = Date()) -> Routine? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !selectedExercises.isEmpty else {
            return nil
        }

        let routineExercises = selectedExercises.enumerated().map { index, exercise in
            RoutineExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.displayName,
                bodyPart: exercise.bodyPart,
                orderIndex: index,
                setTargets: Self.defaultRoutineTargets()
            )
        }

        return Routine(
            name: trimmedName,
            exercises: routineExercises,
            createdAt: now,
            updatedAt: now
        )
    }

    @discardableResult
    func saveNewRoutine(_ routine: Routine, now: Date = Date()) -> Routine? {
        let trimmedName = routine.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !routine.exercises.isEmpty else {
            return nil
        }

        var savedRoutine = routine
        savedRoutine.name = trimmedName
        savedRoutine.updatedAt = now

        if let index = routines.firstIndex(where: { $0.id == savedRoutine.id }) {
            routines[index] = savedRoutine
        } else {
            routines.insert(savedRoutine, at: 0)
        }

        persist()
        return savedRoutine
    }

    @discardableResult
    func updateRoutine(_ routine: Routine, now: Date = Date()) -> Routine? {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else {
            return nil
        }

        var updatedRoutine = routine
        updatedRoutine.updatedAt = now
        routines[index] = updatedRoutine
        persist()
        return updatedRoutine
    }

    func deleteRoutine(id: UUID) {
        routines.removeAll { $0.id == id }
        persist()
    }

    @discardableResult
    func duplicateRoutine(id: UUID, now: Date = Date()) -> Routine? {
        guard let routine = routines.first(where: { $0.id == id }) else {
            return nil
        }

        let duplicatedExercises = routine.exercises.enumerated().map { index, exercise in
            RoutineExercise(
                exerciseID: exercise.exerciseID,
                exerciseName: exercise.exerciseName,
                bodyPart: exercise.bodyPart,
                orderIndex: index,
                setTargets: exercise.setTargets.enumerated().map { setIndex, target in
                    RoutineSetTarget(
                        orderIndex: setIndex,
                        targetWeightKg: target.targetWeightKg,
                        targetRepetitions: target.targetRepetitions,
                        restSeconds: target.restSeconds
                    )
                }
            )
        }

        let duplicatedRoutine = Routine(
            name: "\(routine.name) 복사본",
            exercises: duplicatedExercises,
            createdAt: now,
            updatedAt: now
        )
        routines.insert(duplicatedRoutine, at: 0)
        persist()
        return duplicatedRoutine
    }

    @discardableResult
    func startWorkout(from routine: Routine, startedAt: Date = Date()) -> ActiveWorkoutState {
        let state = ActiveWorkoutState.starting(from: routine, startedAt: startedAt)
        activeWorkout = state
        lastFinishedRecord = nil
        persist()
        return state
    }

    @discardableResult
    func startWorkout(with selectedExercises: [Exercise], startedAt: Date = Date()) -> ActiveWorkoutState {
        var state = ActiveWorkoutState.empty(startedAt: startedAt)
        for exercise in selectedExercises {
            let workoutExercise = state.appendExercise(
                exerciseID: exercise.id,
                exerciseName: exercise.displayName,
                bodyPart: exercise.bodyPart,
                now: startedAt
            )
            _ = state.appendSet(
                toExerciseID: workoutExercise.id,
                restSeconds: ExerciseSeedService.defaultRestSeconds,
                now: startedAt
            )
        }

        activeWorkout = state
        lastFinishedRecord = nil
        persist()
        return state
    }

    @discardableResult
    func startEmptyWorkout(startedAt: Date = Date()) -> ActiveWorkoutState {
        let state = ActiveWorkoutState.empty(startedAt: startedAt)
        activeWorkout = state
        lastFinishedRecord = nil
        persist()
        return state
    }

    @discardableResult
    func addExerciseToActiveWorkout(_ exercise: Exercise, now: Date = Date()) -> ActiveWorkoutExercise? {
        if activeWorkout == nil {
            startEmptyWorkout(startedAt: now)
        }

        guard var workout = activeWorkout else {
            return nil
        }

        let addedExercise = workout.appendExercise(
            exerciseID: exercise.id,
            exerciseName: exercise.displayName,
            bodyPart: exercise.bodyPart,
            now: now
        )
        if addedExercise.sets.isEmpty {
            _ = workout.appendSet(
                toExerciseID: addedExercise.id,
                restSeconds: ExerciseSeedService.defaultRestSeconds,
                now: now
            )
        }
        activeWorkout = workout
        persist()
        return addedExercise
    }

    @discardableResult
    func addSetToActiveWorkout(
        exerciseID: UUID,
        targetWeightKg: Double? = nil,
        targetRepetitions: Int? = nil,
        actualWeightKg: Double? = nil,
        actualRepetitions: Int? = nil,
        restSeconds: Int = ExerciseSeedService.defaultRestSeconds,
        now: Date = Date()
    ) -> ActiveWorkoutSet? {
        guard var workout = activeWorkout else {
            return nil
        }

        let set = workout.appendSet(
            toExerciseID: exerciseID,
            targetWeightKg: targetWeightKg,
            targetRepetitions: targetRepetitions,
            actualWeightKg: actualWeightKg,
            actualRepetitions: actualRepetitions,
            restSeconds: restSeconds,
            now: now
        )
        if set != nil {
            activeWorkout = workout
            persist()
        }

        return set
    }

    @discardableResult
    func updateActiveSetActuals(
        exerciseID: UUID? = nil,
        setID: UUID,
        actualWeightKg: Double?,
        actualRepetitions: Int?,
        now: Date = Date()
    ) -> Bool {
        guard var workout = activeWorkout else {
            return false
        }

        let original = workout
        let didUpdate = workout.updateSetActuals(
            exerciseID: exerciseID,
            setID: setID,
            actualWeightKg: actualWeightKg,
            actualRepetitions: actualRepetitions,
            now: now
        )
        if didUpdate, workout != original {
            activeWorkout = workout
            persist()
        }

        return didUpdate
    }

    @discardableResult
    func completeActiveSet(
        exerciseID: UUID? = nil,
        setID: UUID,
        completedAt: Date = Date()
    ) -> ActiveWorkoutSetCompletionResult {
        guard var workout = activeWorkout else {
            return .setNotFound
        }

        let result = workout.completeSet(
            exerciseID: exerciseID,
            setID: setID,
            completedAt: completedAt,
            restTimer: restTimer
        )
        if result == .completed {
            activeWorkout = workout
            persist()
        }

        return result
    }

    @discardableResult
    func moveActiveWorkoutExercise(
        exerciseID: UUID,
        direction: ActiveWorkoutExerciseMoveDirection,
        now: Date = Date()
    ) -> Bool {
        guard var workout = activeWorkout else {
            return false
        }

        let didMove = workout.moveExercise(
            exerciseID: exerciseID,
            direction: direction,
            now: now
        )
        if didMove {
            activeWorkout = workout
            persist()
        }

        return didMove
    }

    @discardableResult
    func applyWatchSetCompletion(_ event: SetCompletionEventDTO) -> ActiveWorkoutSetCompletionResult {
        guard activeWorkout?.id == event.sessionID else {
            return .setNotFound
        }

        return completeActiveSet(
            exerciseID: event.exerciseID,
            setID: event.setID,
            completedAt: event.completedAt
        )
    }

    @discardableResult
    func adjustActiveRestTimer(by deltaSeconds: Int, now: Date = Date()) -> Bool {
        guard var workout = activeWorkout else {
            return false
        }

        let didAdjust = workout.adjustRestTimer(
            by: deltaSeconds,
            now: now,
            restTimer: restTimer
        )
        if didAdjust {
            activeWorkout = workout
            persist()
        }

        return didAdjust
    }

    @discardableResult
    func applyWatchRestAdjustment(_ event: RestAdjustmentEventDTO) -> Bool {
        guard activeWorkout?.id == event.sessionID else {
            return false
        }

        return adjustActiveRestTimer(by: event.deltaSeconds)
    }

    @discardableResult
    func finishActiveWorkout(endedAt: Date = Date()) -> WorkoutSessionRecord? {
        guard let activeWorkout else {
            return nil
        }

        let record = activeWorkout.finishedRecord(endedAt: endedAt)
        history.insert(record, at: 0)
        lastFinishedRecord = record
        self.activeWorkout = nil
        markRoutinePerformed(for: record, at: endedAt)
        persist()
        return record
    }

    func remainingRestSeconds(now: Date = Date()) -> Int {
        restTimer.remainingSeconds(restEndAt: activeWorkout?.restEndAt, now: now)
    }

    func records(on date: Date, calendar: Calendar = .current) -> [WorkoutSessionRecord] {
        history.filter { record in
            calendar.isDate(record.startedAt, inSameDayAs: date)
        }
    }
}

private extension AppDataStore {
    func loadOrCreateSnapshot() {
        guard let modelContext else {
            return
        }

        do {
            var descriptor = FetchDescriptor<PersistedAppSnapshot>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            if let existingSnapshot = try modelContext.fetch(descriptor).first {
                snapshot = existingSnapshot
                apply(existingSnapshot)
            } else {
                seedInitialData()
                let newSnapshot = PersistedAppSnapshot()
                snapshot = newSnapshot
                modelContext.insert(newSnapshot)
                persist()
            }
        } catch {
            lastErrorMessage = "저장소를 불러오지 못했어요."
            seedInitialData()
        }
    }

    func apply(_ snapshot: PersistedAppSnapshot) {
        exercises = decoded([Exercise].self, from: snapshot.exercisesData, fallback: [])
        routines = decoded([Routine].self, from: snapshot.routinesData, fallback: [])
        history = decoded([WorkoutSessionRecord].self, from: snapshot.historyData, fallback: [])

        if let activeWorkoutData = snapshot.activeWorkoutData {
            activeWorkout = try? decoder.decode(ActiveWorkoutState.self, from: activeWorkoutData)
        } else {
            activeWorkout = nil
        }

        if exercises.isEmpty {
            seedInitialData()
            persist()
        }
    }

    func seedInitialData(now: Date = Date()) {
        var seededExercises = seedService.loadEmbeddedSeeds(now: now)
        for exercise in MockFitnessData.exercises where !seededExercises.contains(where: { $0.sourceID == exercise.sourceID }) {
            seededExercises.append(exercise)
        }

        exercises = seededExercises
        routines = MockFitnessData.routines
        history = []
        activeWorkout = nil
        lastFinishedRecord = nil
    }

    func persist() {
        guard let snapshot else {
            return
        }

        do {
            snapshot.exercisesData = try encoder.encode(exercises)
            snapshot.routinesData = try encoder.encode(routines)
            snapshot.historyData = try encoder.encode(history)
            snapshot.activeWorkoutData = try activeWorkout.map { try encoder.encode($0) }
            snapshot.updatedAt = Date()
            try modelContext?.save()
        } catch {
            lastErrorMessage = "변경사항을 저장하지 못했어요."
        }
    }

    func decoded<T: Decodable>(_ type: T.Type, from data: Data, fallback: T) -> T {
        guard !data.isEmpty else {
            return fallback
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            lastErrorMessage = "저장된 데이터를 읽지 못했어요."
            return fallback
        }
    }

    func markRoutinePerformed(for record: WorkoutSessionRecord, at date: Date) {
        guard let routineID = record.routineID,
              let index = routines.firstIndex(where: { $0.id == routineID }) else {
            return
        }

        routines[index].lastPerformedAt = date
        routines[index].completedCount += 1
        routines[index].updatedAt = date
    }

    static func defaultRoutineTargets() -> [RoutineSetTarget] {
        (0..<3).map { index in
            RoutineSetTarget(orderIndex: index, restSeconds: ExerciseSeedService.defaultRestSeconds)
        }
    }
}
