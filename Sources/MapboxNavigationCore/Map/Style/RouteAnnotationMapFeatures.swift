import _MapboxNavigationHelpers
import CoreLocation
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

/// Describes the possible annotation types on the route line.
public enum RouteAnnotationKind {
    /// Shows the route duration.
    case routeDurations
    /// Shows the relative diff between the main route and the alternative.
    /// The annotation is displayed in the approximate middle of the alternative steps.
    case relativeDurationsOnAlternative
    /// Shows the relative diff between the main route and the alternative.
    /// The annotation is displayed next to the first different maneuver of the alternative road.
    case relativeDurationsOnAlternativeManuever
}

extension NavigationRoutes {
    func routeDurationMapFeatures(
        ids: FeatureIds.RouteAnnotations,
        annotationKinds: Set<RouteAnnotationKind>,
        visibleBoundingBox: BoundingBox,
        pointForCoordinate: (LocationCoordinate2D) -> CGPoint,
        mapBounds: CGRect,
        config: MapStyleConfig,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [any MapFeature] {
        var sources: [GeoJsonMapFeature.Source] = []
        var layers: [any Layer] = []

        for annotationKind in annotationKinds {
            switch annotationKind {
            case .routeDurations, .relativeDurationsOnAlternative:
                if let routeDurationSource = routeDurationSource(
                    ids: ids,
                    annotationKind: annotationKind,
                    pointForCoordinate: pointForCoordinate,
                    mapBounds: mapBounds,
                    config: config
                ) {
                    sources.append(routeDurationSource)
                    let id = routeDurationSource.id
                    layers.append(routeDurationLayer(id: id, sourceId: id, config: config))
                }
            case .relativeDurationsOnAlternativeManuever:
                if config.showsAlternatives, let relativeDurationSource = alternativesRelativeSource(
                    ids: ids,
                    offset: 75,
                    pointForCoordinate: pointForCoordinate,
                    mapBounds: mapBounds
                ) {
                    sources.append(relativeDurationSource)
                    let id = relativeDurationSource.id
                    layers.append(routeDurationLayer(id: id, sourceId: id, config: config))
                }
            }
        }

        guard !sources.isEmpty else { return [] }

        return [
            GeoJsonMapFeature(
                id: ids.featureId,
                sources: sources,
                customizeSource: { _, _ in },
                layers: layers.map { customizedLayerProvider.customizedLayer($0) },
                onBeforeAdd: { mapView in
                    mapView.mapboxMap.provisionImage(id: ids.routeAnnotationLeftHandedImage) { map in
                        try map.addRouteDurationAnnotationImageToStyle(
                            .leading,
                            imageId: ids.routeAnnotationLeftHandedImage,
                            imageName: "RouteInfoAnnotationLeftHanded",
                            config: config
                        )
                    }
                    mapView.mapboxMap.provisionImage(id: ids.routeAnnotationRightHandedImage) { style in
                        try style.addRouteDurationAnnotationImageToStyle(
                            .leading,
                            imageId: ids.routeAnnotationRightHandedImage,
                            imageName: "RouteInfoAnnotationRightHanded",
                            config: config
                        )
                    }
                },
                onUpdate: { _ in },
                onAfterRemove: { mapView in
                    do {
                        try mapView.mapboxMap.removeImage(withId: ids.routeAnnotationLeftHandedImage)
                        try mapView.mapboxMap.removeImage(withId: ids.routeAnnotationRightHandedImage)
                    } catch {
                        Log.error(
                            "Failed to remove route annotation images with error \(error)", category: .navigationUI
                        )
                    }
                }
            ),
        ]
    }

    private func routeDurationSource(
        ids: FeatureIds.RouteAnnotations,
        annotationKind: RouteAnnotationKind,
        pointForCoordinate: (LocationCoordinate2D) -> CGPoint,
        mapBounds: CGRect,
        config: MapStyleConfig
    ) -> GeoJsonMapFeature.Source? {
        let routes = alternativeRoutes.lazy.map(\.route)

        let tollRoutes = routes.filter {
            ($0.tollIntersections?.count ?? 0) > 0
        }
        let routesContainTolls = tollRoutes.count > 0

        var features = [Turf.Feature]()

        // Run through our heuristic algorithm looking for a good coordinate along each route line
        // to place it's route annotation.
        // First, we will look for a set of RouteSteps unique to each route.
        var excludedSteps = [RouteStep]()
        var allRoutes = [mainRoute.route]
        if config.showsAlternatives {
            allRoutes += alternativeRoutes.map { $0.route }
        }
        for (index, route) in allRoutes.enumerated() {
            let allSteps = route.legs.flatMap(\.steps)
            let alternateSteps = allSteps.filter { !excludedSteps.contains($0) }

            excludedSteps.append(contentsOf: alternateSteps)

            var coordinate: CLLocationCoordinate2D?

            // Obtain a polyline of the set of steps. We'll look for a good spot along this line to
            // place the annotation.
            // We will consider a good spot to be somewhere near the middle of the line, making sure
            // that the coordinate is visible on-screen.
            if let continuousLine = alternateSteps.continuousShape(),
               continuousLine.coordinates.count > 0
            {
                coordinate = continuousLine.coordinates[0]

                // Pick a coordinate using some randomness in order to give visual variety.
                // Take care to snap that coordinate to one that lays on the original route line.
                // If the chosen snapped coordinate is not visible on the screen, then we walk back
                // along the route coordinates looking for one that is.
                // If none of the earlier points are on screen then we walk forward along the route
                // coordinates until we find one that is.
                let random: CLLocationDistance = getRandomNumber(in: 0.4..<0.6)
                if let distance = continuousLine.distance(),
                   let sampleCoordinate = continuousLine
                       .indexedCoordinateFromStart(distance: distance * random)?
                       .coordinate,
                       let routeShape = route.shape,
                       let snappedCoordinate = routeShape.closestCoordinate(to: sampleCoordinate)
                {
                    coordinate = snappedCoordinate.coordinate
                }
            }

            guard let annotationCoordinate = coordinate else { continue }

            // Form the appropriate text string for the annotation.
            let labelText: String
            if annotationKind == .routeDurations {
                labelText = annotationLabelForRoute(route, tolls: routesContainTolls)
            } else if index > 0 {
                let alternativeRoute = alternativeRoutes[index - 1]
                labelText = annotationLabelForAlternativeRoute(alternativeRoute, tolls: routesContainTolls)
            } else {
                continue
            }

            let feature = composeCalloutFeature(
                ids: .default,
                annotationCoordinate: annotationCoordinate,
                pointForCoordinate: pointForCoordinate,
                mapBounds: mapBounds,
                labelText: labelText,
                index: index,
                isSelected: index == 0
            )
            features.append(feature)
        }

        return .init(id: annotationKind.sourceId, geoJson: .featureCollection(.init(features: features)))
    }

    private func routeDurationLayer(
        id: String,
        sourceId: String,
        config: MapStyleConfig
    ) -> some Layer {
        with(SymbolLayer(id: id, source: sourceId)) {
            $0.textField = .expression(Exp(.get) {
                "text"
            })
            $0.iconImage = .expression(Exp(.get) {
                "imageName"
            })
            $0.textColor = .expression(Exp(.switchCase) {
                Exp(.any) {
                    Exp(.get) {
                        "selected"
                    }
                }
                config.routeAnnotationSelectedTextColor
                config.routeAnnotationTextColor
            })
            $0.textSize = .constant(16)
            $0.iconTextFit = .constant(IconTextFit.both)
            $0.iconAllowOverlap = .constant(true)
            $0.textAllowOverlap = .constant(true)
            $0.textJustify = .constant(TextJustify.left)
            $0.symbolZOrder = .constant(SymbolZOrder.auto)
            $0.symbolSortKey = .expression(Exp(.get) {
                "sortOrder"
            })
            let anchorExpression = Exp(.match) {
                Exp(.get) { "tailPosition" }
                0
                "bottom-left"
                1
                "bottom-right"
                "center"
            }
            $0.iconAnchor = .expression(anchorExpression)
            $0.textAnchor = .expression(anchorExpression)
            let offsetExpression = Exp(.match) {
                Exp(.get) { "tailPosition" }
                0
                Exp(.literal) { [0.7, -1.7] }
                Exp(.literal) { [-0.7, -1.7] }
            }
            $0.iconOffset = .expression(offsetExpression)
            $0.textOffset = .expression(offsetExpression)
        }
    }

    private func composeCalloutFeature(
        ids: FeatureIds.RouteAnnotations,
        annotationCoordinate: LocationCoordinate2D,
        pointForCoordinate: (LocationCoordinate2D) -> CGPoint,
        mapBounds: CGRect,
        labelText: String,
        index: Int,
        isSelected: Bool
    ) -> Feature {
        // Create the feature for this route annotation. Set the styling attributes that will be
        // used to render the annotation in the style layer.
        var feature = Feature(geometry: .point(Point(annotationCoordinate)))

        // Pick a random tail direction to keep things varied.
        var tailPosition: RouteDurationAnnotationTailPosition = getRandomNumber(in: 0..<1) > 0.5 ? .leading : .trailing

        // Convert our coordinate to screen space so we can make a choice on which side of the
        // coordinate the label ends up on.
        let unprojectedCoordinate = pointForCoordinate(annotationCoordinate)

        // Pick the orientation of the bubble "stem" based on how close to the edge of the screen it is.
        if tailPosition == .leading, unprojectedCoordinate.x > mapBounds.width * 0.75 {
            tailPosition = .trailing
        } else if tailPosition == .trailing, unprojectedCoordinate.x < mapBounds.width * 0.25 {
            tailPosition = .leading
        }

        var imageName = tailPosition == .leading
            ? ids.routeAnnotationLeftHandedImage
            : ids.routeAnnotationRightHandedImage

        // The selected route uses the colored annotation image.
        if isSelected {
            imageName += "-Selected"
        }

        // Set the feature attributes which will be used in styling the symbol style layer.
        feature.properties = [
            "selected": .boolean(isSelected),
            "tailPosition": .number(Double(tailPosition.rawValue)),
            "text": .string(labelText),
            "imageName": .string(imageName),
            "sortOrder": .number(Double(isSelected ? index : -index)),
            "routeIndex": .number(Double(index)),
        ]

        return feature
    }

    /// Generate the text for the label to be shown on screen. It will include estimated duration
    /// and info on Tolls, if applicable.
    private func annotationLabelForRoute(_ route: Route, tolls: Bool) -> String {
        let eta = DateComponentsFormatter.noCommaShortDateComponentsFormatter
            .string(from: route.expectedTravelTime) ?? ""

        return tollAnnotationForLabel(on: route, tolls: tolls, label: eta)
    }

    private func tollAnnotationForLabel(on route: Route?, tolls: Bool, label: String) -> String {
        var labelWithTolls = label
        let hasTolls = (route?.tollIntersections?.count ?? 0) > 0
        if hasTolls {
            labelWithTolls += "\n" + "Tolls"
            if let symbol = Locale.current.currencySymbol {
                labelWithTolls += " " + symbol
            }
        } else if tolls {
            // If one of the routes has tolls, but this one does not then it needs to explicitly say that it has no
            // tolls. If no routes have tolls at all then we can omit this portion of the string.
            labelWithTolls += "\n" + "No Tolls"
        }

        return labelWithTolls
    }

    /// Generate the text for the label to be shown on screen. It will include estimated duration delta relative to the
    /// main route and info on Tolls, if applicable.
    private func annotationLabelForAlternativeRoute(_ alternativeRoute: AlternativeRoute, tolls: Bool) -> String {
        let timeDelta: String = if abs(alternativeRoute.expectedTravelTimeDelta) >= 180 {
            DateComponentsFormatter.travelTimeString(
                alternativeRoute.expectedTravelTimeDelta,
                signed: true
            )
        } else {
            "SAME_TIME".localizedString(
                value: "Similar ETA",
                comment: "Alternatives selection note about equal travel time."
            )
        }

        return tollAnnotationForLabel(
            on: alternativeRoute.route,
            tolls: tolls,
            label: timeDelta
        )
    }

    func alternativesRelativeSource(
        ids: FeatureIds.RouteAnnotations,
        offset: LocationDistance,
        pointForCoordinate: (LocationCoordinate2D) -> CGPoint,
        mapBounds: CGRect
    ) -> GeoJsonMapFeature.Source? {
        guard !alternativeRoutes.isEmpty else { return nil }

        let tollRoutes = alternativeRoutes.filter { route -> Bool in
            (route.route.tollIntersections?.count ?? 0) > 0
        }
        let routesContainTolls = tollRoutes.count > 0

        var features = [Turf.Feature]()

        for (index, alternativeRoute) in alternativeRoutes.enumerated() {
            let annotationCoordinate = alternativeRoute.route
                .shape?
                .trimmed(
                    from: alternativeRoute.alternativeRouteIntersection.location,
                    distance: offset
                )?.coordinates.last
            guard let annotationCoordinate else {
                continue
            }

            // Form the appropriate text string for the annotation.
            let labelText = annotationLabelForAlternativeRoute(
                alternativeRoute,
                tolls: routesContainTolls
            )

            let feature = composeCalloutFeature(
                ids: ids,
                annotationCoordinate: annotationCoordinate,
                pointForCoordinate: pointForCoordinate,
                mapBounds: mapBounds,
                labelText: labelText,
                index: index + 1,
                isSelected: false
            )

            features.append(feature)
        }

        return .init(
            id: ids.relativeDurationOnAlternativeManuever,
            geoJson: .featureCollection(.init(features: features))
        )
    }

    func getRandomNumber(in range: Range<Double>) -> Double {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // No randomness in unit tests
            return range.lowerBound / 2 + range.upperBound / 2
        } else {
            return Double.random(in: range)
        }
    }
}

