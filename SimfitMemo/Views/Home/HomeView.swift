import SwiftUI

struct HomeView: View {
    private let exercises = MockFitnessData.exercises
    private let routines = MockFitnessData.routines

    @State private var isResting = false

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
        .preferredColorScheme(.dark)
    }

    private var monthHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Calendar.current.component(.month, from: Date()))월")
                    .font(AppTheme.titleFont(30))
                    .foregroundStyle(AppTheme.primaryText)

                Text("오늘 할 운동을 빠르게 기록하세요")
                    .font(AppTheme.bodyFont(14, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 6) {
                AppIconButton(systemName: "calendar", backgroundColor: AppTheme.surface) {}
                    .accessibilityLabel("달력")
                AppIconButton(systemName: "line.3.horizontal", backgroundColor: AppTheme.surface) {}
                    .accessibilityLabel("메뉴")
            }
        }
    }

    private var dateStrip: some View {
        HStack(spacing: 8) {
            ForEach(visibleDates, id: \.self) { date in
                DateStripItem(date: date, isSelected: Calendar.current.isDateInToday(date))
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
                    Text("오늘")
                        .font(AppTheme.bodyFont(15, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("운동을 직접 계획해보세요!")
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

            HStack(spacing: 10) {
                NavigationLink {
                    RoutineListView(routines: routines, exercises: exercises)
                } label: {
                    OutlineButtonLabel(title: "불러오기", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ExerciseSelectionView(exercises: exercises)
                } label: {
                    PrimaryButtonLabel(title: "운동 선택하기", systemImage: "checklist")
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

    private var quickActionGrid: some View {
        HStack(spacing: 12) {
            NavigationLink {
                NewRoutineView(exercises: exercises)
            } label: {
                HomeActionTile(
                    title: "루틴 탐색",
                    subtitle: "새 루틴 만들기",
                    systemImage: "square.grid.2x2"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RoutineListView(routines: routines, exercises: exercises)
            } label: {
                HomeActionTile(
                    title: "내 루틴",
                    subtitle: "\(routines.count)개 저장됨",
                    systemImage: "list.bullet.rectangle"
                )
            }
            .buttonStyle(.plain)
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
                    Text(isResting ? "휴식 타이머 준비됨" : "90초 휴식 타이머")
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
            Calendar.current.date(byAdding: .day, value: offset, to: Date())
        }
    }
}

private struct DateStripItem: View {
    var date: Date
    var isSelected: Bool

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
        }
        .frame(maxWidth: .infinity, minHeight: 68)
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
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
