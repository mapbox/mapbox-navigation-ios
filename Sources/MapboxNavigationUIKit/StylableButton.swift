import UIKit

@_documentation(visibility: internal)
@objc(MBStylableButton)
open class StylableButton: UIButton {
    // Sets the font on the button’s titleLabel
    @objc open dynamic var textFont: UIFont = .systemFont(ofSize: 20, weight: .medium) {
        didSet {
            titleLabel?.font = textFont
        }
    }

    // Sets the text color for normal state
    @objc open dynamic var textColor: UIColor = .black {
        didSet {
            setTitleColor(textColor, for: .normal)
        }
    }

    // Sets the border color
    @objc open dynamic var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    // Sets the border width
    @objc open dynamic var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    // Sets the corner radius
    @objc open dynamic var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
}

/// `Button` sets the tintColor according to the style.
@_documentation(visibility: internal)
@objc(MBButton)
open class Button: StylableButton {}

@_documentation(visibility: internal)
@objc(MBCancelButton)
open class CancelButton: Button {}

@_documentation(visibility: internal)
@objc(MBDismissButton)
open class DismissButton: Button {}

@_documentation(visibility: internal)
public class BackButton: Button {}

@_documentation(visibility: internal)
public class PreviewButton: Button {}

@_documentation(visibility: internal)
public class StartButton: Button {}
