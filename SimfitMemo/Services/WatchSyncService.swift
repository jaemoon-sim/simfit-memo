import Combine
import Foundation
import WatchConnectivity

enum WatchSyncConnectionState: Equatable {
    case unavailable
    case inactive
    case activated
    case reachable
    case notPaired
    case watchAppNotInstalled
    case failed(String)
}

enum WatchSyncDeliveryResult: Equatable {
    case sentLive
    case queuedApplicationContext
    case queuedUserInfo
    case unavailable
    case failed(String)
}

final class WatchSyncService: NSObject, ObservableObject {
    @Published private(set) var connectionState: WatchSyncConnectionState = .inactive
    @Published private(set) var lastDeliveryResult: WatchSyncDeliveryResult?
    @Published private(set) var lastReceivedSetCompletion: SetCompletionEventDTO?
    @Published private(set) var lastReceivedRestAdjustment: RestAdjustmentEventDTO?
    @Published private(set) var lastReceivedSyncRequest: SyncRequestEventDTO?

    var onSetCompletion: ((SetCompletionEventDTO) -> Void)?
    var onRestAdjustment: ((RestAdjustmentEventDTO) -> Void)?
    var onSyncRequest: ((SyncRequestEventDTO) -> Void)?

    private let session: WCSession?
    private var deduplicator = WatchSetCompletionEventDeduplicator()

    init(session: WCSession? = WCSession.isSupported() ? WCSession.default : nil) {
        self.session = session
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
    func sendActiveWorkoutSnapshot(_ state: ActiveWorkoutState?) -> WatchSyncDeliveryResult {
        send(.activeWorkout(ActiveWorkoutSnapshotDTO(state: state)))
    }

    @discardableResult
    func sendRoutineSnapshot(_ routines: [Routine]) -> WatchSyncDeliveryResult {
        send(.routines(RoutineSnapshotDTO(routines: routines)))
    }

    @discardableResult
    func sendHistorySnapshot(_ records: [WorkoutSessionRecord]) -> WatchSyncDeliveryResult {
        send(.history(WorkoutHistorySnapshotDTO(records: records)))
    }

    @discardableResult
    func sendFullSnapshot(
        activeWorkout: ActiveWorkoutState?,
        routines: [Routine],
        history: [WorkoutSessionRecord]
    ) -> WatchSyncDeliveryResult {
        send(.fullSnapshot(FullSyncSnapshotDTO(
            activeWorkout: activeWorkout,
            routines: routines,
            history: history
        )))
    }

    @discardableResult
    func send(_ payload: WatchSyncPayloadDTO) -> WatchSyncDeliveryResult {
        guard let session else {
            let result = WatchSyncDeliveryResult.unavailable
            publishDeliveryResult(result)
            return result
        }

        guard session.isPaired else {
            let result = WatchSyncDeliveryResult.unavailable
            publishConnectionState(.notPaired)
            publishDeliveryResult(result)
            return result
        }

        guard session.isWatchAppInstalled else {
            let result = WatchSyncDeliveryResult.unavailable
            publishConnectionState(.watchAppNotInstalled)
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
                errorHandler: { [weak self, weak session] _ in
                    guard let self, let session else {
                        return
                    }

                    _ = self.queue(dictionary, with: session)
                }
            )

            let result = WatchSyncDeliveryResult.sentLive
            publishDeliveryResult(result)
            publishConnectionState(.reachable)
            return result
        }

        return queue(dictionary, with: session)
    }

    private func queue(_ dictionary: [String: Any], with session: WCSession) -> WatchSyncDeliveryResult {
        if session.activationState == .activated {
            do {
                try session.updateApplicationContext(dictionary)
                let result = WatchSyncDeliveryResult.queuedApplicationContext
                publishDeliveryResult(result)
                publishConnectionState(currentConnectionState(for: session))
                return result
            } catch {
                session.transferUserInfo(dictionary)
                let result = WatchSyncDeliveryResult.queuedUserInfo
                publishDeliveryResult(result)
                publishConnectionState(currentConnectionState(for: session))
                return result
            }
        }

        session.transferUserInfo(dictionary)
        let result = WatchSyncDeliveryResult.queuedUserInfo
        publishDeliveryResult(result)
        publishConnectionState(currentConnectionState(for: session))
        return result
    }

    private func receive(_ dictionary: [String: Any]) {
        do {
            let payload = try WatchPayloadCoding.decodeDictionary(dictionary)
            handle(payload)
        } catch {
            publishConnectionState(.failed(error.localizedDescription))
        }
    }

    private func handle(_ payload: WatchSyncPayloadDTO) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            switch payload {
            case .setCompletion(let event):
                guard self.deduplicator.shouldAccept(event) else {
                    return
                }

                self.lastReceivedSetCompletion = event
                self.onSetCompletion?(event)
            case .restAdjustment(let event):
                self.lastReceivedRestAdjustment = event
                self.onRestAdjustment?(event)
            case .syncRequest(let event):
                self.lastReceivedSyncRequest = event
                self.onSyncRequest?(event)
            case .activeWorkout, .routines, .history, .fullSnapshot:
                return
            }
        }
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

        guard session.isPaired else {
            return .notPaired
        }

        guard session.isWatchAppInstalled else {
            return .watchAppNotInstalled
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
        }
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
