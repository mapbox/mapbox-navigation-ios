import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import Turf
import CoreLocation

/// A components, designed to help manage `NavigationMapView` ornaments logic.
class OrnamentsController: NavigationComponent, NavigationComponentDelegate {
    
    // MARK: Lifecycle Management
    
    weak var navigationViewData: NavigationViewData!
    weak var eventsManager: NavigationEventsManager!
    
    fileprivate var navigationView: NavigationView {
        return navigationViewData.navigationView
    }
    
    fileprivate var navigationMapView: NavigationMapView {
        return navigationViewData.navigationView.navigationMapView
    }
    
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
    
    // MARK: Feedback Collection
    
    var detailedFeedbackEnabled: Bool = false
    
    @objc func feedback(_ sender: Any) {
        let parent = navigationViewData.containerViewController
        let feedbackViewController = FeedbackViewController(eventsManager: eventsManager)
        feedbackViewController.detailedFeedbackEnabled = detailedFeedbackEnabled
        parent.present(feedbackViewController, animated: true)
    }
    
    // MARK: Map View Ornaments Handlers
    
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
        return navigationView.reportButton
    }
    
    @objc func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        let muted = sender.isSelected
        NavigationSettings.shared.voiceMuted = muted
    }
    
    /**
     Method updates `logoView` and `attributionButton` margins to prevent incorrect alignment
     reported in https://github.com/mapbox/mapbox-navigation-ios/issues/2561.
     */
    private func updateMapViewOrnaments() {
        let bottomBannerHeight = navigationView.bottomBannerContainerView.bounds.height
        let bottomBannerVerticalOffset = navigationView.bounds.height - bottomBannerHeight - navigationView.bottomBannerContainerView.frame.origin.y
        let defaultOffset: CGFloat = 10.0
        let x: CGFloat = 10.0
        let y: CGFloat = bottomBannerHeight + defaultOffset + bottomBannerVerticalOffset
        
        navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(x: x - navigationView.safeAreaInsets.left,
                                                                           y: y - navigationView.safeAreaInsets.bottom)
        
        switch navigationView.traitCollection.verticalSizeClass {
        case .unspecified:
            fallthrough
        case .regular:
            navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(x: -navigationView.safeAreaInsets.right,
                                                                                            y: y - navigationView.safeAreaInsets.bottom)
        case .compact:
            if UIApplication.shared.statusBarOrientation == .landscapeRight {
                navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(x: -navigationView.safeAreaInsets.right,
                                                                                                y: defaultOffset - navigationView.safeAreaInsets.bottom)
            } else {
                navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(x: 0.0,
                                                                                                y: defaultOffset - navigationView.safeAreaInsets.bottom)
            }
        @unknown default:
            break
        }
    }
    
    // MARK: Road Labelling
    
    typealias LabelRoadNameCompletionHandler = (_ defaultRoadNameAssigned: Bool) -> Void
    
    var labelRoadNameCompletionHandler: (LabelRoadNameCompletionHandler)?
    
    @objc func didUpdateRoadNameFromStatus(_ notification: Notification) {
        let roadNameFromStatus = notification.userInfo?[RouteController.NotificationUserInfoKey.roadNameKey] as? String
        if let roadName = roadNameFromStatus?.nonEmptyString {
            let representation = notification.userInfo?[RouteController.NotificationUserInfoKey.routeShieldRepresentationKey] as? VisualInstruction.Component.ImageRepresentation
            navigationView.wayNameView.label.updateRoad(roadName: roadName, representation: representation)
            
            // The `WayNameView` will be hidden when not under following camera state.
            navigationView.wayNameView.containerView.isHidden = !navigationView.resumeButton.isHidden
        } else {
            navigationView.wayNameView.text = nil
            navigationView.wayNameView.containerView.isHidden = true
            return
        }
    }
    
    /**
     Update the sprite repository of current road label when map style changes.
     
     - parameter styleURI: The `StyleURI` that the map is presenting.
     */
    func updateStyle(styleURI: StyleURI?) {
        navigationView.wayNameView.label.updateStyle(styleURI: styleURI)
    }
    
    /**
     Update the current road name label to reflect the road name user suggested.
     
     - parameter suggestedName: The road name to put onto label. If not provided - method will ignore it.
     */
    func labelCurrentRoadName(suggestedName roadName: String?) {
        // The `WayNameView` will be hidden when not under following camera state.
        guard navigationView.resumeButton.isHidden else { return }
        
        if let roadName = roadName {
            navigationView.wayNameView.text = roadName.nonEmptyString
            navigationView.wayNameView.containerView.isHidden = roadName.isEmpty
            return
        }
    }
    
    // MARK: NavigationComponentDelegate implementation
    
    func navigationViewDidLoad(_: UIView) {
        navigationView.muteButton.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
        navigationView.reportButton.addTarget(self, action: #selector(feedback(_:)), for: .touchUpInside)
    }
    
    func navigationViewWillAppear(_: Bool) {
        resumeNotifications()
        navigationView.muteButton.isSelected = NavigationSettings.shared.voiceMuted
    }
    
    func navigationViewDidDisappear(_: Bool) {
        suspendNotifications()
    }
    
    func navigationViewDidLayoutSubviews() {
        updateMapViewOrnaments()
    }
    
    // MARK: NavigationComponent implementation
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        navigationView.speedLimitView.signStandard = progress.currentLegProgress.currentStep.speedLimitSignStandard
        navigationView.speedLimitView.speedLimit = progress.currentLegProgress.currentSpeedLimit
    }
}
