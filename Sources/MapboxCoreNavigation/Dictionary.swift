import Foundation

extension Dictionary where Value == Any {
    mutating func deepMerge(with dictionary: Dictionary) {
        merge(dictionary) { (current, new) in
            guard var currentDict = current as? Dictionary, let newDict = new as? Dictionary else {
                return current
            }
            currentDict.deepMerge(with: newDict)
            return currentDict
        }
    }
}
