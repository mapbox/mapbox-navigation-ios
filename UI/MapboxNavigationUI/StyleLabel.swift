import UIKit

enum TextStyle: Int {
    case primary = 1
    case secondary = 2
    case highlighted = 3
}

@IBDesignable
class StyleLabel: UILabel {

    var textStyle: TextStyle = .primary {
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
    var inspectableTextStyle: Int = 1 {
        didSet {
            textStyle = TextStyle(rawValue: inspectableTextStyle)!
        }
    }
}
