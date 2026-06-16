import SwiftUI
import SwiftData

@main
struct SimfitMemoApp: App {
    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: PersistedAppSnapshot.self)
        } catch {
            fatalError("Failed to create SimfitMemo model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(modelContainer)
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appStore = AppDataStore()
    @StateObject private var watchSyncService = WatchSyncService()
    @StateObject private var liveActivityService = WorkoutLiveActivityService()

    var body: some View {
        HomeView()
            .environmentObject(appStore)
            .environmentObject(watchSyncService)
            .task {
                appStore.configure(modelContext: modelContext)
                watchSyncService.onSetCompletion = { event in
                    appStore.applyWatchSetCompletion(event)
                    syncWatchSnapshots()
                }
                watchSyncService.onRestAdjustment = { event in
                    appStore.applyWatchRestAdjustment(event)
                    syncWatchSnapshots()
                }
                watchSyncService.onSyncRequest = { _ in
                    syncWatchSnapshots()
                }
                syncWatchSnapshots()
                liveActivityService.sync(with: appStore.activeWorkout)
            }
            .onChange(of: appStore.activeWorkout) { _, _ in
                syncWatchSnapshots()
                liveActivityService.sync(with: appStore.activeWorkout)
            }
            .onChange(of: appStore.routines) { _, _ in
                syncWatchSnapshots()
            }
            .onChange(of: appStore.history) { _, _ in
                syncWatchSnapshots()
            }
    }

    private func syncWatchSnapshots() {
        watchSyncService.sendFullSnapshot(
            activeWorkout: appStore.activeWorkout,
            routines: appStore.routines,
            history: appStore.history
        )
    }
}
