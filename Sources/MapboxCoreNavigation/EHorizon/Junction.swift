import Foundation
import MapboxNavigationNative

/// Contains information about routing and passing junction along the route.
public struct Junction: Equatable {
    /// The localized names of the junction, if available.
    public let names: [LocalizedRoadObjectName]

    /// Initializes a new `Junction` object.
    /// - Parameters:
    ///   - names: The localized names of the interchange.
    public init(names: [LocalizedRoadObjectName]) {
        self.names = names
    }

    init(_ jctInfo: JctInfo) {
        let names = jctInfo.name.map { LocalizedRoadObjectName($0) }
        self.init(names: names)
    }
}
