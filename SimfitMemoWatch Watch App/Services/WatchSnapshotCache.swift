import Foundation

final class WatchSnapshotCache {
    private enum Key {
        static let activeWorkout = "simfitMemo.watch.cache.activeWorkout"
        static let routines = "simfitMemo.watch.cache.routines"
        static let history = "simfitMemo.watch.cache.history"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadActiveWorkout() -> ActiveWorkoutSnapshotDTO? {
        load(ActiveWorkoutSnapshotDTO.self, forKey: Key.activeWorkout)
    }

    func loadRoutines() -> RoutineSnapshotDTO? {
        load(RoutineSnapshotDTO.self, forKey: Key.routines)
    }

    func loadHistory() -> WorkoutHistorySnapshotDTO? {
        load(WorkoutHistorySnapshotDTO.self, forKey: Key.history)
    }

    func save(_ snapshot: ActiveWorkoutSnapshotDTO) {
        save(snapshot, forKey: Key.activeWorkout)
    }

    func save(_ snapshot: RoutineSnapshotDTO) {
        save(snapshot, forKey: Key.routines)
    }

    func save(_ snapshot: WorkoutHistorySnapshotDTO) {
        save(snapshot, forKey: Key.history)
    }

    private func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<Value: Encodable>(_ value: Value, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
