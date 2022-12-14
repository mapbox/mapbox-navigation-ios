import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf

extension NavigationMapView {
    
    // MARK: Route Duration Annotations
    
    /**
     Shows a callout containing the relative duration to the primary route of each continuous alternative route.
     Useful as a way to give the user more information when picking between multiple route alternatives.
     If the route contains any tolled segments then the callout will specify that as well.
     */
    public func showContinuousAlternativeRoutesDurations() {
        // Remove any existing route annotation.
        removeContinuousAlternativeRoutesDurations()
        
        guard showsRelativeDurationOnContinuousAlternativeRoutes,
              let visibleRoutes = continuousAlternatives, visibleRoutes.count > 0 else { return }
        
        do {
            try updateAnnotationSymbolImages()
        } catch {
            Log.error("Error occured while updating annotation symbol images: \(error.localizedDescription).",
                      category: .navigationUI)
        }
        
        updateContinuousAlternativeRoutesDurations(along: visibleRoutes)
    }
    
    /**
     Updates the image assets in the map style for the route duration annotations. Useful when the
     desired callout colors change, such as when transitioning between light and dark mode on iOS 13 and later.
     */
    func updateAnnotationSymbolImages() throws {
        try addRouteDurationAnnotationImageToStyle(.leading)
        try addRouteDurationAnnotationImageToStyle(.trailing)
    }
    
    func addRouteDurationAnnotationImageToStyle(_ tailPosition: RouteDurationAnnotationTailPosition) throws {
        let style = mapView.mapboxMap.style
        
        let routeDurationAnnotationImageIdentifier: String
        switch tailPosition {
        case .leading:
            routeDurationAnnotationImageIdentifier = ImageIdentifier.routeAnnotationLeftHanded
        case .trailing:
            routeDurationAnnotationImageIdentifier = ImageIdentifier.routeAnnotationRightHanded
        }
        
        let capInsets = UIEdgeInsets(top: 15.0, left: 15.0, bottom: 35.0, right: 15.0)
        
        // In case if image was already added to the style - do not add it.
        guard style.image(withId: routeDurationAnnotationImageIdentifier) == nil,
              let routeDurationAnnotationImage = Bundle.mapboxNavigation.image(named: routeDurationAnnotationImageIdentifier)?.resizableImage(withCapInsets: capInsets) else { return }
        
        let scale = Float(routeDurationAnnotationImage.scale)
        
        // Define the "stretchable" areas in the image that will be fitted to the text label.
        // These numbers are the pixel offsets into the PDF image asset.
        let stretchXFirst = Float(routeDurationAnnotationImage.capInsets.left) * scale
        let stretchXSecond = Float(routeDurationAnnotationImage.size.width - routeDurationAnnotationImage.capInsets.right) * scale
        let stretchYFirst = Float(routeDurationAnnotationImage.capInsets.top) * scale
        let stretchYSecond = Float(routeDurationAnnotationImage.size.height - routeDurationAnnotationImage.capInsets.bottom) * scale
        
        let contentInsets = UIEdgeInsets(top: 10.0, left: 15.0, bottom: 35.0, right: 15.0)
        let contentBoxLeft = Float(contentInsets.left) * scale
        let contentBoxRight = Float(routeDurationAnnotationImage.size.width - contentInsets.right) * scale
        let contentBoxTop = Float(contentInsets.top) * scale
        let contentBoxBottom = Float(routeDurationAnnotationImage.size.height - contentInsets.bottom) * scale
        
        let contentBox = ImageContent(left: contentBoxLeft,
                                      top: contentBoxTop,
                                      right: contentBoxRight,
                                      bottom: contentBoxBottom)
        
        let stretchX = [
            ImageStretches(first: stretchXFirst, second: stretchXSecond)
        ]
        
        let stretchY = [
            ImageStretches(first: stretchYFirst, second: stretchYSecond)
        ]
        
        let regularAnnotationImage = routeDurationAnnotationImage.tint(routeDurationAnnotationColor)
        try style.addImage(regularAnnotationImage,
                           id: routeDurationAnnotationImageIdentifier,
                           stretchX: stretchX,
                           stretchY: stretchY,
                           content: contentBox)
        
        let selectedRouteDurationAnnotationImageIdentifier = routeDurationAnnotationImageIdentifier.appending("-Selected")
        let selectedAnnotationImage = routeDurationAnnotationImage.tint(routeDurationAnnotationSelectedColor)
        try style.addImage(selectedAnnotationImage,
                           id: selectedRouteDurationAnnotationImageIdentifier,
                           stretchX: stretchX,
                           stretchY: stretchY,
                           content: contentBox)
    }
    
