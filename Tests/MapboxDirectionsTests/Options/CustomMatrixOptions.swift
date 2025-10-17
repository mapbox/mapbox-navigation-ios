#if !os(Linux)
@testable import MapboxDirections
#if canImport(CoreLocation)
import CoreLocation
#endif

final class CustomMatrixOptions: MatrixOptions {
    var customParameters: [URLQueryItem]

    init(
        sources: [Waypoint],
        destinations: [Waypoint],
        profileIdentifier: ProfileIdentifier,
        customParameters: [URLQueryItem] = []
    ) {
        self.customParameters = customParameters

        super.init(sources: sources, destinations: destinations, profileIdentifier: profileIdentifier)
    }

    override var urlQueryItems: [URLQueryItem] {
        var combined = super.urlQueryItems
        combined.append(contentsOf: customParameters)
        return combined
    }

    required init(from decoder: any Decoder) throws {
        self.customParameters = []
        try super.init(from: decoder)
    }
}
#endif
