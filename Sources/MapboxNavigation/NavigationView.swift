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
    
    lazy var endOfRouteShowConstraint: NSLayoutConstraint? = self.endOfRouteView?.bottomAnchor.constraint(equalTo: self.safeBottomAnchor)
    
    lazy var endOfRouteHideConstraint: NSLayoutConstraint? = self.endOfRouteView?.topAnchor.constraint(equalTo: self.bottomAnchor)
    
    lazy var endOfRouteHeightConstraint: NSLayoutConstraint? = self.endOfRouteView?.heightAnchor.constraint(equalToConstant: Constants.endOfRouteHeight)
    
    lazy var navigationMapView: NavigationMapView = {
        let navigationMapView: NavigationMapView = .forAutoLayout(frame: self.bounds)
        navigationMapView.delegate = delegate
        
        return navigationMapView
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
    
    var floatingButtonsPosition: MapOrnamentPosition = .topTrailing {
        didSet {
            reinstallConstraints()
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
        let view: WayNameView = .forAutoLayout(hidden: true)
        view.clipsToBounds = true
        view.layer.borderWidth = 1.0 / UIScreen.main.scale
        return view
    }()
    
    lazy var speedLimitView: SpeedLimitView = .forAutoLayout(hidden: true)
    
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
    
    // MARK: - Initialization methods
    
    convenience init(delegate: NavigationViewDelegate, frame: CGRect = .zero) {
        self.init(frame: frame)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    convenience init(delegate: NavigationViewDelegate) {
        self.init(frame: .zero)
        self.delegate = delegate
        updateDelegates() // this needs to be called because didSet's do not fire in init contexts.
    }
    
    // TODO: Refine public APIs, which are exposed by `NavigationView`.
    public override init(frame: CGRect) {
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
    
    func setupViews() {
        let children: [UIView] = [
            navigationMapView,
            topBannerContainerView,
            floatingStackView,
            resumeButton,
            wayNameView,
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
    
    private func updateDelegates() {
        navigationMapView.delegate = delegate
    }
}

protocol NavigationViewDelegate: NavigationMapViewDelegate, InstructionsBannerViewDelegate, VisualInstructionDelegate {
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton)
}

extension NavigationView {
    
    func setupConstraints() {
        navigationMapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        navigationMapView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        navigationMapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        navigationMapView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
  
        topBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        topBannerContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        floatingStackView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor, constant: 10).isActive = true
        
        resumeButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
        resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true

        bottomBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomBannerContainerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        wayNameView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true
        
        speedLimitView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor, constant: 10).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height).isActive = true
        
        switch floatingButtonsPosition {
        case .topLeading:
            floatingStackView.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
            speedLimitView.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -10).isActive = true
        case .topTrailing:
            floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -10).isActive = true
            speedLimitView.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
        }
    }

    func constrainEndOfRoute() {
        self.endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        self.endOfRouteHeightConstraint?.isActive = true
    }
    
    func reinstallConstraints() {
        if let activeFloatingStackView = self.constraints(affecting: self.floatingStackView) {
            NSLayoutConstraint.deactivate(activeFloatingStackView)
        }
        
        if let activeSpeedLimitView = self.constraints(affecting: self.speedLimitView) {
            NSLayoutConstraint.deactivate(activeSpeedLimitView)
        }

        setupConstraints()
    }
}
