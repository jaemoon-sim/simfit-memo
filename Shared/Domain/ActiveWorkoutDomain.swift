import Foundation

public enum ActiveWorkoutSetCompletionResult: Equatable, Sendable {
    case completed
    case alreadyCompleted
    case setNotFound
}

public extension ActiveWorkoutState {
    static func starting(
        from routine: Routine,
        id: UUID = UUID(),
        startedAt: Date = Date()
    ) -> ActiveWorkoutState {
        let exercises = routine.exercises.stablySortedByOrderIndex().map { routineExercise in
            let setTargets = routineExercise.setTargets.isEmpty
                ? [RoutineSetTarget(orderIndex: 0, restSeconds: ExerciseSeedService.defaultRestSeconds)]
                : routineExercise.setTargets.stablySortedByOrderIndex()

            return ActiveWorkoutExercise(
                exerciseID: routineExercise.exerciseID,
                exerciseName: routineExercise.exerciseName,
                bodyPart: routineExercise.bodyPart,
                orderIndex: routineExercise.orderIndex,
                sets: setTargets.map { target in
                    ActiveWorkoutSet(
                        orderIndex: target.orderIndex,
                        targetWeightKg: target.targetWeightKg,
                        targetRepetitions: target.targetRepetitions,
                        restSeconds: target.restSeconds
                    )
                }
            )
        }

        return ActiveWorkoutState(
            id: id,
            routineID: routine.id,
            routineName: routine.name,
            startedAt: startedAt,
            updatedAt: startedAt,
            syncVersion: 1,
            exercises: exercises,
            currentExerciseID: exercises.first?.id,
            currentSetID: exercises.first?.sets.first?.id,
            restStartedAt: nil,
            restEndAt: nil
        )
    }

    static func empty(
        id: UUID = UUID(),
        startedAt: Date = Date()
    ) -> ActiveWorkoutState {
        ActiveWorkoutState(
            id: id,
            startedAt: startedAt,
            updatedAt: startedAt,
            syncVersion: 1
        )
    }

    @discardableResult
    mutating func appendExercise(
        exerciseID: UUID? = nil,
        exerciseName: String,
        bodyPart: BodyPart,
        id: UUID = UUID(),
        now: Date = Date()
    ) -> ActiveWorkoutExercise {
        let nextOrderIndex = (exercises.map(\.orderIndex).max() ?? -1) + 1
        let exercise = ActiveWorkoutExercise(
            id: id,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            bodyPart: bodyPart,
            orderIndex: nextOrderIndex
        )

        exercises.append(exercise)
        if currentExerciseID == nil {
            currentExerciseID = exercise.id
        }
        markUpdated(at: now)

        return exercise
    }

    @discardableResult
    mutating func appendSet(
        toExerciseID exerciseID: UUID,
        id: UUID = UUID(),
        targetWeightKg: Double? = nil,
        targetRepetitions: Int? = nil,
        actualWeightKg: Double? = nil,
        actualRepetitions: Int? = nil,
        restSeconds: Int = 90,
        now: Date = Date()
    ) -> ActiveWorkoutSet? {
        guard let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseID }) else {
            return nil
        }

        let nextOrderIndex = (exercises[exerciseIndex].sets.map(\.orderIndex).max() ?? -1) + 1
        let set = ActiveWorkoutSet(
            id: id,
            orderIndex: nextOrderIndex,
            targetWeightKg: targetWeightKg,
            targetRepetitions: targetRepetitions,
            actualWeightKg: actualWeightKg,
            actualRepetitions: actualRepetitions,
            restSeconds: restSeconds
        )

        exercises[exerciseIndex].sets.append(set)
        if currentExerciseID == nil {
            currentExerciseID = exercises[exerciseIndex].id
        }
        if currentSetID == nil {
            currentExerciseID = exercises[exerciseIndex].id
            currentSetID = set.id
        }
        markUpdated(at: now)

        return set
    }

    @discardableResult
    mutating func updateSetActuals(
        exerciseID: UUID? = nil,
        setID: UUID,
        actualWeightKg: Double?,
        actualRepetitions: Int?,
        now: Date = Date()
    ) -> Bool {
        guard let indexPath = indexPathForSet(exerciseID: exerciseID, setID: setID) else {
            return false
        }

        var set = exercises[indexPath.exerciseIndex].sets[indexPath.setIndex]
        guard set.actualWeightKg != actualWeightKg || set.actualRepetitions != actualRepetitions else {
            return true
        }

        set.actualWeightKg = actualWeightKg
        set.actualRepetitions = actualRepetitions
        exercises[indexPath.exerciseIndex].sets[indexPath.setIndex] = set
        markUpdated(at: now)

        return true
    }

    @discardableResult
    mutating func completeSet(
        exerciseID: UUID? = nil,
        setID: UUID,
        completedAt: Date = Date(),
        restTimer: RestTimerCalculator = RestTimerCalculator()
    ) -> ActiveWorkoutSetCompletionResult {
        guard let indexPath = indexPathForSet(exerciseID: exerciseID, setID: setID) else {
            return .setNotFound
        }

        if exercises[indexPath.exerciseIndex].sets[indexPath.setIndex].completedAt != nil {
            return .alreadyCompleted
        }

        let restSeconds = exercises[indexPath.exerciseIndex].sets[indexPath.setIndex].restSeconds
        exercises[indexPath.exerciseIndex].sets[indexPath.setIndex].completedAt = completedAt
        restStartedAt = completedAt
        restEndAt = restTimer.restEndDate(startedAt: completedAt, restSeconds: restSeconds)
        advanceCursorIfNeeded(afterCompleting: indexPath)
        markUpdated(at: completedAt)

        return .completed
    }

    func finishedRecord(endedAt: Date = Date()) -> WorkoutSessionRecord {
        WorkoutSessionRecord(
            id: id,
            routineID: routineID,
            routineName: routineName,
            startedAt: startedAt,
            endedAt: endedAt,
            exercises: exercises.map { exercise in
                WorkoutExerciseRecord(
                    id: exercise.id,
                    exerciseID: exercise.exerciseID,
                    exerciseName: exercise.exerciseName,
                    bodyPart: exercise.bodyPart,
                    orderIndex: exercise.orderIndex,
                    sets: exercise.sets.map { set in
                        WorkoutSetRecord(
                            id: set.id,
                            orderIndex: set.orderIndex,
                            targetWeightKg: set.targetWeightKg,
                            targetRepetitions: set.targetRepetitions,
                            actualWeightKg: set.actualWeightKg,
                            actualRepetitions: set.actualRepetitions,
                            restSeconds: set.restSeconds,
                            completedAt: set.completedAt
                        )
                    }
                )
            }
        )
    }
}

