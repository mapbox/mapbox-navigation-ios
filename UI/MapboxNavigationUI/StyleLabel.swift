import UIKit

public enum TextStyle: Int {
    case primary = 1
    case secondary = 2
    case highlighted = 3
}

@IBDesignable
public class StyleLabel: UILabel {

    public var textStyle: TextStyle = .primary {
        didSet {
            switch textStyle {
            case .primary:
                textColor = NavigationUI.shared.primaryTextColor
                break
            case .secondary:
                textColor = NavigationUI.shared.secondaryTextColor
                break
            case .highlighted:
                textColor = NavigationUI.shared.tintColor
                break
            }
        }
    }
    
    @IBInspectable
    public var inspectableTextStyle: Int = 1 {
        didSet {
            textStyle = TextStyle(rawValue: inspectableTextStyle)!
        }
    }
}
