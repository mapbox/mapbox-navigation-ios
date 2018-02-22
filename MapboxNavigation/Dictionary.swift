import Foundation

extension Dictionary where Key == Int, Value: MGLStyleValue<NSNumber> {
    /**
     Returns a copy of the stop dictionary with each value multiplied by the given factor.
     */
    public func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Int: MGLStyleValue<NSNumber>] = [:]
        for stop in self as [Int : MGLStyleValue<NSNumber>] {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * factor
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }
        return newCameraStop as! Dictionary<Key, Value>
    }
}
