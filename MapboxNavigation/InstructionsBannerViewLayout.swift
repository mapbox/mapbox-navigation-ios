import UIKit

extension InstructionsBannerView {
    
    func commonInit() {
        setupViews()
        setupLayout()
        setupAvailableBounds()
    }
    
    func setupViews() {
        backgroundColor = .clear
        
        let maneuverView = ManeuverView()
        maneuverView.backgroundColor = .clear
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maneuverView)
        self.maneuverView = maneuverView
        
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
        // Distance label
        distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0).isActive = true
        distanceLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8).isActive = true
        
        // Turn arrow view
        maneuverView.widthAnchor.constraint(equalToConstant: 54).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: 54).isActive = true
        maneuverView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8).isActive = true
        maneuverView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        maneuverView.bottomAnchor.constraint(equalTo: distanceLabel.topAnchor, constant: -8).isActive = true
        
        // Stack view
        stackView.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -16).isActive = true
        stackView.leftAnchor.constraint(greaterThanOrEqualTo: maneuverView.rightAnchor, constant: 16).isActive = true
        stackView.leftAnchor.constraint(greaterThanOrEqualTo: distanceLabel.rightAnchor, constant: 16).isActive = true
        stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8).isActive = true
        stackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func setupAvailableBounds() {
        // Abbreviate if the instructions do not fit on one line
        primaryLabel.availableBounds = {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.primaryLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
        
        secondaryLabel.availableBounds = {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: self.secondaryLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
    }
}
