import UIKit

/// :nodoc:
@IBDesignable
@objc(MBResumeButton)
public class ResumeButton: UIControl {
    
    public override dynamic var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
            titleLabel.textColor = tintColor
        }
    }
    
    let imageView = UIImageView(image: UIImage(named: "location", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate))
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
