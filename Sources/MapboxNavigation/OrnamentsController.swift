import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf
import CoreLocation

extension NavigationMapView {
    /// A components, designed to help manage `NavigationMapView` ornaments logic.
    class OrnamentsController: NavigationComponent, NavigationComponentDelegate {
        
        // MARK: - Properties
        
        weak var navigationViewData: NavigationViewData!
        weak var eventsManager: NavigationEventsManager!
        
        fileprivate var navigationView: NavigationView {
            return navigationViewData.navigationView
        }
        
        fileprivate var navigationMapView: NavigationMapView {
            return navigationViewData.navigationView.navigationMapView
        }
        
        var detailedFeedbackEnabled: Bool = false
        
        var showsSpeedLimits: Bool = true {
            didSet {
                navigationView.speedLimitView.isAlwaysHidden = !showsSpeedLimits
            }
        }
        
        var floatingButtonsPosition: MapOrnamentPosition? {
            get {
                return navigationView.floatingButtonsPosition
            }
            set {
                if let newPosition = newValue {
                    navigationView.floatingButtonsPosition = newPosition
                }
            }
        }
        
        var floatingButtons: [UIButton]? {
            get {
                return navigationView.floatingButtons
            }
            set {
                navigationView.floatingButtons = newValue
            }
        }
        
        var reportButton: FloatingButton {
            return navigationViewData.navigationView.reportButton
        }
        
        typealias LabelRoadNameCompletionHandler = (_ defaultRoadNameAssigned: Bool) -> Void
        
        var labelRoadNameCompletionHandler: (LabelRoadNameCompletionHandler)?
        
        var roadNameFromStatus: String?
        
        // MARK: - Lifecycle
        
        init(_ navigationViewData: NavigationViewData, eventsManager: NavigationEventsManager) {
            self.navigationViewData = navigationViewData
            self.eventsManager = eventsManager
        }
        
