import Foundation

public struct ExerciseSeedSourceMetadata: Codable, Equatable, Sendable {
    public var sourceName: String
    public var sourceURL: URL
    public var license: String
    public var importedAt: Date
    public var notes: String
}

public enum ExerciseSeedImportError: Error, Equatable {
    case importerNotImplemented
}

public protocol ExerciseSeedImporting: Sendable {
    func importExercises(from data: Data, importedAt: Date) throws -> [Exercise]
}

public struct ExerciseSeedService: Sendable {
    public static let defaultRestSeconds = 90

    public static let sourceMetadata = ExerciseSeedSourceMetadata(
        sourceName: "Free Exercise DB",
        sourceURL: URL(string: "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json")!,
        license: "Unlicense",
        importedAt: Date(timeIntervalSince1970: 1_779_753_600),
        notes: "Tiny embedded seed for scaffolding plus a text-only Free Exercise DB importer that defaults to strength exercises for MVP."
    )

    public init() {}

    public func loadEmbeddedSeeds(now: Date = Date()) -> [Exercise] {
        [
            Exercise(
                sourceID: "barbell-bench-press",
                name: "Barbell Bench Press",
                localizedName: "바벨 벤치프레스",
                bodyPart: .chest,
                primaryMuscles: ["chest"],
                secondaryMuscles: ["shoulders", "triceps"],
                equipment: "barbell",
                category: "strength",
                instructions: ["Lie on a flat bench and press the bar from chest level to full arm extension."],
                createdAt: now,
                updatedAt: now
            ),
            Exercise(
                sourceID: "barbell-squat",
                name: "Barbell Squat",
                localizedName: "바벨 스쿼트",
                bodyPart: .lowerBody,
                primaryMuscles: ["quadriceps"],
                secondaryMuscles: ["glutes", "hamstrings"],
                equipment: "barbell",
                category: "strength",
                instructions: ["Set the bar across the upper back, squat under control, and stand tall."],
                createdAt: now,
                updatedAt: now
            ),
            Exercise(
                sourceID: "pull-up",
                name: "Pull-up",
                localizedName: "풀업",
                bodyPart: .back,
                primaryMuscles: ["lats"],
                secondaryMuscles: ["biceps"],
                equipment: "body only",
                category: "strength",
                instructions: ["Hang from a pull-up bar and pull until the chin clears the bar."],
                createdAt: now,
                updatedAt: now
            )
        ]
    }

    public func importFreeExerciseDBData(_ data: Data, importedAt: Date = Date()) throws -> [Exercise] {
        try importFreeExerciseDBData(data, importedAt: importedAt, importer: FreeExerciseDBExerciseSeedImporter())
    }

    public func importFreeExerciseDBData<Importer: ExerciseSeedImporting>(
        _ data: Data,
        importedAt: Date = Date(),
        importer: Importer
    ) throws -> [Exercise] {
        try importer.importExercises(from: data, importedAt: importedAt)
    }
}
