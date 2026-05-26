import Foundation

enum WatchMockData {
    static var activeWorkoutState: ActiveWorkoutState {
        let sessionID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let exerciseID = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        let firstSetID = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!

        let exercise = ActiveWorkoutExercise(
            id: exerciseID,
            exerciseName: "바벨 벤치프레스",
            bodyPart: .chest,
            orderIndex: 0,
            sets: [
                ActiveWorkoutSet(
                    id: firstSetID,
                    orderIndex: 0,
                    targetWeightKg: 60,
                    targetRepetitions: 8,
                    restSeconds: 90
                ),
                ActiveWorkoutSet(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
                    orderIndex: 1,
                    targetWeightKg: 60,
                    targetRepetitions: 8,
                    restSeconds: 90
                ),
                ActiveWorkoutSet(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
                    orderIndex: 2,
                    targetWeightKg: 62.5,
                    targetRepetitions: 6,
                    restSeconds: 120
                )
            ]
        )

        return ActiveWorkoutState(
            id: sessionID,
            routineName: "가슴 루틴",
            startedAt: Date().addingTimeInterval(-900),
            updatedAt: Date(),
            exercises: [exercise],
            currentExerciseID: exerciseID,
            currentSetID: firstSetID,
            restStartedAt: Date(),
            restEndAt: Date().addingTimeInterval(90)
        )
    }

    static var routines: [Routine] {
        [
            Routine(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                name: "가슴 루틴",
                exercises: [
                    RoutineExercise(
                        exerciseID: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
                        exerciseName: "바벨 벤치프레스",
                        bodyPart: .chest,
                        orderIndex: 0,
                        setTargets: [
                            RoutineSetTarget(orderIndex: 0, targetWeightKg: 60, targetRepetitions: 8),
                            RoutineSetTarget(orderIndex: 1, targetWeightKg: 60, targetRepetitions: 8)
                        ]
                    )
                ],
                completedCount: 4
            ),
            Routine(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
                name: "하체 기본",
                exercises: [
                    RoutineExercise(
                        exerciseID: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
                        exerciseName: "스쿼트",
                        bodyPart: .lowerBody,
                        orderIndex: 0,
                        setTargets: [
                            RoutineSetTarget(orderIndex: 0, targetWeightKg: 80, targetRepetitions: 5)
                        ]
                    )
                ]
            )
        ]
    }

    static var history: [WorkoutSessionRecord] {
        [
            WorkoutSessionRecord(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
                routineName: "가슴 루틴",
                startedAt: Date().addingTimeInterval(-86_400),
                endedAt: Date().addingTimeInterval(-82_800),
                exercises: [
                    WorkoutExerciseRecord(
                        exerciseName: "바벨 벤치프레스",
                        bodyPart: .chest,
                        orderIndex: 0,
                        sets: [
                            WorkoutSetRecord(
                                orderIndex: 0,
                                targetWeightKg: 60,
                                targetRepetitions: 8,
                                actualWeightKg: 60,
                                actualRepetitions: 8,
                                completedAt: Date().addingTimeInterval(-85_800)
                            )
                        ]
                    )
                ]
            )
        ]
    }
}
