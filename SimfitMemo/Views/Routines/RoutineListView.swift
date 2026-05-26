import SwiftUI

struct RoutineListView: View {
    var providedRoutines: [Routine]?
    var providedExercises: [Exercise]?

    @EnvironmentObject private var appStore: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRoutine: Routine?
    @State private var editingRoutine: Routine?
    @State private var showsWorkoutMemo = false
    @State private var sortOption = RoutineSortOption.recent

    init(routines: [Routine]? = nil, exercises: [Exercise]? = nil) {
        self.providedRoutines = routines
        self.providedExercises = exercises
    }

    private var routines: [Routine] {
        providedRoutines ?? appStore.routines
    }

    private var exercises: [Exercise] {
        providedExercises ?? appStore.exercises
    }

    private var sortedRoutines: [Routine] {
        switch sortOption {
        case .recent:
            return routines.sorted { lhs, rhs in
                (lhs.lastPerformedAt ?? lhs.updatedAt) > (rhs.lastPerformedAt ?? rhs.updatedAt)
            }
        case .name:
            return routines.sorted { $0.name < $1.name }
        case .completed:
            return routines.sorted { $0.completedCount > $1.completedCount }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    banner
                    listHeader

                    VStack(spacing: 12) {
                        ForEach(sortedRoutines) { routine in
                            RoutineCard(
                                routine: routine,
                                onTap: {
                                    selectedRoutine = routine
                                },
                                onEdit: {
                                    editingRoutine = routine
                                },
                                onDuplicate: {
                                    appStore.duplicateRoutine(id: routine.id)
                                },
                                onDelete: {
                                    appStore.deleteRoutine(id: routine.id)
                                }
                            )
                        }
                    }

                    if sortedRoutines.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, AppTheme.screenTopPadding)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sheet(item: $selectedRoutine) { routine in
            RoutineDetailSheet(
                routine: currentRoutine(matching: routine) ?? routine,
                startAction: {
                    let latestRoutine = currentRoutine(matching: routine) ?? routine
                    appStore.startWorkout(from: latestRoutine)
                    selectedRoutine = nil
                    showsWorkoutMemo = true
                },
                editAction: {
                    editingRoutine = currentRoutine(matching: routine) ?? routine
                    selectedRoutine = nil
                }
            )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(AppTheme.sheetRadius)
                .presentationBackground(AppTheme.background)
        }
        .navigationDestination(isPresented: $showsWorkoutMemo) {
            WorkoutMemoView()
        }
        .navigationDestination(isPresented: editingRoutineBinding) {
            if let editingRoutine {
                RoutineTargetEditorView(routine: currentRoutine(matching: editingRoutine) ?? editingRoutine)
            }
        }
    }

    private var editingRoutineBinding: Binding<Bool> {
        Binding(
            get: { editingRoutine != nil },
            set: { isPresented in
                if !isPresented {
                    editingRoutine = nil
                }
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText)
            Text("저장된 루틴이 없어요")
                .font(AppTheme.bodyFont(16, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
            NavigationLink {
                NewRoutineView(exercises: exercises)
            } label: {
                PrimaryButtonLabel(title: "새 루틴 만들기", systemImage: "plus")
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func currentRoutine(matching routine: Routine) -> Routine? {
        routines.first { $0.id == routine.id }
    }

    private var topBar: some View {
        ZStack {
            AppTopBar(title: "루틴", showsBackButton: true, leadingAction: {
                dismiss()
            })

            HStack {
                Spacer()

                NavigationLink {
                    NewRoutineView(exercises: exercises)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("새 루틴")
            }
        }
    }

    private var banner: some View {
        NavigationLink {
            NewRoutineView(exercises: exercises)
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("나만의 루틴 만들기")
                        .font(AppTheme.bodyFont(19, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text("운동을 고르고 기록 흐름을 준비하세요")
                        .font(AppTheme.bodyFont(14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            .padding(18)
            .background(AppTheme.blueBannerGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private var listHeader: some View {
        HStack {
            Text("전체 \(routines.count)개")
                .font(AppTheme.bodyFont(15, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            Menu {
                ForEach(RoutineSortOption.allCases) { option in
                    Button(option.title) {
                        sortOption = option
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(sortOption.title)
                        .font(AppTheme.bodyFont(14, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(AppTheme.secondaryText)
                .frame(minHeight: 44)
            }
        }
    }
}

private enum RoutineSortOption: String, CaseIterable, Identifiable {
    case recent
    case name
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent:
            return "최근 수행순"
        case .name:
            return "이름순"
        case .completed:
            return "완료 많은순"
        }
    }
}
