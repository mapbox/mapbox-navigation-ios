import Foundation
#if canImport(OSLog)
import OSLog
#endif

typealias Log = DirectionsLog

enum DirectionsLog {
    typealias Category = DirectionsLogCategory
    static let stderrLock = NSLock()

    static func debug(_ message: String, category: Category) {
        log(message, type: .debug, category: category)
    }

    static func info(_ message: String, category: Category) {
        log(message, type: .info, category: category)
    }

    static func error(_ message: String, category: Category) {
        log(message, type: .error, category: category)
    }

    static func fault(_ message: String, category: Category) {
        log(message, type: .fault, category: category)
    }

    private static func log(_ message: String, type: LogType, category: Category) {
        let logLevel = switch type {
        case .debug:
            "Debug"
        case .info:
            "Info"
        case .error:
            "Error"
        case .fault:
            "Fault"
        }
        let logMessage = "[\(logLevel)), directions]: \(message)"
#if canImport(OSLog)
        osLog(logMessage, type: type, category: category.rawValue)
#else
        stderrLog(logMessage)
#endif
    }

#if canImport(OSLog)
    private static func osLog(_ message: String, type: LogType, category: String) {
        let log: OSLog = .init(subsystem: "com.mapbox.directions-swift", category: category)
        os_log("%{public}@", log: log, type: type.osLogType, message)
    }
#endif

    private static func stderrLog(_ message: String) {
        DirectionsLog.stderrLock.lock()
        defer { DirectionsLog.stderrLock.unlock() }
        if let data = "\(message)\n".data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

extension DirectionsLog {
    enum LogType {
        case debug
        case info
        case error
        case fault
    }
}

#if canImport(OSLog)
extension DirectionsLog.LogType {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}
#endif

struct DirectionsLogCategory: RawRepresentable, Sendable {
    let rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let request: Self = .init(rawValue: "request")

    var rawLogCategory: String {
        "directions-swift/\(rawValue)"
    }
}