    private func updateContinuousAlternativeRoutesDurations(along alternativeRoutes: [AlternativeRoute]?) {
        guard let routes = alternativeRoutes else { return }
        
        let tollRoutes = routes.filter { route -> Bool in
            return (route.indexedRouteResponse.currentRoute?.tollIntersections?.count ?? 0) > 0
        }
        let routesContainTolls = tollRoutes.count > 0
        
        var features = [Turf.Feature]()
        
        for (index, alternativeRoute) in routes.enumerated() {
            guard let routeShape = alternativeRoute.indexedRouteResponse.currentRoute?.shape,
                  let annotationCoordinate = routeShape.indexedCoordinateFromStart(distance: alternativeRoute.infoFromOrigin.distance
                                                                                   - alternativeRoute.infoFromDeviationPoint.distance
                                                                                   + continuousAlternativeDurationAnnotationOffset)?.coordinate else {
                return
            }
            
            // Form the appropriate text string for the annotation.
            let labelText = self.annotationLabelForAlternativeRoute(alternativeRoute,
                                                                    tolls: routesContainTolls)
            
            let feature = composeCalloutFeature(annotationCoordinate: annotationCoordinate,
                                                labelText: labelText,
                                                index: index,
                                                isSelected: false)
            
            features.append(feature)
        }
        
        // Add the features to the style.
        do {
            try addRouteAnnotationSymbolLayer(features: FeatureCollection(features: features),
                                              sourceIdentifier: NavigationMapView.SourceIdentifier.continuousAlternativeRoutesDurationAnnotationsSource,
                                              layerIdentifier: NavigationMapView.LayerIdentifier.continuousAlternativeRoutesDurationAnnotationsLayer)
        } catch {
            NSLog("Error occured while adding route annotation symbol layer: \(error.localizedDescription).")
        }
    }
    
