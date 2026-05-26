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
