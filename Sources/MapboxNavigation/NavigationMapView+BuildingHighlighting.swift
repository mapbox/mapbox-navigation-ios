import CoreLocation
import MapboxMaps
import Turf

extension NavigationMapView {
    
    struct CLLocationCoordinate2DHashable: Hashable {
        var coordinate: CLLocationCoordinate2D
        
        init(_ coordinate: CLLocationCoordinate2D) {
            self.coordinate = coordinate
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
        }
        
        static func == (lhs: CLLocationCoordinate2DHashable,
                        rhs: CLLocationCoordinate2DHashable) -> Bool {
            return lhs.coordinate.latitude == rhs.coordinate.latitude &&
            lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }
    
    // MARK: Building Extrusion Highlighting
    
    /**
     Receives coordinates for searching the map for buildings. If buildings are found, they will be
     highlighted in 2D or 3D depending on the `in3D` value.
     
     - parameter coordinates: Coordinates which represent building locations.
     - parameter extrudesBuildings: Switch which allows to highlight buildings in either 2D or 3D.
     Defaults to `true`.
     - parameter extrudeAll: Switch which allows to extrude either all or only buildings at a
     specific coordinates. Defaults to `false`.
     - parameter completion: An escaping closure to be executed when the `MapView` feature querying
     for all `coordinates` ends. A single `Boolean` argument in closure indicates whether or not
     buildings were found for all coordinates.
     */
    public func highlightBuildings(at coordinates: [CLLocationCoordinate2D],
                                   in3D extrudesBuildings: Bool = true,
                                   extrudeAll: Bool = false,
                                   completion: ((_ foundAllBuildings: Bool) -> Void)? = nil) {
        highlightedBuildingIdentifiersByCoordinate = highlightedBuildingIdentifiersByCoordinate.filter {
            coordinates.contains($0.key.coordinate)
        }
        let group = DispatchGroup()
        let identifiers = mapView.mapboxMap.style.allLayerIdentifiers
            .compactMap({ $0.id })
            .filter({ $0.contains("building") })
        let layerIdentifier = LayerIdentifier.buildingExtrusionLayer
        let layerPosition = layerPosition(for: layerIdentifier) ?? identifiers.last.map { LayerPosition.above($0) }
        
        for coordinate in coordinates {
            let screenCoordinate = mapView.mapboxMap.point(for: coordinate)
            if screenCoordinate == .pointOutOfMapViewBounds {
                continue
            }
            
            group.enter()
            let options = RenderedQueryOptions(layerIds: identifiers, filter: nil)
            
            mapView.mapboxMap.queryRenderedFeatures(with: screenCoordinate,
                                                    options: options,
                                                    completion: { [weak self] result in
                defer {
                    group.leave()
                }
                
                guard let self = self else { return }
                
                if case .success(let queriedFeatures) = result {
                    if let identifier = queriedFeatures.first?.feature.featureIdentifier {
                        let coordinate2DHashable = CLLocationCoordinate2DHashable.init(coordinate)
                        self.highlightedBuildingIdentifiersByCoordinate[coordinate2DHashable] = identifier
                    }
                }
            })
        }

        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            self.addBuildingsLayer(with: Set(self.highlightedBuildingIdentifiersByCoordinate.values),
                                   in3D: extrudesBuildings,
                                   extrudeAll: extrudeAll,
                                   layerPosition: layerPosition)
            completion?(self.highlightedBuildingIdentifiersByCoordinate.keys.count == coordinates.count)
        }
    }
    
    /**
     Removes the highlight from all buildings highlighted by `highlightBuildings(at:in3D:completion:)`.
     */
    public func unhighlightBuildings() {
        highlightedBuildingIdentifiersByCoordinate.removeAll()
        let identifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        
        do {
            if mapView.mapboxMap.style.layerExists(withId: identifier) {
                try mapView.mapboxMap.style.removeLayer(withId: identifier)
            }
        } catch {
            Log.error("Failed to perform operation on \(identifier) with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }

    private func addBuildingsLayer(with identifiers: Set<Int64>,
                                   in3D: Bool = false,
                                   extrudeAll: Bool = false,
                                   layerPosition: LayerPosition? = nil) {
        let identifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        
        do {
            if identifiers.isEmpty { return }
            var highlightedBuildingsLayer = FillExtrusionLayer(id: identifier)
            highlightedBuildingsLayer.source = "composite"
            highlightedBuildingsLayer.sourceLayer = "building"
            
            if extrudeAll {
                highlightedBuildingsLayer.filter = Exp(.eq) {
                    Exp(.get) {
                        "extrude"
                    }
                    "true"
                }
            } else {
                highlightedBuildingsLayer.filter = Exp(.all) {
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
            
            highlightedBuildingsLayer.fillExtrusionColor = .expression(
                Exp(.switchCase) {
                    Exp(.inExpression) {
                        Exp(.id)
                        Exp(.literal) {
                            identifiers.map({ Double($0) })
                        }
                    }
                    buildingHighlightColor
                    buildingDefaultColor
                }
            )
            
            highlightedBuildingsLayer.fillExtrusionHeightTransition = StyleTransition(duration: 0.8, delay: 0)
            highlightedBuildingsLayer.fillExtrusionOpacityTransition = StyleTransition(duration: 0.8, delay: 0)
            highlightedBuildingsLayer = customizedLayer(highlightedBuildingsLayer)
            
            // In case if highlighted buildings layer is already present, instead of removing it - update it.
            if mapView.mapboxMap.style.layerExists(withId: identifier) {
                try mapView.mapboxMap.style.updateLayer(withId: identifier,
                                                        type: FillExtrusionLayer.self,
                                                        update: { oldHighlightedBuildingsLayer in
                    oldHighlightedBuildingsLayer = highlightedBuildingsLayer
                })
            } else {
                try mapView.mapboxMap.style.addPersistentLayer(highlightedBuildingsLayer, layerPosition: layerPosition)
            }
        } catch {
            Log.error("Failed to perform operation on \(identifier) with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    func updateBuildingsLayerIfPresent() {
        let identifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        
        guard mapView.mapboxMap.style.layerExists(withId: identifier) else { return }
        
        do {
            try mapView.mapboxMap.style.updateLayer(withId: identifier,
                                                    type: FillExtrusionLayer.self) { buildingExtrusionLayer in
                buildingExtrusionLayer.fillExtrusionColor = .constant(.init(buildingHighlightColor))
            }
        } catch {
            Log.error("Failed to update building extrusion layer color with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
}
