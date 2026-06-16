import Combine
import Foundation
import WatchConnectivity

enum WatchSyncConnectionState: Equatable {
    case unavailable
    case inactive
    case activated
    case reachable
    case failed(String)
}

enum WatchSyncDeliveryResult: Equatable {
    case sentLive
    case queuedUserInfo
    case unavailable
    case duplicate
    case failed(String)
}

final class WatchSyncService: NSObject, ObservableObject {
    @Published private(set) var connectionState: WatchSyncConnectionState = .inactive
    @Published private(set) var lastDeliveryResult: WatchSyncDeliveryResult?
    @Published private(set) var activeWorkoutSnapshot: ActiveWorkoutSnapshotDTO?
    @Published private(set) var routineSnapshot: RoutineSnapshotDTO?
    @Published private(set) var historySnapshot: WorkoutHistorySnapshotDTO?
    @Published private(set) var pendingEventCount = 0

    private let session: WCSession?
    private let cache: WatchSnapshotCache
    private var pendingEvents: [SetCompletionEventDTO] = []
    private var deduplicator = WatchSetCompletionEventDeduplicator()
    private var clientSequence = 0

    init(
        session: WCSession? = WCSession.isSupported() ? WCSession.default : nil,
        cache: WatchSnapshotCache = WatchSnapshotCache()
    ) {
        self.session = session
        self.cache = cache
        self.activeWorkoutSnapshot = cache.loadActiveWorkout()
        self.routineSnapshot = cache.loadRoutines()
        self.historySnapshot = cache.loadHistory()
        super.init()
        activate()
    }

    func activate() {
        guard let session else {
            publishConnectionState(.unavailable)
            return
        }

        session.delegate = self
        session.activate()
        publishConnectionState(currentConnectionState(for: session))
    }

    @discardableResult
    func sendCompletion(for state: ActiveWorkoutState) -> WatchSyncDeliveryResult {
        guard let context = state.currentSetContext else {
            let result = WatchSyncDeliveryResult.failed("No active set is available.")
            publishDeliveryResult(result)
            return result
        }

        return sendSetCompletion(
            sessionID: state.id,
            exerciseID: context.exercise.id,
            setID: context.set.id
        )
    }

    @discardableResult
    func sendSetCompletion(sessionID: UUID, exerciseID: UUID, setID: UUID) -> WatchSyncDeliveryResult {
        clientSequence += 1
        let event = SetCompletionEventDTO(
            sessionID: sessionID,
            exerciseID: exerciseID,
            setID: setID,
            sourceDeviceID: deviceIdentifier,
            clientSequence: clientSequence
        )

        guard deduplicator.shouldAccept(event) else {
            let result = WatchSyncDeliveryResult.duplicate
            publishDeliveryResult(result)
            return result
        }

        completeLocalSet(event)
        return deliver(.setCompletion(event), eventForRetry: event)
    }

    @discardableResult
    func sendRestAdjustment(for state: ActiveWorkoutState, deltaSeconds: Int) -> WatchSyncDeliveryResult {
        guard deltaSeconds != 0 else {
            let result = WatchSyncDeliveryResult.failed("Rest adjustment cannot be zero.")
            publishDeliveryResult(result)
            return result
        }

        clientSequence += 1
        let event = RestAdjustmentEventDTO(
            sessionID: state.id,
            deltaSeconds: deltaSeconds,
            sourceDeviceID: deviceIdentifier,
            clientSequence: clientSequence
        )

        adjustLocalRestTimer(by: deltaSeconds)
        return deliver(.restAdjustment(event))
    }

    @discardableResult
    func requestSync() -> WatchSyncDeliveryResult {
        activate()
        clientSequence += 1
        let event = SyncRequestEventDTO(
            sourceDeviceID: deviceIdentifier,
            clientSequence: clientSequence
        )

        return deliver(.syncRequest(event))
    }

    private func deliver(
        _ payload: WatchSyncPayloadDTO,
        eventForRetry event: SetCompletionEventDTO? = nil
    ) -> WatchSyncDeliveryResult {
        guard let session else {
            if let event {
                enqueue(event)
            }

            let result = WatchSyncDeliveryResult.unavailable
            publishDeliveryResult(result)
            return result
        }

        let dictionary: [String: Any]
        do {
            dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        } catch {
            let result = WatchSyncDeliveryResult.failed(error.localizedDescription)
            publishDeliveryResult(result)
            return result
        }

        if session.activationState == .activated, session.isReachable {
            session.sendMessage(
                dictionary,
                replyHandler: nil,
                errorHandler: { [weak self] _ in
                    guard let self else {
                        return
                    }

                    if let event {
                        self.enqueueAndTransfer(event, using: session)
                    } else {
                        session.transferUserInfo(dictionary)
                        self.publishDeliveryResult(.queuedUserInfo)
                    }
                }
            )

            let result = WatchSyncDeliveryResult.sentLive
            publishDeliveryResult(result)
            publishConnectionState(.reachable)
            return result
        }

        if let event {
            enqueueAndTransfer(event, using: session)
        } else {
            session.transferUserInfo(dictionary)
        }

        let result = WatchSyncDeliveryResult.queuedUserInfo
        publishDeliveryResult(result)
        publishConnectionState(currentConnectionState(for: session))
        return result
    }

