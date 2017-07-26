import Foundation

extension String {
    var ISO8601Date: Date? {
        return DateFormatter.ISO8601.date(from: self)
    }
}
