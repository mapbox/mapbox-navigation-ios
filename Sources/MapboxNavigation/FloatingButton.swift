import UIKit

/**
 A rounded button with an icon that is designed to float above `NavigationMapView`.
 */
@objc(MBFloatingButton)
open class FloatingButton: Button {
    
    /**
     The default size of a floating button.
     */
    public static let buttonSize = CGSize(width: 50, height: 50)
    
    // Don't fight with the stack view (superview) when it tries to hide buttons.
    static let sizeConstraintPriority = UILayoutPriority(999.0)
    
    lazy var widthConstraint: NSLayoutConstraint = {
        let constraint = self.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width)
        constraint.priority = FloatingButton.sizeConstraintPriority
        return constraint
    }()
    
    lazy var heightConstraint: NSLayoutConstraint = {
        let constraint = self.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height)
        constraint.priority = FloatingButton.sizeConstraintPriority
        return constraint
    }()
        
    var constrainedSize: CGSize? {
        didSet {
            guard let size = constrainedSize else {
                NSLayoutConstraint.deactivate([widthConstraint, heightConstraint])
                return
            }
            widthConstraint.constant = size.width
            heightConstraint.constant = size.height
            NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        }
    }
    
    /**
     Return a `FloatingButton` with given images and size.
     
     - parameter image: The `UIImage` of this button.
     - parameter selectedImage: The `UIImage` of this button when selected.
     - parameter size: The size of this button,  or `FloatingButton.buttonSize` if this argument is not specified.
     - parameter type: `UIButton` type. Defaults to `.custom`.
     - parameter cornerRadius: Corner radius of the button.
     - parameter imageEdgeInsets: Effective drawing rectangle for the button image.
     
     - returns: `FloatingButton` instance.
     */
    public class func rounded<T: FloatingButton>(image: UIImage? = nil,
                                                 selectedImage: UIImage? = nil,
                                                 size: CGSize = FloatingButton.buttonSize,
                                                 type: UIButton.ButtonType = .custom,
                                                 imageEdgeInsets: UIEdgeInsets = .zero,
                                                 cornerRadius: CGFloat = FloatingButton.buttonSize.width / 2.0) -> T {
        let button = T.init(type: type)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.constrainedSize = size
        button.layer.cornerRadius = cornerRadius
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = imageEdgeInsets
        
        if let image = image {
            button.setImage(image, for: .normal)
        }
        
        if let selectedImage = selectedImage {
            button.setImage(selectedImage, for: .selected)
        }
        
        return button
    }
}