    private func enqueueAndTransfer(_ event: SetCompletionEventDTO, using session: WCSession) {
        enqueue(event)

        do {
            let dictionary = try WatchPayloadCoding.makeDictionary(from: .setCompletion(event))
            session.transferUserInfo(dictionary)
        } catch {
            publishDeliveryResult(.failed(error.localizedDescription))
        }
    }

    private func enqueue(_ event: SetCompletionEventDTO) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.pendingEvents.append(event)
            self.pendingEventCount = self.pendingEvents.count
        }
    }

    private func adjustLocalRestTimer(by deltaSeconds: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self, var snapshot = self.activeWorkoutSnapshot, var state = snapshot.state else {
                return
            }

            let now = Date()
            guard state.adjustRestTimer(by: deltaSeconds, now: now) else {
                return
            }

            snapshot.generatedAt = now
            snapshot.state = state
            self.activeWorkoutSnapshot = snapshot
            self.cache.save(snapshot)
        }
    }

    private func completeLocalSet(_ event: SetCompletionEventDTO) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  var snapshot = self.activeWorkoutSnapshot,
                  var state = snapshot.state,
                  state.id == event.sessionID else {
                return
            }

            guard state.completeSet(
                exerciseID: event.exerciseID,
                setID: event.setID,
                completedAt: event.completedAt
            ) == .completed else {
                return
            }

            snapshot.generatedAt = event.completedAt
            snapshot.state = state
            self.activeWorkoutSnapshot = snapshot
            self.cache.save(snapshot)
        }
    }

    private func flushPendingEventsIfPossible() {
        guard let session, session.activationState == .activated, session.isReachable else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            let events = self.pendingEvents
            self.pendingEvents.removeAll()
            self.pendingEventCount = 0

            for event in events {
                _ = self.deliver(.setCompletion(event), eventForRetry: event)
            }
        }
    }

    private func receive(_ dictionary: [String: Any]) {
        do {
            let payload = try WatchPayloadCoding.decodeDictionary(dictionary)
            apply(payload)
        } catch {
            publishConnectionState(.failed(error.localizedDescription))
        }
    }

    private func apply(_ payload: WatchSyncPayloadDTO) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            switch payload {
            case .activeWorkout(let snapshot):
                self.activeWorkoutSnapshot = snapshot
                self.cache.save(snapshot)
            case .routines(let snapshot):
                self.routineSnapshot = snapshot
                self.cache.save(snapshot)
            case .history(let snapshot):
                self.historySnapshot = snapshot
                self.cache.save(snapshot)
            case .fullSnapshot(let snapshot):
                let activeWorkoutSnapshot = ActiveWorkoutSnapshotDTO(
                    generatedAt: snapshot.generatedAt,
                    state: snapshot.activeWorkout
                )
                let routineSnapshot = RoutineSnapshotDTO(
                    generatedAt: snapshot.generatedAt,
                    routines: snapshot.routines
                )
                let historySnapshot = WorkoutHistorySnapshotDTO(
                    generatedAt: snapshot.generatedAt,
                    records: snapshot.history
                )
                self.activeWorkoutSnapshot = activeWorkoutSnapshot
                self.routineSnapshot = routineSnapshot
                self.historySnapshot = historySnapshot
                self.cache.save(activeWorkoutSnapshot)
                self.cache.save(routineSnapshot)
                self.cache.save(historySnapshot)
            case .setCompletion, .restAdjustment, .syncRequest:
                break
            }
        }
    }

    private var deviceIdentifier: String {
        let key = "simfitMemo.watch.deviceIdentifier"
        if let existingIdentifier = UserDefaults.standard.string(forKey: key) {
            return existingIdentifier
        }

        let identifier = "watch-\(UUID().uuidString)"
        UserDefaults.standard.set(identifier, forKey: key)
        return identifier
    }

    private func publishDeliveryResult(_ result: WatchSyncDeliveryResult) {
        DispatchQueue.main.async { [weak self] in
            self?.lastDeliveryResult = result
        }
    }

    private func publishConnectionState(_ state: WatchSyncConnectionState) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = state
        }
    }

    private func currentConnectionState(for session: WCSession) -> WatchSyncConnectionState {
        guard session.activationState == .activated else {
            return .inactive
        }

        return session.isReachable ? .reachable : .activated
    }
}

extension WatchSyncService: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            publishConnectionState(.failed(error.localizedDescription))
        } else {
            publishConnectionState(currentConnectionState(for: session))
            flushPendingEventsIfPossible()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        publishConnectionState(currentConnectionState(for: session))
        flushPendingEventsIfPossible()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        receive(userInfo)
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        publishConnectionState(.inactive)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

private struct ActiveSetContext {
    var exercise: ActiveWorkoutExercise
    var set: ActiveWorkoutSet
}

private extension ActiveWorkoutState {
    var currentSetContext: ActiveSetContext? {
        let exercisesByOrder = exercises.sorted { $0.orderIndex < $1.orderIndex }

        if let currentExerciseID, let currentSetID {
            for exercise in exercisesByOrder where exercise.id == currentExerciseID {
                if let set = exercise.sets.first(where: { $0.id == currentSetID }) {
                    return ActiveSetContext(exercise: exercise, set: set)
                }
            }
        }

        for exercise in exercisesByOrder {
            if let set = exercise.sets.sorted(by: { $0.orderIndex < $1.orderIndex }).first(where: { $0.completedAt == nil }) {
                return ActiveSetContext(exercise: exercise, set: set)
            }
        }

        return nil
    }
}
