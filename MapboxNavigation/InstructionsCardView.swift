import UIKit
import MapboxDirections
import MapboxCoreNavigation

open class InstructionsCardView: BaseInstructionsBannerView, NavigationComponent {
    
    public var style: InstructionsCardStyle = DayInstructionsCardStyle () {
        didSet {
            prepareLayout()
        }
    }
    
    var step: RouteStep! {
        didSet {
            guard let instruction = step.instructionsDisplayedAlongStep?.last else {
                return
            }
            update(for: instruction)
        }
    }
    
    var distanceFromCurrentLocation: CLLocationDistance! {
        didSet {
            distance = distanceFromCurrentLocation
        }
    }
    
    var gradientLayer: CAGradientLayer!
    
    var highlightDistance: CLLocationDistance = InstructionsCardConstants.highlightDistance
    
    var isActive: Bool = false {
        didSet {
            if !oldValue && isActive {
                highlight()
            }
        }
    }
    
    required public init(style: InstructionsCardStyle? = nil) {
        defer {
            self.style = style ?? DayInstructionsCardStyle()
        }
        
        super.init(frame: .zero)
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
    
    @objc public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        update(for: instruction)
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
        maneuverView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height).isActive = true
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
        
        primaryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: InstructionsCardConstants.primaryLabelWidth).isActive = true
        primaryLabel.leadingAnchor.constraint(equalTo: maneuverView.trailingAnchor,
                                              constant: InstructionsCardConstants.primaryLabelLeadingPadding).isActive = true
    }
    
    fileprivate func prepareSecondaryLabel(_ style: InstructionsCardStyle) {
        secondaryLabel.normalFont = style.secondaryLabelNormalFont
        secondaryLabel.normalTextColor = style.secondaryLabelTextColor
        
        secondaryLabel.widthAnchor.constraint(lessThanOrEqualToConstant: InstructionsCardConstants.secondaryLabelWidth).isActive = true
        secondaryLabel.leadingAnchor.constraint(equalTo: maneuverView.trailingAnchor).isActive = true
    }
    
    fileprivate func prepareCardDeck(_ style: InstructionsCardStyle) {
        layer.cornerRadius = style.cornerRadius
        layer.masksToBounds = true
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
    
    func highlight() {
        let duration = InstructionsCardConstants.highlightAnimationDuration
        UIView.animate(withDuration: duration, animations: {
            let alphaComponent = InstructionsCardConstants.highlightedBackgroundAlphaComponent
            self.gradientLayer.colors = [
                self.style.highlightedBackgroundColor.cgColor,
                self.style.highlightedBackgroundColor.withAlphaComponent(alphaComponent).cgColor
            ]
            
            self.primaryLabel.textColor = self.style.primaryLabelHighlightedTextColor
            self.secondaryLabel.textColor = self.style.secondaryLabelHighlightedTextColor
            self.distanceLabel.unitTextColor = self.style.distanceLabelHighlightedTextColor
            self.distanceLabel.valueTextColor = self.style.distanceLabelHighlightedTextColor
            self.maneuverView.primaryColor = self.style.maneuverViewHighlightedColor
            self.maneuverView.secondaryColor = self.style.maneuverViewHighlightedColor
        })
    }
}

