import UIKit
import MapboxNavigation

protocol CustomDestinationPreviewViewControllerDelegate: AnyObject {
    
    func didPressDirectionsButton()
}

class CustomDestinationPreviewViewController: UIViewController, DestinationPreviewing {
    
    var configuration: PreviewBannerConfiguration {
        PreviewBannerConfiguration(position: .bottomLeading)
    }
    
    var directionsButton: UIButton!
    
    var destinationLabel: UILabel!
    
    var destinationOptions: DestinationOptions
    
    weak var delegate: CustomDestinationPreviewViewControllerDelegate?
    
    required init(_ destinationOptions: DestinationOptions) {
        self.destinationOptions = destinationOptions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDirectionsButton()
        setupDestinationLabel()
    }
    
    func setupDirectionsButton() {
        let directionsButton = UIButton(type: .system)
        directionsButton.setTitleColor(.white, for: .normal)
        directionsButton.setTitle("Directions", for: .normal)
        directionsButton.clipsToBounds = true
        directionsButton.backgroundColor = .black
        directionsButton.layer.borderColor = UIColor.black.cgColor
        directionsButton.layer.borderWidth = 1.0
        directionsButton.layer.cornerRadius = 10.0
        directionsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(directionsButton)
        
        directionsButton.addTarget(self, action: #selector(didPressDirectionsButton), for: .touchUpInside)
        
        let directionsButtonLayoutConstraints = [
            directionsButton.widthAnchor.constraint(equalToConstant: 100.0),
            directionsButton.heightAnchor.constraint(equalToConstant: 40.0),
            directionsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: 10.0),
            directionsButton.topAnchor.constraint(equalTo: view.topAnchor,
                                                  constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(directionsButtonLayoutConstraints)
        
        self.directionsButton = directionsButton
    }
    
    func setupDestinationLabel() {
        let destinationLabel = UILabel()
        destinationLabel.font = UIFont.systemFont(ofSize: 15.0)
        destinationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let coordinate = destinationOptions.waypoint.coordinate
        destinationLabel.text = String(format: "(%.5f, %.5f)", coordinate.latitude, coordinate.longitude)
        
        view.addSubview(destinationLabel)
        
        let destinationLabelLayoutConstraints = [
            destinationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                      constant: 10.0),
            destinationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                       constant: -10.0),
            destinationLabel.topAnchor.constraint(equalTo: directionsButton.bottomAnchor,
                                                  constant: 10.0),
            destinationLabel.heightAnchor.constraint(equalToConstant: 30.0)
        ]
        
        NSLayoutConstraint.activate(destinationLabelLayoutConstraints)
        
        self.destinationLabel = destinationLabel
    }
    
    @objc func didPressDirectionsButton() {
        delegate?.didPressDirectionsButton()
    }
}
