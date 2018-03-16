import Foundation
import UIKit


class FeedbackCollectionViewCell: UICollectionViewCell {
    static let defaultIdentifier = "MapboxFeedbackCell"
    
    struct Constants {
        static let imageSize: CGSize = 70.0
        static let circleLabelSpacing: CGFloat = 8.0
    }
    
    lazy var imageView: UIImageView = .forAutoLayout()
    
    lazy var titleLabel: UILabel = {
        let title: UILabel = .forAutoLayout()
        title.numberOfLines = 2
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 18.0)
        return title
    }()
    lazy var circleView: UIView = {
        let circle: UIView = .forAutoLayout()
        circle.layer.cornerRadius = circle.bounds.midY
        return circle
    }()
 
    
    var longPress: UILongPressGestureRecognizer?
    var originalTransform: CGAffineTransform?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupViews()
        setupConstraints()
    }
    
    override var isHighlighted: Bool {
        didSet {
            if originalTransform == nil {
                originalTransform = self.imageView.transform
            }
            
            UIView.defaultSpringAnimation(0.3, animations: {
                if self.isHighlighted {
                    self.imageView.transform = self.imageView.transform.scaledBy(x: 0.85, y: 0.85)
                } else {
                    guard let t = self.originalTransform else { return }
                    self.imageView.transform = t
                }
            }, completion: nil)
        }
    }
    
    func setupViews() {
        circleView.addSubview(imageView)
        [circleView, titleLabel].forEach(contentView.addSubview(_:))
    }
    
    func setupConstraints() {
        let content = contentView
        let image = imageView
        let circle = circleView
        let title = titleLabel
        
        let circleWidth = circle.widthAnchor.constraint(equalToConstant: Constants.imageSize.width)
        let circleHeight = circle.heightAnchor.constraint(equalToConstant: Constants.imageSize.height)
        let circleTop = circle.topAnchor.constraint(equalTo: content.layoutMarginsGuide.topAnchor)
        let circleCenterX = circle.centerXAnchor.constraint(equalTo: content.centerXAnchor)
        let imageCenterX = image.centerXAnchor.constraint(equalTo: circle.centerXAnchor)
        let imageCenterY = image.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
        let titleTop = title.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: Constants.circleLabelSpacing)
        let titleCenterX = title.centerXAnchor.constraint(equalTo: content.centerXAnchor)
        let titleLeading = title.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor)
        let titleTrailing = content.trailingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor)
        
        let constraints = [circleWidth, circleHeight,
                           circleTop, circleCenterX,
                           imageCenterX, imageCenterY,
                           titleTop, titleCenterX,
                           titleLeading, titleTrailing]
        
        NSLayoutConstraint.activate(constraints)
    }
}
