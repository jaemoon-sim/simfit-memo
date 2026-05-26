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

    var body: some View {
        HomeView()
            .environmentObject(appStore)
            .task {
                appStore.configure(modelContext: modelContext)
            }
    }
}
