import UIKit
import CoreLocation
import MapboxDirections

// :nodoc:
public class DestinationPreviewViewController: UIViewController, Banner, DestinationDataSource {
    
    var bottomBannerView: BottomBannerView!
    
    var bottomPaddingView: BottomPaddingView!
    
    var destinationLabel: DestinationLabel!
    
    var previewButton: PreviewButton!
    
    var startButton: StartButton!
    
    var verticalSeparatorView: SeparatorView!
    
    var horizontalSeparatorView: SeparatorView!
    
    var trailingSeparatorView: SeparatorView!
    
    weak var delegate: DestinationPreviewViewControllerDelegate?
    
    // MARK: - Banner properties
    
    // :nodoc:
    public var bannerConfiguration: BannerConfiguration {
        BannerConfiguration(position: .bottomLeading)
    }
    
    // MARK: - DestinationDataSource properties
    
    // :nodoc:
    public var destinationOptions: DestinationOptions {
        didSet {
            if let primaryText = destinationOptions.primaryText {
                destinationLabel.attributedText = primaryText
            }
        }
    }
    
    required init(_ destinationOptions: DestinationOptions) {
        self.destinationOptions = destinationOptions
        
        super.init(nibName: nil, bundle: nil)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func commonInit() {
        setupParentView()
        setupStartButton()
        setupPreviewButton()
        setupDestinationLabel()
        setupSeparatorViews()
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
        let destinationLabel: DestinationLabel = .forAutoLayout()
        view.addSubview(destinationLabel)
        
        self.destinationLabel = destinationLabel
    }
    
    func setupPreviewButton() {
        let previewButton = PreviewButton(type: .system)
        previewButton.translatesAutoresizingMaskIntoConstraints = false
        previewButton.clipsToBounds = true
        previewButton.setImage(.previewOverviewImage, for: .normal)
        previewButton.imageView?.contentMode = .scaleAspectFit
        previewButton.addTarget(self, action: #selector(didPressPreviewButton), for: .touchUpInside)
        view.addSubview(previewButton)
        
        self.previewButton = previewButton
    }
    
    func setupStartButton() {
        let startButton = StartButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.clipsToBounds = true
        startButton.setImage(.previewStartImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
        view.addSubview(startButton)
        
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
    
    @objc func didPressPreviewButton() {
        delegate?.didPressPreviewRoutesButton(self)
    }
    
    @objc func didPressStartButton() {
        delegate?.didPressBeginActiveNavigationButton(self)
    }
}
