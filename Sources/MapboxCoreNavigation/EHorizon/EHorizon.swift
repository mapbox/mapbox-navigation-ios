import Foundation
import MapboxNavigationNative

public class EHorizon {

    public let start: EHorizonEdge

    init(_ native: ElectronicHorizon) {
        self.start = EHorizonEdge(native.start)
    }
}
