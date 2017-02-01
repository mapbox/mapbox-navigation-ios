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
                textColor = .primaryText
                break
            case .secondary:
                textColor = .secondaryText
                break
            case .highlighted:
                textColor = .defaultTint
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