private extension ActiveWorkoutState {
    mutating func markUpdated(at date: Date) {
        updatedAt = date
        syncVersion += 1
    }

    func indexPathForSet(exerciseID: UUID?, setID: UUID) -> (exerciseIndex: Int, setIndex: Int)? {
        for exerciseIndex in exercises.indices where exercises[exerciseIndex].matches(exerciseID: exerciseID) {
            if let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) {
                return (exerciseIndex, setIndex)
            }
        }

        return nil
    }

    mutating func advanceCursorIfNeeded(afterCompleting indexPath: (exerciseIndex: Int, setIndex: Int)) {
        let completedExercise = exercises[indexPath.exerciseIndex]
        let completedSet = completedExercise.sets[indexPath.setIndex]
        let shouldAdvance = currentSetID == nil
            || currentSetID == completedSet.id
            || currentExerciseID == nil

        guard shouldAdvance else {
            return
        }

        if let nextSet = nextIncompleteSet(after: indexPath) {
            currentExerciseID = nextSet.exerciseID
            currentSetID = nextSet.setID
        } else {
            currentExerciseID = nil
            currentSetID = nil
        }
    }

    func nextIncompleteSet(after indexPath: (exerciseIndex: Int, setIndex: Int)) -> (exerciseID: UUID, setID: UUID)? {
        let currentExercise = exercises[indexPath.exerciseIndex]
        let remainingSets = currentExercise.sets.dropFirst(indexPath.setIndex + 1)
        if let nextSet = remainingSets.first(where: { $0.completedAt == nil }) {
            return (currentExercise.id, nextSet.id)
        }

        let remainingExercises = exercises.dropFirst(indexPath.exerciseIndex + 1)
        for exercise in remainingExercises {
            if let nextSet = exercise.sets.first(where: { $0.completedAt == nil }) {
                return (exercise.id, nextSet.id)
            }
        }

        return nil
    }
}

private extension ActiveWorkoutExercise {
    func matches(exerciseID: UUID?) -> Bool {
        guard let exerciseID else {
            return true
        }

        return id == exerciseID || self.exerciseID == exerciseID
    }
}

private protocol OrderedWorkoutElement {
    var orderIndex: Int { get }
}

extension RoutineExercise: OrderedWorkoutElement {}
extension RoutineSetTarget: OrderedWorkoutElement {}

private extension Array where Element: OrderedWorkoutElement {
    func stablySortedByOrderIndex() -> [Element] {
        enumerated()
            .sorted { lhs, rhs in
                if lhs.element.orderIndex == rhs.element.orderIndex {
                    return lhs.offset < rhs.offset
                }

                return lhs.element.orderIndex < rhs.element.orderIndex
            }
            .map(\.element)
    }
}
