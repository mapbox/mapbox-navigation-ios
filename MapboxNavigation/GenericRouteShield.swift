import Foundation
import UIKit

public class GenericRouteShield: StylableView {
    static let labelFontSizeScaleFactor: CGFloat = 2.0/3.0
    
    @objc dynamic var foregroundColor: UIColor? {
        didSet {
            layer.borderColor = foregroundColor?.cgColor
            routeLabel.textColor = foregroundColor
            setNeedsDisplay()
        }
    }
     
    lazy var routeLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.text = routeText
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: pointSize * ExitView.labelFontSizeScaleFactor)
        
        return label
    }()
    
    var routeText: String? {
        didSet {
            routeLabel.text = routeText
            invalidateIntrinsicContentSize()
        }
    }
    var pointSize: CGFloat {
        didSet {
            routeLabel.font = routeLabel.font.withSize(pointSize * ExitView.labelFontSizeScaleFactor)
            rebuildConstraints()
        }
    }
    
    convenience init(pointSize: CGFloat, text: String) {
        self.init(frame: .zero)
        self.pointSize = pointSize
        self.routeText = text
        commonInit()
    }
    
    override init(frame: CGRect) {
        pointSize = 0.0
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        pointSize = 0.0
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func rebuildConstraints() {
        NSLayoutConstraint.deactivate(self.constraints)
        buildConstraints()
    }
    
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true
        
        //build view hierarchy
        addSubview(routeLabel)
        buildConstraints()
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }

    func buildConstraints() {
        let height = heightAnchor.constraint(equalToConstant: pointSize * 1.2)
        
        let labelCenterY = routeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        
        let labelLeading = routeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        let labelTrailingSpacing = routeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        
        let constraints = [height, labelCenterY, labelLeading, labelTrailingSpacing]
        
        addConstraints(constraints)
    }
}
