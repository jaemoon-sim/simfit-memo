import XCTest

final class ActiveWorkoutDomainTests: XCTestCase {
    func testStartingFromRoutinePreservesOrderedExerciseAndSetTargets() throws {
        let routine = Self.makeRoutine()
        let startedAt = Date(timeIntervalSince1970: 1_000)

        let state = ActiveWorkoutState.starting(from: routine, startedAt: startedAt)

        XCTAssertEqual(state.routineID, routine.id)
        XCTAssertEqual(state.routineName, "상체 루틴")
        XCTAssertEqual(state.startedAt, startedAt)
        XCTAssertEqual(state.updatedAt, startedAt)
        XCTAssertEqual(state.syncVersion, 1)
        XCTAssertEqual(state.exercises.map(\.exerciseName), ["벤치프레스", "시티드 로우"])
        XCTAssertEqual(state.exercises.map(\.orderIndex), [0, 1])
        XCTAssertEqual(state.exercises.first?.sets.map(\.orderIndex), [0, 1])
        XCTAssertEqual(state.exercises.first?.sets.map(\.targetWeightKg), [60, 57.5])
        XCTAssertEqual(state.exercises.first?.sets.map(\.targetRepetitions), [8, 10])
        XCTAssertEqual(state.exercises.first?.sets.map(\.restSeconds), [90, 120])
        XCTAssertEqual(state.currentExerciseID, state.exercises.first?.id)
        XCTAssertEqual(state.currentSetID, state.exercises.first?.sets.first?.id)
    }

