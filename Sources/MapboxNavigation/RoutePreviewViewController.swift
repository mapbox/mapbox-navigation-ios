import UIKit
import MapboxDirections

/**
 Banner that is shown at the bottom of the screen and allows to show route-related information
 in `PreviewViewController`.
 */
public class RoutePreviewViewController: UIViewController, Banner, RoutePreviewDataSource {
    
    var bottomBannerView: BottomBannerView!
    
    var bottomPaddingView: BottomPaddingView!
    
    var timeRemainingLabel: TimeRemainingLabel!
    
    var distanceRemainingLabel: DistanceRemainingLabel!
    
    var arrivalTimeLabel: ArrivalTimeLabel!
    
    var startButton: UIButton!
    
    var verticalSeparatorView: SeparatorView!
    
    var horizontalSeparatorView: SeparatorView!
    
    var trailingSeparatorView: SeparatorView!
    
    /**
     The object that serves as the routes preview delegate.
     */
    public weak var delegate: RoutePreviewViewControllerDelegate?
    
    // MARK: - Banner properties
    
    /**
     Configuration of the banner.
     */
    public let bannerConfiguration: BannerConfiguration
    
    // MARK: - RoutePreviewDataSource properties
    
    /**
     Customization options that are used for the route(s) preview.
     */
    public var routePreviewOptions: RoutePreviewOptions {
        didSet {
            updateRouteDetails()
        }
    }
    
    /**
     Initializes a `RoutePreviewViewController` instance.
     
     - parameter routePreviewOptions: Customization options that are used for the route(s) preview.
     - parameter bannerConfiguration: Configuration of the banner. `RoutePreviewViewController` is
     shown at the bottom of the screen by default.
     */
    public required init(_ routePreviewOptions: RoutePreviewOptions,
                         bannerConfiguration: BannerConfiguration = BannerConfiguration(position: .bottomLeading)) {
        self.routePreviewOptions = routePreviewOptions
        self.bannerConfiguration = bannerConfiguration
        
        super.init(nibName: nil, bundle: nil)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController setting-up methods
    
    func commonInit() {
        setupParentView()
        setupTimeRemainingLabel()
        setupStartButton()
        setupDistanceRemainingLabel()
        setupArrivalTimeLabel()
        setupSeparatorViews()
        setupConstraints()
        updateRouteDetails()
    }
    
    func setupParentView() {
        bottomBannerView = .forAutoLayout()
        bottomPaddingView = .forAutoLayout()
        
        let parentViews: [UIView] = [
            bottomBannerView,
            bottomPaddingView
        ]
        
        view.addSubviews(parentViews)
    }
    
    func setupTimeRemainingLabel() {
        let timeRemainingLabel: TimeRemainingLabel = .forAutoLayout()
        timeRemainingLabel.numberOfLines = 1
        bottomBannerView.addSubview(timeRemainingLabel)
        
        self.timeRemainingLabel = timeRemainingLabel
    }
    
    func setupDistanceRemainingLabel() {
        let distanceRemainingLabel: DistanceRemainingLabel = .forAutoLayout()
        distanceRemainingLabel.numberOfLines = 1
        bottomBannerView.addSubview(distanceRemainingLabel)
        
        self.distanceRemainingLabel = distanceRemainingLabel
    }
    
    func setupArrivalTimeLabel() {
        let arrivalTimeLabel: ArrivalTimeLabel = .forAutoLayout()
        arrivalTimeLabel.numberOfLines = 1
        bottomBannerView.addSubview(arrivalTimeLabel)
        
        self.arrivalTimeLabel = arrivalTimeLabel
    }
    
    func setupStartButton() {
        let startButton = StartButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.clipsToBounds = true
        startButton.setImage(.previewStartImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
        bottomBannerView.addSubview(startButton)
        
        self.startButton = startButton
    }
    
    func setupSeparatorViews() {
        let verticalDividerView: SeparatorView = .forAutoLayout()
        bottomBannerView.addSubview(verticalDividerView)
        self.verticalSeparatorView = verticalDividerView
        
        let horizontalDividerView: SeparatorView = .forAutoLayout()
        bottomBannerView.addSubview(horizontalDividerView)
        self.horizontalSeparatorView = horizontalDividerView
        
        let trailingSeparatorView: SeparatorView = .forAutoLayout()
        bottomBannerView.addSubview(trailingSeparatorView)
        self.trailingSeparatorView = trailingSeparatorView
    }
    
    // MARK: - Event handlers
    
    @objc func didPressStartButton() {
        delegate?.didPressBeginActiveNavigationButton(self)
    }
    
    // TODO: Extract implementation out of `RoutePreviewViewController`.
    func updateRouteDetails() {
        guard let route = routePreviewOptions.routeResponse.routes?[routePreviewOptions.routeIndex] else {
            return
        }
        
        let typicalTravelTime = DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)
        timeRemainingLabel.text = typicalTravelTime
        
        let phoneTraitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        let distanceRemainingTintColor = DistanceRemainingLabel.appearance(for: phoneTraitCollection,
                                                                           whenContainedInInstancesOf: [RoutePreviewViewController.self]).normalTextColor
        let distance = Measurement(distance: route.distance).localized()
        let imageBounds = CGRect(x: 0.0, y: -2.0, width: 12.0, height: 15.0)
        
        // FIXME: Tinting with custom method doesn't work on iOS 13 and higher.
        let tintedPinImage: UIImage
        if #available(iOS 13.0, *) {
            tintedPinImage = .pinImage.withTintColor(distanceRemainingTintColor)
        } else {
            tintedPinImage = .pinImage.tint(distanceRemainingTintColor)
        }
        
        distanceRemainingLabel.attributedText = attributedString(with: tintedPinImage,
                                                                 imageBounds: imageBounds,
                                                                 text: MeasurementFormatter().string(from: distance))
        
        if let arrivalDate = NSCalendar.current.date(byAdding: .second,
                                                     value: Int(route.expectedTravelTime),
                                                     to: Date()) {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            
            let arrivalTimeImageTintColor = ArrivalTimeLabel.appearance(for: phoneTraitCollection,
                                                                        whenContainedInInstancesOf: [RoutePreviewViewController.self]).normalTextColor
            
            let tintedTimeImage: UIImage
            if #available(iOS 13.0, *) {
                tintedTimeImage = .timeImage.withTintColor(distanceRemainingTintColor)
            } else {
                tintedTimeImage = .timeImage.tint(arrivalTimeImageTintColor)
            }
            
            arrivalTimeLabel.attributedText = attributedString(with: tintedTimeImage,
                                                               imageBounds: imageBounds,
                                                               text: dateFormatter.string(from: arrivalDate))
        }
    }
    
    func attributedString(with image: UIImage,
                          imageBounds: CGRect,
                          text: String) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        imageAttachment.bounds = imageBounds
        let imageString = NSAttributedString(attachment: imageAttachment)
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(imageString)
        attributedString.append(NSAttributedString(string: " " + text))
        
        return attributedString
    }
}
