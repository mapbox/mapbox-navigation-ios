import Foundation

enum AppEnvironment {
    static var applicationMode: String {
#if DEBUG
        return "mbx-debug"
#else
        return "mbx-prod"
#endif
    }

    static let applicationSessionId = UUID().uuidString // Unique per application launch
}

// MARK: - Version resolving

extension AppEnvironment {
    private static let infoPlistShortVersionKey = "CFBundleShortVersionString"

    enum SDK {
        case navigation
        case navigationNative
    }

    static func hostApplicationVersion() -> String {
        Bundle.main.infoDictionary?[infoPlistShortVersionKey] as? String ?? "unknown"
    }
}
