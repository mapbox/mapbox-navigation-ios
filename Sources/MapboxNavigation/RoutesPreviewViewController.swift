import UIKit
import MapboxDirections

class RoutesPreviewViewController: RoutesPreviewing {
    
    var bottomBannerView: BottomBannerView!
    
    var bottomPaddingView: BottomPaddingView!
    
    var timeRemainingLabel: TimeRemainingLabel!
    
    var distanceRemainingLabel: DistanceRemainingLabel!
    
    var arrivalTimeLabel: ArrivalTimeLabel!
    
    var startButton: UIButton!
    
    weak var delegate: RoutesPreviewViewControllerDelegate?
    
    var routesPreviewOptions: RoutesPreviewOptions {
        didSet {
            updateRouteDetails()
        }
    }
    
    required init(_ routesPreviewOptions: RoutesPreviewOptions) {
        self.routesPreviewOptions = routesPreviewOptions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commonInit()
    }
    
    func commonInit() {
        setupParentView()
        setupTimeRemainingLabel()
        setupStartButton()
        setupDistanceRemainingLabel()
        setupArrivalTimeLabel()
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
        bottomBannerView.addSubview(timeRemainingLabel)
        
        timeRemainingLabel.numberOfLines = 1
        
        self.timeRemainingLabel = timeRemainingLabel
    }
    
    func setupDistanceRemainingLabel() {
        let distanceRemainingLabel: DistanceRemainingLabel = .forAutoLayout()
        bottomBannerView.addSubview(distanceRemainingLabel)
        
        distanceRemainingLabel.numberOfLines = 1
        
        self.distanceRemainingLabel = distanceRemainingLabel
    }
    
    func setupArrivalTimeLabel() {
        let arrivalTimeLabel: ArrivalTimeLabel = .forAutoLayout()
        bottomBannerView.addSubview(arrivalTimeLabel)
        
        arrivalTimeLabel.numberOfLines = 1
        
        self.arrivalTimeLabel = arrivalTimeLabel
    }
    
    func setupStartButton() {
        let startButton = StartButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.clipsToBounds = true
        
        let startImage = UIImage(named: "start", in: .mapboxNavigation, compatibleWith: nil)!
        startButton.setImage(startImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.imageView?.tintColor = .white
        startButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                   left: 0.0,
                                                   bottom: 12.0,
                                                   right: 0.0)
        bottomBannerView.addSubview(startButton)
        
        self.startButton = startButton
        
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            bottomBannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bottomBannerView.bottomAnchor.constraint(equalTo: bottomPaddingView.topAnchor),
            bottomBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            bottomPaddingView.topAnchor.constraint(equalTo: view.safeBottomAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        let buttonWidth: CGFloat = 70.0
        let buttonHeight: CGFloat = 50.0
        
        NSLayoutConstraint.activate([
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            startButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                             constant: 20.0)
        ])
        
        NSLayoutConstraint.activate([
            timeRemainingLabel.heightAnchor.constraint(equalToConstant: 35.0),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                        constant: 10.0),
            timeRemainingLabel.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                         constant: -10.0),
            timeRemainingLabel.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                    constant: 20.0),
        ])
        
        NSLayoutConstraint.activate([
            distanceRemainingLabel.heightAnchor.constraint(equalToConstant: 25.0),
            distanceRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                            constant: 10.0),
            distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                        constant: 0.0)
        ])
        
        NSLayoutConstraint.activate([
            arrivalTimeLabel.heightAnchor.constraint(equalToConstant: 25.0),
            arrivalTimeLabel.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                       constant: -5.0),
            arrivalTimeLabel.leadingAnchor.constraint(equalTo: distanceRemainingLabel.trailingAnchor,
                                                      constant: 10.0),
            arrivalTimeLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                  constant: 0.0)
        ])
    }
    
    @objc func didPressStartButton() {
        delegate?.didPressStartButton()
    }
    
    func updateRouteDetails() {
        guard let route = routesPreviewOptions.routeResponse.routes?[routesPreviewOptions.routeIndex] else {
            return
        }
        
        let typicalTravelTime = DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)
        timeRemainingLabel.text = typicalTravelTime
        
        let pinImage = UIImage(named: "pin", in: .mapboxNavigation, compatibleWith: nil)!
        let styledPinImage: UIImage!
        let distance = Measurement(distance: route.distance).localized()
        let distanceRemainingTintColor = DistanceRemainingLabel.appearance().normalTextColor
        if #available(iOS 13.0, *) {
            styledPinImage = pinImage.withTintColor(distanceRemainingTintColor)
        } else {
            styledPinImage = pinImage.tint(distanceRemainingTintColor)
        }
        
        distanceRemainingLabel.attributedText = attributedString(with: styledPinImage,
                                                                 imageBounds: CGRect(x: 0, y: -2, width: 12.0, height: 15.0),
                                                                 text: MeasurementFormatter().string(from: distance))
        
        if let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(route.expectedTravelTime), to: Date()) {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            
            let timeImage = UIImage(named: "time", in: .mapboxNavigation, compatibleWith: nil)!
            let styledTimeImage: UIImage!
            let arrivalTimeImageTintColor = ArrivalTimeLabel.appearance().normalTextColor
            if #available(iOS 13.0, *) {
                styledTimeImage = timeImage.withTintColor(arrivalTimeImageTintColor)
            } else {
                styledTimeImage = timeImage.tint(arrivalTimeImageTintColor)
            }
            
            arrivalTimeLabel.attributedText = attributedString(with: styledTimeImage,
                                                               imageBounds: CGRect(x: 0, y: -2, width: 15.0, height: 15.0),
                                                               text: dateFormatter.string(from: arrivalDate))
        }
    }
    
    func attributedString(with image: UIImage, imageBounds: CGRect, text: String) -> NSAttributedString {
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
