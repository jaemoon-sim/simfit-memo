import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.07)
    static let backgroundElevated = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let surface = Color(red: 0.09, green: 0.11, blue: 0.15)
    static let elevatedSurface = Color(red: 0.12, green: 0.15, blue: 0.20)
    static let recessedSurface = Color(red: 0.07, green: 0.085, blue: 0.11)
    static let primaryBlue = Color(red: 0.05, green: 0.42, blue: 1.00)
    static let primaryBluePressed = Color(red: 0.03, green: 0.31, blue: 0.82)
    static let softBlue = Color(red: 0.13, green: 0.29, blue: 0.56)
    static let success = Color(red: 0.16, green: 0.78, blue: 0.48)
    static let warning = Color(red: 1.00, green: 0.70, blue: 0.20)
    static let primaryText = Color(red: 0.96, green: 0.98, blue: 1.00)
    static let secondaryText = Color(red: 0.56, green: 0.64, blue: 0.74)
    static let tertiaryText = Color(red: 0.40, green: 0.47, blue: 0.57)
    static let divider = Color(red: 0.20, green: 0.25, blue: 0.33)
    static let hairline = Color(red: 0.14, green: 0.18, blue: 0.24)

    static let cardRadius: CGFloat = 8
    static let sheetRadius: CGFloat = 30
    static let controlHeight: CGFloat = 46
    static let bottomBarHeight: CGFloat = 74

    static let horizontalPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 14

    static func titleFont(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold)
    }

    static func bodyFont(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static var blueBannerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.32, blue: 0.86),
                Color(red: 0.07, green: 0.47, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
