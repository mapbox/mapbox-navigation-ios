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

final class ElectronicHorizonEventsViewController: UIViewController {
    private let mapboxNavigationProvider: MapboxNavigationProvider = {
        var coreConfig = CoreConfig(
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live
        )

        // Customize the `ElectronicHorizonConfig` to start Electronic Horizon updates.
        coreConfig.electronicHorizonConfig = ElectronicHorizonConfig(
            length: 500,
            expansionLevel: 1,
            branchLength: 50,
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

    private let upcomingIntersectionLabel = UILabel()
    private let routeLineColor: UIColor = .green.withAlphaComponent(0.9)
    private let traversedRouteColor: UIColor = .clear
    private var totalDistance: CLLocationDistance = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        setupUpcomingIntersectionLabel()
        subscribeToElectronicHorizonUpdates()

        mapboxNavigation.tripSession().startFreeDrive()
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
                self?.setupMostProbablePathStyle()
            }.store(in: &subscriptions)
    }

    private func setupUpcomingIntersectionLabel() {
        upcomingIntersectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upcomingIntersectionLabel)

        let safeAreaWidthAnchor = view.safeAreaLayoutGuide.widthAnchor
        NSLayoutConstraint.activate([
            upcomingIntersectionLabel.widthAnchor.constraint(lessThanOrEqualTo: safeAreaWidthAnchor, multiplier: 0.9),
            upcomingIntersectionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            upcomingIntersectionLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        upcomingIntersectionLabel.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
        upcomingIntersectionLabel.layer.cornerRadius = 5
        upcomingIntersectionLabel.numberOfLines = 0
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
        let startingEdge = positionUpdatedEvent.startingEdge

        let currentStreetName = streetName(for: startingEdge)
        let upcomingCrossStreet = nearestCrossStreetName(from: startingEdge)
        updateLabel(currentStreetName: currentStreetName, predictedCrossStreet: upcomingCrossStreet)

        // Update the most probable path when the position update indicates a new most probable path (MPP).
        if positionUpdatedEvent.updatesMostProbablePath {
            let mostProbablePath = routeLine(from: startingEdge, roadGraph: roadGraph)
            updateMostProbablePath(with: mostProbablePath)
        }

        // Update the most probable path layer when the position update indicates
        // a change of the fraction of the point traveled distance to the current edge’s length.
        updateMostProbablePathLayer(
            fractionFromStart: positionUpdatedEvent.position.fractionFromStart,
            roadGraph: roadGraph,
            currentEdge: startingEdge.identifier
        )
    }

    private func streetName(for edge: RoadGraph.Edge) -> String? {
        let edgeMetadata = roadGraph.edgeMetadata(edgeIdentifier: edge.identifier)
        return edgeMetadata?.names.first?.text
    }

    private func nearestCrossStreetName(from edge: RoadGraph.Edge) -> String? {
        let initialStreetName = streetName(for: edge)
        var currentEdge: RoadGraph.Edge? = edge
        while let nextEdge = currentEdge?.outletEdges.max(by: { $0.probability < $1.probability }) {
            if let nextStreetName = streetName(for: nextEdge), nextStreetName != initialStreetName {
                return nextStreetName
            }
            currentEdge = nextEdge
        }
        return nil
    }

    private func updateLabel(currentStreetName: String?, predictedCrossStreet: String?) {
        var statusString = ""
        if let currentStreetName {
            statusString = "Currently on:\n\(currentStreetName)"
            if let predictedCrossStreet {
                statusString += "\nUpcoming intersection with:\n\(predictedCrossStreet)"
            } else {
                statusString += "\nNo upcoming intersections"
            }
        }

        DispatchQueue.main.async {
            self.upcomingIntersectionLabel.text = statusString
            self.upcomingIntersectionLabel.sizeToFit()
        }
    }

    // MARK: - Drawing the most probable path

    private let sourceIdentifier = "mpp-source"
    private let layerIdentifier = "mpp-layer"

    private func routeLine(from edge: RoadGraph.Edge, roadGraph: RoadGraph) -> [LocationCoordinate2D] {
        var coordinates = [LocationCoordinate2D]()
        var edge: RoadGraph.Edge? = edge
        totalDistance = 0.0

        // Update the route line shape and total distance of the most probable path.
        while let currentEdge = edge {
            if let shape = roadGraph.edgeShape(edgeIdentifier: currentEdge.identifier) {
                coordinates.append(contentsOf: shape.coordinates.dropFirst(coordinates.isEmpty ? 0 : 1))
            }
            if let distance = roadGraph.edgeMetadata(edgeIdentifier: currentEdge.identifier)?.length {
                totalDistance += distance
            }
            edge = currentEdge.outletEdges.max(by: { $0.probability < $1.probability })
        }
        return coordinates
    }

    private func updateMostProbablePath(with mostProbablePath: [CLLocationCoordinate2D]) {
        let feature = Feature(geometry: .lineString(LineString(mostProbablePath)))
        navigationMapView.mapView.mapboxMap.updateGeoJSONSource(
            withId: sourceIdentifier,
            geoJSON: .feature(feature)
        )
    }

    private func updateMostProbablePathLayer(
        fractionFromStart: Double,
        roadGraph: RoadGraph,
        currentEdge: RoadGraph.Edge.Identifier
    ) {
        // Based on the length of current edge and the total distance of the most probable path (MPP),
        // calculate the fraction of the point traveled distance to the whole most probable path (MPP).
        if totalDistance > 0.0,
           let currentLength = roadGraph.edgeMetadata(edgeIdentifier: currentEdge)?.length
        {
            let fraction = fractionFromStart * currentLength / totalDistance
            updateMostProbablePathLayerFraction(fraction)
        }
    }

    private func setupMostProbablePathStyle() {
        var source = GeoJSONSource(id: sourceIdentifier)
        source.data = .geometry(Geometry.lineString(LineString([])))
        source.lineMetrics = true
        try? navigationMapView.mapView.mapboxMap.addSource(source)

        var layer = LineLayer(id: layerIdentifier, source: sourceIdentifier)
        layer.source = sourceIdentifier
        layer.lineWidth = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                RouteLineWidthByZoomLevel.mapValues { $0 * 0.5 }
            }
        )
        layer.lineColor = .constant(.init(routeLineColor))
        layer.lineCap = .constant(.round)
        layer.lineJoin = .constant(.miter)
        layer.minZoom = 9
        layer.slot = .middle
        try? navigationMapView.mapView.mapboxMap.addLayer(layer)
    }

    // Update the line gradient property of the most probable path line layer,
    // so the part of the most probable path that has been traversed will be rendered with full transparency.
    private func updateMostProbablePathLayerFraction(_ fraction: Double) {
        let nextDown = max(fraction.nextDown, 0.0)
        let exp = Exp(.step) {
            Exp(.lineProgress)
            traversedRouteColor
            nextDown
            traversedRouteColor
            fraction
            routeLineColor
        }

        if let data = try? JSONEncoder().encode(exp.self),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [])
        {
            try? navigationMapView.mapView.mapboxMap.setLayerProperty(
                for: layerIdentifier,
                property: "line-gradient",
                value: jsonObject
            )
        }
    }
}
