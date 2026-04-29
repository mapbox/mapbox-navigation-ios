import UIKit

@_documentation(visibility: internal)
@objc(MBStylableLabel)
open class StylableLabel: UILabel {
    // Workaround the fact that UILabel properties are not marked with UI_APPEARANCE_SELECTOR.
    @objc open dynamic var normalTextColor: UIColor = .black {
        didSet {
            update()
        }
    }

    @objc open dynamic var normalFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            update()
        }
    }

    @objc public dynamic var textColorHighlighted: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
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

@objc(MBTimeRemainingLabel)
open class TimeRemainingLabel: StylableLabel {
    /// Sets the text color for no or unknown traffic.
    @objc public dynamic var trafficUnknownColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
        didSet {
            textColor = trafficUnknownColor
        }
    }

    /// Sets the text color for low traffic.
    @objc public dynamic var trafficLowColor: UIColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)

    /// Sets the text color for moderate traffic.
    @objc public dynamic var trafficModerateColor: UIColor = #colorLiteral(red: 0.95, green: 0.65, blue: 0.31, alpha: 1.0)

    /// Sets the text color for heavy traffic.
    @objc public dynamic var trafficHeavyColor: UIColor = #colorLiteral(red: 0.91, green: 0.20, blue: 0.25, alpha: 1.0)

    /// Sets the text color for severe traffic.
    @objc public dynamic var trafficSevereColor: UIColor = #colorLiteral(red: 0.54, green: 0.06, blue: 0.22, alpha: 1.0)
}

@_documentation(visibility: internal)
@objc(MBDistanceRemainingLabel)
open class DistanceRemainingLabel: StylableLabel {}

@_documentation(visibility: internal)
@objc(MBArrivalTimeLabel)
open class ArrivalTimeLabel: StylableLabel {}

@_documentation(visibility: internal)
public class DestinationLabel: StylableLabel {}
