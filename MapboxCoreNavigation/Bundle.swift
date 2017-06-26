import Foundation

extension Bundle {
    var backgroundModeLocationSupported: Bool {
        get {
            if let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
                return modes.contains("location")
            }
            return false
        }
    }
}