        private func resumeNotifications() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(orientationDidChange(_:)),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didUpdateRoadNameFromStatus),
                                                   name: .currentRoadNameDidChange,
                                                   object: nil)
        }
        
        private func suspendNotifications() {
            NotificationCenter.default.removeObserver(self,
                                                      name: UIDevice.orientationDidChangeNotification,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: .currentRoadNameDidChange,
                                                      object: nil)
        }
        
        @objc func orientationDidChange(_ notification: Notification) {
            updateMapViewOrnaments()
        }
        
        @objc func didUpdateRoadNameFromStatus(_ notification: Notification) {
            roadNameFromStatus = notification.userInfo?[RouteController.NotificationUserInfoKey.roadNameKey] as? String
        }
        
        // MARK: - Methods
        
        @objc func toggleMute(_ sender: UIButton) {
            sender.isSelected = !sender.isSelected
            
            let muted = sender.isSelected
            NavigationSettings.shared.voiceMuted = muted
        }
        
        @objc func feedback(_ sender: Any) {
            let parent = navigationViewData.containerViewController
            let feedbackViewController = FeedbackViewController(eventsManager: eventsManager)
            feedbackViewController.detailedFeedbackEnabled = detailedFeedbackEnabled
            parent.present(feedbackViewController, animated: true)
        }
        
        /**
         Updates the current road name label to reflect the road on which the user is currently traveling.
         
         - parameter at: The user’s current location as provided by the system location management system. This has less priority then `snappedLocation` (see below) and is used only if method will attempt to resolve road name automatically.
         - parameter suggestedName: The road name to put onto label. If not provided - method will attempt to extract the closest road name from map features.
         - parameter snappedLocation: User's location, snapped to the road network. Has higher priority then `at` location.
         */
        func labelCurrentRoad(at rawLocation: CLLocation, suggestedName roadName: String?, for snappedLocation: CLLocation? = nil) {
            guard navigationView.resumeButton.isHidden else { return }
            
            if let roadName = roadName {
                navigationView.wayNameView.text = roadName.nonEmptyString
                navigationView.wayNameView.isHidden = roadName.isEmpty
                
                return
            }
            
            labelCurrentRoadFeature(at: snappedLocation ?? rawLocation)
            
            if let labelRoadNameCompletionHandler = labelRoadNameCompletionHandler {
                labelRoadNameCompletionHandler(true)
            }
        }
        
        func embedBanners(topBanner: ContainerViewController, bottomBanner: ContainerViewController) {
            let topContainer = navigationViewData.navigationView.topBannerContainerView
            
            embed(topBanner, in: topContainer) { (parent, banner) -> [NSLayoutConstraint] in
                banner.view.translatesAutoresizingMaskIntoConstraints = false
                return banner.view.constraintsForPinning(to: self.navigationViewData.navigationView.topBannerContainerView)
            }
            
            topContainer.backgroundColor = .clear
            
            let bottomContainer = navigationViewData.navigationView.bottomBannerContainerView
            embed(bottomBanner, in: bottomContainer) { (parent, banner) -> [NSLayoutConstraint] in
                banner.view.translatesAutoresizingMaskIntoConstraints = false
                return banner.view.constraintsForPinning(to: self.navigationViewData.navigationView.bottomBannerContainerView)
            }
            
            bottomContainer.backgroundColor = .clear
            
            navigationViewData.containerViewController.view.bringSubviewToFront(navigationViewData.navigationView.topBannerContainerView)
        }
        
        private func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
            child.willMove(toParent: navigationViewData.containerViewController)
            navigationViewData.containerViewController.addChild(child)
            container.addSubview(child.view)
            if let childConstraints: [NSLayoutConstraint] = constraints?(navigationViewData.containerViewController, child) {
                navigationViewData.containerViewController.view.addConstraints(childConstraints)
            }
            child.didMove(toParent: navigationViewData.containerViewController)
        }
        
        private func labelCurrentRoadFeature(at location: CLLocation) {
            let router = navigationViewData.router
            guard
                  let stepShape = router.routeProgress.currentLegProgress.currentStep.shape,
                  !stepShape.coordinates.isEmpty,
                  let mapView = navigationMapView.mapView else {
                return
            }
            
            // Add Mapbox Streets if the map does not already have it
            if mapView.streetsSources().isEmpty {
                var streetsSource = VectorSource()
                streetsSource.url = "mapbox://mapbox.mapbox-streets-v8"
                
                let sourceIdentifier = "com.mapbox.MapboxStreets"
                
                do {
                    try mapView.mapboxMap.style.addSource(streetsSource, id: sourceIdentifier)
                } catch {
                    NSLog("Failed to add \(sourceIdentifier) with error: \(error.localizedDescription).")
                }
            }
            
            guard let mapboxStreetsSource = mapView.streetsSources().first else { return }
            
            let identifierNamespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""
            let roadLabelStyleLayerIdentifier = "\(identifierNamespace).roadLabels"
            let roadLabelLayer = try? mapView.mapboxMap.style.layer(withId: roadLabelStyleLayerIdentifier) as LineLayer
            
            if roadLabelLayer == nil {
                var streetLabelLayer = LineLayer(id: roadLabelStyleLayerIdentifier)
                streetLabelLayer.source = mapboxStreetsSource.id
                
                var sourceLayerIdentifier: String? {
                    let identifiers = mapView.tileSetIdentifiers(mapboxStreetsSource.id,
                                                                 sourceType: mapboxStreetsSource.type.rawValue)
                    if VectorSource.isMapboxStreets(identifiers) {
                        let roadLabelLayerIdentifiersByTileSetIdentifier = [
                            "mapbox.mapbox-streets-v8": "road",
                            "mapbox.mapbox-streets-v7": "road_label",
                        ]
                        
                        return identifiers.compactMap({ roadLabelLayerIdentifiersByTileSetIdentifier[$0] }).first
                    }
                    
                    return nil
                }
                
                streetLabelLayer.sourceLayer = sourceLayerIdentifier
                streetLabelLayer.lineOpacity = .constant(1.0)
                streetLabelLayer.lineWidth = .constant(20.0)
                streetLabelLayer.lineColor = .constant(.init(color: .white))
                
                if ![DirectionsProfileIdentifier.walking, DirectionsProfileIdentifier.cycling].contains(router.routeProgress.routeOptions.profileIdentifier) {
                    // Filter out to road classes valid only for motor transport.
                    let filter = Exp(.inExpression) {
                        "class"
                        "motorway"
                        "motorway_link"
                        "trunk"
                        "trunk_link"
                        "primary"
                        "primary_link"
                        "secondary"
                        "secondary_link"
                        "tertiary"
                        "tertiary_link"
                        "street"
                        "street_limited"
                        "roundabout"
                    }
                    
                    streetLabelLayer.filter = filter
                }
                
                do {
                    var layerPosition: MapboxMaps.LayerPosition? = nil
                    if let firstLayerIdentifier = mapView.mapboxMap.style.allLayerIdentifiers.first?.id {
                        layerPosition = .below(firstLayerIdentifier)
                    }
                    
                    try mapView.mapboxMap.style.addLayer(streetLabelLayer, layerPosition: layerPosition)
                } catch {
                    NSLog("Failed to add \(roadLabelStyleLayerIdentifier) with error: \(error.localizedDescription).")
                }
            }
            
            let closestCoordinate = location.coordinate
            let position = mapView.mapboxMap.point(for: closestCoordinate)
            
            mapView.mapboxMap.queryRenderedFeatures(at: position,
                                                    options: RenderedQueryOptions(layerIds: [roadLabelStyleLayerIdentifier], filter: nil)) { [weak self] result in
                switch result {
                case .success(let queriedFeatures):
                    guard let self = self else { return }
                    
                    var smallestLabelDistance = Double.infinity
                    var latestFeature: MapboxCommon.Feature?
                    
                    var minimumEditDistance = Int.max
                    var similarFeature: MapboxCommon.Feature?

                    for queriedFeature in queriedFeatures {
                        // Calculate the Levenshtein–Damerau edit distance between the road name from status and the feature property road name, and then use the smallest one for the road label.
                        if let roadName = queriedFeature.feature.properties["name"] as? String,
                           let roadNameFromStatus = self.roadNameFromStatus {
                            let stringEditDistance = roadNameFromStatus.minimumEditDistance(to: roadName)
                            if stringEditDistance < minimumEditDistance {
                                minimumEditDistance = stringEditDistance
                                similarFeature = queriedFeature.feature
                            }
                        }
                        
                        var lineStrings: [LineString] = []
                        
                        if queriedFeature.feature.geometry.geometryType == GeometryType_Line,
                           let coordinates = queriedFeature.feature.geometry.extractLocationsArray() as? [CLLocationCoordinate2D] {
                            lineStrings.append(LineString(coordinates))
                        } else if queriedFeature.feature.geometry.geometryType == GeometryType_MultiLine,
                                  let coordinates = queriedFeature.feature.geometry.extractLocations2DArray() as? [[CLLocationCoordinate2D]] {
                            for coordinates in coordinates {
                                lineStrings.append(LineString(coordinates))
                            }
                        }
                        
                        for lineString in lineStrings {
                            let lookAheadDistance: CLLocationDistance = 10
                            guard let pointAheadFeature = lineString.sliced(from: closestCoordinate)?.coordinateFromStart(distance: lookAheadDistance) else { continue }
                            guard let slicedLine = stepShape.sliced(from: closestCoordinate),
                                  let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                            guard let reversedPoint = LineString(lineString.coordinates.reversed()).sliced(from: closestCoordinate)?.coordinateFromStart(distance: lookAheadDistance) else { continue }
                            
                            let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                            let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                            let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                            
                            if minDistanceBetweenPoints < smallestLabelDistance {
                                smallestLabelDistance = minDistanceBetweenPoints
                                
                                latestFeature = queriedFeature.feature
                            }
                        }
                    }
                    
                    var hideWayName = true
                    if latestFeature != similarFeature {
                        let style = self.navigationMapView.mapView.mapboxMap.style
                        if let similarFeature = similarFeature,
                           self.navigationView.wayNameView.setupWith(feature: similarFeature,
                                                                     using: style) {
                            hideWayName = false
                        }
                    } else if smallestLabelDistance < 5 {
                        let style = self.navigationMapView.mapView.mapboxMap.style
                        if let latestFeature = latestFeature,
                           self.navigationView.wayNameView.setupWith(feature: latestFeature,
                                                                     using: style) {
                            hideWayName = false
                        }
                    }
                    self.navigationView.wayNameView.isHidden = hideWayName
                case .failure:
                    NSLog("Failed to find visible features.")
                }
            }
        }
        
        /**
         Method updates `logoView` and `attributionButton` margins to prevent incorrect alignment
         reported in https://github.com/mapbox/mapbox-navigation-ios/issues/2561.
         */
        private func updateMapViewOrnaments() {
            let bottomBannerHeight = navigationViewData.navigationView.bottomBannerContainerView.bounds.height
            let bottomBannerVerticalOffset = navigationViewData.navigationView.bounds.height - bottomBannerHeight - navigationViewData.navigationView.bottomBannerContainerView.frame.origin.y
            let defaultOffset: CGFloat = 10.0
            let x: CGFloat = defaultOffset
            let y: CGFloat = bottomBannerHeight + defaultOffset + bottomBannerVerticalOffset
            
            if #available(iOS 11.0, *) {
                navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(x: x, y: y - navigationView.safeAreaInsets.bottom)
            } else {
                navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(x: x, y: y)
            }
            
            if #available(iOS 11.0, *) {
                navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(x: x, y: y - navigationView.safeAreaInsets.bottom)
            } else {
                navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(x: x, y: y)
            }
        }
        
        // MARK: - NavigationComponentDelegate implementation
        
        func navigationViewDidLoad(_: UIView) {
            navigationViewData.navigationView.muteButton.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
            navigationViewData.navigationView.reportButton.addTarget(self, action: #selector(feedback(_:)), for: .touchUpInside)
        }
        
        func navigationViewWillAppear(_: Bool) {
            resumeNotifications()
            navigationViewData.navigationView.muteButton.isSelected = NavigationSettings.shared.voiceMuted
        }
        
        func navigationViewDidDisappear(_: Bool) {
            suspendNotifications()
        }
        
        func navigationViewDidLayoutSubviews() {
            updateMapViewOrnaments()
        }
        
        // MARK: - NavigationComponent implementation
        
        func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
            
            navigationViewData.navigationView.speedLimitView.signStandard = progress.currentLegProgress.currentStep.speedLimitSignStandard
            navigationViewData.navigationView.speedLimitView.speedLimit = progress.currentLegProgress.currentSpeedLimit
        }
    }
}
