import UIKit

extension InstructionsBannerView {
    
    func commonInit() {
        setupViews()
        setupLayout()
        setupAvailableBounds()
    }
    
    func setupViews() {
        backgroundColor = .clear
        
        let turnArrowView = TurnArrowView()
        turnArrowView.backgroundColor = .clear
        turnArrowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(turnArrowView)
        self.turnArrowView = turnArrowView
        
        let distanceLabel = DistanceLabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.minimumScaleFactor = 0.2
        addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 3
        primaryLabel.minimumScaleFactor = 0.5
        primaryLabel.lineBreakMode = .byTruncatingTail
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.adjustsFontSizeToFitWidth = true
        secondaryLabel.numberOfLines = 3
        secondaryLabel.minimumScaleFactor = 0.2
        secondaryLabel.lineBreakMode = .byTruncatingTail
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.addArrangedSubview(primaryLabel)
        stackView.addArrangedSubview(secondaryLabel)
        addSubview(stackView)
        
        self.stackView = stackView
        self.primaryLabel = primaryLabel
        self.secondaryLabel = secondaryLabel
    }
    
    func setupLayout() {
        let views: [String: Any] = ["turnArrowView": self.turnArrowView, "distanceLabel": self.distanceLabel, "primaryLabel": self.primaryLabel, "secondaryLabel": self.secondaryLabel]
        
        // Distance label
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .top, relatedBy: .equal, toItem: turnArrowView, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: distanceLabel, attribute: .bottom, multiplier: 1, constant: 8))
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .centerX, relatedBy: .equal, toItem: turnArrowView, attribute: .centerX, multiplier: 1, constant: 0))
        
        // Turn arrow view
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[turnArrowView(50)]", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[turnArrowView(50)][distanceLabel]", options: [], metrics: nil, views: views))
        
        // Stack view
        stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: 8).isActive = true
        stackView.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -8).isActive = true
        stackView.leftAnchor.constraint(equalTo: turnArrowView.rightAnchor, constant: 8).isActive = true
        stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    func setupAvailableBounds() {
        // Abbreviate if the instructions do not fit on one line
        primaryLabel.availableBounds = {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.primaryLabel.font]).height
            let availableWidth = self.bounds.width-self.turnArrowView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
        
        secondaryLabel.availableBounds = {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.secondaryLabel.font]).height
            let availableWidth = self.bounds.width-self.turnArrowView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
    }
}
