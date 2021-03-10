import Foundation
import MapboxNavigationNative

extension ElectronicHorizon {

    /** Result type */
    public enum ResultType {

        /**
         State will be `initial` for the first `ElectronicHorizon` and after its reset.
         This represents a new MPP.

         These are possible scenarios:
         - The very first Electronic Horizon generation
         - Localization error which leads to a completely separate MPP from the previous
         - Deviate from the previous MPP, i.e. driving to the side path of the previous MPP
         */
        case initial

        /**
         State will be `update` for continuation of the `ElectronicHorizon`.
         */
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
