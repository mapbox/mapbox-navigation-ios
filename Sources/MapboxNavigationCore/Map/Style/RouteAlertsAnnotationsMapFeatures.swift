import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import MapboxNavigationNative
import enum SwiftUI.ColorScheme
import UIKit

struct RouteAlertsStyleContent: MapStyleContent {
    let source: GeoJSONSource
    let symbolLayer: SymbolLayer

    var body: some MapStyleContent {
        source
        symbolLayer
    }
}

extension NavigationRoutes {
    func routeAlertsAnnotationsMapFeatures(
        ids: FeatureIds.RouteAlertAnnotation,
        mapboxMap: MapboxMap,
        distanceTraveled: CLLocationDistance,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>,
        excludedRouteAlertTypes: RoadAlertType
    ) -> (RouteAlertsStyleContent, MapFeature)? {
        let convertedRouteAlerts = mainRoute.nativeRoute.getRouteInfo().alerts.map {
            RoadObjectAhead(
                roadObject: RoadObject($0.roadObject),
                distance: $0.distanceToStart
            )
        }

        return convertedRouteAlerts.routeAlertsAnnotationsMapFeatures(
            ids: ids,
            mapboxMap: mapboxMap,
            distanceTraveled: distanceTraveled,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider,
            excludedRouteAlertTypes: excludedRouteAlertTypes
        )
    }
}

extension [RoadObjectAhead] {
    func routeAlertsAnnotationsMapFeatures(
        ids: FeatureIds.RouteAlertAnnotation,
        mapboxMap: MapboxMap,
        distanceTraveled: CLLocationDistance,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>,
        excludedRouteAlertTypes: RoadAlertType
    ) -> (RouteAlertsStyleContent, MapFeature)? {
        guard !isEmpty else { return nil }

        let featureCollection = FeatureCollection(features: roadObjectsFeatures(
            for: self,
            currentDistance: distanceTraveled,
            excludedRouteAlertTypes: excludedRouteAlertTypes
        ))

        let source = GeoJsonMapFeature.Source(
            id: ids.source,
            geoJson: .featureCollection(featureCollection)
        )
        guard let sourceData = source.data() else { return nil }

        let layer = with(SymbolLayer(id: ids.layer, source: ids.source)) {
            $0.iconImage = .expression(Exp(.get) { RoadObjectInfo.objectImageType })
            $0.minZoom = 10

            $0.iconSize = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    Self.interpolationFactors.mapValues { $0 * 0.2 }
                }
            )

