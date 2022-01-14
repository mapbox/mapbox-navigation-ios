import MapboxMaps
import MapboxDirections
import MapboxCoreNavigation

extension NavigationMapView {
    
    func labelCurrentRoadFeature(at location: CLLocation,
                                 router: Router,
                                 wayNameView: WayNameView,
                                 roadNameFromStatus: String?) {
        guard let stepShape = router.routeProgress.currentLegProgress.currentStep.shape,
              !stepShape.coordinates.isEmpty else {
                  return
              }
        
        // Add Mapbox Streets if the map does not already have it
        if mapView.streetsSources().isEmpty {
            var streetsSource = VectorSource()
            streetsSource.url = "mapbox://mapbox.mapbox-streets-v8"
            
            let sourceIdentifier = "com.mapbox.MapboxStreets"
            
            do {
                try mapView.mapboxMap.style.addSource(streetsSource, id: sourceIdentifier)
            } catch {
                NSLog("Failed to add \(sourceIdentifier) with error: \(error.localizedDescription).")
            }
        }
        
        guard let mapboxStreetsSource = mapView.streetsSources().first else { return }
        
        let identifierNamespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""
        let roadLabelStyleLayerIdentifier = "\(identifierNamespace).roadLabels"
        let roadLabelLayer = try? mapView.mapboxMap.style.layer(withId: roadLabelStyleLayerIdentifier) as? LineLayer
        
        if roadLabelLayer == nil {
            var streetLabelLayer = LineLayer(id: roadLabelStyleLayerIdentifier)
            streetLabelLayer.source = mapboxStreetsSource.id
            
            var sourceLayerIdentifier: String? {
                let identifiers = mapView.tileSetIdentifiers(mapboxStreetsSource.id,
                                                             sourceType: mapboxStreetsSource.type.rawValue)
                if VectorSource.isMapboxStreets(identifiers) {
                    return identifiers.compactMap({ VectorSource.roadLabelLayerIdentifiersByTileSetIdentifier[$0] }).first
                }
                
                return nil
            }
            
            streetLabelLayer.sourceLayer = sourceLayerIdentifier
            streetLabelLayer.lineOpacity = .constant(1.0)
            streetLabelLayer.lineWidth = .constant(20.0)
            streetLabelLayer.lineColor = .constant(.init(.white))
            
            if ![ProfileIdentifier.walking, ProfileIdentifier.cycling].contains(router.routeProgress.routeOptions.profileIdentifier) {
                // Filter out to road classes valid only for motor transport.
                let filter = Exp(.inExpression) {
                    "class"
                    "motorway"
                    "motorway_link"
                    "trunk"
                    "trunk_link"
                    "primary"
                    "primary_link"
                    "secondary"
                    "secondary_link"
                    "tertiary"
                    "tertiary_link"
                    "street"
                    "street_limited"
                    "roundabout"
                }
                
                streetLabelLayer.filter = filter
            }
            
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                if let firstLayerIdentifier = mapView.mapboxMap.style.allLayerIdentifiers.first?.id {
                    layerPosition = .below(firstLayerIdentifier)
                }
                
                try mapView.mapboxMap.style.addLayer(streetLabelLayer, layerPosition: layerPosition)
            } catch {
                NSLog("Failed to add \(roadLabelStyleLayerIdentifier) with error: \(error.localizedDescription).")
            }
        }
        
        let closestCoordinate = location.coordinate
        let lookAheadDistance: CLLocationDistance = 10
        let pointAheadUser = stepShape.sliced(from: closestCoordinate)?.coordinateFromStart(distance: lookAheadDistance)
        let position = mapView.mapboxMap.point(for: closestCoordinate)
        
        let ids = mapView.mapboxMap.style.allLayerIdentifiers
        
        mapView.mapboxMap.queryRenderedFeatures(at: position,
                                                options: RenderedQueryOptions(layerIds: [roadLabelStyleLayerIdentifier], filter: nil)) { [weak self] result in
            switch result {
            case .success(let queriedFeatures):
                guard let self = self else { return }
                
                var smallestLabelDistance = Double.infinity
                var latestFeature: Turf.Feature?
                
                var minimumEditDistance = Int.max
                var similarFeature: Turf.Feature?
                
                for queriedFeature in queriedFeatures {
                    // Calculate the Levenshtein–Damerau edit distance between the road name from status and the feature property road name, and then use the smallest one for the road label.
                    if case let .string(roadName) = queriedFeature.feature.properties?["name"],
                       let roadNameFromStatus = roadNameFromStatus {
                        let stringEditDistance = roadNameFromStatus.minimumEditDistance(to: roadName)
                        if stringEditDistance < minimumEditDistance {
                            minimumEditDistance = stringEditDistance
                            similarFeature = queriedFeature.feature
                        }
                    }
                    
                    guard let pointAheadUser = pointAheadUser else { continue }
                    
                    var lineStrings: [LineString] = []
                    
                    switch queriedFeature.feature.geometry {
                    case .lineString(let lineString):
                        lineStrings.append(lineString)
                    case .multiLineString(let multiLineString):
                        for coordinates in multiLineString.coordinates {
                            lineStrings.append(LineString(coordinates))
                        }
                    default:
                        break
                    }
                    
                    for lineString in lineStrings {
                        guard let pointAheadFeature = lineString.sliced(from: closestCoordinate)?.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        guard let reversedPoint = LineString(lineString.coordinates.reversed()).sliced(from: closestCoordinate)?.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        
                        let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                        let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                        let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                        
                        if minDistanceBetweenPoints < smallestLabelDistance {
                            smallestLabelDistance = minDistanceBetweenPoints
                            
                            latestFeature = queriedFeature.feature
                        }
                    }
                }
                
                var hideWayName = true
                if latestFeature?.featureIdentifier != similarFeature?.featureIdentifier {
                    let style = self.mapView.mapboxMap.style
                    if let similarFeature = similarFeature,
                       wayNameView.setupWith(feature: similarFeature,
                                             using: style) {
                        hideWayName = false
                    }
                } else if smallestLabelDistance < 5 {
                    let style = self.mapView.mapboxMap.style
                    if let latestFeature = latestFeature,
                       wayNameView.setupWith(feature: latestFeature,
                                             using: style) {
                        hideWayName = false
                    }
                }
                wayNameView.containerView.isHidden = hideWayName
                
            case .failure:
                NSLog("Failed to find visible features.")
            }
        }
    }
}
