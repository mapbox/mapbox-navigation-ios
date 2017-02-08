import UIKit

@IBDesignable
class StyleButton: UIButton {
    
    @IBInspectable
    var defaultTint: Bool = false {
        didSet {
            if defaultTint {
                backgroundColor = NavigationUI.shared.tintColor
            }
        }
    }
    
    var whiteButton: Bool = false {
        didSet {
            if whiteButton {
                backgroundColor = UIColor.white
                self.setTitleColor(NavigationUI.shared.tintColor, for: .normal)
                self.tintColor = NavigationUI.shared.tintColor
            }
        }
    }
    
    var hasBorder: Bool = false {
        didSet {
            if hasBorder {
                self.layer.borderWidth = 1
                self.layer.borderColor = NavigationUI.shared.tintColor.cgColor
            }
        }
    }
    
    var hasShadow: Bool = false {
        didSet {
            if hasShadow {
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 0)
                self.layer.shadowRadius = 10
                self.layer.shadowOpacity = 0.8
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 6
    }
}