            $0.iconColor = .expression(Exp(.get) { RoadObjectInfo.objectColor })
        }
        let customizedLayer = customizedSymbolLayerProvider.customizedLayer(layer)
        Self.upsertRouteAlertsSymbolImages(map: mapboxMap)

        let content = RouteAlertsStyleContent(source: sourceData, symbolLayer: customizedLayer)

        let feature = GeoJsonMapFeature(
            id: ids.featureId,
            sources: [source],
            customizeSource: { _, _ in },
            layers: [customizedLayer],
            onBeforeAdd: { mapView in
                Self.upsertRouteAlertsSymbolImages(
                    map: mapView.mapboxMap
                )
            },
            onUpdate: { mapView in
                Self.upsertRouteAlertsSymbolImages(
                    map: mapView.mapboxMap
                )
            },
            onAfterRemove: { mapView in
                do {
                    try Self.removeRouteAlertSymbolImages(
                        from: mapView.mapboxMap
                    )
                } catch {
                    Log.error(
                        "Failed to remove route alerts annotation images with error \(error)",
                        category: .navigationUI
                    )
                }
            }
        )
        return (content, feature)
    }

    private static let interpolationFactors = [
        10.0: 1.0,
        14.5: 3.0,
        17.0: 6.0,
        22.0: 8.0,
    ]

    private func roadObjectsFeatures(
        for alerts: [RoadObjectAhead],
        currentDistance: CLLocationDistance,
        excludedRouteAlertTypes: RoadAlertType
    ) -> [Feature] {
        var features = [Feature]()
        for alert in alerts where !alert.isExcluded(excludedRouteAlertTypes: excludedRouteAlertTypes) {
            guard alert.distance == nil || alert.distance! >= currentDistance,
                  let objectInfo = info(for: alert.roadObject.kind)
            else { continue }
            let object = alert.roadObject
            func addImage(
                _ coordinate: LocationCoordinate2D,
                _ distance: LocationDistance?,
                color: UIColor? = nil
            ) {
                var feature = Feature(geometry: .point(.init(coordinate)))
                let identifier: FeatureIdentifier =
                    .string("road-alert-\(coordinate.latitude)-\(coordinate.longitude)-\(features.count)")
                let colorHex = (color ?? objectInfo.color ?? UIColor.gray).hexString
                let properties: [String: JSONValue?] = [
                    RoadObjectInfo.objectColor: JSONValue(rawValue: colorHex ?? UIColor.gray.hexString!),
                    RoadObjectInfo.objectImageType: .string(objectInfo.imageType.rawValue),
                    RoadObjectInfo.objectDistanceFromStart: .number(distance ?? 0.0),
                    RoadObjectInfo.distanceTraveled: .number(0.0),
                ]
                feature.properties = properties
                feature.identifier = identifier
                features.append(feature)
            }
            switch object.location {
            case .routeAlert(shape: .lineString(let shape)):
                guard
                    let startCoordinate = shape.coordinates.first,
                    let endCoordinate = shape.coordinates.last
                else {
                    break
                }

                if alert.distance.map({ $0 > 0 }) ?? true {
                    addImage(startCoordinate, alert.distance, color: .blue)
                }
                addImage(endCoordinate, alert.distance.map { $0 + (object.length ?? 0) }, color: .red)
            case .routeAlert(shape: .point(let point)):
                addImage(point.coordinates, alert.distance, color: nil)
            case .openLRPoint(position: _, sideOfRoad: _, orientation: _, coordinate: let coordinates):
                addImage(coordinates, alert.distance, color: nil)
            case .openLRLine(path: _, shape: let geometry):
                guard
                    let shape = openLRShape(from: geometry),
                    let startCoordinate = shape.coordinates.first,
                    let endCoordinate = shape.coordinates.last
                else {
                    break
                }
                if alert.distance.map({ $0 > 0 }) ?? true {
                    addImage(startCoordinate, alert.distance, color: .blue)
                }
                addImage(endCoordinate, alert.distance.map { $0 + (object.length ?? 0) }, color: .red)
            case .subgraph(enters: let enters, exits: let exits, shape: _, edges: _):
                for enter in enters {
                    addImage(enter.coordinate, nil, color: .blue)
                }
                for exit in exits {
                    addImage(exit.coordinate, nil, color: .red)
                }
            default:
                Log.error(
                    "Unexpected road object as Route Alert: \(object.identifier):\(object.kind)",
                    category: .navigationUI
                )
            }
        }
        return features
    }

    private func openLRShape(from geometry: Geometry) -> LineString? {
        switch geometry {
        case .point(let point):
            return .init([point.coordinates])
        case .lineString(let lineString):
            return lineString
        default:
            break
        }
        return nil
    }

    private func info(for objectKind: RoadObject.Kind) -> RoadObjectInfo? {
        switch objectKind {
        case .incident(let incident):
            let text = incident?.description
            let color = incident?.impact.map(color(for:))
            switch incident?.kind {
            case .congestion:
                return .init(.congestion, text: text, color: color)
            case .construction:
                return .init(.construction, text: text, color: color)
            case .roadClosure:
                return .init(.roadClosure, text: text, color: color)
            case .accident:
                return .init(.accident, text: text, color: color)
            case .disabledVehicle:
                return .init(.disabledVehicle, text: text, color: color)
            case .laneRestriction:
                return .init(.laneRestriction, text: text, color: color)
            case .massTransit:
                return .init(.massTransit, text: text, color: color)
            case .miscellaneous:
                return .init(.miscellaneous, text: text, color: color)
            case .otherNews:
                return .init(.otherNews, text: text, color: color)
            case .plannedEvent:
                return .init(.plannedEvent, text: text, color: color)
            case .roadHazard:
                return .init(.roadHazard, text: text, color: color)
            case .weather:
                return .init(.weather, text: text, color: color)
            case .undefined, .none:
                return nil
            }
        default:
            // We only show incidents on the map
            return nil
        }
    }

    private func color(for impact: Incident.Impact) -> UIColor {
        switch impact {
        case .critical:
            return .red
        case .major:
            return .purple
        case .minor:
            return .orange
        case .low:
            return .blue
        case .unknown:
            return .gray
        }
    }

    private static func upsertRouteAlertsSymbolImages(
        map: MapboxMap
    ) {
        for (imageName, imageIdentifier) in imageNameToMapIdentifier(ids: RoadObjectFeature.ImageType.allCases) {
            if let image = Bundle.mapboxNavigationUXCore.image(named: imageName) {
                map.provisionImage(id: imageIdentifier) { _ in
                    try map.addImage(image, id: imageIdentifier)
                }
            } else {
                assertionFailure("No image for route alert \(imageName) in the bundle.")
            }
        }
    }

    private static func removeRouteAlertSymbolImages(
        from map: MapboxMap
    ) throws {
        for (_, imageIdentifier) in imageNameToMapIdentifier(ids: RoadObjectFeature.ImageType.allCases) {
            try map.removeImage(withId: imageIdentifier)
        }
    }

    private static func imageNameToMapIdentifier(
        ids: [RoadObjectFeature.ImageType]
    ) -> [String: String] {
        return ids.reduce(into: [String: String]()) { partialResult, type in
            partialResult[type.imageName] = type.rawValue
        }
    }

    private struct RoadObjectFeature: Equatable {
        enum ImageType: String, CaseIterable {
            case accident
            case congestion
            case construction
            case disabledVehicle = "disabled_vehicle"
            case laneRestriction = "lane_restriction"
            case massTransit = "mass_transit"
            case miscellaneous
            case otherNews = "other_news"
            case plannedEvent = "planned_event"
            case roadClosure = "road_closure"
            case roadHazard = "road_hazard"
            case weather

            var imageName: String {
                switch self {
                case .accident:
                    return "ra_accident"
                case .congestion:
                    return "ra_congestion"
                case .construction:
                    return "ra_construction"
                case .disabledVehicle:
                    return "ra_disabled_vehicle"
                case .laneRestriction:
                    return "ra_lane_restriction"
                case .massTransit:
                    return "ra_mass_transit"
                case .miscellaneous:
                    return "ra_miscellaneous"
                case .otherNews:
                    return "ra_other_news"
                case .plannedEvent:
                    return "ra_planned_event"
                case .roadClosure:
                    return "ra_road_closure"
                case .roadHazard:
                    return "ra_road_hazard"
                case .weather:
                    return "ra_weather"
                }
            }
        }

        struct Image: Equatable {
            var id: String?
            var type: ImageType
            var coordinate: LocationCoordinate2D
            var color: UIColor?
            var text: String?
            var isOnMainRoute: Bool
        }

        struct Shape: Equatable {
            var geometry: Geometry
        }

        var id: String
        var images: [Image]
        var shape: Shape?
    }

    private struct RoadObjectInfo {
        var imageType: RoadObjectFeature.ImageType
        var text: String?
        var color: UIColor?

        init(_ imageType: RoadObjectFeature.ImageType, text: String? = nil, color: UIColor? = nil) {
            self.imageType = imageType
            self.text = text
            self.color = color
        }

        static let objectColor = "objectColor"
        static let objectImageType = "objectImageType"
        static let objectDistanceFromStart = "objectDistanceFromStart"
        static let distanceTraveled = "distanceTraveled"
    }
}

extension RoadObjectAhead {
    fileprivate func isExcluded(excludedRouteAlertTypes: RoadAlertType) -> Bool {
        guard let roadAlertType = RoadAlertType(roadObjectKind: roadObject.kind) else {
            return false
        }

        return excludedRouteAlertTypes.contains(roadAlertType)
    }
}
