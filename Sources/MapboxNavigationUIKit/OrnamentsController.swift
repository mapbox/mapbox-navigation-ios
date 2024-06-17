import Combine
import CoreLocation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import Turf
import UIKit

/// A components, designed to help manage `NavigationMapView` ornaments logic.
class OrnamentsController: NavigationComponentDelegate {
    // MARK: Lifecycle Management

    weak var navigationViewData: NavigationViewData? {
        didSet {
            if !subscriptions.isEmpty {
                subscriptions.removeAll()
                resumeNotifications()
            }
        }
    }

    weak var eventsManager: NavigationEventsManager!
    private var subscriptions: Set<AnyCancellable> = []

    fileprivate var navigationView: NavigationView? {
        return navigationViewData?.navigationView
    }

    fileprivate var navigationMapView: NavigationMapView? {
        return navigationViewData?.navigationView.navigationMapView
    }

    init(_ navigationViewData: NavigationViewData, eventsManager: NavigationEventsManager) {
        self.navigationViewData = navigationViewData
        self.eventsManager = eventsManager
    }

    private func resumeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        Task { @MainActor in
            navigationViewData?.mapboxNavigation.navigation().locationMatching
                .sink { [weak self] status in
                    self?.updateSpeedLimitFromStatus(status.speedLimit, currentSpeed: status.currentSpeed)
                }
                .store(in: &subscriptions)
            navigationViewData?.navigationView.navigationMapView.navigationCamera.cameraStates
                .sink { [weak self] in
                    self?.navigationCameraStateDidChange($0)
                }
                .store(in: &subscriptions)
        }
    }

    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        subscriptions.removeAll()
    }

    @objc
    func orientationDidChange(_ notification: Notification) {
        // There are some race conditions when superview of the `NavigationView` no longer exists
        // (e.g. when device orientation changes and `NavigationView` is being removed at the same time).
        // Do not apply layout constraints in such cases.
        if navigationView?.superview == nil { return }

        navigationView?.setupConstraints()
        updateMapViewOrnaments()
    }

    func embedBanners(
        topBannerViewController: ContainerViewController,
        bottomBannerViewController: ContainerViewController
    ) {
        if let bottomBannerContainerView = navigationView?.bottomBannerContainerView {
            navigationViewData?.containerViewController.embed(
                bottomBannerViewController,
                in: bottomBannerContainerView
            ) { _, banner -> [NSLayoutConstraint] in
                banner.view.translatesAutoresizingMaskIntoConstraints = false
                return banner.view.constraintsForPinning(to: bottomBannerContainerView)
            }

            bottomBannerContainerView.backgroundColor = .clear
            bottomBannerContainerView.isHidden = false
        }

        if let topBannerContainerView = navigationView?.topBannerContainerView {
            navigationViewData?.containerViewController
                .embed(topBannerViewController, in: topBannerContainerView) { _, banner -> [NSLayoutConstraint] in
                    banner.view.translatesAutoresizingMaskIntoConstraints = false
                    return banner.view.constraintsForPinning(to: topBannerContainerView)
                }

            topBannerContainerView.backgroundColor = .clear
            topBannerContainerView.isHidden = false
            navigationViewData?.containerViewController.view.bringSubviewToFront(topBannerContainerView)
        }
    }

    // MARK: Feedback Collection

    @objc
    func feedback(_ sender: Any) {
        if let parent = navigationViewData?.containerViewController {
            let feedbackViewController = FeedbackViewController(eventsManager: eventsManager)
            parent.present(feedbackViewController, animated: true)
        }
    }

    // MARK: Map View Ornaments Handlers

    var showsSpeedLimits: Bool = true {
        didSet {
            navigationView?.speedLimitView.isAlwaysHidden = !showsSpeedLimits
        }
    }

    var floatingButtonsPosition: MapOrnamentPosition? {
        get {
            return navigationView?.floatingButtonsPosition
        }
        set {
            if let newPosition = newValue {
                navigationView?.floatingButtonsPosition = newPosition
            }
        }
    }

    var floatingButtons: [UIButton]? {
        get {
            return navigationView?.floatingButtons
        }
        set {
            navigationView?.floatingButtons = newValue
        }
    }

    @objc
    func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        let muted = sender.isSelected
        Task { @MainActor in
            navigationViewData?.voiceController?.speechSynthesizer.muted = muted
        }
    }

    @objc
    func overview(_ sender: UIButton) {
        Task { @MainActor in
            navigationMapView?.navigationCamera.update(cameraState: .overview)
        }
    }

    @objc
    func recenter(_ sender: UIButton) {
        Task { @MainActor in
            navigationMapView?.navigationCamera.update(cameraState: .following)
        }
    }

    /// Method updates `logoView` and `attributionButton` margins to prevent incorrect alignment reported in
    /// https://github.com/mapbox/mapbox-navigation-ios/issues/2561.
    private func updateMapViewOrnaments() {
        Task { @MainActor in
            guard let navigationView else { return }
            let bottomBannerHeight = navigationView.bottomBannerContainerView.bounds.height
            let bottomBannerVerticalOffset = navigationView.bounds.height - bottomBannerHeight - navigationView
                .bottomBannerContainerView.frame.origin.y
            let defaultOffset: CGFloat = 10.0
            let x: CGFloat = 10.0
            let y: CGFloat = bottomBannerHeight + defaultOffset + bottomBannerVerticalOffset

            navigationView.navigationMapView.mapView.ornaments.options.logo.margins = CGPoint(
                x: x - navigationView.safeAreaInsets.left,
                y: y - navigationView.safeAreaInsets.bottom
            )

            switch navigationView.traitCollection.verticalSizeClass {
            case .unspecified:
                fallthrough
            case .regular:
                navigationView.navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(
                    x: -navigationView.safeAreaInsets.right,
                    y: y - navigationView.safeAreaInsets.bottom
                )
            case .compact:
                if navigationMapView?.interfaceOrientation == .landscapeRight {
                    navigationView.navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(
                        x: x - navigationView.safeAreaInsets.right,
                        y: defaultOffset - navigationView.safeAreaInsets.bottom
                    )
                } else {
                    navigationView.navigationMapView.mapView.ornaments.options.attributionButton.margins = CGPoint(
                        x: x,
                        y: defaultOffset -
                            navigationView
                            .safeAreaInsets
                            .bottom
                    )
                }
            @unknown default:
                break
            }
        }
    }

    // MARK: Road Labelling

    func updateRoadNameFromStatus(_ roadName: RoadName?) {
        if let name = roadName?.text.nonEmptyString {
            let representation = roadName?.routeShieldRepresentation
            navigationView?.wayNameView.label.updateRoad(roadName: name, representation: representation)

            // The `WayNameView` will be hidden when not under following camera state.
            navigationView?.wayNameView.containerView.isHidden = !(navigationView?.resumeButton.isHidden ?? false)
        } else {
            navigationView?.wayNameView.text = nil
            navigationView?.wayNameView.containerView.isHidden = true
            return
        }
    }

    /// Update the sprite repository of current road label when map style changes.
    ///
    /// - Parameter styleURI: The `StyleURI` that the map is presenting.
    func updateStyle(styleURI: StyleURI?) {
        navigationView?.wayNameView.label.updateStyle(styleURI: styleURI)
    }

    // MARK: NavigationComponentDelegate implementation

    func navigationViewDidLoad(_: UIView) {
        guard let navigationViewController = navigationViewData?.containerViewController as? NavigationViewController
        else {
            return
        }

        navigationViewController.overviewButton.addTarget(
            self,
            action: #selector(overview(_:)),
            for: .touchUpInside
        )

        navigationView?.resumeButton.addTarget(
            self,
            action: #selector(recenter(_:)),
            for: .touchUpInside
        )

        navigationViewController.muteButton.addTarget(
            self,
            action: #selector(toggleMute(_:)),
            for: .touchUpInside
        )

        navigationViewController.reportButton.addTarget(
            self,
            action: #selector(feedback(_:)),
            for: .touchUpInside
        )
    }

    func navigationViewWillAppear(_: Bool) {
        resumeNotifications()

        let navigationViewController = navigationViewData?.containerViewController as? NavigationViewController
        Task { @MainActor in
            navigationViewController?.muteButton.isSelected = navigationViewData?.voiceController?.speechSynthesizer
                .muted ?? true
        }
    }

    func navigationViewDidDisappear(_: Bool) {
        suspendNotifications()
    }

    func navigationViewDidLayoutSubviews() {
        updateMapViewOrnaments()
    }

    func updateSpeedLimitFromStatus(_ speedLimit: SpeedLimit, currentSpeed: Measurement<UnitSpeed>) {
        navigationView?.speedLimitView.signStandard = speedLimit.signStandard
        navigationView?.speedLimitView.speedLimit = speedLimit.value
        navigationView?.speedLimitView.currentSpeed = currentSpeed.value
    }

    func navigationCameraStateDidChange(_ state: NavigationCameraState) {
        switch state {
        case .idle, .overview:
            navigationViewData?.navigationView.resumeButton.isHidden = false
            (navigationViewData?.containerViewController as? NavigationViewController)?.overviewButton.isHidden = true
        case .following:
            navigationViewData?.navigationView.resumeButton.isHidden = true
            (navigationViewData?.containerViewController as? NavigationViewController)?.overviewButton.isHidden = false
        }
    }
}