    /**
     Remove any old route duration callouts and generate new ones for each passed in route.
     */
    func updateRouteDurations(along routes: [Route]?) {
        // Remove any existing route annotation.
        removeRouteDurations()
        
        guard let routes = routes else { return }
        
        let coordinateBounds = mapView.mapboxMap.coordinateBounds(for: mapView.frame)
        let visibleBoundingBox = BoundingBox(southWest: coordinateBounds.southwest, northEast: coordinateBounds.northeast)
        
        let tollRoutes = routes.filter { route -> Bool in
            return (route.tollIntersections?.count ?? 0) > 0
        }
        let routesContainTolls = tollRoutes.count > 0
        
        var features = [Turf.Feature]()
        
        // Run through our heuristic algorithm looking for a good coordinate along each route line
        // to place it's route annotation.
        // First, we will look for a set of RouteSteps unique to each route.
        var excludedSteps = [RouteStep]()
        for (index, route) in routes.enumerated() {
            let allSteps = route.legs.flatMap { return $0.steps }
            let alternateSteps = allSteps.filter { !excludedSteps.contains($0) }
            
            excludedSteps.append(contentsOf: alternateSteps)
            let visibleAlternateSteps = alternateSteps.filter { $0.intersects(visibleBoundingBox) }
            
            var coordinate: CLLocationCoordinate2D?
            
            // Obtain a polyline of the set of steps. We'll look for a good spot along this line to
            // place the annotation.
            // We will consider a good spot to be somewhere near the middle of the line, making sure
            // that the coordinate is visible on-screen.
            if let continuousLine = visibleAlternateSteps.continuousShape(),
                continuousLine.coordinates.count > 0 {
                coordinate = continuousLine.coordinates[0]
                
                // Pick a coordinate using some randomness in order to give visual variety.
                // Take care to snap that coordinate to one that lays on the original route line.
                // If the chosen snapped coordinate is not visible on the screen, then we walk back
                // along the route coordinates looking for one that is.
                // If none of the earlier points are on screen then we walk forward along the route
                // coordinates until we find one that is.
                if let distance = continuousLine.distance(),
                    let sampleCoordinate = continuousLine.indexedCoordinateFromStart(distance: distance * CLLocationDistance.random(in: 0.3...0.8))?.coordinate,
                    let routeShape = route.shape,
                    let snappedCoordinate = routeShape.closestCoordinate(to: sampleCoordinate) {
                    var foundOnscreenCoordinate = false
                    var firstOnscreenCoordinate = snappedCoordinate.coordinate
                    for indexedCoordinate in routeShape.coordinates.prefix(through: snappedCoordinate.index).reversed() {
                        if visibleBoundingBox.contains(indexedCoordinate) {
                            firstOnscreenCoordinate = indexedCoordinate
                            foundOnscreenCoordinate = true
                            break
                        }
                    }
                    
                    if foundOnscreenCoordinate {
                        // We found a point that is both on the route and on-screen.
                        coordinate = firstOnscreenCoordinate
                    } else {
                        // We didn't find a previous point that is on-screen so we'll move forward
                        // through the coordinates looking for one.
                        for indexedCoordinate in routeShape.coordinates.suffix(from: snappedCoordinate.index) {
                            if visibleBoundingBox.contains(indexedCoordinate) {
                                firstOnscreenCoordinate = indexedCoordinate
                                break
                            }
                        }
                        coordinate = firstOnscreenCoordinate
                    }
                }
            }
            
            guard let annotationCoordinate = coordinate else { return }
            
            // Form the appropriate text string for the annotation.
            let labelText = annotationLabelForRoute(route, tolls: routesContainTolls)
            
            
            let feature = composeCalloutFeature(annotationCoordinate: annotationCoordinate,
                                                labelText: labelText,
                                                index: index,
                                                isSelected: index == 0)
            features.append(feature)
        }
        
        // Add the features to the style.
        do {
            try addRouteAnnotationSymbolLayer(features: FeatureCollection(features: features),
                                              sourceIdentifier: NavigationMapView.SourceIdentifier.routeDurationAnnotationsSource,
                                              layerIdentifier: NavigationMapView.LayerIdentifier.routeDurationAnnotationsLayer)
        } catch {
            Log.error("Error occured while adding route annotation symbol layer: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    /**
     Add the MGLSymbolStyleLayer for the route duration annotations.
     */
    private func addRouteAnnotationSymbolLayer(features: FeatureCollection,
                                               sourceIdentifier: String,
                                               layerIdentifier: String) throws {
        let style = mapView.mapboxMap.style
        
        if style.sourceExists(withId: sourceIdentifier) {
            try style.updateGeoJSONSource(withId: sourceIdentifier, geoJSON: .featureCollection(features))
        } else {
            var dataSource = GeoJSONSource()
            dataSource.data = .featureCollection(features)
            try style.addSource(dataSource, id: sourceIdentifier)
        }
        
        var shapeLayer: SymbolLayer
        if style.layerExists(withId: layerIdentifier),
           let symbolLayer = try style.layer(withId: layerIdentifier) as? SymbolLayer {
            shapeLayer = symbolLayer
        } else {
            shapeLayer = SymbolLayer(id: layerIdentifier)
        }
        
        shapeLayer.source = sourceIdentifier
        
        shapeLayer.textField = .expression(Exp(.get) {
            "text"
        })
        
        shapeLayer.iconImage = .expression(Exp(.get) {
            "imageName"
        })
        
        shapeLayer.textColor = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "selected"
                }
            }
            routeDurationAnnotationSelectedTextColor
            routeDurationAnnotationTextColor
        })
        