extension MapboxMap {
    fileprivate func addRouteDurationAnnotationImageToStyle(
        _ tailPosition: RouteDurationAnnotationTailPosition,
        imageId: String,
        imageName: String,
        config: MapStyleConfig
    ) throws {
        let capInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 35.0, right: 15.0)

        // In case if image was already added to the style - do not add it.
        guard let image = Bundle.module.image(named: imageName)?.resizableImage(withCapInsets: capInsets)
        else { return }

        let scale = Float(image.scale)

        // Define the "stretchable" areas in the image that will be fitted to the text label.
        // These numbers are the pixel offsets into the PDF image asset.
        let stretchXFirst = Float(image.capInsets.left) * scale
        let stretchXSecond = Float(image.size.width - image.capInsets.right) * scale
        let stretchYFirst = Float(image.capInsets.top) * scale
        let stretchYSecond = Float(image.size.height - image.capInsets.bottom) * scale

        let contentInsets = UIEdgeInsets(top: 10.0, left: 15.0, bottom: 35.0, right: 15.0)
        let contentBoxLeft = Float(contentInsets.left) * scale
        let contentBoxRight = Float(image.size.width - contentInsets.right) * scale
        let contentBoxTop = Float(contentInsets.top) * scale
        let contentBoxBottom = Float(image.size.height - contentInsets.bottom) * scale

