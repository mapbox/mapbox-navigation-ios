import UIKit
import CoreLocation
import MapboxDirections

public struct DestinationOptions {
    
    public private(set) var waypoints: [Waypoint]
    
    public init(coordinates: [CLLocationCoordinate2D]) {
        self.waypoints = coordinates.map({ Waypoint(coordinate: $0) })
    }
    
    public init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
    }
}

public protocol Destinationable: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}

public typealias DestinationableViewController = UIViewController & Destinationable

protocol DestinationPreviewViewControllerDelegate: AnyObject {
    
    func didPressPreviewButton()
    
    func didPressStartButton()
}

class DestinationPreviewViewController: DestinationableViewController {
    
    var bottomBannerView: BottomBannerView!
    
    var bottomPaddingView: BottomPaddingView!
    
    var destinationLabel: UILabel!
    
    var previewButton: PreviewButton!
    
    var startButton: StartButton!
    
    weak var delegate: DestinationPreviewViewControllerDelegate?
    
    var destinationOptions: DestinationOptions
    
    required init(_ destinationOptions: DestinationOptions) {
        self.destinationOptions = destinationOptions
        
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
        setupStartButton()
        setupPreviewButton()
        setupDestinationLabel()
        setupConstraints()
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
    
    func setupDestinationLabel() {
        let destinationLabel: UILabel = .forAutoLayout()
        view.addSubview(destinationLabel)
        
        destinationLabel.font = UIFont.systemFont(ofSize: 27.0)
        destinationLabel.textColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        destinationLabel.numberOfLines = 2
        
        self.destinationLabel = destinationLabel
    }
    
    func setupPreviewButton() {
        let previewButton = PreviewButton(type: .system)
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.clipsToBounds = true
        
        let previewImage = UIImage(named: "route", in: .mapboxNavigation, compatibleWith: nil)
        previewButton.setImage(previewImage, for: .normal)
        previewButton.imageView?.contentMode = .scaleAspectFit
        previewButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                     left: 0.0,
                                                     bottom: 12.0,
                                                     right: 0.0)
        view.addSubview(previewButton)
        
        previewButton.addTarget(self, action: #selector(didPressPreviewButton), for: .touchUpInside)
        
        self.previewButton = previewButton
    }
    
    func setupStartButton() {
        let startButton = StartButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.clipsToBounds = true
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
        
        let startImage = UIImage(named: "start", in: .mapboxNavigation, compatibleWith: nil)!
        startButton.setImage(startImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                   left: 0.0,
                                                   bottom: 12.0,
                                                   right: 0.0)
        view.addSubview(startButton)
        
        self.startButton = startButton
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
        
        let startButtonLayoutConstraints = [
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            startButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                             constant: 20.0)
        ]
        
        NSLayoutConstraint.activate(startButtonLayoutConstraints)
        
        let previewButtonLayoutConstraints = [
            previewButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            previewButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            previewButton.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                    constant: -10.0),
            previewButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                               constant: 20.0)
        ]
        
        NSLayoutConstraint.activate(previewButtonLayoutConstraints)
        
        let destinationLabelLayoutConstraints = [
            destinationLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                      constant: 10.0),
            destinationLabel.trailingAnchor.constraint(equalTo: previewButton.leadingAnchor,
                                                       constant: -10.0),
            destinationLabel.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                  constant: 20.0),
            destinationLabel.bottomAnchor.constraint(equalTo: bottomBannerView.safeBottomAnchor,
                                                     constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(destinationLabelLayoutConstraints)
    }
    
    @objc func didPressPreviewButton() {
        delegate?.didPressPreviewButton()
    }
    
    @objc func didPressStartButton() {
        delegate?.didPressStartButton()
    }
}
