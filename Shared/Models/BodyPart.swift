import Foundation

public enum BodyPart: String, CaseIterable, Codable, Identifiable, Sendable {
    case lowerBody
    case chest
    case back
    case shoulders
    case arms
    case core
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .lowerBody:
            return "하체"
        case .chest:
            return "가슴"
        case .back:
            return "등"
        case .shoulders:
            return "어깨"
        case .arms:
            return "팔"
        case .core:
            return "복근"
        case .other:
            return "기타"
        }
    }

    public static var plannedFilterCategories: [BodyPart] {
        [.lowerBody, .chest, .back, .shoulders, .arms, .core]
    }
}
