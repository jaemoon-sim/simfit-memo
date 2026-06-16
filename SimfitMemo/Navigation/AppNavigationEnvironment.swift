import SwiftUI

private struct ResetToHomeKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var resetToHome: () -> Void {
        get { self[ResetToHomeKey.self] }
        set { self[ResetToHomeKey.self] = newValue }
    }
}
