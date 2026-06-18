import Foundation

extension Double {
    func safeValue(default: Double = 0) -> Double {
        return isFinite ? self : `default`
    }
}
