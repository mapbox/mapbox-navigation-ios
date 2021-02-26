import Foundation
import MapboxNavigationNative

public enum EHorizonResultType {
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
