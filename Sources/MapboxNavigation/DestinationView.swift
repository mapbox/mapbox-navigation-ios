import UIKit

protocol DestinationViewDelegate: AnyObject {
    
    func didPressPreviewButton()
    
    func didPressStartButton()
}

class DestinationView: UIView {
    
    var destinationLabel: UILabel!
    
    var previewButton: UIButton!
    
    var startButton: UIButton!
    
    weak var delegate: DestinationViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        setupStartButton()
        setupPreviewButton()
        setupDestinationLabel()
        setupConstraints()
    }
    
    func setupDestinationLabel() {
        let destinationLabel: UILabel = .forAutoLayout()
        addSubview(destinationLabel)
        
        destinationLabel.font = UIFont.systemFont(ofSize: 27.0)
        destinationLabel.textColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        destinationLabel.numberOfLines = 2
        
        self.destinationLabel = destinationLabel
    }
    
    func setupPreviewButton() {
        let previewButton: UIButton = .forAutoLayout()
        previewButton.backgroundColor = .white
        previewButton.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        previewButton.layer.cornerRadius = 5
        previewButton.layer.borderWidth = 2
        previewButton.setTitleColor(UIColor(red: 0.216, green: 0.212, blue: 0.454, alpha: 1), for: .normal)
        previewButton.clipsToBounds = true
        
        let previewImage = UIImage(named: "route", in: .mapboxNavigation, compatibleWith: nil)!
        previewButton.setImage(previewImage, for: .normal)
        previewButton.imageView?.contentMode = .scaleAspectFit
        previewButton.imageView?.tintColor = UIColor(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        previewButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                     left: 0.0,
                                                     bottom: 12.0,
                                                     right: 0.0)
        previewButton.layer.borderColor = UIColor(red: 0.804, green: 0.816, blue: 0.816, alpha: 1).cgColor
        addSubview(previewButton)
        
        previewButton.addTarget(self, action: #selector(didPressPreviewButton), for: .touchUpInside)
        
        self.previewButton = previewButton
    }
    
    func setupStartButton() {
        let startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        startButton.layer.cornerRadius = 5.0
        startButton.setTitleColor(.white, for: .normal)
        startButton.clipsToBounds = true
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
        
        let startImage = UIImage(named: "start", in: .mapboxNavigation, compatibleWith: nil)!
        startButton.setImage(startImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.imageView?.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        startButton.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        startButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                   left: 0.0,
                                                   bottom: 12.0,
                                                   right: 0.0)
        addSubview(startButton)
        
        self.startButton = startButton
    }
    
    func setupConstraints() {
        let buttonWidth: CGFloat = 70.0
        let buttonHeight: CGFloat = 50.0
        
        let startButtonLayoutConstraints = [
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            startButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: topAnchor,
                                             constant: 20.0)
        ]
        
        NSLayoutConstraint.activate(startButtonLayoutConstraints)
        
        let previewButtonLayoutConstraints = [
            previewButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            previewButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            previewButton.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                    constant: -10.0),
            previewButton.topAnchor.constraint(equalTo: topAnchor,
                                               constant: 20.0)
        ]
        
        NSLayoutConstraint.activate(previewButtonLayoutConstraints)
        
        let destinationLabelLayoutConstraints = [
            destinationLabel.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                      constant: 10.0),
            destinationLabel.trailingAnchor.constraint(equalTo: previewButton.leadingAnchor,
                                                       constant: -10.0),
            destinationLabel.topAnchor.constraint(equalTo: topAnchor,
                                                  constant: 20.0),
            destinationLabel.bottomAnchor.constraint(equalTo: safeBottomAnchor,
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