        shapeLayer.textSize = .constant(16)
        shapeLayer.iconTextFit = .constant(IconTextFit.both)
        shapeLayer.iconAllowOverlap = .constant(true)
        shapeLayer.textAllowOverlap = .constant(true)
        shapeLayer.textJustify = .constant(TextJustify.left)
        shapeLayer.symbolZOrder = .constant(SymbolZOrder.auto)
        shapeLayer.textFont = .constant(self.routeDurationAnnotationFontNames)
        
        shapeLayer.symbolSortKey = .expression(Exp(.get) {
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
        shapeLayer.iconAnchor = .expression(anchorExpression)
        shapeLayer.textAnchor = .expression(anchorExpression)
        
        let offsetExpression = Exp(.match) {
            Exp(.get) { "tailPosition" }
            0
            Exp(.literal) { [0.5, -1.0] }
            Exp(.literal) { [-0.5, -1.0] }
        }
        shapeLayer.iconOffset = .expression(offsetExpression)
        shapeLayer.textOffset = .expression(offsetExpression)
        
        let layerPosition = layerPosition(for: layerIdentifier)
        try style.addPersistentLayer(shapeLayer, layerPosition: layerPosition)
    }
    
    private func composeCalloutFeature(annotationCoordinate: LocationCoordinate2D,
                                       labelText: String,
                                       index: Int,
                                       isSelected: Bool) -> Feature {
        // Create the feature for this route annotation. Set the styling attributes that will be
        // used to render the annotation in the style layer.
        var feature = Feature(geometry: .point(Point(annotationCoordinate)))
        
        // Pick a random tail direction to keep things varied.
        guard var tailPosition = [
            RouteDurationAnnotationTailPosition.leading,
            RouteDurationAnnotationTailPosition.trailing
        ].randomElement() else { return  feature }
        
        // Convert our coordinate to screen space so we can make a choice on which side of the
        // coordinate the label ends up on.
        let unprojectedCoordinate = mapView.mapboxMap.point(for: annotationCoordinate)
        
        // Pick the orientation of the bubble "stem" based on how close to the edge of the screen it is.
        if tailPosition == .leading && unprojectedCoordinate.x > bounds.width * 0.75 {
            tailPosition = .trailing
        } else if tailPosition == .trailing && unprojectedCoordinate.x < bounds.width * 0.25 {
            tailPosition = .leading
        }
        
        var imageName = tailPosition == .leading ? ImageIdentifier.routeAnnotationLeftHanded : ImageIdentifier.routeAnnotationRightHanded
        
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
            "routeIndex": .number(Double(index))
        ]
        
        return feature
    }
    
    /**
     Generate the text for the label to be shown on screen. It will include estimated duration
     and info on Tolls, if applicable.
     */
    private func annotationLabelForRoute(_ route: Route, tolls: Bool) -> String {
        let eta = DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime) ?? ""
        
