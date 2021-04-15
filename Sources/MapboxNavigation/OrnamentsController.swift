
import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf
import CoreLocation

/// A components, designed to help manage `NavigationMapView` ornaments logic.
class OrnamentsController: NavigationComponent, NavigationComponentDelegate {
    
    // MARK: - Properties
    
    weak var navigationViewData: NavigationViewData!
    
    fileprivate var navigationView: NavigationView! {
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
                navigationView?.floatingButtonsPosition = newPosition
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
    
    // MARK: - Lifecycle
    
    init(_ navigationViewData: NavigationViewData) {
        self.navigationViewData = navigationViewData
    }
    
    private func resumeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        updateMapViewOrnaments()
    }
    
    // MARK: - Methods
    
    @objc func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let muted = sender.isSelected
        NavigationSettings.shared.voiceMuted = muted
    }
    
    @objc func feedback(_ sender: Any) {
//        showFeedback()
        guard let parent = navigationViewData.navigationViewController else { return }
        let feedbackViewController = FeedbackViewController(eventsManager: navigationViewData.navigationService.eventsManager)
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
            navigationView.wayNameView.text = roadName
            navigationView.wayNameView.isHidden = roadName.isEmpty
            
            return
        }
        
        // Avoid aggressively opting the developer into Mapbox services if they haven’t provided an access token.
        guard let _ = AccountManager.shared.accessToken else {
            navigationView.wayNameView.isHidden = true
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
        
        navigationViewData.navigationViewController.view.bringSubviewToFront(navigationViewData.navigationView.topBannerContainerView)
    }
    
    private func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: navigationViewData.navigationViewController)
        navigationViewData.navigationViewController.addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(navigationViewData.navigationViewController, child) {
            navigationViewData.navigationViewController.view.addConstraints(childConstraints)
        }
        child.didMove(toParent: navigationViewData.navigationViewController)
    }
    
    private func labelCurrentRoadFeature(at location: CLLocation) {
        guard let router = navigationViewData.navigationService.router,
              let stepShape = router.routeProgress.currentLegProgress.currentStep.shape,
              !stepShape.coordinates.isEmpty,
              let mapView = navigationMapView.mapView else {
            return
        }
        
        // Add Mapbox Streets if the map does not already have it
        if mapView.streetsSources().isEmpty {
            var streetsSource = VectorSource()
            streetsSource.url = "mapbox://mapbox.mapbox-streets-v8"
            mapView.style.addSource(source: streetsSource, identifier: "com.mapbox.MapboxStreets")
        }
        
        guard let mapboxStreetsSource = mapView.streetsSources().first else { return }
        
        let identifierNamespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""
        let roadLabelStyleLayerIdentifier = "\(identifierNamespace).roadLabels"
        let roadLabelLayer = try? mapView.style.getLayer(with: roadLabelStyleLayerIdentifier, type: LineLayer.self).get()
        
        if roadLabelLayer == nil {
            var streetLabelLayer = LineLayer(id: roadLabelStyleLayerIdentifier)
            streetLabelLayer.source = mapboxStreetsSource.id
            
            var sourceLayerIdentifier: String? {
                let identifiers = mapView.tileSetIdentifiers(mapboxStreetsSource.id, sourceType: mapboxStreetsSource.type)
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
            streetLabelLayer.paint?.lineOpacity = .constant(1.0)
            streetLabelLayer.paint?.lineWidth = .constant(20.0)
            streetLabelLayer.paint?.lineColor = .constant(.init(color: .white))
            
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
            
            let firstLayerIdentifier = try? mapView.__map.getStyleLayers().first?.id
            mapView.style.addLayer(layer: streetLabelLayer, layerPosition: .init(below: firstLayerIdentifier))
        }
        
        let closestCoordinate = location.coordinate
        let position = mapView.point(for: closestCoordinate)
        mapView.visibleFeatures(at: position, styleLayers: Set([roadLabelStyleLayerIdentifier]), completion: { result in
            switch result {
            case .success(let features):
                var smallestLabelDistance = Double.infinity
                var latestFeature: Feature?
                let slicedLine = stepShape.sliced(from: closestCoordinate)!
                
                for feature in features {
                    var lineStrings: [LineString] = []
                    
                    if let line = feature.geometry.value as? LineString {
                        lineStrings.append(line)
                    } else if let multiLine = feature.geometry.value as? MultiLineString {
                        for coordinates in multiLine.coordinates {
                            lineStrings.append(LineString(coordinates))
                        }
                    }
                    
                    for lineString in lineStrings {
                        let lookAheadDistance: CLLocationDistance = 10
                        guard let pointAheadFeature = lineString.sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        guard let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        guard let reversedPoint = LineString(lineString.coordinates.reversed()).sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        
                        let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                        let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                        let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                        
                        if minDistanceBetweenPoints < smallestLabelDistance {
                            smallestLabelDistance = minDistanceBetweenPoints
                            
                            latestFeature = feature
                        }
                    }
                }
                
                var hideWayName = true
                if smallestLabelDistance < 5 {
                    if self.navigationView.wayNameView.setupWith(roadFeature: latestFeature!, using: self.navigationMapView.mapView.style) {
                        hideWayName = false
                    }
                }
                self.navigationView.wayNameView.isHidden = hideWayName
            case .failure:
                NSLog("Failed to find visible features.")
            }
        })
    }
    
//    private func showFeedback(source: FeedbackSource = .user) {
//        guard let parent = navigationViewData.navigationViewController else { return }
//        let feedbackViewController = FeedbackViewController(eventsManager: navigationViewData.navigationService.eventsManager)
//        feedbackViewController.detailedFeedbackEnabled = detailedFeedbackEnabled
//        parent.present(feedbackViewController, animated: true)
//    }
    
    /**
     Method updates `logoView` and `attributionButton` margins to prevent incorrect alignment
     reported in https://github.com/mapbox/mapbox-navigation-ios/issues/2561.
     */
    private func updateMapViewOrnaments() {
        let bottomBannerHeight = navigationViewData.navigationView.bottomBannerContainerView.bounds.height
        let bottomBannerVerticalOffset = UIScreen.main.bounds.height - bottomBannerHeight - navigationViewData.navigationView.bottomBannerContainerView.frame.origin.y
        let defaultOffset: CGFloat = 10.0
        let x: CGFloat = defaultOffset
        let y: CGFloat = bottomBannerHeight + defaultOffset + bottomBannerVerticalOffset
        
        navigationMapView.mapView.update {
            if #available(iOS 11.0, *) {
                $0.ornaments.logoViewMargins = CGPoint(x: x, y: y - navigationView.safeAreaInsets.bottom)
            } else {
                $0.ornaments.logoViewMargins = CGPoint(x: x, y: y)
            }
            
            if #available(iOS 11.0, *) {
                $0.ornaments.attributionButtonMargins = CGPoint(x: x, y: y - navigationView.safeAreaInsets.bottom)
            } else {
                $0.ornaments.attributionButtonMargins = CGPoint(x: x, y: y)
            }
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
