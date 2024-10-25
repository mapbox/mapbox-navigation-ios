import Combine
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

class RouteLineLayerPositionTests: TestCase {
    let buildingLayer: [String: String] = [
        "id": "building-outline",
        "type": "line",
        "source": "composite",
        "source-layer": "building",
    ]
    let roadTrafficLayer: [String: String] = [
        "id": "road-traffic",
        "type": "line",
        "source": "composite",
        "source-layer": "road",
    ]
    let roadLabelLayer: [String: String] = [
        "id": "road-label",
        "type": "symbol",
        "source": "composite",
        "source-layer": "road",
    ]
    let roadExitLayer: [String: String] = [
        "id": "road-exit-label",
        "type": "symbol",
        "source": "composite",
        "source-layer": "road-exit",
    ]
    let poiLabelLayer: [String: String] = [
        "id": "poi-label",
        "type": "symbol",
        "source": "composite",
        "source-layer": "poi",
    ]
    let poiLabelCircleLayer: [String: String] = [
        "id": "poi-label copy",
        "type": "circle",
        "source": "composite",
        "source-layer": "poi",
        "circle-pitch-alignment": "viewport",
    ]

    let options: NavigationRouteOptions = .init(
        coordinates: [
            CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
            CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
        ]
    )

    var routes: NavigationRoutes!
    var routeProgress: RouteProgress!
    var navigationMapView: NavigationMapView!
    var mapboxMap: MapboxMap!
    var routeProgressPublisher: CurrentValueSubject<RouteProgress?, Never>!
    var subscriptions: Set<AnyCancellable>!

    override func setUp() async throws {
        try? await super.setUp()

        subscriptions = []
        routeProgressPublisher = .init(nil)
        routes = await Fixture.navigationRoutes(from: "route-with-instructions", options: options)
        routeProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: [],
            congestionConfiguration: .default
        )

        navigationMapView = NavigationMapView(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        navigationMapView.frame = UIScreen.main.bounds
        guard let mapboxMap = navigationMapView.mapView.mapboxMap else {
            XCTFail("Should have non-nil mapboxMap")
            return
        }
        try? mapboxMap.addLayer(SlotLayer(id: Slot.middle!.rawValue))
        self.mapboxMap = mapboxMap
    }

    var route: Route {
        routes!.mainRoute.route
    }

