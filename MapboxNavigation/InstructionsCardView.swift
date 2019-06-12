import UIKit
import MapboxDirections
import MapboxCoreNavigation

public class InstructionsCardView: BaseInstructionsBannerView {
    
    @objc dynamic var cardWidthFactor: CGFloat = 0.82
    @objc dynamic var cardHeight: CGFloat = 100.0
    
    var style: InstructionsCardStyle = DayInstructionsCardStyle()
    var step: RouteStep! {
        didSet {
            self.updateInstruction(for: step)
        }
    }
    var distanceFromCurrentLocation: CLLocationDistance!
    var gradientLayer: CAGradientLayer!
    var highlightDistance: CLLocationDistance = InstructionsCardConstants.highlightDistance
    
    required public init(style: InstructionsCardStyle? = nil, frame: CGRect = .zero) {
        super.init(frame: frame)
        self.showStepIndicator = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareLayout()
        showStepIndicator = false
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    public func prepareLayout(for style: InstructionsCardStyle) {
        self.style = style
        prepareLayout()
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
    
    func prepareLayout() {
        prepareCardDeck(style)
        prepareManeuver(style)
        prepareDistance(style)
        preparePrimaryLabel(style)
        prepareSecondaryLabel(style)
    }
    
    fileprivate func prepareManeuver(_ style: InstructionsCardStyle) {
        maneuverView.primaryColor = style.maneuverViewPrimaryColor
        maneuverView.secondaryColor = style.maneuverViewSecondaryColor
    }
    
    fileprivate func prepareDistance(_ style: InstructionsCardStyle) {
        distanceLabel.valueTextColor = style.distanceLabelValueTextColor
        distanceLabel.unitTextColor = style.distanceLabelUnitTextColor
        
        distanceLabel.valueFont = style.distanceLabelValueFont
        distanceLabel.unitFont = style.distanceLabelUnitFont
    }
    
    fileprivate func preparePrimaryLabel(_ style: InstructionsCardStyle) {
        primaryLabel.normalFont = style.primaryLabelNormalFont
        primaryLabel.normalTextColor = style.primaryLabelTextColor
    }
    
    fileprivate func prepareSecondaryLabel(_ style: InstructionsCardStyle) {
        secondaryLabel.normalFont = style.secondaryLabelNormalFont
        secondaryLabel.normalTextColor = style.secondaryLabelTextColor
    }
    
    fileprivate func prepareCardDeck(_ style: InstructionsCardStyle) {
        backgroundColor = .clear
        
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            layer.insertSublayer(gradientLayer, at: 0)
        }
        
        let alphaComponent = InstructionsCardConstants.backgroundColorAlphaComponent
        gradientLayer.colors = [
            style.backgroundColor.cgColor,
            style.backgroundColor.withAlphaComponent(alphaComponent).cgColor
        ]
    }
}
