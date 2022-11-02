import UIKit
import CoreLocation
import MapboxDirections

/**
 Banner that is shown at the bottom of the screen and allows to show final destination information
 in `PreviewViewController`.
 */
public class DestinationPreviewViewController: UIViewController, Banner, DestinationDataSource {
    
    var bottomBannerView: BottomBannerView!
    
    var bottomPaddingView: BottomPaddingView!
    
    var destinationLabel: DestinationLabel!
    
    var previewButton: PreviewButton!
    
    var startButton: StartButton!
    
    var verticalSeparatorView: SeparatorView!
    
    var horizontalSeparatorView: SeparatorView!
    
    var trailingSeparatorView: SeparatorView!
    
    /**
     The object that serves as the destination preview delegate.
     */
    public weak var delegate: DestinationPreviewViewControllerDelegate?
    
    // MARK: - Banner properties
    
    /**
     Configuration of the banner.
     */
    public let bannerConfiguration: BannerConfiguration
    
    // MARK: - DestinationDataSource properties
    
    /**
     Customization options that are used for the destination(s) preview.
     */
    public var destinationOptions: DestinationOptions {
        didSet {
            updateDestinationDetails()
        }
    }
    
    /**
     Initializes a `DestinationPreviewViewController` instance.
     
     - parameter destinationOptions: Customization options that are used for the destination(s) preview.
     - parameter bannerConfiguration: Configuration of the banner. `DestinationPreviewViewController` is
     shown at the bottom of the screen by default.
     */
    public required init(_ destinationOptions: DestinationOptions,
                         bannerConfiguration: BannerConfiguration = BannerConfiguration(position: .bottomLeading)) {
        self.destinationOptions = destinationOptions
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
        setupStartButton()
        setupPreviewButton()
        setupDestinationLabel()
        setupSeparatorViews()
        setupConstraints()
        updateDestinationDetails()
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
        previewButton.addTarget(self, action: #selector(didTapPreviewRoutesButton), for: .touchUpInside)
        view.addSubview(previewButton)
        
        self.previewButton = previewButton
    }
    
    func setupStartButton() {
        let startButton = StartButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.clipsToBounds = true
        startButton.setImage(.previewStartImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.addTarget(self, action: #selector(didTapBeginActiveNavigationButton), for: .touchUpInside)
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
    
    // MARK: - Event handlers
    
    @objc func didTapPreviewRoutesButton() {
        delegate?.didTapPreviewRoutesButton(self)
    }
    
    @objc func didTapBeginActiveNavigationButton() {
        delegate?.didTapBeginActiveNavigationButton(self)
    }
    
    func updateDestinationDetails() {
        if let primaryText = destinationOptions.primaryText {
            destinationLabel.attributedText = primaryText
        }
    }
}
