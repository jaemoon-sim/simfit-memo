import SwiftUI

struct AppCheckbox: View {
    var isChecked: Bool
    var label: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isChecked ? AppTheme.primaryBlue : AppTheme.recessedSurface)
                        .frame(width: 22, height: 22)
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(isChecked ? AppTheme.primaryBlue : AppTheme.divider, lineWidth: 1)
                        }

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.white)
                    }
                }

                if let label {
                    Text(label)
                        .font(AppTheme.bodyFont(14, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}