        return tollAnnotationForLabel(on: route, tolls: tolls, label: eta)
    }
    
    private func tollAnnotationForLabel(on route: Route?, tolls: Bool, label: String) -> String {
        var labelWithTolls = label
        let hasTolls = (route?.tollIntersections?.count ?? 0) > 0
        if hasTolls {
            labelWithTolls += "\n" + NSLocalizedString("ROUTE_HAS_TOLLS", bundle: .mapboxNavigation, value: "Tolls", comment: "This route does have tolls")
            if let symbol = Locale.current.currencySymbol {
                labelWithTolls += " " + symbol
            }
        } else if tolls {
            // If one of the routes has tolls, but this one does not then it needs to explicitly say that it has no tolls
            // If no routes have tolls at all then we can omit this portion of the string.
            labelWithTolls += "\n" + NSLocalizedString("ROUTE_HAS_NO_TOLLS", bundle: .mapboxNavigation, value: "No Tolls", comment: "This route does not have tolls")
        }
        
        return labelWithTolls
    }
    
    /**
     Generate the text for the label to be shown on screen. It will include estimated duration delta relative to the main route
     and info on Tolls, if applicable.
     */
    private func annotationLabelForAlternativeRoute(_ alternativeRoute: AlternativeRoute, tolls: Bool) -> String {
        let timeDelta = DateComponentsFormatter.travelTimeString(alternativeRoute.expectedTravelTimeDelta,
                                                                 signed: true,
                                                                 unitStyle: nil)
        
        return tollAnnotationForLabel(on: alternativeRoute.indexedRouteResponse.currentRoute,
                                      tolls: tolls,
                                      label: timeDelta)
    }
    
    // MARK: Intersection Signals Annotations
    
    /**
     Removes all the intersection annotations on current route.
     */
    func removeIntersectionAnnotations() {
        let style = mapView.mapboxMap.style
        style.removeLayers([NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer])
        style.removeSources([NavigationMapView.SourceIdentifier.intersectionAnnotationsSource])
    }
    
    /**
     Updates the image assets in the map style for the route intersection signals.
     
     - parameter styleType: The `StyleType` to choose `Day` or `Night` style of icon images for route intersection signals.
     */
    func updateIntersectionSymbolImages(styleType: StyleType?) {
        let style = mapView.mapboxMap.style
        let styleType = styleType ?? .day
        let iconNameToIdentifier: [String: String] = ["trafficSignal": ImageIdentifier.trafficSignal,
                                                      "railroadCrossing": ImageIdentifier.railroadCrossing,
                                                      "yieldSign": ImageIdentifier.yieldSign,
                                                      "stopSign": ImageIdentifier.stopSign]
        
        do {
            for iconType in iconNameToIdentifier.keys {
                let iconName = iconType.firstCapitalized + styleType.description.firstCapitalized
                if let imageIdentifier = iconNameToIdentifier[iconType],
                   let iconImage = Bundle.mapboxNavigation.image(named: iconName) {
                    try style.addImage(iconImage, id: imageIdentifier)
                }
            }
        } catch {
            Log.error("Error occured while updating intersection signal images: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    func updateIntersectionAnnotations(with routeProgress: RouteProgress) {
        guard !routeProgress.routeIsComplete else {
            removeIntersectionAnnotations()
            return
        }
        var featureCollection = FeatureCollection(features: [])
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let intersectionIndex = stepProgress.intersectionIndex
        let stepIntersections = stepProgress.intersectionsIncludingUpcomingManeuverIntersection
        
        for intersection in stepIntersections?.suffix(from: intersectionIndex) ?? [] {
            if let feature = intersectionFeature(from: intersection) {
                featureCollection.features.append(feature)
            }
        }
        
        let style = mapView.mapboxMap.style
        
        do {
            let sourceIdentifier = NavigationMapView.SourceIdentifier.intersectionAnnotationsSource
            if style.sourceExists(withId: sourceIdentifier) {
                try style.updateGeoJSONSource(withId: sourceIdentifier, geoJSON: .featureCollection(featureCollection))
            } else {
                var source = GeoJSONSource()
                source.data = .featureCollection(featureCollection)
                try style.addSource(source, id: sourceIdentifier)
            }
            
            let layerIdentifier = NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer
            guard !style.layerExists(withId: layerIdentifier) else { return }
            
            var shapeLayer = SymbolLayer(id: layerIdentifier)
            shapeLayer.source = sourceIdentifier
            shapeLayer.iconAllowOverlap = .constant(false)
            shapeLayer.iconImage = .expression(Exp(.get) {
                "imageName"
            })
            
            let layerPosition = layerPosition(for: layerIdentifier)
            try style.addPersistentLayer(shapeLayer, layerPosition: layerPosition)
        } catch {
            Log.error("Failed to perform operation while adding intersection signals with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    private func intersectionFeature(from intersection: Intersection) -> Feature? {
        var properties: JSONObject? = nil
        if intersection.yieldSign == true {
            properties = ["imageName": .string(ImageIdentifier.yieldSign)]
        }
        if intersection.stopSign == true {
            properties = ["imageName": .string(ImageIdentifier.stopSign)]
        }
        if intersection.railroadCrossing == true {
            properties = ["imageName": .string(ImageIdentifier.railroadCrossing)]
        }
        if intersection.trafficSignal == true {
            properties = ["imageName": .string(ImageIdentifier.trafficSignal)]
        }
        
        guard let properties = properties else { return nil }
        
        var feature = Feature(geometry: .point(Point(intersection.location)))
        feature.properties = properties
        return feature
    }
}
