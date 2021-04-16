import Foundation

extension Date {
    public static func +(lhs: Date, rhs: Int) -> Date {
        return lhs.addingTimeInterval(TimeInterval(rhs))
    }
}
