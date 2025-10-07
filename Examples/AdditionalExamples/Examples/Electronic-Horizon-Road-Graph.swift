/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import Turf
import UIKit

extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

extension String {
    func abbreviatedStreetName() -> String {
        return self
            .replacingOccurrences(of: " Street", with: " St", options: .caseInsensitive)
            .replacingOccurrences(of: " Avenue", with: " Ave", options: .caseInsensitive)
            .replacingOccurrences(of: " Boulevard", with: " Blvd", options: .caseInsensitive)
            .replacingOccurrences(of: " Road", with: " Rd", options: .caseInsensitive)
            .replacingOccurrences(of: " Drive", with: " Dr", options: .caseInsensitive)
            .replacingOccurrences(of: " Lane", with: " Ln", options: .caseInsensitive)
            .replacingOccurrences(of: " Court", with: " Ct", options: .caseInsensitive)
            .replacingOccurrences(of: " Place", with: " Pl", options: .caseInsensitive)
    }
}

final class ElectronicHorizonRoadGraphViewController: UIViewController {
    // New York City route (Manhattan)
    private let initialLocation = CLLocation(latitude: 40.7580, longitude: -73.9855)

    private lazy var mapboxNavigationProvider: MapboxNavigationProvider = {
        var coreConfig = CoreConfig(
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: initialLocation
            ) : .live
        )

