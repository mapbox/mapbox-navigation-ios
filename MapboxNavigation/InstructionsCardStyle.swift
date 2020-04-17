/// :nodoc:
public protocol InstructionsCardStyle: class {
    var cornerRadius: CGFloat { get set }
    var backgroundColor: UIColor { get set }
    var highlightedBackgroundColor: UIColor { get set }
    
    // MARK: Primary label custom formats
    var primaryLabelNormalFont: UIFont { get }
    var primaryLabelTextColor: UIColor { get }
    var primaryLabelHighlightedTextColor: UIColor { get }
    
    // MARK: Secondary label custom formats
    var secondaryLabelNormalFont: UIFont { get }
    var secondaryLabelTextColor: UIColor { get }
    var secondaryLabelHighlightedTextColor: UIColor { get }
    
    // MARK: Distance label custom formats
    var distanceLabelNormalFont: UIFont { get }
    var distanceLabelValueTextColor: UIColor { get }
    var distanceLabelUnitTextColor: UIColor { get }
    var distanceLabelUnitFont: UIFont { get }
    var distanceLabelValueFont: UIFont { get }
    var distanceLabelHighlightedTextColor: UIColor { get }
    
    // MARK: Maneuver view custom formats
    var maneuverViewPrimaryColor: UIColor { get }
    var maneuverViewSecondaryColor: UIColor { get }
    var maneuverViewHighlightedColor: UIColor { get }
    var maneuverViewSecondaryHighlightedColor: UIColor { get }
    
    // MARK: Next Banner Instruction custom formats
    var nextBannerViewPrimaryColor: UIColor { get }
    var nextBannerViewSecondaryColor: UIColor { get }
    var nextBannerInstructionLabelTextColor: UIColor { get }
    var nextBannerInstructionLabelNormalFont: UIFont { get }
    var nextBannerInstructionHighlightedColor: UIColor { get }
    var nextBannerInstructionSecondaryHighlightedColor: UIColor { get }
    
    // MARK: Lanes View custom formats
    var lanesViewDefaultColor: UIColor { get }
    var lanesViewHighlightedColor: UIColor { get }
}
