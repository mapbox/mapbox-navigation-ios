import Foundation
import MapboxNavigationNative

/// Contains information about routing and passing interchange along the route.
public struct Interchange: Equatable {
    /// The localized names of the interchange, if available.
    public let names: [LocalizedRoadObjectName]

    /// Initializes a new `Interchange` object.
    /// - Parameters:
    ///   - names: The localized names of the interchange.
    public init(names: [LocalizedRoadObjectName]) {
        self.names = names
    }

    init(_ icInfo: IcInfo) {
        let names = icInfo.name.map { LocalizedRoadObjectName($0) }
        self.init(names: names)
    }
}