    @MainActor
    func testRouteLineLayerPosition() {
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330,
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector",
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster",
                ],
            ],
            "layers": [],
        ]

        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")

        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false

        mapboxMap.onMapLoadingError.observe { _ in
            mapLoadingErrorExpectation.fulfill()
        }
        .store(in: &subscriptions)

        mapboxMap.loadStyle(styleJSON)

        wait(for: [mapLoadingErrorExpectation], timeout: 1.0)

        let mainRouteIdentifier = FeatureIds.RouteLine.main.main
        let mainRouteCasingIdentifier = FeatureIds.RouteLine.main.casing

        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.show(routes, routeAnnotationKinds: [])

        // Style doesn't contain any layers besides main route layer and its casing. In case if
        // layer position wasn't provided main route line casing layer should be placed below the
        // main route line layer.
        XCTAssertEqual(
            mapboxMap.allLayerIdentifiers[safe: 0]?.id,
            mainRouteCasingIdentifier,
            "Route line casing layer identifiers should be equal."
        )

        XCTAssertEqual(
            mapboxMap.allLayerIdentifiers[safe: 1]?.id,
            mainRouteIdentifier,
            "Route line layer identifiers should be equal."
        )

        navigationMapView.removeRoutes()

        // After removing all routes there should be no layers in style.
        XCTAssertEqual(mapboxMap.allLayerIdentifiers.count, 0, "Unexpected number of layer identifiers in style.")

        let sourceIdentifier = "test_source"
        var source = GeoJSONSource(id: sourceIdentifier)
        source.data = .geometry(.point(.init(.init(latitude: 0.0, longitude: 0.0))))

        try? mapboxMap.addSource(source)

        let layerIdentifier = "test_dentifier"
        var layer = LineLayer(id: layerIdentifier, source: sourceIdentifier)
        layer.source = sourceIdentifier
        try? mapboxMap.addLayer(layer)

        navigationMapView.show(routes, routeAnnotationKinds: [])

        // In case if layer position was provided to be placed above specific layer,
        // main route line casing layer should be placed above that specific layer followed by the
        // main route line layer.
        XCTAssertEqual(
            mapboxMap.allLayerIdentifiers[safe: 0]?.id,
            layerIdentifier,
            "Custom line layer identifiers should be equal."
        )

        XCTAssertEqual(
            mapboxMap.allLayerIdentifiers[safe: 1]?.id,
            mainRouteCasingIdentifier,
            "Route line casing layer identifiers should be equal."
        )

        XCTAssertEqual(
            mapboxMap.allLayerIdentifiers[safe: 2]?.id,
            mainRouteIdentifier,
            "Route line layer identifiers should be equal."
        )
    }

    @MainActor
    func testLayerPosition() async {
        routes = await Fixture.navigationRoutes(from: "multileg-route", options: routeOptions3Waypoints)

        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330,
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector",
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster",
                ],
            ],
            "layers": [
                buildingLayer,
                roadTrafficLayer,
                roadLabelLayer,
                roadExitLayer,
                poiLabelLayer,
                poiLabelCircleLayer,
            ],
        ]

        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")

        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false

        mapboxMap.onMapLoadingError.observe { _ in
            mapLoadingErrorExpectation.fulfill()
        }
        .store(in: &subscriptions)

        mapboxMap.loadStyle(styleJSON)
        try? mapboxMap.addLayer(SlotLayer(id: Slot.middle!.rawValue))

        await fulfillment(of: [mapLoadingErrorExpectation], timeout: 1)
        navigationMapView.mapStyleManager.onStyleLoaded()

        navigationMapView.show(routes, routeAnnotationKinds: [])
        navigationMapView.showsRestrictedAreasOnRoute = true
        let status = TestNavigationStatusProvider.createActiveStatus(stepIndex: 1)
        routeProgress.update(using: status)
        navigationMapView.updateArrow(routeProgress: routeProgress)

        let routeIds = FeatureIds.RouteLine.main
        let arrowIds = FeatureIds.ManeuverArrow.nextArrow()
        let waypointIds = FeatureIds.RouteWaypoints.default
        let intersectionIds = FeatureIds.IntersectionAnnotation()
        let routeAlertIds = FeatureIds.RouteAlertAnnotation.default

        var allLayerIds = mapboxMap.allLayerIdentifiers.map { $0.id }
        var expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            roadLabelLayer["id"]!,
            roadExitLayer["id"]!,
            routeIds.casing,
            routeIds.main,
            arrowIds.arrowStroke,
            arrowIds.arrow,
            arrowIds.arrowSymbolCasing,
            arrowIds.arrowSymbol,
            routeIds.restrictedArea,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            routeAlertIds.layer,
            waypointIds.innerCircle,
            waypointIds.markerIcon,
            Slot.middle!.rawValue,
        ]
        XCTAssertEqual(
            allLayerIds,
            expectedLayerSequence,
            "Failed to add route line layers below bottommost symbol layer."
        )

        navigationMapView.showsRestrictedAreasOnRoute = false
        navigationMapView.show(routes, routeAnnotationKinds: [])
        navigationMapView.mapStyleManager.removeWaypoints()
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.updateIntersectionAnnotations(routeProgress: routeProgress)
        navigationMapView.updateArrow(routeProgress: routeProgress)

        expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            roadLabelLayer["id"]!,
            roadExitLayer["id"]!,
            routeIds.casing,
            routeIds.main,
            arrowIds.arrowStroke,
            arrowIds.arrow,
            arrowIds.arrowSymbolCasing,
            arrowIds.arrowSymbol,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            intersectionIds.layer,
            routeAlertIds.layer,
            Slot.middle!.rawValue,
        ]
        allLayerIds = mapboxMap.allLayerIdentifiers.map { $0.id }
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Failed to apply custom layer position for route line.")

        let status0 = TestNavigationStatusProvider.createActiveStatus(stepIndex: 0)
        routeProgress.update(using: status0)
        navigationMapView.updateArrow(routeProgress: routeProgress)
        allLayerIds = mapboxMap.allLayerIdentifiers.map { $0.id }
        XCTAssertEqual(
            allLayerIds,
            expectedLayerSequence,
            "Failed to keep custom layer positions in active navigation."
        )
    }

    @MainActor
    func testLayerPositionIfAddedCustomLayer() async {
        let mapLoadingErrorExpectation = expectation(description: "Map loading error expectation")
        mapLoadingErrorExpectation.assertForOverFulfill = false

        mapboxMap.onMapLoadingError.observe { _ in
            mapLoadingErrorExpectation.fulfill()
        }
        .store(in: &subscriptions)

        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330,
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector",
                ],
                "custom": [
                    "url": "http://api.example.com/tilejson.json",
                    "type": "raster",
                ],
            ],
            "layers": [
                buildingLayer,
                roadTrafficLayer,
                roadLabelLayer,
                roadExitLayer,
                poiLabelLayer,
                poiLabelCircleLayer,
            ],
        ]

        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)

        mapboxMap.loadStyle(styleJSON)
        try? mapboxMap.addLayer(SlotLayer(id: Slot.middle!.rawValue))

        await fulfillment(of: [mapLoadingErrorExpectation], timeout: 1)
        navigationMapView.mapStyleManager.onStyleLoaded()

        // Add different circle layers in runtime to NavigationMapView at designed layer positions.
        let circleLabelLayer = "circleLabelLayer"
        let circleMapLayer = "circleMapLayer"
        await addCircleLayerInRuntime(
            circleLabelId: circleLabelLayer,
            isPersistent: true
        )
        await addCircleLayerInRuntime(
            circleLabelId: circleMapLayer,
            isPersistent: false,
            circlePitchAlignment: .map,
            layerPosition: .below(roadLabelLayer["id"]!)
        )

        let routeIds = FeatureIds.RouteLine.main
        let arrowIds = FeatureIds.ManeuverArrow.nextArrow()
        let intersectionIds = FeatureIds.IntersectionAnnotation()
        let routeAlertIds = FeatureIds.RouteAlertAnnotation.default
        let waypointIds = FeatureIds.RouteWaypoints.default

        var expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            circleMapLayer,
            roadLabelLayer["id"]!,
            roadExitLayer["id"]!,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            Slot.middle!.rawValue,
            circleLabelLayer,
        ]
        var allLayerIds = mapboxMap.allLayerIdentifiers.map { $0.id }
        XCTAssertEqual(
            allLayerIds,
            expectedLayerSequence,
            "Added custom layer."
        )

        // When circle layers added from map style and in runtime to `NavigationMapView`,
        // the route line should be added above the un-persistent circle layer that has non-empty source layer
        // and with `CirclePitchAlignment` as `map`. Other circle layers should be skipped to be above route line.
        let status1 = TestNavigationStatusProvider.createActiveStatus(stepIndex: 1)
        routeProgress.update(using: status1)
        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.showsRestrictedAreasOnRoute = true
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show(routes, routeAnnotationKinds: [])
        navigationMapView.updateArrow(routeProgress: routeProgress)
        navigationMapView.updateIntersectionAnnotations(routeProgress: routeProgress)

        expectedLayerSequence = [
            buildingLayer["id"]!,
            roadTrafficLayer["id"]!,
            circleMapLayer,
            roadLabelLayer["id"]!,
            roadExitLayer["id"]!,
            routeIds.casing,
            routeIds.main,
            arrowIds.arrowStroke,
            arrowIds.arrow,
            arrowIds.arrowSymbolCasing,
            arrowIds.arrowSymbol,
            routeIds.restrictedArea,
            poiLabelLayer["id"]!,
            poiLabelCircleLayer["id"]!,
            intersectionIds.layer,
            routeAlertIds.layer,
            waypointIds.innerCircle,
            waypointIds.markerIcon,
            Slot.middle!.rawValue,
            circleLabelLayer,
        ]
        allLayerIds = mapboxMap.allLayerIdentifiers.map { $0.id }
        XCTAssertEqual(allLayerIds, expectedLayerSequence, "Added with different circle layers.")
    }

    @MainActor
    func testLayersForMultiLegRouteWithAlternatives() async {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.330536, longitude: -122.030373),
            CLLocationCoordinate2D(latitude: 37.412221, longitude: -121.887143),
            CLLocationCoordinate2D(latitude: 37.493855, longitude: -121.936005),
        ])

        routes = await Fixture.navigationRoutes(from: "multileg-route-alternatives", options: navigationRouteOptions)

        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.showcase(routes)

        let allLayerIds = Set(mapboxMap.allLayerIdentifiers.map { $0.id })
        let routeIds = FeatureIds.RouteLine.main
        let alternative_0_ids = FeatureIds.RouteLine.alternative(idx: 0)
        let alternative_1_ids = FeatureIds.RouteLine.alternative(idx: 1)
        let expectedLayers: Set<String> = [
            routeIds.main,
            routeIds.casing,
            routeIds.restrictedArea,
            alternative_0_ids.main,
            alternative_0_ids.casing,
            alternative_1_ids.main,
            alternative_1_ids.casing,
            Slot.middle!.rawValue,
        ]
        XCTAssertTrue(allLayerIds.isSuperset(of: expectedLayers))
    }

    @MainActor
    func testLayersForMultiLegRouteWithHiddenAlternatives() async {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.330536, longitude: -122.030373),
            CLLocationCoordinate2D(latitude: 37.412221, longitude: -121.887143),
            CLLocationCoordinate2D(latitude: 37.493855, longitude: -121.936005),
        ])

        routes = await Fixture.navigationRoutes(from: "multileg-route-alternatives", options: navigationRouteOptions)

        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.showsAlternatives = false
        navigationMapView.showcase(routes)

        let allLayerIds = Set(mapboxMap.allLayerIdentifiers.map { $0.id })
        let routeIds = FeatureIds.RouteLine.main
        let alternative_0_ids = FeatureIds.RouteLine.alternative(idx: 0)
        let alternative_1_ids = FeatureIds.RouteLine.alternative(idx: 1)
        let expectedLayers: Set<String> = [
            routeIds.main,
            routeIds.casing,
            routeIds.restrictedArea,
        ]
        XCTAssertTrue(allLayerIds.isSuperset(of: expectedLayers))
        XCTAssertFalse(allLayerIds.contains(alternative_0_ids.main))
        XCTAssertFalse(allLayerIds.contains(alternative_0_ids.casing))
        XCTAssertFalse(allLayerIds.contains(alternative_1_ids.main))
        XCTAssertFalse(allLayerIds.contains(alternative_1_ids.casing))
    }

    @MainActor
    func addCircleLayerInRuntime(
        circleLabelId: String,
        isPersistent: Bool,
        circlePitchAlignment: CirclePitchAlignment? = nil,
        layerPosition: MapboxMaps.LayerPosition? = nil
    ) async {
        do {
            navigationMapView.mapStyleManager.onStyleLoaded()
            if !mapboxMap.sourceExists(withId: circleLabelId) {
                var feature = Feature(geometry: .point(Point(.init(latitude: 30, longitude: 120))))
                feature.properties = ["name": .string(circleLabelId)]
                var circleLabelSource = GeoJSONSource(id: circleLabelId)
                circleLabelSource.data = .feature(feature)
                try mapboxMap.addSource(circleLabelSource)
            }

            try? mapboxMap.removeLayer(withId: circleLabelId)
            var circleLabelLayer = CircleLayer(id: circleLabelId, source: circleLabelId)
            circleLabelLayer.sourceLayer = "poi"
            circleLabelLayer.circleColor = .constant(.init(UIColor.black))
            circleLabelLayer.circleOpacity = .constant(.init(1))
            circleLabelLayer.circleRadius = .constant(.init(10))
            if let circlePitchAlignment {
                circleLabelLayer.circlePitchAlignment = .constant(circlePitchAlignment)
            }

            if isPersistent {
                try mapboxMap.addPersistentLayer(circleLabelLayer, layerPosition: layerPosition)
            } else {
                try mapboxMap.addLayer(circleLabelLayer, layerPosition: layerPosition)
            }
        } catch {
            XCTFail("Failed to add circle layer in runtime.")
        }
    }
}
