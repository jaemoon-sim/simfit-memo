import Combine
import Foundation

@MainActor
final class ActiveWorkoutStore: ObservableObject {
    @Published private(set) var state: ActiveWorkoutState?
    @Published private(set) var lastFinishedRecord: WorkoutSessionRecord?

    private let restTimer = RestTimerCalculator()

    @discardableResult
    func start(from routine: Routine, startedAt: Date = Date()) -> ActiveWorkoutState {
        let state = ActiveWorkoutState.starting(from: routine, startedAt: startedAt)
        self.state = state
        lastFinishedRecord = nil
        return state
    }

    @discardableResult
    func startEmpty(startedAt: Date = Date()) -> ActiveWorkoutState {
        let state = ActiveWorkoutState.empty(startedAt: startedAt)
        self.state = state
        lastFinishedRecord = nil
        return state
    }

    @discardableResult
    func addExercise(_ exercise: Exercise, now: Date = Date()) -> ActiveWorkoutExercise? {
        addExercise(
            exerciseID: exercise.id,
            exerciseName: exercise.displayName,
            bodyPart: exercise.bodyPart,
            now: now
        )
    }

    @discardableResult
    func addExercise(
        exerciseID: UUID? = nil,
        exerciseName: String,
        bodyPart: BodyPart,
        now: Date = Date()
    ) -> ActiveWorkoutExercise? {
        guard var workout = state else {
            return nil
        }

        let exercise = workout.appendExercise(
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            bodyPart: bodyPart,
            now: now
        )
        state = workout
        return exercise
    }

    @discardableResult
    func addSet(
        toExerciseID exerciseID: UUID,
        targetWeightKg: Double? = nil,
        targetRepetitions: Int? = nil,
        actualWeightKg: Double? = nil,
        actualRepetitions: Int? = nil,
        restSeconds: Int = 90,
        now: Date = Date()
    ) -> ActiveWorkoutSet? {
        guard var workout = state else {
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
            state = workout
        }

        return set
    }

    @discardableResult
    func updateSetActuals(
        exerciseID: UUID? = nil,
        setID: UUID,
        actualWeightKg: Double?,
        actualRepetitions: Int?,
        now: Date = Date()
    ) -> Bool {
        guard var workout = state else {
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
            state = workout
        }

        return didUpdate
    }

    @discardableResult
    func completeSet(
        exerciseID: UUID? = nil,
        setID: UUID,
        completedAt: Date = Date()
    ) -> ActiveWorkoutSetCompletionResult {
        guard var workout = state else {
            return .setNotFound
        }

        let result = workout.completeSet(
            exerciseID: exerciseID,
            setID: setID,
            completedAt: completedAt,
            restTimer: restTimer
        )
        if result == .completed {
            state = workout
        }

        return result
    }

    @discardableResult
    func finish(endedAt: Date = Date()) -> WorkoutSessionRecord? {
        guard let state else {
            return nil
        }

        let record = state.finishedRecord(endedAt: endedAt)
        lastFinishedRecord = record
        self.state = nil
        return record
    }

    func remainingRestSeconds(now: Date = Date()) -> Int {
        restTimer.remainingSeconds(restEndAt: state?.restEndAt, now: now)
    }
}
