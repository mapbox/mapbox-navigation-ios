import Foundation
import MapboxNavigationNative

/// Contains information about routing and passing interchange along the route.
public struct Interchange: Equatable {
    /// Interchange identifier, if available.
    public var identifier: String
    /// The localized names of the interchange, if available.
    public let names: [LocalizedRoadObjectName]

    /// Initializes a new `Interchange` object.
    /// - Parameters:
    ///   - names: The localized names of the interchange.
    public init(names: [LocalizedRoadObjectName]) {
        self.identifier = ""
        self.names = names
    }

    /// Initializes a new `Interchange` object.
    /// - Parameters:
    ///   - identifier: Interchange identifier.
    ///   - names: The localized names of the interchange.
    public init(identifier: String, names: [LocalizedRoadObjectName]) {
        self.identifier = identifier
        self.names = names
    }

    init(_ icInfo: IcInfo) {
        let names = icInfo.name.map { LocalizedRoadObjectName($0) }
        self.init(identifier: icInfo.id, names: names)
    }
}
