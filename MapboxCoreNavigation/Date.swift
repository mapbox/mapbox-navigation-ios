import Foundation

let ISO8601Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

extension Date {
    var ISO8601: String {
        return ISO8601Formatter.string(from: self)
    }
}
