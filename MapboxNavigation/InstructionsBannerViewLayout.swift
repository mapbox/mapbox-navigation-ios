import UIKit

extension BaseInstructionsBannerView {
    
    static let padding: CGFloat = 16
    static let maneuverViewSize = CGSize(width: 38, height: 38)
    static let stepListIndicatorViewSize = CGSize(width: 30, height: 5)
    
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
        distanceLabel.minimumScaleFactor = 16.0 / 22.0
        addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.instructionDelegate = instructionDelegate
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.allowsDefaultTighteningForTruncation = true
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 1
        primaryLabel.minimumScaleFactor = 20.0 / 30.0
        primaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.instructionDelegate = instructionDelegate
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
        
        let stepListIndicatorView = StepListIndicatorView()
        stepListIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stepListIndicatorView)
        self.stepListIndicatorView = stepListIndicatorView
        
        addTarget(self, action: #selector(BaseInstructionsBannerView.tappedInstructionsBanner(_:)), for: .touchUpInside)

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(BaseInstructionsBannerView.draggedInstructionsBanner(_:))))
    }
    
    func setupLayout() {
        // firstColumnWidth is the width of the left side of the banner containing the maneuver view and distance label
        let firstColumnWidth = BaseInstructionsBannerView.maneuverViewSize.width + BaseInstructionsBannerView.padding * 3
        
        // Distance label
        distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor, constant: 0).isActive = true
        distanceLabel.lastBaselineAnchor.constraint(equalTo: bottomAnchor, constant: -BaseInstructionsBannerView.padding).isActive = true
        distanceLabel.topAnchor.constraint(greaterThanOrEqualTo: maneuverView.bottomAnchor).isActive = true
        
        // Turn arrow view
        maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.width).isActive = true
        maneuverView.topAnchor.constraint(equalTo: topAnchor, constant: BaseInstructionsBannerView.padding).isActive = true
        maneuverView.centerXAnchor.constraint(equalTo: leadingAnchor, constant: firstColumnWidth / 2).isActive = true
        
        // Primary Label
        primaryLabel.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        primaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor, constant: -BaseInstructionsBannerView.padding/2))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        
        // Secondary Label
        secondaryLabel.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor, constant: -BaseInstructionsBannerView.padding / 2))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor, constant: 0))
        
        // Drag Indicator View
        stepListIndicatorView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.stepListIndicatorViewSize.height).isActive = true
        stepListIndicatorView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.stepListIndicatorViewSize.width).isActive = true
        stepListIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -BaseInstructionsBannerView.padding / 2).isActive = true
        stepListIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        baselineConstraints.append(stepListIndicatorView.topAnchor.constraint(greaterThanOrEqualTo: secondaryLabel.bottomAnchor))
        centerYConstraints.append(stepListIndicatorView.topAnchor.constraint(greaterThanOrEqualTo: secondaryLabel.bottomAnchor, constant: 0))

        // Divider view (vertical divider between maneuver/distance to primary/secondary instruction
        dividerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: firstColumnWidth).isActive = true
        dividerView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        dividerView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        dividerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // Separator view (invisible helper view for visualizing the result of the constraints)
        _separatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        _separatorView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        
        // Visible separator docked to the bottom
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
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
        primaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.primaryLabel.viewForAvailableBoundsCalculation?.bounds.width ?? self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.primaryLabel.font.lineHeight)
        }
        
        secondaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.secondaryLabel.viewForAvailableBoundsCalculation?.bounds.width ?? self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.secondaryLabel.font.lineHeight)
        }
    }
}
