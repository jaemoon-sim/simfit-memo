import Combine
import Foundation
import HealthKit

enum HeartRateReadingState: Equatable {
    case unavailable
    case notRequested
    case requesting
    case authorized
    case unauthorized
    case noData
    case failed(String)

    var displayText: String {
        switch self {
        case .unavailable:
            return "심박수 사용 불가"
        case .notRequested:
            return "심박수 권한 필요"
        case .requesting:
            return "심박수 확인 중"
        case .authorized:
            return "심박수"
        case .unauthorized:
            return "심박수 권한 없음"
        case .noData:
            return "심박수 데이터 없음"
        case .failed:
            return "심박수 오류"
        }
    }
}

final class HealthKitHeartRateService: ObservableObject {
    @Published private(set) var state: HeartRateReadingState
    @Published private(set) var latestHeartRate: Int?
    @Published private(set) var latestSampleDate: Date?

    private let healthStore: HKHealthStore?
    private let heartRateType: HKQuantityType?
    private var observerQuery: HKObserverQuery?
    private var latestSampleQuery: HKSampleQuery?

    init(
        healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    ) {
        self.healthStore = healthStore
        self.heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        self.state = healthStore == nil ? .unavailable : .notRequested
    }

    func requestAuthorizationAndStart() {
        guard let healthStore, let heartRateType else {
            publish(state: .unavailable)
            return
        }

        publish(state: .requesting)

        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] success, error in
            guard let self else {
                return
            }

            if let error {
                self.publish(state: .failed(error.localizedDescription))
                return
            }

            guard success else {
                self.publish(state: .unauthorized)
                return
            }

            self.fetchLatestHeartRate()
            self.startObserverIfNeeded()
        }
    }

    func refreshLatestHeartRate() {
        fetchLatestHeartRate()
    }

    func stop() {
        if let observerQuery {
            healthStore?.stop(observerQuery)
        }

        if let latestSampleQuery {
            healthStore?.stop(latestSampleQuery)
        }

        observerQuery = nil
        latestSampleQuery = nil
    }

    private func startObserverIfNeeded() {
        guard observerQuery == nil, let healthStore, let heartRateType else {
            return
        }

        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, completionHandler, error in
            defer { completionHandler() }

            if let error {
                self?.publish(state: .failed(error.localizedDescription))
                return
            }

            self?.fetchLatestHeartRate()
        }

        observerQuery = query
        healthStore.execute(query)
    }

    private func fetchLatestHeartRate() {
        guard let healthStore, let heartRateType else {
            publish(state: .unavailable)
            return
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, error in
            guard let self else {
                return
            }

            if let error {
                self.publish(state: .failed(error.localizedDescription))
                return
            }

            guard let sample = samples?.first as? HKQuantitySample else {
                self.publishHeartRate(nil, sampleDate: nil, state: .noData)
                return
            }

            let unit = HKUnit.count().unitDivided(by: .minute())
            let beatsPerMinute = Int(sample.quantity.doubleValue(for: unit).rounded())
            self.publishHeartRate(beatsPerMinute, sampleDate: sample.endDate, state: .authorized)
        }

        latestSampleQuery = query
        healthStore.execute(query)
    }

    private func publishHeartRate(_ heartRate: Int?, sampleDate: Date?, state: HeartRateReadingState) {
        DispatchQueue.main.async { [weak self] in
            self?.latestHeartRate = heartRate
            self?.latestSampleDate = sampleDate
            self?.state = state
        }
    }

    private func publish(state: HeartRateReadingState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = state
        }
    }
}
