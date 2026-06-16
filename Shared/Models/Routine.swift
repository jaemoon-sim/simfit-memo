import Foundation

public struct Routine: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var exercises: [RoutineExercise]
    public var createdAt: Date
    public var updatedAt: Date
    public var lastPerformedAt: Date?
    public var completedCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        exercises: [RoutineExercise] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastPerformedAt: Date? = nil,
        completedCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastPerformedAt = lastPerformedAt
        self.completedCount = completedCount
    }
}

public struct RoutineExercise: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var exerciseID: UUID
    public var exerciseName: String
    public var bodyPart: BodyPart
    public var orderIndex: Int
    public var setTargets: [RoutineSetTarget]

    public init(
        id: UUID = UUID(),
        exerciseID: UUID,
        exerciseName: String,
        bodyPart: BodyPart,
        orderIndex: Int,
        setTargets: [RoutineSetTarget] = []
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.bodyPart = bodyPart
        self.orderIndex = orderIndex
        self.setTargets = setTargets
    }
}

public struct RoutineSetTarget: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var orderIndex: Int
    public var targetWeightKg: Double?
    public var targetRepetitions: Int?
    public var restSeconds: Int

    public init(
        id: UUID = UUID(),
        orderIndex: Int,
        targetWeightKg: Double? = nil,
        targetRepetitions: Int? = nil,
        restSeconds: Int = ExerciseSeedService.defaultRestSeconds
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.targetWeightKg = targetWeightKg
        self.targetRepetitions = targetRepetitions
        self.restSeconds = restSeconds
    }
}
