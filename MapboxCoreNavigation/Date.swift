import Foundation

extension Date {
    var ISO8601: String {
        return DateFormatter.ISO8601.string(from: self)
    }
}

extension DateFormatter {
    class var ISO8601: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
