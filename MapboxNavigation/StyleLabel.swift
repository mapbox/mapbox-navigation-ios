import UIKit

public enum TextStyle: Int {
    case primary = 1
    case secondary = 2
    case highlighted = 3
}

@IBDesignable
@objc(MBStyleLabel)
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
    
    @IBInspectable var topInset: CGFloat = 0.0
    @IBInspectable var leftInset: CGFloat = 0.0
    @IBInspectable var bottomInset: CGFloat = 0.0
    @IBInspectable var rightInset: CGFloat = 0.0
    
    var insets: UIEdgeInsets {
        get {
            return UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)
        }
        set {
            topInset = newValue.top
            leftInset = newValue.left
            bottomInset = newValue.bottom
            rightInset = newValue.right
        }
    }
    
    override public func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += leftInset + rightInset
        adjSize.height += topInset + bottomInset
        
        return adjSize
    }
    
    override public var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += leftInset + rightInset
        contentSize.height += topInset + bottomInset
        
        return contentSize
    }
}
