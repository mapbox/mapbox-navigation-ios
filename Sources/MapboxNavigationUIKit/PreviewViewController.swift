import Combine
import CoreLocation
import MapboxMaps
import MapboxNavigationCore
import UIKit

/// ``PreviewViewController`` is a user interface for the preview mode experience. It allows to present
/// banners that contain information that is important for the user before actually starting turn-by-turn
/// navigation session (e.g. final destination presentation, main and alternative routes preview etc).
///
/// By default Mapbox Navigation SDK provides the following banners:
/// - ``DestinationPreviewViewController`` - banner that is shown at the bottom of the screen and allows
/// to show information about the final destination, preview available routes and start active navigation
/// session
/// - ``RoutePreviewViewController`` - banner that is shown at the bottom of the screen and allows to
/// preview information about the current `Route` (expected travel time, distance and expected time of arrival)
/// - ``BannerDismissalViewController`` - banner that is shown at the top of the screen and allows to
/// dismiss already presented banner
///
/// Internally ``PreviewViewController`` relies on two components:
/// - `NavigationMapView` - wraps `MapView` and provides convenience functions for adding and removing
/// route lines, route duration annotations, shows user location indicator etc
/// - ``NavigationView`` - wraps `NavigationMapView` and provides the ability to show drop-in related UI
/// components like ``SpeedLimitView``, ``WayNameView``, top and bottom ``BannerContainerView``s etc.
///
/// ``PreviewViewController`` works as an initial step before switching to the active navigation.
/// Use ``NavigationViewController`` for turn-by-turn navigation experience.
public class PreviewViewController: UIViewController {
    // MARK: - BannerPresentation properties and methods

    /// ``NavigationView``, that is displayed inside the view controller.
    public var navigationView: NavigationView {
        view as! NavigationView
    }

    weak var bannerPresentationDelegate: BannerPresentationDelegate? = nil

    var topBanners = Stack<Banner>()

    var bottomBanners = Stack<Banner>()

    // MARK: - PreviewViewController properties

    /// ``PreviewViewControllerDelegate`` that allows to observe ``Banner`` presentation and dismissal events.
    public weak var delegate: PreviewViewControllerDelegate?

    var styleManager: StyleManager!

    let previewOptions: PreviewOptions

    /// The `NavigationMapView`, that is displayed inside the view controller.
    public var navigationMapView: NavigationMapView {
        get {
            navigationView.navigationMapView
        }

        set {
            navigationView.navigationMapView = newValue
        }
    }

    private var cancellable: AnyCancellable?
    private var latestLocation: CLLocation?

    // MARK: - Initialization methods

    /// Initializes a ``PreviewViewController`` that presents the user interface for the destination and
    /// routes preview.
    ///
    /// - Parameters:
    ///   - previewOptions: Customization options for the navigation preview user experience.
    public init(_ previewOptions: PreviewOptions) {
        self.previewOptions = previewOptions

        super.init(nibName: nil, bundle: nil)

        self.cancellable = previewOptions.locationMatching.sink { [weak self] state in
            self?.latestLocation = state.enhancedLocation
            self?.handleLocationMatching(state)
        }

        self.bannerPresentationDelegate = self

        setupFloatingButtons()
        setupConstraints()
        setupStyleManager()
        setupNavigationCamera()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController lifecycle methods

    override public func loadView() {
        view = setupNavigationView()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Apply style that was set specifically for the `PreviewViewController` when it appears on
        // the screen to prevent incorrect style usage (e.g. after finishing active navigation when
        // using `NavigationViewController`).
        styleManager.currentStyle?.apply()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupOrnaments()
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        navigationView.setupTopBannerContainerViewHeightLayoutConstraints(topmostTopBanner?.bannerConfiguration.height)
        navigationView
            .setupBottomBannerContainerViewHeightLayoutConstraints(topmostBottomBanner?.bannerConfiguration.height)
    }

    // MARK: - UIViewController setting-up methods

    func setupNavigationView() -> NavigationView {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds

        let navigationView = NavigationView(
            frame: frame,
            mapViewConfiguration: .createNew(
                location: previewOptions.locationMatching
                    .map(\.enhancedLocation)
                    .eraseToAnyPublisher(),
                routeProgress: previewOptions.routeProgress,
                heading: previewOptions.heading,
                predictiveCacheManager: previewOptions.predictiveCacheManager
            )
        )
        navigationView.navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return navigationView
    }

    func setupFloatingButtons() {
        let cameraModeFloatingButton = FloatingButton
            .rounded(imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0)) as CameraModeFloatingButton
        cameraModeFloatingButton.navigationView = navigationView

        navigationView.floatingButtons = [
            cameraModeFloatingButton,
        ]

#if DEBUG
        let debugFloatingButton = FloatingButton.rounded(
            image: .debugImage,
            imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0)
        )
        debugFloatingButton.addTarget(
            self,
            action: #selector(didPressDebugButton(_:)),
            for: .touchUpInside
        )

