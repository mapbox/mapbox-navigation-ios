import Foundation
import MapboxNavigationNative

public class ElectronicHorizon {

    public let start: Edge

    init(_ native: MapboxNavigationNative.ElectronicHorizon) {
        self.start = Edge(native.start)
    }
}
