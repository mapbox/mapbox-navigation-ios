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
    
    private struct Images {
        static let overview = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!
        static let volumeUp = UIImage(named: "volume_up", in: .mapboxNavigation, compatibleWith: nil)!
        static let feedback = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!
    }
    
    private static let rerouteReportTitle = NSLocalizedString("REROUTE_REPORT_TITLE", bundle: .mapboxNavigation, value: "Report Problem", comment: "Title on button that appears when a reroute occurs")
    
    static let buttonSize = CGSize(width: 50, height: 50)
    
    lazy var mapView: NavigationMapView = {
        let map: NavigationMapView = .forAutoLayout()
        map.delegate = delegate
        return map
    }()
    
    lazy var instructionsBannerContentView: InstructionsBannerContentView = .forAutoLayout()
    
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner: InstructionsBannerView = .forAutoLayout()
        banner.delegate = delegate
        return banner
    }()
    
    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var floatingStackView: UIStackView = {
        let stack = UIStackView(orientation: .vertical, autoLayout: true)
        stack.distribution = .equalSpacing
        stack.spacing = 8
        return stack
    }()
    
    lazy var overivewButton = FloatingButton.rounded(image: Images.overview)
    lazy var muteButton = FloatingButton.rounded(image: Images.volumeUp)
    lazy var reportButton = FloatingButton.rounded(image: Images.feedback)
    
    lazy var separatorView: SeparatorView = .forAutoLayout()
    lazy var lanesView: LanesView = .forAutoLayout()
    lazy var nextBannerView: NextBannerView = .forAutoLayout()
    lazy var statusView: StatusView = {
        let status: StatusView = .forAutoLayout()
        status.delegate = delegate
        return status
    }()
    
    lazy var resumeButton: ResumeButton = {
        let button: ResumeButton = .forAutoLayout()
        button.backgroundColor = .white
        return button
    }()
    
    lazy var wayNameLabel: WayNameLabel = {
        let label: WayNameLabel = .forAutoLayout()
        label.clipsToBounds = true
        label.layer.borderWidth = 1.0 / UIScreen.main.scale
        return label
    }()
    
    lazy var rerouteReportButton: ReportButton = {
        let button: ReportButton = .forAutoLayout()
        button.applyDefaultCornerRadiusShadow(cornerRadius: 4)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.setTitle(NavigationView.rerouteReportTitle, for: .normal)
        return button
    }()
    
    lazy var bottomBannerContentView: BottomBannerContentView = .forAutoLayout()
    lazy var bottomBannerView: BottomBannerView = .forAutoLayout()
    

    var delegate: NavigationViewDelegate? {
        didSet {
            mapView.delegate = delegate
            instructionsBannerView.delegate = delegate
            statusView.delegate = delegate
        }
    }
    
    convenience init(delegate: NavigationViewDelegate) {
        self.init(frame: .zero)
        self.delegate = delegate
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
        informationStackView.addArrangedSubviews([instructionsBannerView, lanesView, nextBannerView, statusView])
        floatingStackView.addArrangedSubviews([overivewButton, muteButton, reportButton])
    }
    
    func setupContainers() {
        let containers: [(UIView, UIView)] = [(instructionsBannerContentView, instructionsBannerView), (bottomBannerContentView, bottomBannerView)]
        containers.forEach { $0.addSubview($1) }
    }
    
    func setupViews() {
        setupStackViews()
        setupContainers()
        
        let subviews: [UIView] = [instructionsBannerContentView,
                        informationStackView,
                        floatingStackView,
                        separatorView,
                        resumeButton,
                        wayNameLabel,
                        rerouteReportButton,
                        bottomBannerContentView]
        
        subviews.forEach(addSubview(_:))
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        DayStyle().apply()
        [mapView, instructionsBannerView, lanesView, bottomBannerView, nextBannerView].forEach { $0.prepareForInterfaceBuilder() }
        wayNameLabel.text = "Street Label"
    }
}

protocol NavigationViewDelegate: NavigationMapViewDelegate, MGLMapViewDelegate, StatusViewDelegate, InstructionsBannerViewDelegate {}


