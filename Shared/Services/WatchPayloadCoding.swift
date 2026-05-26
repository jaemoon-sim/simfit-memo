import Foundation

public enum WatchSyncPayloadKind: String, Codable, Equatable, Sendable {
    case activeWorkout
    case routines
    case history
    case setCompletion
}

public enum WatchPayloadCodingError: Error, Equatable {
    case missingPayloadData
    case invalidPayloadData
    case invalidPayloadKind(String)
    case unsupportedSchemaVersion(Int)
    case mismatchedPayloadKind(expected: WatchSyncPayloadKind, actual: WatchSyncPayloadKind)
}

public enum WatchPayloadCoding {
    public static let payloadDataKey = "simfitMemo.watchSync.payloadData"
    public static let payloadKindKey = "simfitMemo.watchSync.payloadKind"
    public static let schemaVersionKey = "simfitMemo.watchSync.schemaVersion"

    public static func encode(_ payload: WatchSyncPayloadDTO) throws -> Data {
        try JSONEncoder.watchSync.encode(payload)
    }

    public static func decode(_ data: Data) throws -> WatchSyncPayloadDTO {
        let payload = try JSONDecoder.watchSync.decode(WatchSyncPayloadDTO.self, from: data)
        try validate(schemaVersion: payload.schemaVersion)
        return payload
    }

    public static func makeDictionary(from payload: WatchSyncPayloadDTO) throws -> [String: Any] {
        [
            payloadDataKey: try encode(payload),
            payloadKindKey: payload.watchPayloadKind.rawValue,
            schemaVersionKey: payload.schemaVersion
        ]
    }

    public static func decodeDictionary(_ dictionary: [String: Any]) throws -> WatchSyncPayloadDTO {
        if let schemaVersion = intValue(dictionary[schemaVersionKey]) {
            try validate(schemaVersion: schemaVersion)
        }

        guard let data = dataValue(dictionary[payloadDataKey]) else {
            throw WatchPayloadCodingError.missingPayloadData
        }

        let payload = try decode(data)

        if let kindValue = dictionary[payloadKindKey] as? String {
            guard let expectedKind = WatchSyncPayloadKind(rawValue: kindValue) else {
                throw WatchPayloadCodingError.invalidPayloadKind(kindValue)
            }

            guard expectedKind == payload.watchPayloadKind else {
                throw WatchPayloadCodingError.mismatchedPayloadKind(
                    expected: expectedKind,
                    actual: payload.watchPayloadKind
                )
            }
        }

        return payload
    }

    private static func validate(schemaVersion: Int) throws {
        guard schemaVersion <= WatchSyncSchema.currentVersion else {
            throw WatchPayloadCodingError.unsupportedSchemaVersion(schemaVersion)
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        return nil
    }

    private static func dataValue(_ value: Any?) -> Data? {
        if let data = value as? Data {
            return data
        }

        if let data = value as? NSData {
            return data as Data
        }

        return nil
    }
}

public extension WatchSyncPayloadDTO {
    var watchPayloadKind: WatchSyncPayloadKind {
        switch self {
        case .activeWorkout:
            return .activeWorkout
        case .routines:
            return .routines
        case .history:
            return .history
        case .setCompletion:
            return .setCompletion
        }
    }

    var schemaVersion: Int {
        switch self {
        case .activeWorkout(let snapshot):
            return snapshot.schemaVersion
        case .routines(let snapshot):
            return snapshot.schemaVersion
        case .history(let snapshot):
            return snapshot.schemaVersion
        case .setCompletion(let event):
            return event.schemaVersion
        }
    }
}

public struct WatchSetCompletionEventDeduplicator: Equatable, Sendable {
    private var acceptedKeys: Set<String>
    private var acceptedKeyOrder: [String]
    private let maximumStoredKeys: Int

    public init(maximumStoredKeys: Int = 256) {
        self.acceptedKeys = []
        self.acceptedKeyOrder = []
        self.maximumStoredKeys = maximumStoredKeys
    }

    public mutating func shouldAccept(_ event: SetCompletionEventDTO) -> Bool {
        let key = Self.key(for: event)
        guard acceptedKeys.contains(key) == false else {
            return false
        }

        acceptedKeys.insert(key)
        acceptedKeyOrder.append(key)
        trimIfNeeded()
        return true
    }

    public func contains(_ event: SetCompletionEventDTO) -> Bool {
        acceptedKeys.contains(Self.key(for: event))
    }

    private mutating func trimIfNeeded() {
        guard acceptedKeyOrder.count > maximumStoredKeys else {
            return
        }

        let removalCount = acceptedKeyOrder.count - maximumStoredKeys
        let removedKeys = acceptedKeyOrder.prefix(removalCount)
        acceptedKeys.subtract(removedKeys)
        acceptedKeyOrder.removeFirst(removalCount)
    }

    private static func key(for event: SetCompletionEventDTO) -> String {
        [
            event.sessionID.uuidString,
            event.exerciseID.uuidString,
            event.setID.uuidString
        ].joined(separator: ":")
    }
}

private extension JSONEncoder {
    static var watchSync: JSONEncoder {
        JSONEncoder()
    }
}

private extension JSONDecoder {
    static var watchSync: JSONDecoder {
        JSONDecoder()
    }
}
