import Foundation

enum MockFitnessData {
    static var exercises: [Exercise] {
        [
            exercise(1, "Barbell Bench Press", "바벨 벤치프레스", .chest, "바벨", true),
            exercise(2, "Incline Dumbbell Press", "인클라인 덤벨 프레스", .chest, "덤벨", false),
            exercise(3, "Barbell Squat", "바벨 스쿼트", .lowerBody, "바벨", true),
            exercise(4, "Leg Press", "레그 프레스", .lowerBody, "머신", false),
            exercise(5, "Pull-up", "풀업", .back, "맨몸", true),
            exercise(6, "Seated Cable Row", "시티드 케이블 로우", .back, "케이블", false),
            exercise(7, "Shoulder Press", "숄더 프레스", .shoulders, "머신", true),
            exercise(8, "Lateral Raise", "사이드 레터럴 레이즈", .shoulders, "덤벨", false),
            exercise(9, "Barbell Curl", "바벨 컬", .arms, "바벨", false),
            exercise(10, "Cable Pushdown", "케이블 푸시다운", .arms, "케이블", false),
            exercise(11, "Hanging Leg Raise", "행잉 레그 레이즈", .core, "맨몸", false),
            exercise(12, "Plank", "플랭크", .core, "맨몸", true)
        ]
    }

    static var routines: [Routine] {
        let allExercises = exercises

        return [
            Routine(
                id: uuid(101),
                name: "상체 밀기",
                exercises: [
                    routineExercise(allExercises[0], order: 0, sets: 4, weight: 60, repetitions: 8),
                    routineExercise(allExercises[1], order: 1, sets: 3, weight: 24, repetitions: 10),
                    routineExercise(allExercises[6], order: 2, sets: 4, weight: 45, repetitions: 10),
                    routineExercise(allExercises[7], order: 3, sets: 3, weight: 8, repetitions: 15)
                ],
                createdAt: Date().addingTimeInterval(-240_000),
                updatedAt: Date().addingTimeInterval(-84_000),
                lastPerformedAt: Date().addingTimeInterval(-172_800),
                completedCount: 8
            ),
            Routine(
                id: uuid(102),
                name: "등과 팔",
                exercises: [
                    routineExercise(allExercises[4], order: 0, sets: 4, weight: nil, repetitions: 8),
                    routineExercise(allExercises[5], order: 1, sets: 4, weight: 50, repetitions: 10),
                    routineExercise(allExercises[8], order: 2, sets: 3, weight: 20, repetitions: 12),
                    routineExercise(allExercises[9], order: 3, sets: 3, weight: 30, repetitions: 12)
                ],
                createdAt: Date().addingTimeInterval(-420_000),
                updatedAt: Date().addingTimeInterval(-120_000),
                lastPerformedAt: Date().addingTimeInterval(-432_000),
                completedCount: 12
            ),
            Routine(
                id: uuid(103),
                name: "하체 기본",
                exercises: [
                    routineExercise(allExercises[2], order: 0, sets: 5, weight: 90, repetitions: 5),
                    routineExercise(allExercises[3], order: 1, sets: 4, weight: 140, repetitions: 10),
                    routineExercise(allExercises[10], order: 2, sets: 3, weight: nil, repetitions: 12)
                ],
                createdAt: Date().addingTimeInterval(-620_000),
                updatedAt: Date().addingTimeInterval(-620_000),
                lastPerformedAt: nil,
                completedCount: 0
            )
        ]
    }

    private static func exercise(
        _ id: Int,
        _ name: String,
        _ localizedName: String,
        _ bodyPart: BodyPart,
        _ equipment: String,
        _ isBookmarked: Bool
    ) -> Exercise {
        Exercise(
            id: uuid(id),
            sourceID: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            localizedName: localizedName,
            bodyPart: bodyPart,
            primaryMuscles: [bodyPart.displayName],
            equipment: equipment,
            category: "strength",
            instructions: ["자세를 안정적으로 유지하고 목표 반복 수를 기록하세요."],
            isBookmarked: isBookmarked,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private static func routineExercise(
        _ exercise: Exercise,
        order: Int,
        sets: Int,
        weight: Double?,
        repetitions: Int?
    ) -> RoutineExercise {
        RoutineExercise(
            exerciseID: exercise.id,
            exerciseName: exercise.displayName,
            bodyPart: exercise.bodyPart,
            orderIndex: order,
            setTargets: (0..<sets).map { index in
                RoutineSetTarget(
                    orderIndex: index,
                    targetWeightKg: weight,
                    targetRepetitions: repetitions,
                    restSeconds: ExerciseSeedService.defaultRestSeconds
                )
            }
        )
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
    }
}
