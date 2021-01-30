import Foundation

extension Date {
    var ISO8601: String {
        return Date.ISO8601Formatter.string(from: self)
    }

    static let ISO8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    var nanosecondsSince1970: Double {
        // UnitDuration.nanoseconds requires iOS 13
        return timeIntervalSince1970 * 1e6
    }
}
