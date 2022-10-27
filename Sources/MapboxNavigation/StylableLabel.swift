import UIKit

// :nodoc:
@objc(MBStylableLabel)
open class StylableLabel: UILabel {
    
    // Workaround the fact that UILabel properties are not marked with UI_APPEARANCE_SELECTOR.
    @objc dynamic open var normalTextColor: UIColor = .black {
        didSet {
            update()
        }
    }
    
    @objc dynamic open var normalFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            update()
        }
    }
    
    @objc dynamic public var textColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            update()
        }
    }
    
    @objc public var showHighlightedTextColor: Bool = false {
        didSet {
            update()
        }
    }
    
    open func update() {
        textColor = showHighlightedTextColor ? textColorHighlighted : normalTextColor
        font = normalFont
    }
}

// :nodoc:
@objc(MBTimeRemainingLabel)
open class TimeRemainingLabel: StylableLabel {
    
    /**
     Sets the text color for no or unknown traffic.
     */
    @objc dynamic public var trafficUnknownColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
        didSet {
            textColor = trafficUnknownColor
        }
    }
    
    /**
     Sets the text color for low traffic.
     */
    @objc dynamic public var trafficLowColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    
    /**
     Sets the text color for moderate traffic.
     */
    @objc dynamic public var trafficModerateColor: UIColor = #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0)
    
    /**
     Sets the text color for heavy traffic.
     */
    @objc dynamic public var trafficHeavyColor: UIColor = #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0)
    
    /**
     Sets the text color for severe traffic.
     */
    @objc dynamic public var trafficSevereColor: UIColor = #colorLiteral(red:0.54, green:0.06, blue:0.22, alpha:1.0)
}

// :nodoc:
@objc(MBDistanceRemainingLabel)
open class DistanceRemainingLabel: StylableLabel {
    
}

// :nodoc:
@objc(MBArrivalTimeLabel)
open class ArrivalTimeLabel: StylableLabel {
    
}

// :nodoc:
public class DestinationLabel: StylableLabel {
    
}
