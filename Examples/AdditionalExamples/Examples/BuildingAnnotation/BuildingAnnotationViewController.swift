/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import Turf
import UIKit
import Combine

final class BuildingAnnotationViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.7627,
                    longitude: -122.4192
                ),
                speedMultiplier: 4
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }
    
    private var cancellable: Any? = nil

    // Building annotation manager (created lazily after navigation view is available)
    private var buildingAnnotationManager: BuildingAnnotationManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        let waypoint1 = CLLocationCoordinate2DMake(37.7627, -122.4192)
        let waypoint2 = CLLocationCoordinate2DMake(37.7653577, -122.4183502)
        let waypoint3 = CLLocationCoordinate2DMake(37.7657253, -122.4145371)
        let options = NavigationRouteOptions(coordinates: [waypoint1, waypoint2, waypoint3])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):

                // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider.routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager()
                )

                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )
                
                if let navMapView = navigationViewController.navigationMapView {
                    cancellable = navMapView.mapView.mapboxMap.onStyleLoaded.observe { _ in
                        print("in onStyleLoaded")
                        try? navMapView.mapView.mapboxMap
                            .setStyleImportConfigProperty(
                                for: "basemap",
                                config: "show3dObjects",
                                value: false
                            )
                    }
                }

                navigationViewController.delegate = self

                // Disable the default arrival experience to keep the building annotation visible
                navigationViewController.showsEndOfRouteFeedback = false

                // Render part of the route that has been traversed with full transparency, to give the illusion of a
                // disappearing route.
                navigationViewController.routeLineTracksTraversal = true

                // Embed as a child view controller instead of presenting modally
                // This prevents auto-dismissal on arrival
                addChild(navigationViewController)
                view.addSubview(navigationViewController.view)
                navigationViewController.view.frame = view.bounds
                navigationViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                navigationViewController.didMove(toParent: self)
            }
        }
    }

    /// Extracts coordinate points from polygon geometries.
    /// - Parameter geometry: The geometry to extract points from
    /// - Returns: Array of coordinates for the outer ring of a polygon, or nil for non-polygon geometries
    private func extractPoints(from geometry: Geometry) -> [CLLocationCoordinate2D]? {
        switch geometry {
        case .polygon(let polygon):
            return polygon.outerRing.coordinates
        case .multiPolygon(let multiPolygon):
            return multiPolygon.coordinates.first?.first
        default:
            return nil
        }
    }
}

extension BuildingAnnotationViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) {
        // Check if this is the final destination
        guard let routeProgress = navigationViewController.mapboxNavigation.navigation().currentRouteProgress?.routeProgress,
              routeProgress.isFinalLeg else {
            return
        }

        Task {
            do {
                if let navMapView = navigationViewController.navigationMapView {
                    let buildings = try await navMapView.queryBuildings(at: waypoint.coordinate)

                    if let building = buildings.first,
                       let points = extractPoints(from: building.geometry) {
                        if buildingAnnotationManager == nil {
                            buildingAnnotationManager = BuildingAnnotationManager(mapView: navMapView.mapView)
                        }

                        // Create and add building annotation
                        let annotation = BuildingAnnotation(
                            coordinates: points,
                            fillExtrusionColor: .red,
                            fillExtrusionOpacity: 0.8,
                            fillExtrusionHeight: 50.0,
                            fillExtrusionBase: 0.0
                        )
                        buildingAnnotationManager?.annotations = [annotation]
                    }
                }
            } catch {
                // Silently handle errors
            }
        }
    }
}

