import Foundation

public struct Exercise: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var sourceID: String?
    public var name: String
    public var localizedName: String?
    public var bodyPart: BodyPart
    public var primaryMuscles: [String]
    public var secondaryMuscles: [String]
    public var equipment: String?
    public var category: String?
    public var instructions: [String]
    public var isBookmarked: Bool
    public var isCustom: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        sourceID: String? = nil,
        name: String,
        localizedName: String? = nil,
        bodyPart: BodyPart,
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        equipment: String? = nil,
        category: String? = nil,
        instructions: [String] = [],
        isBookmarked: Bool = false,
        isCustom: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sourceID = sourceID
        self.name = name
        self.localizedName = localizedName
        self.bodyPart = bodyPart
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.category = category
        self.instructions = instructions
        self.isBookmarked = isBookmarked
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var displayName: String {
        localizedName?.isEmpty == false ? localizedName! : name
    }
}
