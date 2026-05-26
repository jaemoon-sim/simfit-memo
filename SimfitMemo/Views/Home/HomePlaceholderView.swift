import SwiftUI

struct HomePlaceholderView: View {
    private let seedService = ExerciseSeedService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        todayCard
                        quickActions
                        seedPreview
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("운동 기록")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            HStack(spacing: 8) {
                ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(day == "화" ? AppTheme.primaryText : AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(day == "화" ? AppTheme.primaryBlue : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
            }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("오늘 운동")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("운동을 직접 계획해보세요.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)

            HStack(spacing: 10) {
                Button("불러오기") {}
                    .buttonStyle(SecondaryActionButtonStyle())

                Button("운동 선택하기") {}
                    .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            ActionTile(title: "루틴 탐색", subtitle: "새 루틴 만들기")
            ActionTile(title: "내 루틴", subtitle: "저장한 운동")
        }
    }

    private var seedPreview: some View {
        let exercises = seedService.loadEmbeddedSeeds()

        return VStack(alignment: .leading, spacing: 12) {
            Text("기본 운동")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            ForEach(exercises) { exercise in
                HStack(spacing: 12) {
                    Text(exercise.bodyPart.displayName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 44, height: 28)
                        .background(AppTheme.elevatedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(exercise.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text(exercise.equipment ?? "장비 없음")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()
                }
                .padding(14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
        }
    }
}

private struct ActionTile: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(AppTheme.primaryBlue.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(AppTheme.primaryText)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(AppTheme.elevatedSurface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
