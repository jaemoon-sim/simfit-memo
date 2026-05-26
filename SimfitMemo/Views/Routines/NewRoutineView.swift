import SwiftUI

struct NewRoutineView: View {
    var exercises: [Exercise]

    @Environment(\.dismiss) private var dismiss
    @State private var routineName = ""

    private var canContinue: Bool {
        !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                AppTopBar(title: "새로운 루틴 만들기", showsBackButton: true, leadingAction: {
                    dismiss()
                })
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, AppTheme.screenTopPadding)

                VStack(alignment: .leading, spacing: 16) {
                    Text("루틴 이름을 정해주세요")
                        .font(AppTheme.titleFont(25))
                        .foregroundStyle(AppTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("운동 선택 후 세트 목표는 나중에 비워둘 수 있어요.")
                        .font(AppTheme.bodyFont(14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)

                    TextField("예: 월요일 상체", text: $routineName)
                        .font(AppTheme.bodyFont(17, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .tint(AppTheme.primaryBlue)
                        .padding(.horizontal, 16)
                        .frame(height: 54)
                        .background(AppTheme.recessedSurface)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                                .stroke(routineName.isEmpty ? AppTheme.divider : AppTheme.primaryBlue, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                        .submitLabel(.next)
                }
                .padding(.horizontal, AppTheme.horizontalPadding)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                OutlineButton(title: "이전 기록 보기", systemImage: "clock.arrow.circlepath") {}

                if canContinue {
                    NavigationLink {
                        ExerciseSelectionView(exercises: exercises, routineName: routineName)
                    } label: {
                        PrimaryButtonLabel(title: "운동 선택하기", systemImage: "checklist")
                    }
                    .buttonStyle(.plain)
                } else {
                    PrimaryButtonLabel(title: "운동 선택하기", systemImage: "checklist", isEnabled: false)
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        }
        .preferredColorScheme(.dark)
    }
}
