import Foundation

public struct FreeExerciseDBExerciseSeedImporter: ExerciseSeedImporting {
    public static let mvpIncludedCategories: Set<String> = ["strength"]

    private let includedCategories: Set<String>?

    public init(includedCategories: Set<String>? = FreeExerciseDBExerciseSeedImporter.mvpIncludedCategories) {
        self.includedCategories = includedCategories.map { categories in
            Set(categories.map { $0.exerciseSeedNormalizedKey })
        }
    }

    public func importExercises(from data: Data, importedAt: Date) throws -> [Exercise] {
        let sourceExercises = try JSONDecoder().decode([FreeExerciseDBExercise].self, from: data)

        return sourceExercises.compactMap { sourceExercise in
            guard shouldInclude(sourceExercise) else {
                return nil
            }

            let sourceID = sourceExercise.id.exerciseSeedTrimmed
            let name = sourceExercise.name.exerciseSeedTrimmed
            guard name.isEmpty == false else {
                return nil
            }

            let primaryMuscles = sourceExercise.primaryMuscles.exerciseSeedCleanedStrings()
            let secondaryMuscles = sourceExercise.secondaryMuscles.exerciseSeedCleanedStrings()

            return Exercise(
                sourceID: sourceID.isEmpty ? nil : sourceID,
                name: name,
                localizedName: ExerciseSeedLocalizedNameProvider.localizedName(for: name),
                bodyPart: ExerciseSeedBodyPartMapper.bodyPart(
                    primaryMuscles: primaryMuscles,
                    secondaryMuscles: secondaryMuscles
                ),
                primaryMuscles: primaryMuscles,
                secondaryMuscles: secondaryMuscles,
                equipment: sourceExercise.equipment?.exerciseSeedNilIfBlank(),
                category: sourceExercise.category?.exerciseSeedNilIfBlank(),
                instructions: sourceExercise.instructions.exerciseSeedCleanedStrings(),
                isBookmarked: false,
                isCustom: false,
                createdAt: importedAt,
                updatedAt: importedAt
            )
        }
    }

    private func shouldInclude(_ sourceExercise: FreeExerciseDBExercise) -> Bool {
        guard let includedCategories else {
            return true
        }

        guard let category = sourceExercise.category?.exerciseSeedNormalizedKey else {
            return false
        }

        return includedCategories.contains(category)
    }
}

private struct FreeExerciseDBExercise: Decodable {
    let id: String
    let name: String
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let instructions: [String]?
    let category: String?
}

private enum ExerciseSeedBodyPartMapper {
    static func bodyPart(primaryMuscles: [String], secondaryMuscles: [String]) -> BodyPart {
        mappedBodyPart(for: primaryMuscles)
            ?? mappedBodyPart(for: secondaryMuscles)
            ?? .other
    }

    private static func mappedBodyPart(for muscles: [String]) -> BodyPart? {
        for muscle in muscles {
            if let bodyPart = muscleMap[muscle.exerciseSeedNormalizedKey] {
                return bodyPart
            }
        }

        return nil
    }

    private static let muscleMap: [String: BodyPart] = [
        "abdominals": .core,
        "abs": .core,
        "core": .core,
        "obliques": .core,
        "abductors": .lowerBody,
        "adductors": .lowerBody,
        "calves": .lowerBody,
        "glutes": .lowerBody,
        "hamstrings": .lowerBody,
        "quadriceps": .lowerBody,
        "quads": .lowerBody,
        "chest": .chest,
        "pectorals": .chest,
        "lats": .back,
        "lower back": .back,
        "middle back": .back,
        "traps": .back,
        "trapezius": .back,
        "shoulders": .shoulders,
        "delts": .shoulders,
        "deltoids": .shoulders,
        "biceps": .arms,
        "forearms": .arms,
        "triceps": .arms
    ]
}

private enum ExerciseSeedLocalizedNameProvider {
    static func localizedName(for name: String) -> String {
        koreanNames[name.exerciseSeedNormalizedKey] ?? name
    }

    private static let koreanNames: [String: String] = [
        "barbell bench press": "바벨 벤치프레스",
        "dumbbell bench press": "덤벨 벤치프레스",
        "barbell squat": "바벨 스쿼트",
        "squat": "스쿼트",
        "barbell deadlift": "바벨 데드리프트",
        "deadlift": "데드리프트",
        "pull up": "풀업",
        "pullups": "풀업",
        "pushups": "푸시업",
        "push up": "푸시업",
        "plank": "플랭크",
        "crunches": "크런치",
        "leg press": "레그 프레스",
        "barbell curl": "바벨 컬",
        "dumbbell shoulder press": "덤벨 숄더 프레스"
    ]
}

private extension Optional where Wrapped == [String] {
    func exerciseSeedCleanedStrings() -> [String] {
        switch self {
        case .some(let strings):
            return strings
                .map { $0.exerciseSeedTrimmed }
                .filter { $0.isEmpty == false }
        case .none:
            return []
        }
    }
}

private extension String {
    var exerciseSeedTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var exerciseSeedNormalizedKey: String {
        exerciseSeedTrimmed
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    func exerciseSeedNilIfBlank() -> String? {
        let trimmed = exerciseSeedTrimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
