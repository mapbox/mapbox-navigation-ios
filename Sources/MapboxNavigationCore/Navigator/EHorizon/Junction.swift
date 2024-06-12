import Foundation
import MapboxNavigationNative

/// Contains information about routing and passing junction along the route.
public struct Junction: Equatable {
    /// Junction identifier, if available.
    public var identifier: String
    /// The localized names of the junction, if available.
    public let names: [LocalizedRoadObjectName]

    /// Initializes a new `Junction` object.
    /// - Parameters:
    ///   - names: The localized names of the interchange.
    public init(names: [LocalizedRoadObjectName]) {
        self.identifier = ""
        self.names = names
    }

    /// Initializes a new `Junction` object.
    /// - Parameters:
    ///   - identifier: Junction identifier.
    ///   - names: The localized names of the interchange.
    public init(identifier: String, names: [LocalizedRoadObjectName]) {
        self.identifier = identifier
        self.names = names
    }

    init(_ jctInfo: JctInfo) {
        let names = jctInfo.name.map { LocalizedRoadObjectName($0) }
        self.init(identifier: jctInfo.id, names: names)
    }
}
