import Foundation
import MapboxNavigationNative

extension ElectronicHorizon {
    public enum ResultType {
        case initial
        case update

        init(_ native: ElectronicHorizonResultType) {
            switch (native) {
            case .INITIAL:
                self = .initial
            case .UPDATE:
                self = .update
            }
        }
    }
}
