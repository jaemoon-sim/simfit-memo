import SwiftUI

@main
struct SimfitMemoWatchApp: App {
    @StateObject private var watchSyncService = WatchSyncService()
    @StateObject private var heartRateService = HealthKitHeartRateService()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(watchSyncService)
                .environmentObject(heartRateService)
        }
    }
}
