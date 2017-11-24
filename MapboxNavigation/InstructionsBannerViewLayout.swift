import UIKit

extension BaseInstructionsBannerView: AdaptiveView {
    
    static let padding: CGFloat = 16
    static let maneuverViewSize = CGSize(width: 38, height: 38)
    
    func setupViews() {
        clipsToBounds = false
        translatesAutoresizingMaskIntoConstraints = false
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.isUserInteractionEnabled = false
        addSubview(contentView)
        self.contentView = contentView
        
        let leftView = UIView() // Overlapping view on the left side, visible in compact mode
        leftView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftView)
        self.leftView = leftView
        
        let maneuverView = ManeuverView()
        maneuverView.backgroundColor = .clear
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        leftView.addSubview(maneuverView)
        self.maneuverView = maneuverView
        
        let distanceLabel = DistanceLabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.minimumScaleFactor = 20.0 / 22.0
        leftView.addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.allowsDefaultTighteningForTruncation = true
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 1
        primaryLabel.minimumScaleFactor = 26.0 / 30.0
        primaryLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.allowsDefaultTighteningForTruncation = true
        secondaryLabel.numberOfLines = 1
        secondaryLabel.minimumScaleFactor = 20.0 / 26.0
        secondaryLabel.lineBreakMode = .byTruncatingTail
        contentView.addSubview(secondaryLabel)
        self.secondaryLabel = secondaryLabel
        
        let _separatorView = UIView()
        _separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_separatorView)
        self._separatorView = _separatorView
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorView)
        self.separatorView = separatorView
        
        addTarget(self, action: #selector(BaseInstructionsBannerView.tappedInstructionsBanner(_:)), for: .touchUpInside)
        
        setupConstraints()
    }
    
    fileprivate func setupConstraints() {
        // Special constraints that are not based on trait collections.
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor))
        
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        
        let constraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(), constraints: [
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            // Content view
            contentView.topAnchor.constraint(equalTo: safeTopAnchor),
            contentView.leftAnchor.constraint(equalTo: safeLeftAnchor),
            contentView.rightAnchor.constraint(equalTo: safeRightAnchor),
            // Separator view (invisible helper view for visualizing the constraints)
            _separatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            _separatorView.heightAnchor.constraint(equalToConstant: 1),
            _separatorView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            _separatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            // Visible separator docked to the bottom
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.leftAnchor.constraint(equalTo: leftAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.rightAnchor.constraint(equalTo: rightAnchor),
            // Distance label
            distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0),
            distanceLabel.lastBaselineAnchor.constraint(equalTo: leftView.bottomAnchor, constant: -BaseInstructionsBannerView.padding),
            // Maneuver view
            maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height),
            maneuverView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.width),
            maneuverView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: BaseInstructionsBannerView.padding),
            maneuverView.bottomAnchor.constraint(greaterThanOrEqualTo: distanceLabel.topAnchor),
            maneuverView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: BaseInstructionsBannerView.padding)
            ])
        
        let verticalRegularConstraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(verticalSizeClass: .regular), constraints: [
            contentView.heightAnchor.constraint(equalToConstant: 96),
            
            // Left view
            leftView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            leftView.rightAnchor.constraint(equalTo: safeLeftAnchor, constant: 70),
            leftView.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftView.leftAnchor.constraint(equalTo: leftAnchor),
            
            // Primary Label
            primaryLabel.leftAnchor.constraint(equalTo: leftView.rightAnchor),
            primaryLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -18),
            // Secondary Label
            secondaryLabel.leftAnchor.constraint(equalTo: leftView.rightAnchor),
            secondaryLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -18),
            ])
        
        let verticalCompactConstraints = AdaptiveConstraintContainer(traitCollection: UITraitCollection(verticalSizeClass: .compact), constraints: [
            contentView.heightAnchor.constraint(equalToConstant: 60),
            
            // Left view
            leftView.heightAnchor.constraint(equalToConstant: 96),
            leftView.rightAnchor.constraint(equalTo: safeLeftAnchor, constant: 70),
            leftView.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftView.leftAnchor.constraint(equalTo: leftAnchor),
            
            // Primary Label
            primaryLabel.leftAnchor.constraint(equalTo: leftView.rightAnchor),
            primaryLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -18),
            primaryLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            // Secondary Label
            secondaryLabel.leftAnchor.constraint(equalTo: primaryLabel.rightAnchor, constant: 10),
            secondaryLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -18),
            secondaryLabel.lastBaselineAnchor.constraint(equalTo: primaryLabel.lastBaselineAnchor)
            ])
        
        constraintContainers = [constraints,
                                verticalRegularConstraints,
                                verticalCompactConstraints]
        
        centerYAlignInstructions()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let traitCollection = isOpen ? UITraitCollection(verticalSizeClass: .regular) : self.traitCollection
        constraintContainers.forEach { $0.update(for: traitCollection ) }
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        let isRegularVerticalSizeClass = traitCollection.verticalSizeClass != .compact
        if isRegularVerticalSizeClass || isOpen {
            if secondaryLabel.instruction == nil {
                centerYAlignInstructions()
            } else {
                baselineAlignInstructions()
            }
        } else {
            centerYConstraints.forEach { $0.isActive = false }
            baselineConstraints.forEach { $0.isActive = false }
        }
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
