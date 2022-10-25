import UIKit
import MapboxDirections
import MapboxCoreNavigation

/**
 A view that represents the root view of the MapboxNavigation drop-in UI.
 
 ## Components
 
 1. InstructionsBannerView
 2. InformationStackView
 3. BottomBannerView
 4. ResumeButton
 5. WayNameLabel
 6. FloatingStackView
 7. NavigationMapView
 8. SpeedLimitView
 
 ```
 +--------------------+
 |         1          |
 +--------------------+
 |         2          |
 +---+------------+---+
 | 8 |            |   |
 +---+            | 6 |
 |                |   |
 |         7      +---+
 |                    |
 |                    |
 |                    |
 +------------+       |
 |  4  ||  5  |       |
 +------------+-------+
 |         3          |
 +--------------------+
 ```
 */
@IBDesignable
open class NavigationView: UIView {
    
    enum Constants {
        static let endOfRouteHeight: CGFloat = 260.0
        static let buttonSpacing: CGFloat = 8.0
    }
    
    var compactConstraints = [NSLayoutConstraint]()
    var regularConstraints = [NSLayoutConstraint]()
    
    // MARK: Data Configuration
    
    weak var delegate: NavigationViewDelegate? {
        didSet {
            updateDelegates()
        }
    }
    
    private func updateDelegates() {
        navigationMapView.delegate = delegate
    }
    
    /**
     `NavigationMapView` that is displayed inside the `NavigationView`.
     */
    public var navigationMapView: NavigationMapView {
        didSet {
            oldValue.removeFromSuperview()
            insertSubview(navigationMapView, at: 0)
            
            navigationMapView.isHidden = false
            navigationMapView.translatesAutoresizingMaskIntoConstraints = false
            navigationMapView.delegate = delegate
            navigationMapView.pinTo(parentView: self)
            
            // FIXME: Provide a reliable way of notifying dependants (e.g. `CameraController`,
            // `ArrivalController` might need to re-subscribe to notifications that are sent from
            // injected `NavigationMapView` instance).
            if oldValue != navigationMapView {
                delegate?.navigationView(self, didReplace: navigationMapView)
            }
        }
    }
    
    // MARK: End of Route UI
    
    lazy var endOfRouteShowConstraint: NSLayoutConstraint? = endOfRouteView?.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    lazy var endOfRouteHeightConstraint: NSLayoutConstraint? = endOfRouteView?.heightAnchor.constraint(equalToConstant: Constants.endOfRouteHeight)
    
    var topBannerContainerViewLayoutConstraints: [NSLayoutConstraint] = []
    
    var bottomBannerContainerViewLayoutConstraints: [NSLayoutConstraint] = []
    
    var endOfRouteViewLayoutConstraints: [NSLayoutConstraint] = []
    
