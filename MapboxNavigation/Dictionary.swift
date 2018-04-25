import Foundation

extension Dictionary where Key == Int, Value: NSExpression {
    /**
     Returns a copy of the stop dictionary with each value multiplied by the given factor.
     */
    public func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Int: NSExpression] = [:]
        for stop in self {
            let currentValue = stop.value.constantValue as! Double
            let newValue =  currentValue * factor
            newCameraStop[stop.key] = NSExpression(forConstantValue: newValue)
        }
        return newCameraStop as! Dictionary<Key, Value>
    }
}
