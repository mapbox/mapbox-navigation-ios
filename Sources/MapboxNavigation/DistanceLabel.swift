import UIKit

/// :nodoc:
@objc(MBDistanceLabel)
open class DistanceLabel: StylableLabel {
    
    @objc dynamic public var valueTextColor: UIColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var unitTextColor: UIColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var valueTextColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var unitTextColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var valueFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var unitFont: UIFont = UIFont.systemFont(ofSize: 11, weight: .medium) {
        didSet {
            update()
        }
    }
    
    /**
     An attributed string indicating the distance along with a unit.
     
     - precondition: `NSAttributedStringKey.quantity` should be applied to the
        numeric quantity.
     */
    var attributedDistanceString: NSAttributedString? {
        didSet {
            update()
        }
    }
    
    open override func update() {
        guard let attributedDistanceString = attributedDistanceString else {
            return
        }
        
        // Create a copy of the attributed string that emphasizes the quantity.
        let emphasizedDistanceString = NSMutableAttributedString(attributedString: attributedDistanceString)
        let wholeRange = NSRange(location: 0, length: emphasizedDistanceString.length)
        var hasQuantity = false
        emphasizedDistanceString.enumerateAttribute(.quantity, in: wholeRange, options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
            let foregroundColor: UIColor
            let font: UIFont
            if let _ = emphasizedDistanceString.attribute(.quantity, at: range.location, effectiveRange: nil) {
                foregroundColor = showHighlightedTextColor ? valueTextColorHighlighted : valueTextColor
                font = valueFont
                hasQuantity = true
            } else {
                foregroundColor = showHighlightedTextColor ? unitTextColorHighlighted : unitTextColor
                font = unitFont
            }
            emphasizedDistanceString.addAttributes([.foregroundColor: foregroundColor, .font: font], range: range)
        }
        
        // As a failsafe, if no quantity was found, emphasize the entire string.
        if !hasQuantity {
            emphasizedDistanceString.addAttributes([.foregroundColor: valueTextColor, .font: valueFont], range: wholeRange)
        }
        
        // Replace spaces with hair spaces to economize on horizontal screen
        // real estate. Formatting the distance with a short style would remove
        // spaces, but in English it would also denote feet with a prime
        // mark (′), which is typically used for heights, not distances.
        emphasizedDistanceString.mutableString.replaceOccurrences(of: " ", with: "\u{200A}", options: [], range: wholeRange)
        
        attributedText = emphasizedDistanceString
    }
}
