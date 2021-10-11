import Foundation
import Turf

extension Feature {

    var featureIdentifier: Int64? {
        guard let featureIdentifier = self.identifier else { return nil }
        
        switch featureIdentifier {
        case .string(let identifier):
            return Int64(identifier)
        case .number(let identifier):
            return Int64(identifier)
        }
    }
}
