import UIKit

// :nodoc:
public class PreviewDismissalViewController: UIViewController, Banner {
    
    var backButton: BackButton!
    
    weak var delegate: PreviewDismissalViewControllerDelegate?
    
    // MARK: - Banner properties
    
    public var bannerConfiguration: BannerConfiguration {
        BannerConfiguration(position: .topLeading, height: 40.0)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.setupBackButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController lifecycle methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        
        setupConstraints()
    }
    
    // MARK: - UIViewController setting-up methods
    
    func setupBackButton() {
        let backButton = BackButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let backButtonTitle = NSLocalizedString("BACK",
                                                bundle: .mapboxNavigation,
                                                value: "BACK",
                                                comment: "Title of the back button.")
        
        backButton.setTitle(backButtonTitle, for: .normal)
        backButton.clipsToBounds = true
        backButton.isHidden = true
        backButton.addTarget(self, action: #selector(didPressBackButton), for: .touchUpInside)
        backButton.setImage(.backImage, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.imageEdgeInsets = UIEdgeInsets(top: 10,
                                                  left: 0,
                                                  bottom: 10,
                                                  right: 15)
        view.addSubview(backButton)
        
        self.backButton = backButton
    }
    
    // MARK: - Event handlers
    
    @objc func didPressBackButton() {
        delegate?.didDismiss(self)
    }
}
