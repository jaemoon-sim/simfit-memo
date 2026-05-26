import SwiftUI

struct ExerciseSelectionView: View {
    var routineName: String?

    @Environment(\.dismiss) private var dismiss
    @State private var availableExercises: [Exercise]
    @State private var selectedExerciseIDs: Set<UUID> = []
    @State private var bookmarkedExerciseIDs: Set<UUID>
    @State private var searchText = ""
    @State private var selectedBodyPart: BodyPart?
    @State private var bookmarkOnly = false
    @State private var sortOption = ExerciseSortOption.recommended
    @State private var infoExercise: Exercise?
    @State private var showsCustomExerciseSheet = false
    @State private var showsSelectionConfirmation = false

    init(exercises: [Exercise], routineName: String? = nil) {
        self.routineName = routineName
        _availableExercises = State(initialValue: exercises)
        _bookmarkedExerciseIDs = State(initialValue: Set(exercises.filter(\.isBookmarked).map(\.id)))
    }

    private var filteredExercises: [Exercise] {
        var result = availableExercises

        if let selectedBodyPart {
            result = result.filter { $0.bodyPart == selectedBodyPart }
        }

        if bookmarkOnly {
            result = result.filter { bookmarkedExerciseIDs.contains($0.id) }
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            result = result.filter { exercise in
                exercise.displayName.localizedCaseInsensitiveContains(trimmedSearch)
                    || exercise.name.localizedCaseInsensitiveContains(trimmedSearch)
                    || exercise.bodyPart.displayName.localizedCaseInsensitiveContains(trimmedSearch)
                    || (exercise.equipment ?? "").localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        switch sortOption {
        case .recommended:
            return result
        case .name:
            return result.sorted { $0.displayName < $1.displayName }
        case .recent:
            return result.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    AppTopBar(title: routineName ?? "운동 선택", showsBackButton: true) {
                        dismiss()
                    }

                    AppSearchField(placeholder: "운동 검색", text: $searchText)

                    categoryChips
                    filterRow
                    exerciseList
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, AppTheme.screenTopPadding)
                .padding(.bottom, 104)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            StickyBottomActionBar(
                leadingAccessibilityLabel: "커스텀 운동 추가",
                primaryTitle: selectedExerciseIDs.isEmpty ? "운동을 선택해주세요" : "\(selectedExerciseIDs.count)개 운동 추가하기",
                primarySystemImage: "checkmark",
                isPrimaryEnabled: !selectedExerciseIDs.isEmpty,
                leadingAction: { showsCustomExerciseSheet = true },
                primaryAction: { showsSelectionConfirmation = true }
            )
        }
        .sheet(isPresented: $showsCustomExerciseSheet) {
            CustomExerciseSheet { name, bodyPart in
                let customExercise = Exercise(
                    name: name,
                    localizedName: name,
                    bodyPart: bodyPart,
                    primaryMuscles: [bodyPart.displayName],
                    equipment: "사용자 지정",
                    category: "custom",
                    isCustom: true
                )
                availableExercises.insert(customExercise, at: 0)
                selectedExerciseIDs.insert(customExercise.id)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(AppTheme.sheetRadius)
            .presentationBackground(AppTheme.background)
        }
        .alert(item: $infoExercise) { exercise in
            Alert(
                title: Text(exercise.displayName),
                message: Text("\(exercise.bodyPart.displayName) · \(exercise.equipment ?? "장비 없음")"),
                dismissButton: .default(Text("확인"))
            )
        }
        .alert("선택 완료", isPresented: $showsSelectionConfirmation) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("\(selectedExerciseIDs.count)개 운동을 선택했습니다.")
        }
        .preferredColorScheme(.dark)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "전체", systemImage: nil, isSelected: selectedBodyPart == nil) {
                    selectedBodyPart = nil
                }

                ForEach(BodyPart.plannedFilterCategories) { bodyPart in
                    CategoryChip(title: bodyPart.displayName, systemImage: nil, isSelected: selectedBodyPart == bodyPart) {
                        selectedBodyPart = bodyPart
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var filterRow: some View {
        HStack {
            AppCheckbox(isChecked: bookmarkOnly, label: "북마크만 보기") {
                bookmarkOnly.toggle()
            }

            Spacer()

            Menu {
                ForEach(ExerciseSortOption.allCases) { option in
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

    private var exerciseList: some View {
        VStack(spacing: 10) {
            ForEach(filteredExercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    isSelected: selectedExerciseIDs.contains(exercise.id),
                    isBookmarked: bookmarkedExerciseIDs.contains(exercise.id),
                    selectionAction: { toggleSelection(for: exercise) },
                    bookmarkAction: { toggleBookmark(for: exercise) },
                    infoAction: { infoExercise = exercise }
                )
            }

            if filteredExercises.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.tertiaryText)
                    Text("조건에 맞는 운동이 없어요")
                        .font(AppTheme.bodyFont(15, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
        }
    }

    private func toggleSelection(for exercise: Exercise) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
    }

    private func toggleBookmark(for exercise: Exercise) {
        if bookmarkedExerciseIDs.contains(exercise.id) {
            bookmarkedExerciseIDs.remove(exercise.id)
        } else {
            bookmarkedExerciseIDs.insert(exercise.id)
        }
    }
}

private enum ExerciseSortOption: String, CaseIterable, Identifiable {
    case recommended
    case name
    case recent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recommended:
            return "기본순"
        case .name:
            return "이름순"
        case .recent:
            return "최근 사용순"
        }
    }
}

private struct CustomExerciseSheet: View {
    var onAdd: (String, BodyPart) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var bodyPart = BodyPart.other

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                BottomSheetHeader(title: "커스텀 운동", actionTitle: nil)

                VStack(alignment: .leading, spacing: 12) {
                    Text("운동 이름")
                        .font(AppTheme.bodyFont(14, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)

                    TextField("예: 케이블 플라이", text: $name)
                        .font(AppTheme.bodyFont(17, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .tint(AppTheme.primaryBlue)
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(AppTheme.recessedSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                                .stroke(AppTheme.divider, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }

                Menu {
                    ForEach(BodyPart.plannedFilterCategories + [.other]) { part in
                        Button(part.displayName) {
                            bodyPart = part
                        }
                    }
                } label: {
                    HStack {
                        Text("부위")
                            .font(AppTheme.bodyFont(15, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)

                        Spacer()

                        Text(bodyPart.displayName)
                            .font(AppTheme.bodyFont(15, weight: .bold))
                            .foregroundStyle(AppTheme.secondaryText)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }

                Spacer()

                HStack(spacing: 10) {
                    OutlineButton(title: "취소") {
                        dismiss()
                    }

                    PrimaryButton(title: "추가하기", isEnabled: canAdd) {
                        onAdd(name.trimmingCharacters(in: .whitespacesAndNewlines), bodyPart)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.bottom, 18)
        }
        .preferredColorScheme(.dark)
    }
}
