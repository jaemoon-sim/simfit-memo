import SwiftUI

struct BottomSheetHeader: View {
    var title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppTheme.divider)
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            ZStack {
                Text(title)
                    .font(AppTheme.bodyFont(18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                    .padding(.horizontal, 72)

                HStack {
                    Spacer()

                    if let actionTitle {
                        Button(action: action ?? {}) {
                            Text(actionTitle)
                                .font(AppTheme.bodyFont(15, weight: .bold))
                                .foregroundStyle(AppTheme.primaryBlue)
                                .frame(minWidth: 52, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
