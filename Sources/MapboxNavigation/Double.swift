import Foundation

extension Double {
    
    func round(_ fraction: Int) -> Double {
        let multiplier = pow(10, Double(fraction))
        return Darwin.round(self * multiplier) / multiplier
    }
}
