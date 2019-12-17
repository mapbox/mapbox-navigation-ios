import Foundation

extension Date {
    var ISO8601: String {
        return Date.ISO8601Formatter.string(from: self)
    }

    static let ISO8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
