import UIKit

/// :nodoc:
@IBDesignable
@objc(MBResumeButton)
public class ResumeButton: UIControl {
    
    /**
     The tint color of the `ResumeButton`'s icon and title.
     */
    public override dynamic var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
            titleLabel.textColor = tintColor
        }
    }
    
    /**
     The width of the `ResumeButton`'s border.
     */
    @objc public dynamic var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    /**
     The radius of the `ResumeButton`'s corner.
     */
    @objc public dynamic var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    /**
     The color of the `ResumeButton`'s border.
     */
    @objc public dynamic var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    let imageView = UIImageView(image: .locationImage)
    let titleLabel = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }
    
    func commonInit() {
        titleLabel.text = NSLocalizedString("RESUME", bundle: .mapboxNavigation, value: "Resume", comment: "Button title for resume tracking")
        titleLabel.sizeToFit()
        addSubview(imageView)
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["label": titleLabel, "imageView": imageView]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[imageView]-8-[label]-8-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|->=12-[imageView]->=12-|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|->=12-[label]->=12-|", options: [], metrics: nil, views: views))
        setNeedsUpdateConstraints()
    }
}
