import UIKit
import MapboxNavigation

protocol CustomRoutesPreviewViewControllerDelegate: AnyObject {
    
    func didPressStartNavigationButton()
}

class CustomRoutesPreviewViewController: UIViewController, RoutesPreviewing {
    
    var configuration: PreviewBannerConfiguration {
        PreviewBannerConfiguration(position: .bottomLeading)
    }
    
    var startNavigationButton: UIButton!
    
    var routesPreviewOptions: RoutesPreviewOptions
    
    weak var delegate: CustomRoutesPreviewViewControllerDelegate?
    
    required init(_ routesPreviewOptions: RoutesPreviewOptions) {
        self.routesPreviewOptions = routesPreviewOptions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupStartNavigationButton()
    }
    
    func setupStartNavigationButton() {
        let startNavigationButton = UIButton(type: .system)
        startNavigationButton.setTitleColor(.white, for: .normal)
        startNavigationButton.setTitle("Start navigation", for: .normal)
        startNavigationButton.clipsToBounds = true
        startNavigationButton.backgroundColor = .black
        startNavigationButton.layer.borderColor = UIColor.black.cgColor
        startNavigationButton.layer.borderWidth = 1.0
        startNavigationButton.layer.cornerRadius = 10.0
        startNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startNavigationButton)
        
        startNavigationButton.addTarget(self, action: #selector(didPressStartNavigationButton), for: .touchUpInside)
        
        let directionsButtonLayoutConstraints = [
            startNavigationButton.widthAnchor.constraint(equalToConstant: 150.0),
            startNavigationButton.heightAnchor.constraint(equalToConstant: 40.0),
            startNavigationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                           constant: 10.0),
            startNavigationButton.topAnchor.constraint(equalTo: view.topAnchor,
                                                       constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(directionsButtonLayoutConstraints)
        
        self.startNavigationButton = startNavigationButton
    }
    
    @objc func didPressStartNavigationButton() {
        delegate?.didPressStartNavigationButton()
    }
}
