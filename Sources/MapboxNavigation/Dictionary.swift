import Foundation

extension Dictionary where Key == Double, Value == Double {
    /**
     Returns a copy of the stop dictionary with each value multiplied by the given factor.
     */
    public func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Double: Double] = [:]
        for stop in self {
            let newValue =  stop.value * factor
            newCameraStop[stop.key] = newValue
        }
        return newCameraStop
    }
}
