import SwiftUI

struct WorkoutCalendarView: View {
    @Binding var selectedDate: Date

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appStore: AppDataStore

    @State private var visibleMonth: Date

    private let calendar = Calendar.current
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _visibleMonth = State(initialValue: Calendar.current.startOfMonth(for: selectedDate.wrappedValue))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    AppTopBar(title: "운동 달력", showsBackButton: true, leadingAction: {
                        dismiss()
                    })

                    monthPicker
                    calendarGrid
                    selectedDateRecordsSection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var monthPicker: some View {
        HStack {
            AppIconButton(systemName: "chevron.left", backgroundColor: AppTheme.surface) {
                moveMonth(by: -1)
            }
            .accessibilityLabel("이전 달")

            Spacer()

            Text(monthTitle)
                .font(AppTheme.titleFont(24))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            AppIconButton(systemName: "chevron.right", backgroundColor: AppTheme.surface) {
                moveMonth(by: 1)
            }
            .accessibilityLabel("다음 달")
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 10) {
            HStack {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(AppTheme.bodyFont(12, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        Button {
                            selectedDate = date
                        } label: {
                            WorkoutCalendarDayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                recordCount: appStore.records(on: date).count
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 48)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var selectedDateRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateTitle)
                    .font(AppTheme.bodyFont(18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text("\(selectedDateRecords.count)개")
                    .font(AppTheme.bodyFont(13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if selectedDateRecords.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                    Text("운동 기록이 없어요")
                        .font(AppTheme.bodyFont(15, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)

                    Spacer()
                }
                .padding(14)
                .background(AppTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .stroke(AppTheme.hairline, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            } else {
                VStack(spacing: 10) {
                    ForEach(selectedDateRecords) { record in
                        NavigationLink {
                            WorkoutHistoryDetailView(record: record)
                        } label: {
                            WorkoutCalendarHistoryRow(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var selectedDateRecords: [WorkoutSessionRecord] {
        appStore.records(on: selectedDate)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: visibleMonth)
    }

    private var selectedDateTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "오늘 기록"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 기록"
        return formatter.string(from: selectedDate)
    }

    private var monthCells: [Date?] {
        let monthStart = calendar.startOfMonth(for: visibleMonth)
        let dayRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<1
        let leadingEmptyCells = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var cells = Array<Date?>(repeating: nil, count: leadingEmptyCells)

        for day in dayRange {
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = day
            cells.append(calendar.date(from: components))
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private func moveMonth(by offset: Int) {
        guard let nextMonth = calendar.date(byAdding: .month, value: offset, to: visibleMonth) else {
            return
        }

        visibleMonth = calendar.startOfMonth(for: nextMonth)
    }
}

private struct WorkoutCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let recordCount: Int

    var body: some View {
        VStack(spacing: 5) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(AppTheme.bodyFont(15, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : AppTheme.primaryText)

            Circle()
                .fill(isSelected ? Color.white.opacity(0.9) : AppTheme.primaryBlue)
                .frame(width: 4, height: 4)
                .opacity(recordCount > 0 ? 1 : 0)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(isSelected ? AppTheme.primaryBlue : AppTheme.recessedSurface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(isToday && !isSelected ? AppTheme.primaryBlue.opacity(0.7) : Color.clear, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct WorkoutCalendarHistoryRow: View {
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

                Text("\(record.exercises.count)개 운동 · \(completedSetCount)세트")
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
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}
