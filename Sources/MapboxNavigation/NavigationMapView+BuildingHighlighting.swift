import CoreLocation
import MapboxMaps
import Turf

extension NavigationMapView {
    
    // MARK: - Building Extrusion Highlighting methods
    
    /**
     Receives coordinates for searching the map for buildings. If buildings are found, they will be highlighted in 2D or 3D depending on the `in3D` value.
     
     - parameter coordinates: Coordinates which represent building locations.
     - parameter extrudesBuildings: Switch which allows to highlight buildings in either 2D or 3D. Defaults to true.
     - parameter completion: An escaping closure to be executed when the `MapView` feature querying for all `coordinates` ends. A single `Boolean` argument in closure indicates whether or not buildings were found for all coordinates.
     */
    public func highlightBuildings(at coordinates: [CLLocationCoordinate2D],
                                   in3D extrudesBuildings: Bool = true,
                                   completion: ((_ foundAllBuildings: Bool) -> Void)? = nil) {
        var foundBuildingIds = Set<Int64>()
        let group = DispatchGroup()
        let identifiers = mapView.mapboxMap.style.allLayerIdentifiers
            .compactMap({ $0.id })
            .filter({ $0.contains("building") })
        
        coordinates.forEach {
            group.enter()
            
            let screenCoordinate = mapView.mapboxMap.point(for: $0)
            let options = RenderedQueryOptions(layerIds: identifiers, filter: nil)
            
            mapView.mapboxMap.queryRenderedFeatures(at: screenCoordinate,
                                                    options: options,
                                                    completion: { [weak self] result in
                                                        guard let _ = self else { return }
                                                        if case .success(let queriedFeatures) = result {
                                                            if let identifier = queriedFeatures.first?.feature.identifier as? Int64 {
                                                                foundBuildingIds.insert(identifier)
                                                            }
                                                            group.leave()
                                                        }
                                                    })
        }

        group.notify(queue: DispatchQueue.main) {
            self.addBuildingsLayer(with: foundBuildingIds, in3D: extrudesBuildings)
            completion?(foundBuildingIds.count == coordinates.count)
        }
    }
    
    /**
     Removes the highlight from all buildings highlighted by `highlightBuildings(at:in3D:completion:)`.
     */
    public func unhighlightBuildings() {
        let identifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        
        do {
            if mapView.mapboxMap.style.layerExists(withId: identifier) {
                try mapView.mapboxMap.style.removeLayer(withId: identifier)
            }
        } catch {
            NSLog("Failed to perform operation on \(identifier) with error: \(error.localizedDescription).")
        }
    }

    private func addBuildingsLayer(with identifiers: Set<Int64>, in3D: Bool = false, extrudeAll: Bool = false) {
        let identifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        
        do {
            if mapView.mapboxMap.style.layerExists(withId: identifier) {
                try mapView.mapboxMap.style.removeLayer(withId: identifier)
            }
            
            if identifiers.isEmpty { return }
            var highlightedBuildingsLayer = FillExtrusionLayer(id: identifier)
            highlightedBuildingsLayer.source = "composite"
            highlightedBuildingsLayer.sourceLayer = "building"
            
            let extrudeExpression: Expression = Exp(.eq) {
                Exp(.get) {
                    "extrude"
                }
                "true"
            }
            
            if extrudeAll {
                highlightedBuildingsLayer.filter = extrudeExpression
            } else {
                highlightedBuildingsLayer.filter = Exp(.all) {
                    extrudeExpression
                    Exp(.inExpression) {
                        Exp(.id)
                        Exp(.literal) {
                            identifiers.map({ Double($0) })
                        }
                    }
                }
            }
            
            if in3D {
                highlightedBuildingsLayer.fillExtrusionHeight = .expression(Expression.buildingExtrusionHeightExpression("height"))
            } else {
                highlightedBuildingsLayer.fillExtrusionHeight = .constant(0.0)
            }
            
            highlightedBuildingsLayer.fillExtrusionBase = .expression(Expression.buildingExtrusionHeightExpression("min_height"))
            
            highlightedBuildingsLayer.fillExtrusionOpacity = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    13; 0.5
                    17; 0.8
                }
            )
            
            highlightedBuildingsLayer.fillExtrusionColor = .constant(.init(color: buildingHighlightColor))
            highlightedBuildingsLayer.fillExtrusionHeightTransition = StyleTransition(duration: 0.8, delay: 0)
            highlightedBuildingsLayer.fillExtrusionOpacityTransition = StyleTransition(duration: 0.8, delay: 0)
            try mapView.mapboxMap.style.addLayer(highlightedBuildingsLayer)
        } catch {
            NSLog("Failed to perform operation on \(identifier) with error: \(error.localizedDescription).")
        }
    }
}
