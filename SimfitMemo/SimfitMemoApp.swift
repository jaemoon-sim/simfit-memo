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
                syncWatchSnapshots()
            }
            .onChange(of: appStore.activeWorkout) { _, _ in
                watchSyncService.sendActiveWorkoutSnapshot(appStore.activeWorkout)
            }
            .onChange(of: appStore.routines) { _, routines in
                watchSyncService.sendRoutineSnapshot(routines)
            }
            .onChange(of: appStore.history) { _, history in
                watchSyncService.sendHistorySnapshot(history)
            }
    }

    private func syncWatchSnapshots() {
        watchSyncService.sendActiveWorkoutSnapshot(appStore.activeWorkout)
        watchSyncService.sendRoutineSnapshot(appStore.routines)
        watchSyncService.sendHistorySnapshot(appStore.history)
    }
}