        navigationView.floatingButtons?.append(debugFloatingButton)
#endif
    }

    // TODO: Implement the ability to set default positions for logo and attribution button.
    func setupOrnaments() {
        navigationView.navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
    }

    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager.delegate = self
        styleManager.styles = previewOptions.styles ?? [StandardDayStyle(), StandardNightStyle()]
    }

    func setupNavigationCamera() {
        navigationView.moveCamera(to: .centered)
    }

    private func handleLocationMatching(_ state: MapMatchingState) {
        // Update current speed limit. In case if speed limit is not available `SpeedLimitView` is hidden.
        navigationView.speedLimitView.signStandard = state.speedLimit.signStandard
        navigationView.speedLimitView.speedLimit = state.speedLimit.value

        // Update current road name. In case if road name is not available `WayNameView` is hidden.
        if let name = state.roadName?.text.nonEmptyString {
            let representation = state.roadName?.routeShieldRepresentation
            navigationView.wayNameView.label.updateRoad(roadName: name, representation: representation)
            navigationView.wayNameView.containerView.isHidden = false
        } else {
            navigationView.wayNameView.text = nil
            navigationView.wayNameView.containerView.isHidden = true
        }
    }

    // MARK: - Banner presentation and dismissal methods

    /// Removes the top-most banner from the banners hierarchy.
    ///
    /// - Parameters:
    ///   - position: Position of the ``Banner`` on the screen.
    ///   - animated: If true, ``PreviewViewController`` animates the transition between banners.
    ///   - duration: Duration of the animation. Defaults to `0.2` seconds.
    ///   - animations: A block object containing the changes to commit to the views.
    ///     This is where you programmatically change any animatable properties of the views in your
    ///     view hierarchy. This block takes no parameters and has no return value.
    ///   - completion: A block object to be executed when the animation sequence ends.
    ///     This block has no return value.
    /// - Returns: ``Banner`` that was dismissed. If there are no more banners in the banners hierarchy
    ///   `nil` will be returned instead.
    @discardableResult
    public func dismissBanner(
        at position: BannerPosition,
        animated: Bool = true,
        duration: TimeInterval = 0.2,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> Banner? {
        return popBanner(
            at: position,
            animated: animated,
            duration: duration,
            animations: animations,
            completion: completion
        )
    }

    /// Removes all of the banners from the banners hierarchy except the first banner.
    ///
    /// - Parameters:
    ///   - position: Position of the ``Banner`` on the screen.
    ///   - animated: Controls whether ``PreviewViewController`` animates the transition
    ///     between banners. Defaults to `true`.
    ///   - duration: Duration of the animation. Defaults to `0.2` seconds.
    ///   - animations: A block object containing the changes to commit to the views.
    ///     This is where you programmatically change any animatable properties of the views in your
    ///     view hierarchy. This block takes no parameters and has no return value.
    ///   - completion: A block object to be executed when the animation sequence ends.
    ///     This block has no return value.
    public func dismissAllExceptFirst(
        at position: BannerPosition,
        animated: Bool = true,
        duration: TimeInterval = 0.2,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        popBanner(
            at: position,
            animated: animated,
            duration: duration,
            animations: animations,
            completion: completion,
            popAllExceptFirstBanner: true
        )
    }

    /// Adds the specified banner to the banners hierarchy and displays it.
    ///
    /// - Parameters:
    ///   - banner: ``Banner`` instance that will be presented.
    ///   - animated: Controls whether ``PreviewViewController`` animates the transition
    ///     between banners. Defaults to `true`.
    ///   - duration: Duration of the animation. Defaults to `0.2` seconds.
    ///   - animations: A block object containing the changes to commit to the views.
    ///     This is where you programmatically change any animatable properties of the views in your
    ///     view hierarchy. This block takes no parameters and has no return value.
    ///   - completion: A block object to be executed when the animation sequence ends.
    ///     This block has no return value.
    public func present(
        _ banner: Banner,
        animated: Bool = true,
        duration: TimeInterval = 0.2,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        push(
            banner,
            animated: animated,
            duration: duration,
            animations: animations,
            completion: completion
        )
    }

    /// Returns the top-most banner in the banners hierarchy.
    ///
    /// - Parameters:
    ///   - position: Position of the ``Banner`` on the screen.
    /// - Returns: The top-most ``Banner``. If there are no banners in the banners hierarchy
    ///   `nil` will be returned instead.
    public func topBanner(at position: BannerPosition) -> Banner? {
        switch position {
        case .topLeading:
            return topmostTopBanner
        case .bottomLeading:
            return topmostBottomBanner
        }
    }

    // MARK: - Event handlers

    @objc
    func didPressDebugButton(_ sender: Any) {
        // TODO: Implement debug view presentation.
    }
}

// MARK: - BannerPresentation conformance

extension PreviewViewController: BannerPresentation {}

// MARK: - StyleManagerDelegate methods

extension PreviewViewController: StyleManagerDelegate {
    public func location(for styleManager: StyleManager) -> CLLocation? {
        latestLocation ?? CLLocationManager().location
    }

    public func styleManager(
        _ styleManager: StyleManager,
        didApply style: Style
    ) {
        if navigationView.navigationMapView.mapView.mapboxMap.styleURI?.rawValue != style.mapStyleURL.absoluteString {
            navigationView.navigationMapView.mapView.mapboxMap.styleURI = StyleURI(url: style.mapStyleURL)
        }
    }
}

// MARK: - BannerPresentationDelegate methods

extension PreviewViewController: BannerPresentationDelegate {
    func bannerWillAppear(
        _ presenter: BannerPresentation,
        banner: Banner
    ) {
        delegate?.previewViewController(self, willPresent: banner)
    }

    func bannerDidAppear(
        _ presenter: BannerPresentation,
        banner: Banner
    ) {
        delegate?.previewViewController(self, didPresent: banner)
    }

    func bannerWillDisappear(
        _ presenter: BannerPresentation,
        banner: Banner
    ) {
        delegate?.previewViewController(self, willDismiss: banner)
    }

    func bannerDidDisappear(
        _ presenter: BannerPresentation,
        banner: Banner
    ) {
        delegate?.previewViewController(self, didDismiss: banner)
    }
}
