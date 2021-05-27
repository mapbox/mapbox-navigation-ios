import CoreLocation
import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf
import MapboxMaps
import MapboxNavigationNative

extension NavigationMapView {
    
    public struct EdgeIntersection {
        var root: RoadGraph.Edge
        var branch: RoadGraph.Edge
        var rootMetadata: RoadGraph.Edge.Metadata
        var rootShape: LineString
        var branchMetadata: RoadGraph.Edge.Metadata
        var branchShape: LineString

        public var coordinate: CLLocationCoordinate2D? {
            branchShape.coordinates.first
        }

        public var annotationPoint: CLLocationCoordinate2D? {
            guard let length = branchShape.distance() else { return nil }
            let targetDistance = min(length / 2, Double(30))
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

        public var angle: CLLocationDegrees {
            return (branchMetadata.heading).wrap(min: 0, max: 360)
        }

        public var description: String {
            return "EdgeIntersection: root: \(wayName ?? "") intersection: \(intersectingWayName ?? "") coordinate: \(String(describing: coordinate))"
        }

        public var feature: Feature? {
            guard let coordinate = annotationPoint else { return nil }
            var featurePoint = Feature(Point(coordinate))
            let tailPosition = incidentAngle < 180 ? AnnotationTailPosition.left : AnnotationTailPosition.right

            let imageName = tailPosition == .left ? "AnnotationLeftHanded" : "AnnotationRightHanded"

            // set the feature attributes which will be used in styling the symbol style layer
            featurePoint.properties = ["highlighted": false, "tailPosition": tailPosition.rawValue, "text": intersectingWayName, "imageName": imageName]

            return featurePoint
        }
    }

    enum AnnotationTailPosition: Int {
        case left
        case right
        case center
    }
}

extension RouteStep {
    var annotationLabel: String {
        var label = names?.first ?? ""

        if label.count == 0, let destinationCodes = destinationCodes, destinationCodes.count > 0 {
            label = destinationCodes[0]

            destinationCodes.dropFirst().forEach { destination in
                label += " / " + destination
            }
        } else if label.count == 0, let exitCodes = exitCodes, let code = exitCodes.first {
            label = "Exit \(code)"
        } else if label.count == 0, let destination = destinations?.first {
            label = destination
        } else if label.count == 0, let exitName = exitNames?.first {
            label = exitName
        } else if label.count == 0 {
            label = instructions.description
        }

        return label
    }

    var annotationFeature: Feature {
        var featurePoint = Feature(Point(maneuverLocation))

        let tailPosition = NavigationMapView.AnnotationTailPosition.center

        featurePoint.properties = ["highlighted": true, "tailPosition": tailPosition.rawValue, "text": self.annotationLabel, "imageName": "AnnotationCentered-Highlighted", "sortOrder": 0]

        return featurePoint
    }
}
