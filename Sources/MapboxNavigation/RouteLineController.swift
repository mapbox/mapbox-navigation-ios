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
                guard let self = self else { return }
                
                self.navigationMapView.localizeLabels()
                self.navigationMapView.mapView.showsTraffic = false
                self.showRouteIfNeeded()
            }
        }
        
        private func showRouteIfNeeded() {
            guard navigationViewData.containerViewController.isViewLoaded else { return }
            
            guard !navigationMapView.showsRoute else { return }
            navigationMapView.updateRouteLine(routeProgress: router.routeProgress, coordinate: router.location?.coordinate)
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
            navigationMapView.updateRouteLine(routeProgress: router.routeProgress, coordinate: location?.coordinate)
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
        
        func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
            navigationMapView.updateRouteLine(routeProgress: routeProgress, coordinate: router.location?.coordinate)
        }
    }
}