    func testCompletingSetIsIdempotentAndStartsRestOnce() throws {
        var state = ActiveWorkoutState.starting(
            from: Self.makeRoutine(),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let firstExercise = try XCTUnwrap(state.exercises.first)
        let firstSet = try XCTUnwrap(firstExercise.sets.first)
        let completedAt = Date(timeIntervalSince1970: 2_000)

        let result = state.completeSet(
            exerciseID: firstExercise.id,
            setID: firstSet.id,
            completedAt: completedAt
        )

        XCTAssertEqual(result, .completed)
        XCTAssertEqual(state.exercises[0].sets[0].completedAt, completedAt)
        XCTAssertEqual(state.restStartedAt, completedAt)
        XCTAssertEqual(state.restEndAt, completedAt.addingTimeInterval(90))
        XCTAssertEqual(state.currentSetID, state.exercises[0].sets[1].id)
        XCTAssertEqual(state.syncVersion, 2)

        let stateAfterFirstCompletion = state
        let duplicateResult = state.completeSet(
            exerciseID: firstExercise.id,
            setID: firstSet.id,
            completedAt: completedAt.addingTimeInterval(600)
        )

        XCTAssertEqual(duplicateResult, .alreadyCompleted)
        XCTAssertEqual(state, stateAfterFirstCompletion)
    }

    func testCompletingLastSetClearsCurrentCursor() throws {
        var state = ActiveWorkoutState.starting(
            from: Routine(
                name: "단일 세트",
                exercises: [
                    RoutineExercise(
                        exerciseID: UUID(),
                        exerciseName: "스쿼트",
                        bodyPart: .lowerBody,
                        orderIndex: 0,
                        setTargets: [RoutineSetTarget(orderIndex: 0)]
                    )
                ]
            ),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let exercise = try XCTUnwrap(state.exercises.first)
        let set = try XCTUnwrap(exercise.sets.first)

        state.completeSet(
            exerciseID: exercise.id,
            setID: set.id,
            completedAt: Date(timeIntervalSince1970: 2_000)
        )

        XCTAssertNil(state.currentExerciseID)
        XCTAssertNil(state.currentSetID)
    }

    func testAdjustingRestTimerUsesRemainingTimeAndClampsAtZero() throws {
        var state = ActiveWorkoutState.starting(
            from: Self.makeRoutine(),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let firstExercise = try XCTUnwrap(state.exercises.first)
        let firstSet = try XCTUnwrap(firstExercise.sets.first)
        let completedAt = Date(timeIntervalSince1970: 2_000)

        state.completeSet(
            exerciseID: firstExercise.id,
            setID: firstSet.id,
            completedAt: completedAt
        )

        let extendedAt = Date(timeIntervalSince1970: 2_030)
        XCTAssertTrue(state.adjustRestTimer(by: 10, now: extendedAt))
        XCTAssertEqual(state.restEndAt, extendedAt.addingTimeInterval(70))

        let reducedAt = Date(timeIntervalSince1970: 2_050)
        XCTAssertTrue(state.adjustRestTimer(by: -80, now: reducedAt))
        XCTAssertEqual(state.restEndAt, reducedAt)
    }

    func testAdjustingRestTimerDoesNothingWhenRestIsNotRunning() {
        var state = ActiveWorkoutState.empty(startedAt: Date(timeIntervalSince1970: 1_000))

        XCTAssertFalse(state.adjustRestTimer(by: 10, now: Date(timeIntervalSince1970: 1_100)))
        XCTAssertNil(state.restEndAt)
        XCTAssertEqual(state.syncVersion, 1)
    }

    func testStartingFromRoutineWithOnlyExerciseCreatesBlankSet() throws {
        let routine = Routine(
            name: "종목만 있는 루틴",
            exercises: [
                RoutineExercise(
                    exerciseID: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
                    exerciseName: "스쿼트",
                    bodyPart: .lowerBody,
                    orderIndex: 0,
                    setTargets: []
                )
            ]
        )

        let state = ActiveWorkoutState.starting(from: routine)

        XCTAssertEqual(state.exercises.count, 1)
        XCTAssertEqual(state.exercises[0].sets.count, 1)
        XCTAssertNil(state.exercises[0].sets[0].targetWeightKg)
        XCTAssertNil(state.exercises[0].sets[0].targetRepetitions)
        XCTAssertEqual(state.exercises[0].sets[0].restSeconds, ExerciseSeedService.defaultRestSeconds)
        XCTAssertEqual(state.currentSetID, state.exercises[0].sets[0].id)
    }

    func testMovingExerciseReordersExercisesAndNormalizesOrderIndices() throws {
        var state = ActiveWorkoutState.starting(
            from: Self.makeRoutine(),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let firstExerciseID = try XCTUnwrap(state.exercises.first?.id)
        let movedAt = Date(timeIntervalSince1970: 1_500)

        XCTAssertTrue(state.moveExercise(exerciseID: firstExerciseID, direction: .down, now: movedAt))

        XCTAssertEqual(state.exercises.map(\.exerciseName), ["시티드 로우", "벤치프레스"])
        XCTAssertEqual(state.exercises.map(\.orderIndex), [0, 1])
        XCTAssertEqual(state.updatedAt, movedAt)
        XCTAssertEqual(state.syncVersion, 2)

        let secondExerciseID = try XCTUnwrap(state.exercises.last?.id)
        XCTAssertTrue(state.moveExercise(exerciseID: secondExerciseID, direction: .up, now: movedAt.addingTimeInterval(1)))
        XCTAssertEqual(state.exercises.map(\.exerciseName), ["벤치프레스", "시티드 로우"])
        XCTAssertEqual(state.exercises.map(\.orderIndex), [0, 1])
    }

    func testMovingExerciseFailsAtBoundsWithoutMutatingState() throws {
        var state = ActiveWorkoutState.starting(
            from: Self.makeRoutine(),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let original = state
        let firstExerciseID = try XCTUnwrap(state.exercises.first?.id)

        XCTAssertFalse(state.moveExercise(exerciseID: firstExerciseID, direction: .up))
        XCTAssertEqual(state, original)
    }

    func testFinishedRecordMapsActiveWorkoutSnapshot() throws {
        var state = ActiveWorkoutState.starting(
            from: Self.makeRoutine(),
            startedAt: Date(timeIntervalSince1970: 1_000)
        )
        let firstExercise = try XCTUnwrap(state.exercises.first)
        let firstSet = try XCTUnwrap(firstExercise.sets.first)
        let completedAt = Date(timeIntervalSince1970: 2_000)

        state.updateSetActuals(
            exerciseID: firstExercise.id,
            setID: firstSet.id,
            actualWeightKg: 62.5,
            actualRepetitions: 9,
            now: Date(timeIntervalSince1970: 1_500)
        )
        state.completeSet(
            exerciseID: firstExercise.id,
            setID: firstSet.id,
            completedAt: completedAt
        )

        let endedAt = Date(timeIntervalSince1970: 3_000)
        let record = state.finishedRecord(endedAt: endedAt)

        XCTAssertEqual(record.id, state.id)
        XCTAssertEqual(record.routineID, state.routineID)
        XCTAssertEqual(record.routineName, state.routineName)
        XCTAssertEqual(record.startedAt, state.startedAt)
        XCTAssertEqual(record.endedAt, endedAt)
        XCTAssertEqual(record.exercises.count, 2)
        XCTAssertEqual(record.exercises[0].id, firstExercise.id)
        XCTAssertEqual(record.exercises[0].sets[0].id, firstSet.id)
        XCTAssertEqual(record.exercises[0].sets[0].targetWeightKg, 60)
        XCTAssertEqual(record.exercises[0].sets[0].actualWeightKg, 62.5)
        XCTAssertEqual(record.exercises[0].sets[0].actualRepetitions, 9)
        XCTAssertEqual(record.exercises[0].sets[0].completedAt, completedAt)
        XCTAssertNil(record.exercises[0].sets[1].completedAt)
    }

    func testLatestSetPerformanceUsesMostRecentCompletedActualsForSetOrder() throws {
        let exerciseID = UUID(uuidString: "00000000-0000-0000-0000-000000000401")!
        let activeExercise = ActiveWorkoutExercise(
            exerciseID: exerciseID,
            exerciseName: "벤치프레스",
            bodyPart: .chest,
            orderIndex: 0
        )

        let oldRecord = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 1_100),
            exercises: [
                WorkoutExerciseRecord(
                    exerciseID: exerciseID,
                    exerciseName: "벤치프레스",
                    bodyPart: .chest,
                    orderIndex: 0,
                    sets: [
                        WorkoutSetRecord(
                            orderIndex: 1,
                            actualWeightKg: 50,
                            actualRepetitions: 5,
                            completedAt: Date(timeIntervalSince1970: 1_050)
                        )
                    ]
                )
            ]
        )
        let futureRecord = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 3_000),
            endedAt: Date(timeIntervalSince1970: 3_100),
            exercises: [
                WorkoutExerciseRecord(
                    exerciseID: exerciseID,
                    exerciseName: "벤치프레스",
                    bodyPart: .chest,
                    orderIndex: 0,
                    sets: [
                        WorkoutSetRecord(
                            orderIndex: 1,
                            actualWeightKg: 100,
                            actualRepetitions: 1,
                            completedAt: Date(timeIntervalSince1970: 3_050)
                        )
                    ]
                )
            ]
        )
        let recentRecord = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 2_000),
            endedAt: Date(timeIntervalSince1970: 2_100),
            exercises: [
                WorkoutExerciseRecord(
                    exerciseID: exerciseID,
                    exerciseName: "벤치프레스",
                    bodyPart: .chest,
                    orderIndex: 0,
                    sets: [
                        WorkoutSetRecord(
                            orderIndex: 0,
                            actualWeightKg: 62.5,
                            actualRepetitions: 8,
                            completedAt: Date(timeIntervalSince1970: 2_030)
                        ),
                        WorkoutSetRecord(
                            orderIndex: 1,
                            actualWeightKg: 60,
                            actualRepetitions: 9,
                            completedAt: Date(timeIntervalSince1970: 2_060)
                        )
                    ]
                )
            ]
        )

