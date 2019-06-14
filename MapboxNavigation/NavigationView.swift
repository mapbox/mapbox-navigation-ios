import UIKit
import MapboxDirections


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
 
 ```
 +--------------------+
 |         1          |
 +--------------------+
 |         2          |
 +----------------+---+
 |                |   |
 |                | 6 |
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
@objc(MBNavigationView)
open class NavigationView: UIView {
    
    private enum Constants {
        static let endOfRouteHeight: CGFloat = 260.0
        static let buttonSpacing: CGFloat = 8.0
    }
    
    lazy var endOfRouteShowConstraint: NSLayoutConstraint? = self.endOfRouteView?.bottomAnchor.constraint(equalTo: self.safeBottomAnchor)
    
    lazy var endOfRouteHideConstraint: NSLayoutConstraint? = self.endOfRouteView?.topAnchor.constraint(equalTo: self.bottomAnchor)
    
    lazy var endOfRouteHeightConstraint: NSLayoutConstraint? = self.endOfRouteView?.heightAnchor.constraint(equalToConstant: Constants.endOfRouteHeight)
    
    private enum Images {
        static let overview = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let volumeUp = UIImage(named: "volume_up", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let volumeOff =  UIImage(named: "volume_off", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        static let feedback = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    }
    
    lazy var mapView: NavigationMapView = {
        let map: NavigationMapView = .forAutoLayout(frame: self.bounds)
        map.navigationMapViewDelegate = delegate
        map.courseTrackingDelegate = delegate
        map.showsUserLocation = true
        return map
    }()
    
    lazy var floatingStackView: UIStackView = {
        let stackView = UIStackView(orientation: .vertical, autoLayout: true)
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.buttonSpacing
        return stackView
    }()
    
    lazy var overviewButton = FloatingButton.rounded(image: Images.overview)
    lazy var muteButton = FloatingButton.rounded(image: Images.volumeUp, selectedImage: Images.volumeOff)
    lazy var reportButton = FloatingButton.rounded(image: Images.feedback)
    
    lazy var resumeButton: ResumeButton = .forAutoLayout()
    
    lazy var wayNameView: WayNameView = {
        let view: WayNameView = .forAutoLayout(hidden: true)
        view.clipsToBounds = true
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        return view
    }()
    
    lazy var topBannerContainerView: BannerContainerView = .forAutoLayout()
    
    lazy var bottomBannerContainerView: BannerContainerView = .forAutoLayout()

    weak var delegate: NavigationViewDelegate? {
        didSet {
            updateDelegates()
        }
    }
    
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
    
    //MARK: - Initializers
    
    convenience init(delegate: NavigationViewDelegate) {
        self.init(frame: .zero)
        self.delegate = delegate
        updateDelegates() //this needs to be called because didSet's do not fire in init contexts.
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupViews()
        setupConstraints()
    }
    
    func setupStackViews() {
        floatingStackView.addArrangedSubviews([overviewButton, muteButton, reportButton])
    }
    
    func setupViews() {
        setupStackViews()
        
        let children: [UIView] = [
            mapView,
            topBannerContainerView,
            floatingStackView,
            resumeButton,
            wayNameView,
            bottomBannerContainerView
        ]
        
        addSubviews(children)
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        DayStyle().apply()
        [mapView, topBannerContainerView, bottomBannerContainerView].forEach( { $0.prepareForInterfaceBuilder() })
        wayNameView.text = "Street Label"
    }
    
    private func updateDelegates() {
        mapView.navigationMapViewDelegate = delegate
        mapView.courseTrackingDelegate = delegate
    }
}

protocol NavigationViewDelegate: NavigationMapViewDelegate, InstructionsBannerViewDelegate, NavigationMapViewCourseTrackingDelegate, VisualInstructionDelegate {
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton)
}
