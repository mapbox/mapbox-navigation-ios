import Foundation

extension Dictionary where Value == Any {
    mutating func deepMerge(with dictionary: Dictionary, uniquingKeysWith combine: @escaping (Value, Value) -> Value) {
        merge(dictionary) { (current, new) in
            guard var currentDict = current as? Dictionary, let newDict = new as? Dictionary else {
                return combine(current, new)
            }
            currentDict.deepMerge(with: newDict, uniquingKeysWith: combine)
            return currentDict
        }
    }
}
