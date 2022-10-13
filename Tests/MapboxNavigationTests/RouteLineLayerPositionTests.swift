import XCTest
import MapboxDirections
import TestHelper
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class RouteLineLayerPositionTests: TestCase {
    let options: NavigationRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197)])
    
    lazy var route: Route = {
        let response = Fixture.routeResponse(from: "route-with-instructions", options: options)
        return response.routes!.first!
    }()
    
    lazy var routeProgress: RouteProgress = {
        let routeProgress = RouteProgress(route: route, options: options, legIndex: 0, spokenInstructionIndex: 0)
        return routeProgress
    }()
    
    func testRouteLineLayerPosition() {
        
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector"
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster"
                ]
            ],
            "layers": []
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false
        
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        navigationMapView.mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 1.0)
        
        let mainRouteIdentifier = route.identifier(.route(isMainRoute: true))
        let mainRouteCasingIdentifier = route.identifier(.routeCasing(isMainRoute: true))
        
        navigationMapView.show([route])
        
        // Style doesn't contain any layers besides main route layer and its casing. In case if
        // layer position wasn't provided main route line casing layer should be placed below the
        // main route line layer.
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 0]?.id,
                       mainRouteCasingIdentifier,
                       "Route line casing layer identifiers should be equal.")
        
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 1]?.id,
                       mainRouteIdentifier,
                       "Route line layer identifiers should be equal.")
        
        navigationMapView.removeRoutes()
        
        // After removing all routes there should be no layers in style.
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.count,
                       0,
                       "Unexpected number of layer identifiers in style.")
        
        var source = GeoJSONSource()
        source.data = .geometry(.point(.init(.init(latitude: 0.0, longitude: 0.0))))
        
        let sourceIdentifier = "test_source"
        try? navigationMapView.mapView.mapboxMap.style.addSource(source, id: sourceIdentifier)
        
        let layerIdentifier = "test_dentifier"
        var layer = LineLayer(id: layerIdentifier)
        layer.source = sourceIdentifier
        try? navigationMapView.mapView.mapboxMap.style.addLayer(layer)
        
        navigationMapView.show([route], layerPosition: .above(layerIdentifier))
        
        // In case if layer position was provided to be placed above specific layer,
        // main route line casing layer should be placed above that specific layer followed by the
        // main route line layer.
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 0]?.id,
                       layerIdentifier,
                       "Custom line layer identifiers should be equal.")
        
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 1]?.id,
                       mainRouteCasingIdentifier,
                       "Route line casing layer identifiers should be equal.")
        
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 2]?.id,
                       mainRouteIdentifier,
                       "Route line layer identifiers should be equal.")
        
        navigationMapView.removeRoutes()
        
        navigationMapView.show([route], layerPosition: .below(layerIdentifier))
        
        // In case if layer position was provided to be placed below specific layer,
        // main route line casing layer should be placed below that specific layer followed by the
        // main route line layer.
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 0]?.id,
                       mainRouteCasingIdentifier,
                       "Route line casing layer identifiers should be equal.")
        
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 1]?.id,
                       mainRouteIdentifier,
                       "Route line layer identifiers should be equal.")
        
        XCTAssertEqual(navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers[safe: 2]?.id,
                       layerIdentifier,
                       "Custom line layer identifiers should be equal.")
        
        navigationMapView.removeRoutes()
    }
    
    func testLayerPosition() {
        let multilegRoute = Fixture.route(from: "multileg-route", options: routeOptions)
        
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        
        let buildingLayer: [String: String] = [
            "id": "building-outline",
            "type": "line",
            "source": "composite",
            "source-layer": "building"
        ]
        let roadTrafficLayer: [String: String] = [
            "id": "road-traffic",
            "type": "line",
            "source": "composite",
            "source-layer": "road"
        ]
        let roadLabelLayer: [String: String] = [
            "id": "road-label",
            "type": "symbol",
            "source": "composite",
            "source-layer": "road"
        ]
        let roadExitLayer: [String: String] = [
            "id": "road-exit-label",
            "type": "symbol",
            "source": "composite",
            "source-layer": "road-exit"
        ]
        let poiLabelLayer: [String: String] = [
            "id": "poi-label",
            "type": "symbol",
            "source": "composite",
            "source-layer": "poi"
        ]
        let poiLabelCircleLayer: [String: String] = [
            "id": "poi-label copy",
            "type": "circle",
            "source": "composite",
            "source-layer": "poi",
            "circle-pitch-alignment": "viewport"
        ]
        
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector"
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster"
                ]
            ],
            "layers": [
                buildingLayer,
                roadTrafficLayer,
                roadLabelLayer,
                roadExitLayer,
                poiLabelLayer,
                poiLabelCircleLayer
            ]
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false
        
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoadingError, handler: { event in
            mapLoadingErrorExpectation.fulfill()
        })
        
        navigationMapView.mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [mapLoadingErrorExpectation], timeout: 1.0)
        
        navigationMapView.show([multilegRoute])
        navigationMapView.showsRestrictedAreasOnRoute = true
        navigationMapView.showWaypoints(on: multilegRoute)
        navigationMapView.addArrow(route: multilegRoute, legIndex: 0, stepIndex: 1)
        
        var allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        var expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            multilegRoute.identifier(.routeCasing(isMainRoute: true)),
            multilegRoute.identifier(.route(isMainRoute: true)),
            multilegRoute.identifier(.restrictedRouteAreaRoute),
            roadLabelLayer["id"]!,
            NavigationMapView.LayerIdentifier.arrowStrokeLayer,
            NavigationMapView.LayerIdentifier.arrowLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolLayer,
            roadExitLayer["id"]!,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.waypointSymbolLayer
        ]
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to add route line layers below bottommost symbol layer.")
        
        // When custom layer position for route line provided, use the custom layer position.
        let customRouteLineLayerPosition = MapboxMaps.LayerPosition.below("road-traffic")
        navigationMapView.show([multilegRoute], layerPosition: customRouteLineLayerPosition)
        navigationMapView.removeWaypoints()
        navigationMapView.showsRestrictedAreasOnRoute = false
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.updateIntersectionSymbolImages(styleType: .day)
        navigationMapView.updateIntersectionAnnotations(with: routeProgress)
        
        expectedLayerSequence = [
            buildingLayer["id"]!,
            multilegRoute.identifier(.traversedRoute),
            multilegRoute.identifier(.routeCasing(isMainRoute: true)),
            multilegRoute.identifier(.route(isMainRoute: true)),
            roadTrafficLayer["id"]!,
            roadLabelLayer["id"]!,
            NavigationMapView.LayerIdentifier.arrowStrokeLayer,
            NavigationMapView.LayerIdentifier.arrowLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolLayer,
            NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer,
            roadExitLayer["id"]!,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!
        ]
        allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to apply custom layer position for route line.")
        
        navigationMapView.addArrow(route: multilegRoute, legIndex: 0, stepIndex: 0)
        navigationMapView.show(continuousAlternatives: [])
        allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to keep custom layer positions in active navigation.")
        
        // Add different circle layers in runtime to NavigationMapView at designed layer positions.
        let circleLabelLayer = "circleLabelLayer"
        let circleMapLayer = "circleMapLayer"
        addCircleLayerInRuntime(mapView: navigationMapView.mapView,
                                circleLabelId: circleLabelLayer,
                                isPersistent: true)
        addCircleLayerInRuntime(mapView: navigationMapView.mapView,
                                circleLabelId: circleMapLayer,
                                isPersistent: false,
                                circlePitchAlignment: .map,
                                layerPosition: .below(roadLabelLayer["id"]!))
        navigationMapView.removeRoutes()
        navigationMapView.removeArrow()
        navigationMapView.removeIntersectionAnnotations()

        expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            circleMapLayer,
            roadLabelLayer["id"]!,
            roadExitLayer["id"]!,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            circleLabelLayer
        ]
        allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to add different circle layers at designed layer position.")
        
        // When circle layers added from map style and in runtime to `NavigationMapView`,
        // the route line should be added above the un-persistent circle layer that has non-empty source layer
        // and with `CirclePitchAlignment` as `map`. Other circle layers should be skipped to be above route line.
        navigationMapView.addArrow(route: multilegRoute, legIndex: 0, stepIndex: 1)
        navigationMapView.showWaypoints(on: multilegRoute)
        navigationMapView.show([multilegRoute])
        navigationMapView.showsRestrictedAreasOnRoute = true
        navigationMapView.routeLineTracksTraversal = false
        navigationMapView.updateIntersectionAnnotations(with: routeProgress)
        
        expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            circleMapLayer,
            multilegRoute.identifier(.routeCasing(isMainRoute: true)),
            multilegRoute.identifier(.route(isMainRoute: true)),
            multilegRoute.identifier(.restrictedRouteAreaRoute),
            roadLabelLayer["id"]!,
            NavigationMapView.LayerIdentifier.arrowStrokeLayer,
            NavigationMapView.LayerIdentifier.arrowLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolLayer,
            NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer,
            roadExitLayer["id"]!,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            circleLabelLayer,
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.waypointSymbolLayer
        ]
        allLayerIds = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to add route line at certain position with different circle layers.")
    }
    
    func addCircleLayerInRuntime(mapView: MapView,
                                 circleLabelId: String,
                                 isPersistent: Bool,
                                 circlePitchAlignment: CirclePitchAlignment? = nil,
                                 layerPosition: MapboxMaps.LayerPosition? = nil) {
        do {
            if !mapView.mapboxMap.style.sourceExists(withId: circleLabelId) {
                var feature = Feature(geometry: .point(Point.init(.init(latitude: 30, longitude: 120))))
                feature.properties = ["name": .string(circleLabelId)]
                var circleLabelSource = GeoJSONSource()
                circleLabelSource.data = .feature(feature)
                try mapView.mapboxMap.style.addSource(circleLabelSource, id: circleLabelId)
            }
            
            mapView.mapboxMap.style.removeLayers([circleLabelId])
            var circleLabelLayer = CircleLayer(id: circleLabelId)
            circleLabelLayer.sourceLayer = "poi"
            circleLabelLayer.source = circleLabelId
            circleLabelLayer.circleColor = .constant(.init(UIColor.black))
            circleLabelLayer.circleOpacity = .constant(.init(1))
            circleLabelLayer.circleRadius = .constant(.init(10))
            if let circlePitchAlignment = circlePitchAlignment {
                circleLabelLayer.circlePitchAlignment = .constant(circlePitchAlignment)
            }
            
            if isPersistent {
                try mapView.mapboxMap.style.addPersistentLayer(circleLabelLayer, layerPosition: layerPosition)
            } else {
                try mapView.mapboxMap.style.addLayer(circleLabelLayer, layerPosition: layerPosition)
            }
        } catch {
            XCTFail("Failed to add circle layer in runtime.")
        }
    }
}
