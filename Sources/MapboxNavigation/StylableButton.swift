import UIKit

// :nodoc:
@objc(MBStylableButton)
open class StylableButton: UIButton {
    
    // Sets the font on the button’s titleLabel
    @objc dynamic open var textFont: UIFont = UIFont.systemFont(ofSize: 20, weight: .medium) {
        didSet {
            titleLabel?.font = textFont
        }
    }
    
    // Sets the text color for normal state
    @objc dynamic open var textColor: UIColor = .black {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }
    
    // Sets the border color
    @objc dynamic open var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    // Sets the border width
    @objc dynamic open var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    // Sets the corner radius
    @objc dynamic open var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
}

/**
 :nodoc:
 `Button` sets the tintColor according to the style.
 */
@objc(MBButton)
open class Button: StylableButton {
    
}

// :nodoc:
@objc(MBCancelButton)
open class CancelButton: Button {
    
}

// :nodoc:
@objc(MBDismissButton)
open class DismissButton: Button {
    
}

// :nodoc:
public class BackButton: Button {
    
}

// :nodoc:
public class PreviewButton: Button {
    
}

// :nodoc:
public class StartButton: Button {
    
}
