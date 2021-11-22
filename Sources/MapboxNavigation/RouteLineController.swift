import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import CoreLocation
import UIKit

extension NavigationMapView {
    /// A component meant to assist displaying route line and related items like arrows, waypoints, annotations and other.
    class RouteOverlayController: NavigationComponent, NavigationComponentDelegate, LocationConsumer {
        
        weak private(set) var navigationViewData: NavigationViewData!
        
        fileprivate var navigationMapView: NavigationMapView {
            return navigationViewData.navigationView.navigationMapView
        }
        
        fileprivate var router: Router! {
            navigationViewData.router
        }
        
        init(_ navigationViewData: NavigationViewData) {
            self.navigationViewData = navigationViewData
        }
        
        // MARK: NavigationComponentDelegate implementation
        
        func navigationViewDidLoad(_ view: UIView) {
            navigationMapView.mapView.mapboxMap.onEvery(.styleLoaded) { [weak self] _ in
                self?.navigationMapView.localizeLabels()
                self?.navigationMapView.mapView.showsTraffic = false
                self?.showRouteIfNeeded()
                
                // FIXME: In case when building highlighting feature is enabled due to style changes and no info currently being stored
                // regarding building identification such highlighted building will disappear.
            }
        }
        
        private func showRouteIfNeeded() {
            guard navigationViewData.containerViewController.isViewLoaded else { return }
            
            guard !navigationMapView.showsRoute else { return }
            updateRouteLine(routeProgress: router.routeProgress, coordinate: router.location?.coordinate)
            navigationMapView.showWaypoints(on: router.route, legIndex: router.routeProgress.legIndex)
            
            let currentLegProgress = router.routeProgress.currentLegProgress
            let nextStepIndex = currentLegProgress.stepIndex + 1
            
            if nextStepIndex <= currentLegProgress.leg.steps.count {
                navigationMapView.addArrow(route: router.route, legIndex: router.routeProgress.legIndex, stepIndex: nextStepIndex)
            }
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: router.route)
            }
        }
        
        func navigationViewDidAppear(_ animated: Bool) {
            currentLegIndexMapped = router.routeProgress.legIndex
            currentStepIndexMapped = router.routeProgress.currentLegProgress.stepIndex
        }
        
        // MARK: NavigationComponent implementation
        
        func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
            currentStepIndexMapped = 0
            let route = router.route
            let stepIndex = router.routeProgress.currentLegProgress.stepIndex
            let legIndex = router.routeProgress.legIndex
            
            navigationMapView.removeWaypoints()
            
            navigationMapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
            updateRouteLine(routeProgress: router.routeProgress, coordinate: location?.coordinate)
            navigationMapView.showWaypoints(on: route)
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: route)
            }
        }
        
        func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
            let route = progress.route
            let legIndex = progress.legIndex
            let stepIndex = progress.currentLegProgress.stepIndex
            
            navigationMapView.updatePreferredFrameRate(for: progress)
            if currentLegIndexMapped != legIndex {
                navigationMapView.showWaypoints(on: route, legIndex: legIndex)
                navigationMapView.show([route], legIndex: legIndex)
                
                currentLegIndexMapped = legIndex
            }
            
            if currentStepIndexMapped != stepIndex {
                updateMapOverlays(for: progress)
                currentStepIndexMapped = stepIndex
            }
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: route)
            }
            
            if routeLineTracksTraversal {
                if progress.routeIsComplete && (navigationMapView.routes != nil) {
                    navigationMapView.removeRoutes()
                }
                navigationMapView.updateUpcomingRoutePointIndex(routeProgress: progress)
                navigationMapView.travelAlongRouteLine(to: location.coordinate)
            }
        }
        
        private func updateMapOverlays(for routeProgress: RouteProgress) {
            if routeProgress.currentLegProgress.followOnStep != nil {
                navigationMapView.addArrow(route: routeProgress.route,
                                           legIndex: routeProgress.legIndex,
                                           stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
            } else {
                navigationMapView.removeArrow()
            }
        }
        
        // MARK: Annotations Overlay
        
        var annotatesSpokenInstructions = false
        
        private var currentLegIndexMapped = 0
        private var currentStepIndexMapped = 0
        
        // MARK: Route Line Traversal Tracking
        
        var routeLineTracksTraversal: Bool {
            get {
                navigationMapView.routeLineTracksTraversal
            }
            set {
                navigationMapView.routeLineTracksTraversal = newValue
                if newValue {
                    navigationMapView.mapView.location.addLocationConsumer(newConsumer: self)
                } else {
                    navigationMapView.mapView.location.removeLocationConsumer(consumer: self)
                }
            }
        }
        
        internal func locationUpdate(newLocation: Location) {
            if routeLineTracksTraversal {
                navigationMapView.travelAlongRouteLine(to: newLocation.coordinate)
            }
        }
        
        private func updateRouteLine(routeProgress: RouteProgress, coordinate: CLLocationCoordinate2D?) {
            navigationMapView.show([routeProgress.route], legIndex: routeProgress.legIndex)
            if routeLineTracksTraversal {
                if routeProgress.routeIsComplete {
                    navigationMapView.removeRoutes()
                }
                navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
                navigationMapView.travelAlongRouteLine(to: coordinate)
            }
        }
        
        func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
            updateRouteLine(routeProgress: routeProgress, coordinate: router.location?.coordinate)
        }
    }
}
