import UIKit

protocol RoutePreviewViewDelegate: AnyObject {
    
    func didPressStartButton()
}

class RoutePreviewView: UIView {
    
    var timeRemainingLabel: TimeRemainingLabel!
    
    var distanceRemainingLabel: DistanceRemainingLabel!
    
    var arrivalTimeLabel: ArrivalTimeLabel!
    
    var startButton: UIButton!
    
    weak var delegate: RoutePreviewViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        setupTimeRemainingLabel()
        setupStartButton()
        setupDistanceRemainingLabel()
        setupArrivalTimeLabel()
        setupConstraints()
    }
    
    func setupTimeRemainingLabel() {
        let timeRemainingLabel = TimeRemainingLabel()
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeRemainingLabel)
        
        timeRemainingLabel.font = UIFont.systemFont(ofSize: 27.0)
        timeRemainingLabel.textColor = UIColor(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        timeRemainingLabel.numberOfLines = 1
        timeRemainingLabel.textAlignment = .center
        
        self.timeRemainingLabel = timeRemainingLabel
    }
    
    func setupDistanceRemainingLabel() {
        let distanceRemainingLabel = DistanceRemainingLabel()
        distanceRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(distanceRemainingLabel)
        
        distanceRemainingLabel.font = UIFont.systemFont(ofSize: 15.0)
        distanceRemainingLabel.textColor = UIColor(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        distanceRemainingLabel.numberOfLines = 1
        distanceRemainingLabel.textAlignment = .right
        
        self.distanceRemainingLabel = distanceRemainingLabel
    }
    
    func setupArrivalTimeLabel() {
        let arrivalTimeLabel = ArrivalTimeLabel()
        arrivalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrivalTimeLabel)
        
        arrivalTimeLabel.font = UIFont.systemFont(ofSize: 15.0)
        arrivalTimeLabel.textColor = UIColor(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        arrivalTimeLabel.numberOfLines = 1
        arrivalTimeLabel.textAlignment = .left
        
        self.arrivalTimeLabel = arrivalTimeLabel
    }
    
    func setupStartButton() {
        let startButton = UIButton(type: .system)
        startButton.backgroundColor = UIColor(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        startButton.layer.cornerRadius = 5
        startButton.setTitleColor(.white, for: .normal)
        startButton.clipsToBounds = true
        
        let startImage = UIImage(named: "start", in: .mapboxNavigation, compatibleWith: nil)!
        startButton.setImage(startImage, for: .normal)
        startButton.imageView?.contentMode = .scaleAspectFit
        startButton.imageView?.tintColor = .white
        startButton.tintColor = .white
        startButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                   left: 0.0,
                                                   bottom: 12.0,
                                                   right: 0.0)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(startButton)
        
        self.startButton = startButton
        
        startButton.addTarget(self, action: #selector(didPressStartButton), for: .touchUpInside)
    }
    
    func setupConstraints() {
        let buttonWidth: CGFloat = 70.0
        let buttonHeight: CGFloat = 50.0
        
        NSLayoutConstraint.activate([
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            startButton.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: topAnchor,
                                             constant: 20.0)
        ])
        
        NSLayoutConstraint.activate([
            timeRemainingLabel.heightAnchor.constraint(equalToConstant: 35.0),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                        constant: 10.0),
            timeRemainingLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                         constant: -10.0),
            timeRemainingLabel.topAnchor.constraint(equalTo: topAnchor,
                                                    constant: 20.0),
        ])
        
        NSLayoutConstraint.activate([
            distanceRemainingLabel.heightAnchor.constraint(equalToConstant: 25.0),
            distanceRemainingLabel.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                            constant: 10.0),
            distanceRemainingLabel.trailingAnchor.constraint(equalTo: centerXAnchor,
                                                             constant: -2.5),
            distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                        constant: 0.0)
        ])
        
        NSLayoutConstraint.activate([
            arrivalTimeLabel.heightAnchor.constraint(equalToConstant: 25.0),
            arrivalTimeLabel.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                       constant: -5.0),
            arrivalTimeLabel.leadingAnchor.constraint(equalTo: centerXAnchor,
                                                      constant: 2.5),
            arrivalTimeLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                  constant: 0.0)
        ])
    }
    
    @objc func didPressStartButton() {
        delegate?.didPressStartButton()
    }
}
