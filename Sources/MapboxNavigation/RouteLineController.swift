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
            navigationMapView.mapView.mapboxMap.onEvery(event: .styleLoaded) { [weak self] _ in
                guard let self = self else { return }
                
                self.navigationMapView.localizeLabels()
                self.navigationMapView.mapView.showsTraffic = false
                self.showRouteIfNeeded()
            }
        }
        
        private func showRouteIfNeeded() {
            guard navigationViewData.containerViewController.isViewLoaded else { return }
            
            guard !navigationMapView.showsRoute else { return }
            navigationMapView.updateRouteLine(routeProgress: router.routeProgress,
                                              coordinate: router.location?.coordinate,
                                              shouldRedraw: true)
            navigationMapView.showWaypoints(on: router.route, legIndex: router.routeProgress.legIndex)
            
            let currentLegProgress = router.routeProgress.currentLegProgress
            let nextStepIndex = currentLegProgress.stepIndex + 1
            
            if nextStepIndex <= currentLegProgress.leg.steps.count,
               navigationMapView.routes != nil {
                navigationMapView.addArrow(route: router.route, legIndex: router.routeProgress.legIndex, stepIndex: nextStepIndex)
            }
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: router.route)
            }
            
            if annotatesIntersections {
                navigationMapView.updateIntersectionAnnotations(with: router.routeProgress)
            }
        }
        
        func navigationViewDidAppear(_ animated: Bool) {
            currentLegIndexMapped = router.routeProgress.legIndex
            currentStepIndexMapped = router.routeProgress.currentLegProgress.stepIndex
        }
        
        // MARK: NavigationComponent implementation
        
        func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
            handleReroute()
        }
        
        func navigationService(_ service: NavigationService, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
            handleReroute()
        }
        
        private func handleReroute() {
            currentStepIndexMapped = 0
            let route = router.route
            let stepIndex = router.routeProgress.currentLegProgress.stepIndex
            let legIndex = router.routeProgress.legIndex
            
            navigationMapView.removeWaypoints()
            
            navigationMapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
            navigationMapView.updateRouteLine(routeProgress: router.routeProgress,
                                              coordinate: router.location?.coordinate,
                                              shouldRedraw: true)
            navigationMapView.showWaypoints(on: route)
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: route)
            }
            
            if annotatesIntersections {
                navigationMapView.updateIntersectionAnnotations(with: router.routeProgress)
            }
        }
        
        func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
            let route = progress.route
            let legIndex = progress.legIndex
            let stepIndex = progress.currentLegProgress.stepIndex
            
            navigationMapView.updatePreferredFrameRate(for: progress)
            if currentLegIndexMapped != legIndex {
                navigationMapView.showWaypoints(on: route, legIndex: legIndex)
            }
            
            if currentStepIndexMapped != stepIndex {
                updateMapOverlays(for: progress)
                currentStepIndexMapped = stepIndex
            }
            
            if annotatesSpokenInstructions {
                navigationMapView.showVoiceInstructionsOnMap(route: route)
            }
            
            if annotatesIntersections {
                navigationMapView.updateIntersectionAnnotations(with: progress)
            }
            
            navigationMapView.updateRouteLine(routeProgress: progress, coordinate: location.coordinate, shouldRedraw: currentLegIndexMapped != legIndex)
            currentLegIndexMapped = legIndex
        }
        
        private func updateMapOverlays(for routeProgress: RouteProgress) {
            if routeProgress.currentLegProgress.followOnStep != nil,
               navigationMapView.routes != nil {
                navigationMapView.addArrow(route: routeProgress.route,
                                           legIndex: routeProgress.legIndex,
                                           stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
            } else {
                navigationMapView.removeArrow()
            }
        }
        
        // MARK: Annotations Overlay
        
        var annotatesSpokenInstructions = false
        var annotatesIntersections: Bool = true
        
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
        
        func locationUpdate(newLocation: Location) {
            // Since `navigationViewData` is stored weakly in rare cases it might be deallocated before
            // running current method. Such check prevents crash in such situations.
            if navigationViewData == nil { return }
            
            if routeLineTracksTraversal {
                navigationMapView.travelAlongRouteLine(to: newLocation.coordinate)
            }
        }
        
        func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
            navigationMapView.updateRouteLine(routeProgress: routeProgress,
                                              coordinate: router.location?.coordinate,
                                              shouldRedraw: true)
        }
    }
}
