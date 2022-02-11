import CoreLocation
import UIKit
import MapboxDirections

/// :nodoc:
public class InstructionsCardView: BaseInstructionsBannerView {
    
    var step: RouteStep!
    var distanceFromCurrentLocation: CLLocationDistance!
    
    public required override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        prepareLayout()
        self.showStepIndicator = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareLayout()
        showStepIndicator = false
    }
    
    public func prepareLayout() {
        prepareManeuver()
        prepareDistance()
        preparePrimaryLabel()
        prepareSecondaryLabel()
    }
    
    public func updateInstruction(for step: RouteStep) {
        if let instruction = step.instructionsDisplayedAlongStep?.last {
            update(for: instruction)
        }
    }
    
    public func updateDistanceFromCurrentLocation(_ distance: CLLocationDistance) {
        self.distanceFromCurrentLocation = distance
        self.distance = distance
    }
    
    fileprivate func prepareManeuver() {
        maneuverView.shouldShowHighlightedColors = false
    }
    
    fileprivate func prepareDistance() {
        distanceLabel.showHighlightedTextColor = false
    }
    
    fileprivate func preparePrimaryLabel() {
        primaryLabel.showHighlightedTextColor = false
    }
    
    fileprivate func prepareSecondaryLabel() {
        secondaryLabel.showHighlightedTextColor = false
    }
    
    // MARK: Layout
    
    override func setupLayout() {
        distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                               constant: BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                                constant: -BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor,
                                               constant: 0).isActive = true
        distanceLabel.lastBaselineAnchor.constraint(equalTo: bottomAnchor,
                                                    constant: -BaseInstructionsBannerView.padding).isActive = true
        distanceLabel.topAnchor.constraint(greaterThanOrEqualTo: maneuverView.bottomAnchor).isActive = true
        
        maneuverView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                              constant: 10).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height).isActive = true
        maneuverView.topAnchor.constraint(equalTo: topAnchor,
                                          constant: BaseInstructionsBannerView.padding).isActive = true
        // Width of the left side of the banner containing the maneuver view and distance label.
        let firstColumnWidth = BaseInstructionsBannerView.maneuverViewSize.width + BaseInstructionsBannerView.padding * 3
        maneuverView.centerXAnchor.constraint(equalTo: leadingAnchor,
                                              constant: firstColumnWidth / 2).isActive = true
        
        primaryLabel.leadingAnchor.constraint(equalTo: maneuverView.trailingAnchor,
                                              constant: 10).isActive = true
        primaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                               constant: -10).isActive = true
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor,
                                                                     constant: -BaseInstructionsBannerView.padding / 2))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        
        secondaryLabel.leadingAnchor.constraint(equalTo: maneuverView.trailingAnchor,
                                                constant: 10).isActive = true
        secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                 constant: -10).isActive = true
        
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor,
                                                                                constant: -BaseInstructionsBannerView.padding / 2))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor,
                                                                       constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor,
                                                                      constant: 0))
        
        // Visible separator docked to the bottom.
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    // Aligns the instruction to the center Y (used for single line primary and/or secondary instructions)
    override func centerYAlignInstructions() {
        baselineConstraints.forEach { $0.isActive = false }
        centerYConstraints.forEach { $0.isActive = true }
    }
    
    // Aligns primary top to the top of the maneuver view and the secondary baseline to the distance baseline (used for multiline)
    override func baselineAlignInstructions() {
        centerYConstraints.forEach { $0.isActive = false }
        baselineConstraints.forEach { $0.isActive = true }
    }
    
    override func setupAvailableBounds() {
        // Abbreviate if the instructions do not fit on one line
        primaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.primaryLabel.font.lineHeight)
        }
        
        secondaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.secondaryLabel.font.lineHeight)
        }
    }
}
