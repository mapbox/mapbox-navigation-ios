import Foundation
import OSLog
@_implementationOnly import MapboxCommon_Private.MBXLog_Internal

internal typealias Log = NavigationLog

/// :nodoc:
public struct NavigationLog {
    public typealias Category = NavigationLogCategory
    private typealias Logger = MapboxCommon_Private.Log

    public static func debug(_ message: String, category: Category) {
        Logger.debug(forMessage: message, category: category.rawLogCategory)
    }

    public static func info(_ message: String, category: Category) {
        Logger.info(forMessage: message, category: category.rawLogCategory)
    }

    public static func warning(_ message: String, category: Category) {
        Logger.warning(forMessage: message, category: category.rawLogCategory)
    }

    public static func error(_ message: String, category: Category) {
        Logger.error(forMessage: message, category: category.rawLogCategory)
    }

    public static func fault(_ message: String, category: Category) {
        let faultLog: OSLog = .init(subsystem: "com.mapbox.navigation", category: category.rawValue)
        os_log("%{public}@", log: faultLog, type: .fault, message)
        Logger.error(forMessage: message, category: category.rawLogCategory)
    }
}

/// :nodoc:
public struct NavigationLogCategory: RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let billing: Self = .init(rawValue: "billing")
    public static let navigation: Self = .init(rawValue: "navigation")
    public static let settings: Self = .init(rawValue: "settings")
    public static let unimplementedMethods: Self = .init(rawValue: "unimplemented-methods")

    public var rawLogCategory: String {
        "navigation-ios/\(rawValue)"
    }
}