    var endOfRouteView: UIView? {
        didSet {
            if let active: [NSLayoutConstraint] = constraints(affecting: oldValue) {
                NSLayoutConstraint.deactivate(active)
            }
            
            oldValue?.removeFromSuperview()
            if let eor = endOfRouteView { addSubview(eor) }
            endOfRouteView?.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    func showEndOfRoute() {
        endOfRouteView?.isHidden = false
        setupEndOfRouteConstraints()
    }
    
    // MARK: Overlay Views
    
    /**
     Stack view that contains floating buttons.
     */
    public lazy var floatingStackView: UIStackView = {
        let stackView = UIStackView(orientation: .vertical, autoLayout: true)
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.buttonSpacing
        return stackView
    }()
    
    var floatingStackViewLayoutGuide: UILayoutGuide? {
        didSet {
            setupConstraints()
        }
    }
    
    var floatingButtonsPosition: MapOrnamentPosition = .topTrailing {
        didSet {
            setupConstraints()
        }
    }
    
    /**
     The buttons to show floating on the map inside `floatingStackView`.
     */
    public var floatingButtons: [UIButton]? {
        didSet {
            clearStackViews()
            setupStackViews()
        }
    }
    
    lazy var resumeButton: ResumeButton = .forAutoLayout(hidden: true)
    
    var wayNameViewLayoutGuide: UILayoutGuide? {
        didSet {
            setupConstraints()
        }
    }
    
    /**
     A host view for `WayNameLabel` that shows a road name and a shield icon.
     */
    public lazy var wayNameView: WayNameView = {
        let wayNameView: WayNameView = .forAutoLayout()
        wayNameView.containerView.isHidden = true
        wayNameView.containerView.clipsToBounds = true
        return wayNameView
    }()
    
    var speedLimitViewLayoutGuide: UILayoutGuide? {
        didSet {
            setupConstraints()
        }
    }
    
    /**
     A view that displays a speed limit.
     */
    public lazy var speedLimitView: SpeedLimitView = .forAutoLayout(hidden: true)
    
    /**
     View that is used as a container for top banners. By default, for turn-by-turn navigation
     `NavigationViewController` presents `TopBannerViewController` in this banner
     container.
     */
    public lazy var topBannerContainerView: BannerContainerView = {
        let topBannerContainerView = BannerContainerView(.topLeading)
        topBannerContainerView.isHidden = true
        topBannerContainerView.translatesAutoresizingMaskIntoConstraints = false
        return topBannerContainerView
    }()
    
    /**
     View that is used as a container for bottom banners. By default, for turn-by-turn navigation
     `NavigationViewController` presents `BottomBannerViewController` in this banner
     container.
     */
    public lazy var bottomBannerContainerView: BannerContainerView = {
        let bottomBannerContainerView = BannerContainerView(.bottomLeading)
        bottomBannerContainerView.isHidden = true
        bottomBannerContainerView.translatesAutoresizingMaskIntoConstraints = false
        return bottomBannerContainerView
    }()
    
    func clearStackViews() {
        let oldFloatingButtons: [UIView] = floatingStackView.subviews
        for floatingButton in oldFloatingButtons {
            floatingStackView.removeArrangedSubview(floatingButton)
            floatingButton.removeFromSuperview()
        }
    }
    
    func setupStackViews() {
        if let buttons = floatingButtons {
            floatingStackView.addArrangedSubviews(buttons)
        }
    }
    
    // MARK: Initialization methods
    
    /**
     Initializes a `NavigationView` instance with the specified parameters.
     
     - parameter frame: The frame rectangle for the `NavigationView`.
     - parameter tileStoreLocation: Configuration of the `TileStore` location, where map tiles are stored.
     Value is ignored if custom `NavigationMapView` instance was provided. Use `nil` to disable onboard tile storage.
     - parameter navigationMapView: Custom `NavigationMapView` instance to supersede the default one.
     */
    public init(frame: CGRect,
                tileStoreLocation: TileStoreConfiguration.Location? = .default,
                navigationMapView: NavigationMapView? = nil) {
        navigationMapView?.translatesAutoresizingMaskIntoConstraints = false
        self.navigationMapView = navigationMapView ?? NavigationMapView(frame: frame, tileStoreLocation: tileStoreLocation)
        
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        navigationMapView = NavigationMapView(frame: .zero)
        super.init(coder: decoder)
        commonInit()
    }
    
    convenience init(delegate: NavigationViewDelegate,
                     frame: CGRect = .zero,
                     tileStoreLocation: TileStoreConfiguration.Location? = .default,
                     navigationMapView: NavigationMapView? = nil) {
        self.init(frame: frame, tileStoreLocation: tileStoreLocation, navigationMapView: navigationMapView)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    convenience init(delegate: NavigationViewDelegate) {
        self.init(frame: .zero)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    func commonInit() {
        DayStyle().apply()
        setupViews()
        setupConstraints()
    }
    
    func setupViews() {
        let children: [UIView] = [
            navigationMapView,
            floatingStackView,
            wayNameView,
            resumeButton,
            speedLimitView,
            topBannerContainerView,
            bottomBannerContainerView
        ]
        
        addSubviews(children)
        
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        navigationMapView.pinTo(parentView: self)
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        DayStyle().apply()
        [navigationMapView, topBannerContainerView, bottomBannerContainerView].forEach({ $0.prepareForInterfaceBuilder() })
        wayNameView.text = "Street Label"
    }
}