        let performance = [oldRecord, futureRecord, recentRecord].latestSetPerformance(
            matching: activeExercise,
            setOrderIndex: 1,
            before: Date(timeIntervalSince1970: 2_500)
        )

        XCTAssertEqual(performance?.weightKg, 60)
        XCTAssertEqual(performance?.repetitions, 9)
    }

    func testLatestSetPerformanceIgnoresIncompleteTargetOnlySetsAndFallsBackToCompletedTargets() throws {
        let activeExercise = ActiveWorkoutExercise(
            exerciseName: "풀업",
            bodyPart: .back,
            orderIndex: 0
        )
        let incompleteRecord = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 2_000),
            endedAt: Date(timeIntervalSince1970: 2_100),
            exercises: [
                WorkoutExerciseRecord(
                    exerciseName: "풀업",
                    bodyPart: .back,
                    orderIndex: 0,
                    sets: [
                        WorkoutSetRecord(
                            orderIndex: 0,
                            targetRepetitions: 12
                        )
                    ]
                )
            ]
        )
        let completedRecord = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 1_100),
            exercises: [
                WorkoutExerciseRecord(
                    exerciseName: "풀업",
                    bodyPart: .back,
                    orderIndex: 0,
                    sets: [
                        WorkoutSetRecord(
                            orderIndex: 0,
                            targetRepetitions: 10,
                            completedAt: Date(timeIntervalSince1970: 1_050)
                        )
                    ]
                )
            ]
        )

        let performance = [incompleteRecord, completedRecord].latestSetPerformance(
            matching: activeExercise,
            setOrderIndex: 0
        )

        XCTAssertNil(performance?.weightKg)
        XCTAssertEqual(performance?.repetitions, 10)
    }

    func testElapsedWorkoutSecondsUsesStartedAtAndClampsAtZero() {
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let state = ActiveWorkoutState.empty(startedAt: startedAt)

        XCTAssertEqual(state.elapsedWorkoutSeconds(now: startedAt.addingTimeInterval(125.9)), 125)
        XCTAssertEqual(state.elapsedWorkoutSeconds(now: startedAt.addingTimeInterval(-10)), 0)
    }

    func testWorkoutDurationSecondsUsesEndedAtWhenAvailable() {
        let record = WorkoutSessionRecord(
            startedAt: Date(timeIntervalSince1970: 1_000),
            endedAt: Date(timeIntervalSince1970: 4_725)
        )

        XCTAssertEqual(record.workoutDurationSeconds(until: Date(timeIntervalSince1970: 9_000)), 3_725)
    }

    private static func makeRoutine() -> Routine {
        Routine(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!,
            name: "상체 루틴",
            exercises: [
                RoutineExercise(
                    exerciseID: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
                    exerciseName: "시티드 로우",
                    bodyPart: .back,
                    orderIndex: 1,
                    setTargets: [
                        RoutineSetTarget(orderIndex: 0, targetWeightKg: 45, targetRepetitions: 10, restSeconds: 75)
                    ]
                ),
                RoutineExercise(
                    exerciseID: UUID(uuidString: "00000000-0000-0000-0000-000000000200")!,
                    exerciseName: "벤치프레스",
                    bodyPart: .chest,
                    orderIndex: 0,
                    setTargets: [
                        RoutineSetTarget(orderIndex: 1, targetWeightKg: 57.5, targetRepetitions: 10, restSeconds: 120),
                        RoutineSetTarget(orderIndex: 0, targetWeightKg: 60, targetRepetitions: 8, restSeconds: 90)
                    ]
                )
            ]
        )
    }
}
