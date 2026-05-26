import SwiftUI

struct HistoryListView: View {
    @EnvironmentObject private var watchSyncService: WatchSyncService

    private var records: [WorkoutSessionRecord] {
        watchSyncService.historySnapshot?.records ?? WatchMockData.history
    }

    var body: some View {
        List {
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.routineName ?? "자유 운동")
                        .font(.headline)
                        .foregroundStyle(WatchTheme.primaryText)
                        .lineLimit(2)

                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(WatchTheme.secondaryText)

                    Text(summary(for: record))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(WatchTheme.primaryBlue)
                        .lineLimit(1)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("기록")
        .scrollContentBackground(.hidden)
        .background(WatchTheme.background)
    }

    private func summary(for record: WorkoutSessionRecord) -> String {
        let setCount = record.exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completedAt != nil }.count
        }

        return "\(record.exercises.count)종목 · \(setCount)세트"
    }
}