        let contentBox = ImageContent(
            left: contentBoxLeft,
            top: contentBoxTop,
            right: contentBoxRight,
            bottom: contentBoxBottom
        )

        let stretchX = [
            ImageStretches(first: stretchXFirst, second: stretchXSecond),
        ]

        let stretchY = [
            ImageStretches(first: stretchYFirst, second: stretchYSecond),
        ]

        let regularAnnotationImage = image.tint(config.routeAnnotationColor)
        try addImage(
            regularAnnotationImage,
            id: imageId,
            stretchX: stretchX,
            stretchY: stretchY,
            content: contentBox
        )

        let selectedImageId = imageId.appending("-Selected")
        let selectedImage = image.tint(config.routeAnnotationSelectedColor)
        try addImage(
            selectedImage,
            id: selectedImageId,
            stretchX: stretchX,
            stretchY: stretchY,
            content: contentBox
        )
    }
}

extension RouteAnnotationKind {
    fileprivate var sourceId: String {
        let ids = FeatureIds.RouteAnnotations.default
        switch self {
        case .relativeDurationsOnAlternative:
            return ids.relativeDurationOnAlternative
        case .relativeDurationsOnAlternativeManuever:
            return ids.relativeDurationOnAlternativeManuever
        case .routeDurations:
            return ids.routeDuration
        }
    }
}
