import Foundation

extension Dictionary where Key == Int, Value: MGLStyleValue<NSNumber> {
    /**
     Returns a proportional `Dictionary` of `lineWidthAtZoomLevels` at a specific factor.
     */
    public func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Int: MGLStyleValue<NSNumber>] = [:]
        for stop in lineWidthAtZoomLevels {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * factor
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }
        return newCameraStop as! Dictionary<Key, Value>
    }
}

