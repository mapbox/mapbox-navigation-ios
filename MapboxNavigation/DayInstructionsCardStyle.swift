class DayInstructionsCardStyle: InstructionsCardStyle {
    var cornerRadius: CGFloat = 20.0
    
    var backgroundColor: UIColor = .white
    
    var highlightedBackgroundColor: UIColor = .cardBlue
    
    lazy var primaryLabelNormalFont: UIFont = {
        return CardFont.create(.bold, with: 24.0)!
    }()
    
    var primaryLabelTextColor: UIColor {
        return .cardDark
    }
    
    var primaryLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    lazy var secondaryLabelNormalFont: UIFont = {
        return CardFont.create(.bold, with: 18.0)!
    }()
    
    var secondaryLabelTextColor: UIColor {
        return .cardDark
    }
    
    var secondaryLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    lazy var distanceLabelNormalFont: UIFont = {
        return CardFont.create(.regular, with: 16.0)!
    }()
    
    var distanceLabelValueTextColor: UIColor {
        return .cardDark
    }
    
    var distanceLabelUnitTextColor: UIColor {
        return .cardDark
    }
    
    lazy var distanceLabelUnitFont: UIFont = {
        return CardFont.create(.regular, with: 16.0)!
    }()
    
    lazy var distanceLabelValueFont: UIFont = {
        return CardFont.create(.bold, with: 20.0)!
    }()
    
    var distanceLabelHighlightedTextColor: UIColor {
        return .cardLight
    }
    
    var maneuverViewPrimaryColor: UIColor {
        return .cardBlue
    }
    
    var maneuverViewSecondaryColor: UIColor {
        return .cardLight
    }
    
    var maneuverViewHighlightedColor: UIColor {
        return .cardLight
    }
}
