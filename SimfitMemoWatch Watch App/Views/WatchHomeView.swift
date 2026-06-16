import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var watchSyncService: WatchSyncService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        CurrentWorkoutView()
                    } label: {
                        HomeEntryRow(
                            title: "현재 운동",
                            subtitle: currentWorkoutSubtitle,
                            systemImage: "figure.strengthtraining.traditional"
                        )
                    }

                    NavigationLink {
                        RoutineListView()
                    } label: {
                        HomeEntryRow(
                            title: "루틴",
                            subtitle: "\(routineCount)개",
                            systemImage: "list.bullet.rectangle"
                        )
                    }

                    NavigationLink {
                        HistoryListView()
                    } label: {
                        HomeEntryRow(
                            title: "기록",
                            subtitle: "\(historyCount)개",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(connectionText)
                            .font(.caption)
                            .foregroundStyle(WatchTheme.primaryText)

                        if watchSyncService.pendingEventCount > 0 {
                            Text("대기 중인 완료 \(watchSyncService.pendingEventCount)개")
                                .font(.caption2)
                                .foregroundStyle(WatchTheme.secondaryText)
                        }
                    }

                    Button {
                        _ = watchSyncService.requestSync()
                    } label: {
                        Label("동기화", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(WatchTheme.primaryBlue)
                }
            }
            .navigationTitle("SimfitMemo")
            .scrollContentBackground(.hidden)
            .background(WatchTheme.background)
        }
    }

    private var currentWorkoutSubtitle: String {
        guard let state = watchSyncService.activeWorkoutSnapshot?.state else {
            return "진행 중인 운동 없음"
        }

        return state.routineName ?? "자유 운동 진행 중"
    }

    private var routineCount: Int {
        (watchSyncService.routineSnapshot?.routines ?? WatchMockData.routines).count
    }

    private var historyCount: Int {
        (watchSyncService.historySnapshot?.records ?? WatchMockData.history).count
    }

    private var connectionText: String {
        switch watchSyncService.connectionState {
        case .unavailable:
            return "WatchConnectivity 사용 불가"
        case .inactive:
            return "연결 준비 중"
        case .activated:
            return "최근 캐시 표시 중"
        case .reachable:
            return "iPhone 연결됨"
        case .failed:
            return "연결 오류"
        }
    }
}

private struct HomeEntryRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(WatchTheme.primaryBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(WatchTheme.primaryText)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
