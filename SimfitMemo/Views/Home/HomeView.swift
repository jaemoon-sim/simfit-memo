import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appStore: AppDataStore
    @EnvironmentObject private var watchSyncService: WatchSyncService

    @State private var isResting = false
    @State private var selectedDate = Date()
    @State private var isCalendarPresented = false
    @State private var navigationResetID = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        monthHeader
                        dateStrip
                        recordTitle
                        todayWorkoutCard
                        historySection
                        quickActionGrid
                        restAffordance
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, AppTheme.screenTopPadding)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .id(navigationResetID)
        .environment(\.resetToHome) {
            navigationResetID = UUID()
        }
        .sheet(isPresented: $isCalendarPresented) {
            NavigationStack {
                WorkoutCalendarView(selectedDate: $selectedDate)
            }
            .environmentObject(appStore)
            .preferredColorScheme(.dark)
            .presentationDetents([.large])
        }
        .preferredColorScheme(.dark)
    }

    private var exercises: [Exercise] {
        appStore.exercises
    }

    private var routines: [Routine] {
        appStore.routines
    }

    private var selectedDateRecords: [WorkoutSessionRecord] {
        appStore.records(on: selectedDate)
    }

    private var monthHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Calendar.current.component(.month, from: selectedDate))월")
                    .font(AppTheme.titleFont(30))
                    .foregroundStyle(AppTheme.primaryText)

                Text("오늘 할 운동을 빠르게 기록하세요")
                    .font(AppTheme.bodyFont(14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 6) {
                AppIconButton(systemName: "arrow.triangle.2.circlepath", backgroundColor: AppTheme.surface) {
                    syncWatchNow()
                }
                    .accessibilityLabel("Watch 동기화")

                AppIconButton(systemName: "calendar", backgroundColor: AppTheme.surface) {
                    isCalendarPresented = true
                }
                    .accessibilityLabel("달력")
            }
        }
    }

    private func syncWatchNow() {
        watchSyncService.sendFullSnapshot(
            activeWorkout: appStore.activeWorkout,
            routines: appStore.routines,
            history: appStore.history
        )
    }

    private var dateStrip: some View {
        HStack(spacing: 8) {
            ForEach(visibleDates, id: \.self) { date in
                Button {
                    selectedDate = date
                } label: {
                    DateStripItem(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasRecords: !appStore.records(on: date).isEmpty
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordTitle: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("운동 기록")
                .font(AppTheme.titleFont(28))
                .foregroundStyle(AppTheme.primaryText)

            Rectangle()
                .fill(AppTheme.primaryBlue)
                .frame(width: 70, height: 3)
                .clipShape(Capsule())
        }
        .padding(.top, 4)
    }

    private var todayWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text(selectedDateLabel)
                        .font(AppTheme.bodyFont(15, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)

                    Text(todayCardTitle)
                        .font(AppTheme.bodyFont(21, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.softBlue.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }

            if Calendar.current.isDateInToday(selectedDate) {
                HStack(spacing: 10) {
                    NavigationLink {
                        RoutineListView()
                    } label: {
                        OutlineButtonLabel(title: "불러오기", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.plain)

                    if appStore.activeWorkout == nil {
                        NavigationLink {
                            ExerciseSelectionView(exercises: exercises)
                        } label: {
                            PrimaryButtonLabel(title: "운동 선택하기", systemImage: "checklist")
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            WorkoutMemoView()
                        } label: {
                            PrimaryButtonLabel(title: "이어서 기록하기", systemImage: "pencil")
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Button {
                    selectedDate = Date()
                } label: {
                    OutlineButtonLabel(title: "오늘로 이동", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var todayCardTitle: String {
        if Calendar.current.isDateInToday(selectedDate), appStore.activeWorkout != nil {
            return "진행 중인 운동이 있어요"
        }

        if !selectedDateRecords.isEmpty {
            return "\(selectedDateRecords.count)개 운동 기록됨"
        }

        if Calendar.current.isDateInToday(selectedDate) {
            return "운동을 직접 계획해보세요!"
        }

        return "운동 기록이 없어요"
    }

    private var quickActionGrid: some View {
        NavigationLink {
            RoutineListView()
        } label: {
            HomeActionTile(
                title: "내 루틴",
                subtitle: "\(routines.count)개 저장됨",
                systemImage: "list.bullet.rectangle"
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var historySection: some View {
        if !selectedDateRecords.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(selectedDateLabel) 기록")
                        .font(AppTheme.bodyFont(17, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    Text("\(selectedDateRecords.count)개")
                        .font(AppTheme.bodyFont(13, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                VStack(spacing: 10) {
                    ForEach(selectedDateRecords) { record in
                        NavigationLink {
                            WorkoutHistoryDetailView(record: record)
                        } label: {
                            HomeHistoryRow(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var restAffordance: some View {
        Button {
            isResting.toggle()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isResting ? "pause.fill" : "timer")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                VStack(alignment: .leading, spacing: 4) {
                    Text("전체 휴식")
                        .font(AppTheme.bodyFont(16, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(isResting ? "휴식 타이머 준비됨" : "60초 휴식 타이머")
                        .font(AppTheme.bodyFont(13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            .padding(16)
            .background(AppTheme.recessedSurface)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(AppTheme.divider, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private var visibleDates: [Date] {
        (-3...3).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)
        }
    }

    private var selectedDateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "오늘"
        }

        if Calendar.current.isDateInYesterday(selectedDate) {
            return "어제"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: selectedDate)
    }
}

private struct DateStripItem: View {
    var date: Date
    var isSelected: Bool
    var hasRecords: Bool

    private var weekday: String {
        let symbols = ["일", "월", "화", "수", "목", "금", "토"]
        let index = Calendar.current.component(.weekday, from: date) - 1
        return symbols[index]
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(weekday)
                .font(AppTheme.bodyFont(12, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.secondaryText)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(AppTheme.bodyFont(17, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.primaryText)

            Circle()
                .fill(isSelected ? Color.white.opacity(0.9) : AppTheme.primaryBlue)
                .frame(width: 4, height: 4)
                .opacity(hasRecords ? 1 : 0)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(isSelected ? AppTheme.primaryBlue : AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct HomeActionTile: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 42, height: 42)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppTheme.bodyFont(17, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(AppTheme.bodyFont(13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
        .padding(16)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct HomeHistoryRow: View {
    let record: WorkoutSessionRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 42, height: 42)
                .background(AppTheme.softBlue.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.routineName ?? "자유 운동")
                    .font(AppTheme.bodyFont(15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Text("\(record.exercises.count)개 운동 · \(completedSetCount)세트 · \(dateText)")
                    .font(AppTheme.bodyFont(12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(14)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var completedSetCount: Int {
        record.exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completedAt != nil }.count
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: record.startedAt)
    }
}
