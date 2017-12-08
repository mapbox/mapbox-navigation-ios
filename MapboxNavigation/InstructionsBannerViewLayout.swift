import UIKit

extension BaseInstructionsBannerView {
    
    static let padding: CGFloat = 16
    static let maneuverViewSize = CGSize(width: 38, height: 38)
    
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
        distanceLabel.minimumScaleFactor = 20.0 / 22.0
        addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.allowsDefaultTighteningForTruncation = true
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 1
        primaryLabel.minimumScaleFactor = 26.0 / 30.0
        primaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.allowsDefaultTighteningForTruncation = true
        secondaryLabel.numberOfLines = 1
        secondaryLabel.minimumScaleFactor = 20.0 / 26.0
        secondaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(secondaryLabel)
        self.secondaryLabel = secondaryLabel
        
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        self.dividerView = dividerView
        
        let _separatorView = UIView()
        _separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_separatorView)
        self._separatorView = _separatorView
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        addTarget(self, action: #selector(BaseInstructionsBannerView.tappedInstructionsBanner(_:)), for: .touchUpInside)
    }
    
    func setupLayout() {
        // Distance label
        distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0).isActive = true
        distanceLabel.lastBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -BaseInstructionsBannerView.padding).isActive = true
        
        // Turn arrow view
        maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.width).isActive = true
        maneuverView.topAnchor.constraint(equalTo: topAnchor, constant: BaseInstructionsBannerView.padding).isActive = true
        maneuverView.bottomAnchor.constraint(greaterThanOrEqualTo: distanceLabel.topAnchor).isActive = true
        maneuverView.leftAnchor.constraint(equalTo: leftAnchor, constant: BaseInstructionsBannerView.padding).isActive = true
        
        // Primary Label
        primaryLabel.leftAnchor.constraint(equalTo: dividerView.rightAnchor).isActive = true
        primaryLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -18).isActive = true
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        
        // Secondary Label
        secondaryLabel.leftAnchor.constraint(equalTo: dividerView.rightAnchor).isActive = true
        secondaryLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -18).isActive = true
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        
        // Divider view (vertical divider between maneuver/distance to primary/secondary instruction
        dividerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 70).isActive = true
        dividerView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        dividerView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        dividerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // Separator view (invisible helper view for visualizing the result of the constraints)
        _separatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        _separatorView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        
        // Visible separator docked to the bottom
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    // Aligns the instruction to the center Y (used for single line primary and/or secondary instructions)
    func centerYAlignInstructions() {
        _separatorView.isHidden = false
        baselineConstraints.forEach { $0.isActive = false }
        centerYConstraints.forEach { $0.isActive = true }
    }
    
    // Aligns primary top to the top of the maneuver view and the secondary baseline to the distance baseline (used for multiline)
    func baselineAlignInstructions() {
        _separatorView.isHidden = true
        centerYConstraints.forEach { $0.isActive = false }
        baselineConstraints.forEach { $0.isActive = true }
    }
    
    func setupAvailableBounds() {
        // Abbreviate if the instructions do not fit on one line
        primaryLabel.availableBounds = {
            let height = ("|" as NSString).size(withAttributes: [.font: self.primaryLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
        
        secondaryLabel.availableBounds = {
            let height = ("|" as NSString).size(withAttributes: [.font: self.secondaryLabel.font]).height
            let availableWidth = self.bounds.width-self.maneuverView.frame.maxX-(8*2)
            return CGRect(x: 0, y: 0, width: availableWidth, height: height)
        }
    }
}
