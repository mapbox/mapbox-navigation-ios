import CoreLocation
import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf
import MapboxMaps

extension NavigationMapView {
    
    public struct EdgeIntersection {
        var root: ElectronicHorizon.Edge
        var branch: ElectronicHorizon.Edge
        var rootMetadata: ElectronicHorizon.Edge.Metadata
        var rootShape: LineString
        var branchMetadata: ElectronicHorizon.Edge.Metadata
        var branchShape: LineString

        public var coordinate: CLLocationCoordinate2D? {
            branchShape.coordinates.first
        }

        public var annotationPoint: CLLocationCoordinate2D? {
            guard let length = branchShape.distance() else { return nil }
            let targetDistance = min(length / 2, Double.random(in: 15...30))
            guard let annotationPoint = branchShape.coordinateFromStart(distance: targetDistance) else { return nil }
            return annotationPoint
        }

        public var wayName: String? {
            guard let roadName = rootMetadata.names.first else { return nil }

            switch roadName {
            case .name(let name):
                return name
            case .code(let code):
                return "(\(code))"
            }
        }
        public var intersectingWayName: String? {
            guard let roadName = branchMetadata.names.first else { return nil }

            switch roadName {
            case .name(let name):
                return name
            case .code(let code):
                return "(\(code))"
            }
        }

        public var incidentAngle: CLLocationDegrees {
            return (branchMetadata.heading - rootMetadata.heading).wrap(min: 0, max: 360)
        }

        var description: String {
            return "EdgeIntersection: root: \(wayName ?? "") intersection: \(intersectingWayName ?? "") coordinate: \(String(describing: coordinate))"
        }
    }

    enum AnnotationTailPosition: Int {
        case left
        case right
        case center
    }

    class AnnotationCacheEntry: Equatable, Hashable {
        var wayname: String
        var coordinate: CLLocationCoordinate2D
        var intersection: EdgeIntersection?
        var feature: Feature
        var lastAccessTime: Date

        init(coordinate: CLLocationCoordinate2D, wayname: String, intersection: EdgeIntersection? = nil, feature: Feature) {
            self.wayname = wayname
            self.coordinate = coordinate
            self.intersection = intersection
            self.feature = feature
            self.lastAccessTime = Date()
        }

        static func == (lhs: AnnotationCacheEntry, rhs: AnnotationCacheEntry) -> Bool {
            return lhs.wayname == rhs.wayname
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(wayname.hashValue)
        }
    }

    class AnnotationCache {
        private let maxEntryAge = TimeInterval(30)
        var entries = Set<AnnotationCacheEntry>()
        var cachePruningTimer: Timer?

        init() {
            // periodically prune the cache to remove entries that have been passed already
            cachePruningTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak self] _ in
                self?.prune()
            })
        }

        deinit {
            cachePruningTimer?.invalidate()
            cachePruningTimer = nil
        }

        func setValue(feature: Feature, coordinate: CLLocationCoordinate2D, intersection: EdgeIntersection?, for wayname: String) {
            entries.insert(AnnotationCacheEntry(coordinate: coordinate, wayname: wayname, intersection: intersection, feature: feature))
        }

        func value(for wayname: String) -> AnnotationCacheEntry? {
            let matchingEntry = entries.first { entry -> Bool in
                entry.wayname == wayname
            }

            if let matchingEntry = matchingEntry {
                // update the timestamp used for pruning the cache
                matchingEntry.lastAccessTime = Date()
            }

            return matchingEntry
        }

        private func prune() {
            let now = Date()

            entries.filter { now.timeIntervalSince($0.lastAccessTime) > maxEntryAge }.forEach { remove($0) }
        }

        public func remove(_ entry: AnnotationCacheEntry) {
            entries.remove(entry)
        }
    }
}
