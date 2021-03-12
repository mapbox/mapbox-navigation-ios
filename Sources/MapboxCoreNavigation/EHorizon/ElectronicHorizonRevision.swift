import Foundation
import MapboxNavigationNative

extension ElectronicHorizon {

    /** A value indicating the revision of the electronic horizon. */
    public enum Revision {

        /**
         The electronic horizon represents a new most probable path (MPP) being reported for the first time after being detected or reset.

         This value can occur due to three scenarios:
         - An electronic horizon is detected for the very first time.
         - A user location tracking error leads to an MPP completely distinct from the previous MPP.
         - The user has departed from the previous MPP, for example by driving to a side path of the previous MPP.
         */
        case initial

        /**
         The user has continued to follow the most probable path.
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
