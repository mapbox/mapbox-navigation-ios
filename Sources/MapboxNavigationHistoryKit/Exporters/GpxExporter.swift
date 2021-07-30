import Foundation
import MapboxNavigationNative
import CoreGPX

public final class GpxExporter: Exporter {
    public private(set) var root: GPXRoot?
    private var waypoints: [GPXWaypoint] = []

    public init() {}

    public func start() {
        assert(root == nil)
        assert(waypoints.isEmpty)

        root = .init(creator: "Mapbox")
    }

    public func append(_ record: HistoryRecord) {
        guard let location = record.updateLocation?.location else { return }

        let coordinate = location.coordinate

        let waypoint = GPXWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        waypoint.elevation = location.altitude?.doubleValue
        waypoint.time = location.time
        waypoint.horizontalDilution = location.accuracyHorizontal?.doubleValue
        waypoint.verticalDilution = location.verticalAccuracy?.doubleValue
        waypoints.append(waypoint)
    }

    public func end() -> String {
        guard let root = root else {
            preconditionFailure();
        }
        root.add(waypoints: waypoints)
        let gpx = root.gpx()
        self.root = nil
        waypoints = []
        return gpx
    }
}

extension Exporter where Self == GpxExporter {
    public static var gpx: GpxExporter {
        .init()
    }
}
