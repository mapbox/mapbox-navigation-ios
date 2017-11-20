import UIKit

extension BaseInstructionsBannerView: AdaptiveView {
    
    static let padding: CGFloat = 16
    static let maneuverViewSize = CGSize(width: 38, height: 38)
    
    func setupViews() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        
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
        
        setupConstraints()
    }
    
    fileprivate func setupConstraints() {
        // Special constraints that are not based on trait collections.
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        
        let constraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(), constraints: [
            // Primary Label
            primaryLabel.leftAnchor.constraint(equalTo: dividerView.rightAnchor),
            primaryLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -18),
            // Secondary Label
            secondaryLabel.leftAnchor.constraint(equalTo: dividerView.rightAnchor),
            secondaryLabel.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -18),
            // Divider view (vertical divider between maneuver/distance to primary/secondary instruction
            dividerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 70),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalTo: heightAnchor),
            dividerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            // Separator view (invisible helper view for visualizing the constraints)
            _separatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            _separatorView.heightAnchor.constraint(equalToConstant: 1),
            _separatorView.widthAnchor.constraint(equalTo: widthAnchor),
            _separatorView.leftAnchor.constraint(equalTo: leftAnchor),
            // Visible separator docked to the bottom
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leftAnchor.constraint(equalTo: leftAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.rightAnchor.constraint(equalTo: rightAnchor)
            ])
        
        let verticalRegularConstraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(verticalSizeClass: .regular), constraints: [
            heightAnchor.constraint(equalToConstant: 96),
            // Distance label
            distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0),
            distanceLabel.lastBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -BaseInstructionsBannerView.padding),
            // Maneuver view
            maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height),
            maneuverView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.width),
            maneuverView.topAnchor.constraint(equalTo: topAnchor, constant: BaseInstructionsBannerView.padding),
            maneuverView.bottomAnchor.constraint(greaterThanOrEqualTo: distanceLabel.topAnchor),
            maneuverView.leftAnchor.constraint(equalTo: leftAnchor, constant: BaseInstructionsBannerView.padding),
            ])
        
        let verticalCompactConstraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(verticalSizeClass: .compact), constraints: [
            heightAnchor.constraint(equalToConstant: 60),
            // Maneuver view
            maneuverView.heightAnchor.constraint(equalToConstant: 28),
            maneuverView.widthAnchor.constraint(equalToConstant: 28),
            maneuverView.bottomAnchor.constraint(equalTo: distanceLabel.topAnchor),
            maneuverView.leftAnchor.constraint(equalTo: leftAnchor, constant: BaseInstructionsBannerView.padding),
            maneuverView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            // Distance label
            distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0),
            distanceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            ])
        
        constraintContainers = [constraints,
                                verticalRegularConstraints,
                                verticalCompactConstraints]
        
        centerYAlignInstructions()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        constraintContainers.forEach { $0.update(for: traitCollection ) }
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
