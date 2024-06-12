import Foundation
import Turf

extension Feature {
    var featureIdentifier: Int64? {
        guard let featureIdentifier = identifier else { return nil }

        switch featureIdentifier {
        case .string(let identifier):
            return Int64(identifier)
        case .number(let identifier):
            return Int64(identifier)
        }
    }

    enum Property: String {
        case poiName = "name"
    }

    subscript(property key: Property, languageCode keySuffix: String?) -> JSONValue? {
        let jsonValue: JSONValue? = if let keySuffix, let value = properties?["\(key.rawValue)_\(keySuffix)"] {
            value
        } else {
            properties?[key.rawValue].flatMap { $0 }
        }
        return jsonValue
    }
}
