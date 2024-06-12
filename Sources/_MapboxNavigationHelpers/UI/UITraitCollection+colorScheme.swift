import SwiftUI

extension ColorScheme {
    public var traitCollection: UITraitCollection {
        .init(userInterfaceStyle: .init(self))
    }
}

extension UITraitCollection {
    public var colorScheme: ColorScheme {
        switch userInterfaceStyle {
        case .dark:
            return .dark
        case .light:
            return .light
        case .unspecified:
            return .light
        @unknown default:
            return .light
        }
    }
}