        // Customize the ElectronicHorizonConfig to start Electronic Horizon updates.
        coreConfig.electronicHorizonConfig = ElectronicHorizonConfig(
            length: 1000,
            expansionLevel: 2,
            branchLength: 500,
            minTimeDeltaBetweenUpdates: nil
        )
        return MapboxNavigationProvider(coreConfig: coreConfig)
    }()

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var electronicHorizonController: ElectronicHorizonController {
        mapboxNavigationProvider.electronicHorizon()
    }

    private var roadGraph: RoadGraph {
        electronicHorizonController.roadMatching.roadGraph
    }

    private var navigationMapView: NavigationMapView!

    private var subscriptions: [AnyCancellable] = []

    // MARK: - Road Graph Visualization

    private let roadGraphSourceIdentifier = "road-graph-source"
    private let roadGraphLayerIdentifier = "road-graph-layer"

    private let intersectionsSourceIdentifier = "intersections-source"
    private let intersectionsLayerIdentifier = "intersections-layer"

    // Cache for label stability
    private var labelCache: [String: LabeledRoad] = [:]
    private let labelCacheExpiry: TimeInterval = 5.0
    private var lastRenderedFeatureIds: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        subscribeToElectronicHorizonUpdates()

        // Start navigation with a route
        startNavigation()
    }

    private func startNavigation() {
        let origin = initialLocation.coordinate
        // Route from Times Square area to Lower Manhattan
        let destination = CLLocationCoordinate2DMake(40.7128, -74.0060)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print("Route calculation failed: \(error.localizedDescription)")
                // Fall back to free drive if route calculation fails
                mapboxNavigation.tripSession().startFreeDrive()
            case .success(let navigationRoutes):
                // Start active navigation to trigger route-based electronic horizon
                let session = mapboxNavigation.tripSession()
                session.startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
            }
        }
    }

    private func setupNavigationMapView() {
        navigationMapView = .init(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )

        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        navigationMapView.mapView.mapboxMap.onMapLoaded
            .sink { [weak self] _ in
                self?.setupRoadGraphStyle()
                self?.setupIntersectionsStyle()
            }.store(in: &subscriptions)
    }

    private func subscribeToElectronicHorizonUpdates() {
        electronicHorizonController.eHorizonEvents
            .compactMap { $0.event as? EHorizonStatus.Events.PositionUpdated }
            .sink { [weak self] event in
                self?.handle(positionUpdatedEvent: event)
            }.store(in: &subscriptions)

        electronicHorizonController.startUpdatingEHorizon()
    }

    private func handle(positionUpdatedEvent: EHorizonStatus.Events.PositionUpdated) {
        // Update the road graph visualization when the electronic horizon changes
        let roadGraphEdges = collectRoadGraphEdges(from: positionUpdatedEvent.startingEdge)
        updateRoadGraphVisualization(with: roadGraphEdges)

        // Update intersections visualization
        let labeledRoads = collectIntersections(from: positionUpdatedEvent.startingEdge)
        updateIntersectionsVisualization(with: labeledRoads)
    }

    // MARK: - Road Graph Collection

    private func collectRoadGraphEdges(from startingEdge: RoadGraph.Edge) -> [LineString] {
        var edges: [LineString] = []
        var visitedEdges = Set<RoadGraph.Edge.Identifier>()

        func collectEdges(_ edge: RoadGraph.Edge) {
            // Avoid processing the same edge twice
            guard !visitedEdges.contains(edge.identifier) else { return }
            visitedEdges.insert(edge.identifier)

            // Get the shape of this edge
            if let shape = roadGraph.edgeShape(edgeIdentifier: edge.identifier) {
                edges.append(shape)
            }

            // Explore all outlet edges recursively
            for outletEdge in edge.outletEdges {
                collectEdges(outletEdge)
            }
        }

        collectEdges(startingEdge)
        return edges
    }

    // MARK: - Road Graph Visualization

    private func setupRoadGraphStyle() {
        var source = GeoJSONSource(id: roadGraphSourceIdentifier)
        source.data = .geometry(Geometry.lineString(LineString([])))
        try? navigationMapView.mapView.mapboxMap.addSource(source)

        var layer = LineLayer(id: roadGraphLayerIdentifier, source: roadGraphSourceIdentifier)
        layer.lineWidth = .constant(5.0)
        layer.lineColor = .constant(.init(.red))
        layer.lineCap = .constant(.round)
        layer.lineJoin = .constant(.round)
        layer.slot = .middle
        try? navigationMapView.mapView.mapboxMap.addLayer(layer)
    }

    private func updateRoadGraphVisualization(with edges: [LineString]) {
        // Create a MultiLineString feature from all the road graph edges
        let coordinates = edges.map { $0.coordinates }
        let multiLineString = Geometry.multiLineString(.init(coordinates))
        let feature = Feature(geometry: multiLineString)

        navigationMapView.mapView.mapboxMap.updateGeoJSONSource(
            withId: roadGraphSourceIdentifier,
            geoJSON: .feature(feature)
        )
    }

    // MARK: - Intersections Visualization

    private struct LabeledRoad {
        let id: String // Stable identifier
        let geometry: LineString
        let streetName: String
        let level: UInt
    }

    private func collectIntersections(from startingEdge: RoadGraph.Edge) -> [LabeledRoad] {
        var labeledRoads: [LabeledRoad] = []
        var visitedEdges = Set<RoadGraph.Edge.Identifier>()
        var usedForLabeling = Set<RoadGraph.Edge.Identifier>() // Edges already used in a label

        func exploreAndLabel(_ edge: RoadGraph.Edge, currentStreetName: String?) {
            // Avoid processing the same edge twice
            guard !visitedEdges.contains(edge.identifier) else { return }
            visitedEdges.insert(edge.identifier)

            // Get the street name for this edge
            let edgeMetadata = roadGraph.edgeMetadata(edgeIdentifier: edge.identifier)
            let streetName = edgeMetadata?.names.first?.text

            // Determine the effective current street name (handle unnamed streets)
            let effectiveCurrentName = !streetName.isNilOrEmpty ? streetName : currentStreetName

            // Explore all outlet edges
            for outletEdge in edge.outletEdges {
                let outletMetadata = roadGraph.edgeMetadata(edgeIdentifier: outletEdge.identifier)
                if let outletStreetName = outletMetadata?.names.first?.text,
                   !outletStreetName.isEmpty {

                    // Create a label if:
                    // 1. Street name is different from current one (new street at intersection)
                    // 2. This edge hasn't been used for labeling yet
                    if outletStreetName != effectiveCurrentName,
                       !usedForLabeling.contains(outletEdge.identifier) {

                        // Extend the line by following edges with the same street name
                        let extendedGeometry = extendLine(
                            startingFrom: outletEdge,
                            streetName: outletStreetName,
                            usedEdges: &usedForLabeling
                        )

                        if let geometry = extendedGeometry {
                            // Create stable ID based on street name and approximate location
                            // Use first coordinate rounded to reduce variations from edge changes
                            let firstCoord = geometry.coordinates.first!
                            let roundedLat = round(firstCoord.latitude * 1000) / 1000
                            let roundedLon = round(firstCoord.longitude * 1000) / 1000
                            let stableId = "\(outletStreetName)-\(roundedLat)-\(roundedLon)"
                            labeledRoads.append(LabeledRoad(
                                id: stableId,
                                geometry: geometry,
                                streetName: outletStreetName.abbreviatedStreetName(),
                                level: outletEdge.level
                            ))
                        }
                    }

                    // Continue exploring this branch recursively
                    exploreAndLabel(outletEdge, currentStreetName: outletStreetName)
                }
            }
        }

        exploreAndLabel(startingEdge, currentStreetName: nil)
        return labeledRoads
    }

    private func extendLine(
        startingFrom edge: RoadGraph.Edge,
        streetName: String,
        usedEdges: inout Set<RoadGraph.Edge.Identifier>
    ) -> LineString? {
        var coordinates: [CLLocationCoordinate2D] = []
        var currentEdge: RoadGraph.Edge? = edge
        var totalDistance: Double = 0
        let maxDistance: Double = 400 // Maximum length in meters

        // Follow edges as long as they have the same street name and under distance cap
        while let edge = currentEdge {
            // Check if this edge is already used
            guard !usedEdges.contains(edge.identifier) else {
                break
            }

            // Get the edge metadata to check length
            let edgeMetadata = roadGraph.edgeMetadata(edgeIdentifier: edge.identifier)
            let edgeLength = edgeMetadata?.length ?? 0

            // Stop if adding this edge would exceed the distance cap
            if totalDistance + edgeLength > maxDistance {
                break
            }

            // Mark this edge as used
            usedEdges.insert(edge.identifier)

            // Get the shape for this edge
            guard let shape = roadGraph.edgeShape(edgeIdentifier: edge.identifier) else {
                break
            }

            // Append coordinates (skip first if we already have coordinates to avoid duplicates)
            if coordinates.isEmpty {
                coordinates.append(contentsOf: shape.coordinates)
            } else {
                coordinates.append(contentsOf: shape.coordinates.dropFirst())
            }

            totalDistance += edgeLength

            // Try to find an outlet edge with the same street name
            // Prefer edges at the same level (continuation), but allow any level if needed
            let sameNameOutlets = edge.outletEdges.filter { outletEdge in
                let metadata = roadGraph.edgeMetadata(edgeIdentifier: outletEdge.identifier)
                let name = metadata?.names.first?.text
                return name == streetName && !usedEdges.contains(outletEdge.identifier)
            }

            // Prefer level 0 (straight continuation), otherwise take first available
            currentEdge = sameNameOutlets.first { $0.level == 0 } ?? sameNameOutlets.first
        }

        return coordinates.isEmpty ? nil : LineString(coordinates)
    }

    private func setupIntersectionsStyle() {
        var source = GeoJSONSource(id: intersectionsSourceIdentifier)
        source.data = .featureCollection(FeatureCollection(features: []))
        source.lineMetrics = true
        try? navigationMapView.mapView.mapboxMap.addSource(source)

        // Add symbol layer for line labels
        var layer = SymbolLayer(id: intersectionsLayerIdentifier, source: intersectionsSourceIdentifier)
        layer.textField = .expression(
            Exp(.upcase) {
                Exp(.get) { "name" }
            }
        )
        layer.textSize = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                10
                9
                18
                16
            }
        )
        layer.textFont = .constant(["DIN Pro Bold", "Arial Unicode MS Bold"])
        layer.textColor = .constant(.init(.white))
        layer.textHaloColor = .constant(.init(.black))
        layer.textHaloWidth = .constant(2.5)
        layer.symbolPlacement = .constant(.line)
        layer.textMaxAngle = .constant(30)
        layer.textPadding = .constant(1)
        layer.textLetterSpacing = .constant(0.15)
        layer.textRotationAlignment = .constant(.map)
        layer.textPitchAlignment = .constant(.viewport)
        layer.symbolSpacing = .constant(10000)
        layer.textKeepUpright = .constant(true)
        layer.textOcclusionOpacity = .constant(0)
        layer.textEmissiveStrength = .constant(1)
        layer.textAllowOverlap = .constant(false)
        layer.iconAllowOverlap = .constant(false)
        layer.symbolSortKey = .expression(Exp(.get) { "level" }) // Stable sorting
        layer.slot = .top
        try? navigationMapView.mapView.mapboxMap.addLayer(layer)
    }

    private func updateIntersectionsVisualization(with labeledRoads: [LabeledRoad]) {
        let currentIds = Set(labeledRoads.map { $0.id })

        // Add or update labels in cache
        for road in labeledRoads {
            labelCache[road.id] = road
        }

        // Use cached labels (all labels that are still in cache)
        let allLabels = Array(labelCache.values)
        let allFeatureIds = Set(allLabels.map { $0.id })

        // Only update the source if the set of features has actually changed
        // This prevents unnecessary updates that cause Mapbox GL to restart label fade animations
        if allFeatureIds != lastRenderedFeatureIds {
            print("=== Updating Labels (feature set changed) ===")
            print("Previous: \(lastRenderedFeatureIds.count), Current: \(allFeatureIds.count)")

            let added = allFeatureIds.subtracting(lastRenderedFeatureIds)
            let removed = lastRenderedFeatureIds.subtracting(allFeatureIds)

            if !added.isEmpty {
                print("Added \(added.count): \(added.prefix(3).map { $0.prefix(30) })")
            }
            if !removed.isEmpty {
                print("Removed \(removed.count): \(removed.prefix(3).map { $0.prefix(30) })")
            }

            let features = allLabels.map { road -> Feature in
                var feature = Feature(geometry: .lineString(road.geometry))
                // Use stable ID for the feature to help with label stability
                feature.identifier = .string(road.id)
                feature.properties = [
                    "name": .string(road.streetName),
                    "level": .number(Double(road.level))
                ]
                return feature
            }

            let featureCollection = FeatureCollection(features: features)
            navigationMapView.mapView.mapboxMap.updateGeoJSONSource(
                withId: intersectionsSourceIdentifier,
                geoJSON: .featureCollection(featureCollection)
            )

            lastRenderedFeatureIds = allFeatureIds
        }

        // Clean up cache: remove labels that haven't been seen recently
        // Schedule cleanup for later to avoid removing labels immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + labelCacheExpiry) { [weak self] in
            guard let self = self else { return }
            let idsToRemove = self.labelCache.keys.filter { !currentIds.contains($0) }
            if !idsToRemove.isEmpty {
                print("Cache cleanup: removing \(idsToRemove.count) labels")
            }
            for id in idsToRemove {
                self.labelCache.removeValue(forKey: id)
            }
        }
    }

}
