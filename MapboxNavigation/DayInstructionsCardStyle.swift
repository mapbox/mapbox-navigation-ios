/// :nodoc:
public class DayInstructionsCardStyle: InstructionsCardStyle {
    public var cornerRadius: CGFloat = 20.0
    
    public var backgroundColor: UIColor = .white
    
    public var highlightedBackgroundColor: UIColor = .cardBlue
    
    public lazy var primaryLabelNormalFont: UIFont = {
        return CardFont.create(.bold, with: 24.0)!
    }()
    
    public var primaryLabelTextColor: UIColor {
        return .cardDark
    }
    
    public var primaryLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    public lazy var secondaryLabelNormalFont: UIFont = {
        return CardFont.create(.bold, with: 18.0)!
    }()
    
    public var secondaryLabelTextColor: UIColor {
        return .cardDark
    }
    
    public var secondaryLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    public lazy var distanceLabelNormalFont: UIFont = {
        return CardFont.create(.regular, with: 16.0)!
    }()
    
    public var distanceLabelValueTextColor: UIColor {
        return .cardDark
    }
    
    public var distanceLabelUnitTextColor: UIColor {
        return .cardDark
    }
    
    public lazy var distanceLabelUnitFont: UIFont = {
        return CardFont.create(.regular, with: 16.0)!
    }()
    
    public lazy var distanceLabelValueFont: UIFont = {
        return CardFont.create(.bold, with: 20.0)!
    }()
    
    public var distanceLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    public var maneuverViewPrimaryColor: UIColor {
        return .cardBlue
    }
    
    public var maneuverViewSecondaryColor: UIColor {
        return .cardLight
    }
    
    public var maneuverViewHighlightedColor: UIColor {
        return .cardLight
    }

    public var maneuverViewSecondaryHighlightedColor: UIColor {
        return UIColor.cardLight.withAlphaComponent(0.4)
    }
    
    public var nextBannerViewPrimaryColor: UIColor {
        return .cardBlue
    }
    
    public var nextBannerViewSecondaryColor: UIColor {
        return .cardLight
    }
    
    public var nextBannerInstructionLabelTextColor: UIColor {
        return .cardDark
    }
    
    public lazy var nextBannerInstructionLabelNormalFont: UIFont = {
        return CardFont.create(.regular, with: 14.0)
    }()
    
    public var nextBannerInstructionHighlightedColor: UIColor {
        return .cardLight
    }

    public var nextBannerInstructionSecondaryHighlightedColor: UIColor {
        return UIColor.cardLight.withAlphaComponent(0.4)
    }
    
    public var lanesViewDefaultColor: UIColor {
        return .cardBlue
    }
    
    public var lanesViewHighlightedColor: UIColor {
        return .cardLight
    }
    
    public init() {}
}
