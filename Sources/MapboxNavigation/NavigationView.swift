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
    
    private enum Constants {
        static let endOfRouteHeight: CGFloat = 260.0
        static let buttonSpacing: CGFloat = 8.0
    }
    
    private enum Images {
        static let overview = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let volumeUp = UIImage(named: "volume_up", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let volumeOff = UIImage(named: "volume_off", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let feedback = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
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
    
    var tileStoreLocation: TileStoreConfiguration.Location? = .default
    private var _navigationMapView: NavigationMapView? = nil
    lazy var navigationMapView: NavigationMapView = {
        _navigationMapView?.frame = bounds
        let navigationMapView = _navigationMapView ?? NavigationMapView(frame: bounds, tileStoreLocation: tileStoreLocation)
        navigationMapView.isHidden = false
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationMapView.delegate = delegate
        navigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                                             viewportDataSourceType: .active)
        
        return navigationMapView
    }()
    
    // MARK: End of Route UI
    
    lazy var endOfRouteShowConstraint: NSLayoutConstraint? = endOfRouteView?.bottomAnchor.constraint(equalTo: bottomAnchor)
    
    lazy var endOfRouteHideConstraint: NSLayoutConstraint? = endOfRouteView?.topAnchor.constraint(equalTo: bottomAnchor)
    
    lazy var endOfRouteHeightConstraint: NSLayoutConstraint? = endOfRouteView?.heightAnchor.constraint(equalToConstant: Constants.endOfRouteHeight)
    
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
    
    func constrainEndOfRoute() {
        endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        endOfRouteHeightConstraint?.isActive = true
    }
    
    // MARK: Overlay Views
    
    lazy var floatingStackView: UIStackView = {
        let stackView = UIStackView(orientation: .vertical, autoLayout: true)
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.buttonSpacing
        return stackView
    }()
    
    lazy var overviewButton = FloatingButton.rounded(image: Images.overview)
    lazy var muteButton = FloatingButton.rounded(image: Images.volumeUp, selectedImage: Images.volumeOff)
    lazy var reportButton = FloatingButton.rounded(image: Images.feedback)
    
    var floatingButtonsPosition: MapOrnamentPosition = .topTrailing {
        didSet {
            setupConstraints()
        }
    }
    
    var floatingButtons : [UIButton]? {
        didSet {
            clearStackViews()
            setupStackViews()
        }
    }
    
    lazy var resumeButton: ResumeButton = .forAutoLayout()
    
    lazy var wayNameView: WayNameView = {
        let wayNameView: WayNameView = .forAutoLayout()
        wayNameView.containerView.isHidden = true
        wayNameView.containerView.clipsToBounds = true
        return wayNameView
    }()
    
    lazy var speedLimitView: SpeedLimitView = .forAutoLayout(hidden: true)
    
    lazy var topBannerContainerView: BannerContainerView = .forAutoLayout()
    
    lazy var bottomBannerContainerView: BannerContainerView = .forAutoLayout()
    
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
    
    convenience init(delegate: NavigationViewDelegate, frame: CGRect = .zero, tileStoreLocation: TileStoreConfiguration.Location? = .default, navigationMapView: NavigationMapView? = nil) {
        self.init(frame: frame, tileStoreLocation: tileStoreLocation, navigationMapView: navigationMapView)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    convenience init(delegate: NavigationViewDelegate) {
        self.init(frame: .zero)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    // TODO: Refine public APIs, which are exposed by `NavigationView`.
    public init(frame: CGRect, tileStoreLocation: TileStoreConfiguration.Location? = .default, navigationMapView: NavigationMapView? = nil) {
        self.tileStoreLocation = tileStoreLocation
        self._navigationMapView = navigationMapView
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        floatingButtons = [overviewButton, muteButton, reportButton]
        setupViews()
        setupConstraints()
    }
    
    func setupViews() {
        let children: [UIView] = [
            navigationMapView,
            topBannerContainerView,
            floatingStackView,
            wayNameView,
            resumeButton,
            speedLimitView,
            bottomBannerContainerView
        ]
        
        addSubviews(children)
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        DayStyle().apply()
        [navigationMapView, topBannerContainerView, bottomBannerContainerView].forEach({ $0.prepareForInterfaceBuilder() })
        wayNameView.text = "Street Label"
    }
}
