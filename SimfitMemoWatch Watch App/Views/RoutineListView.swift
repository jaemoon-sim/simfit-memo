import SwiftUI

struct RoutineListView: View {
    @EnvironmentObject private var watchSyncService: WatchSyncService

    private var routines: [Routine] {
        watchSyncService.routineSnapshot?.routines ?? WatchMockData.routines
    }

    var body: some View {
        List {
            ForEach(routines) { routine in
                VStack(alignment: .leading, spacing: 6) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(WatchTheme.primaryText)
                        .lineLimit(2)

                    Text(summary(for: routine))
                        .font(.caption2)
                        .foregroundStyle(WatchTheme.secondaryText)
                        .lineLimit(2)

                    if routine.completedCount > 0 {
                        Text("완료 \(routine.completedCount)회")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WatchTheme.primaryBlue)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("루틴")
        .scrollContentBackground(.hidden)
        .background(WatchTheme.background)
    }

    private func summary(for routine: Routine) -> String {
        guard routine.exercises.isEmpty == false else {
            return "운동 없음"
        }

        let bodyParts = Array(Set(routine.exercises.map(\.bodyPart.displayName))).sorted()
        let setCount = routine.exercises.reduce(0) { $0 + $1.setTargets.count }
        return "\(bodyParts.joined(separator: " · ")) · \(routine.exercises.count)종목 · \(setCount)세트"
    }
}
