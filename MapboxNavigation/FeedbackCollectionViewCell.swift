import Foundation
import UIKit


class FeedbackCollectionViewCell: UICollectionViewCell {
    static let defaultIdentifier = "MapboxFeedbackCell"
    
    struct Constants {
        static let imageSize: CGSize = 70.0
        static let circleLabelSpacing: CGFloat = 8.0
    }
    
    lazy var imageView: UIImageView = {
        let view: UIImageView = .forAutoLayout()
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let title: UILabel = .forAutoLayout()
        title.numberOfLines = 2
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 18.0)
        return title
    }()
    lazy var circleView: UIView = .forAutoLayout()
    
    lazy var circleViewWidthConstraint = {
        return circleView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width)
    }()
    
    lazy var circleViewHeightConstraint = {
        return circleView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height)
    }()
    
    lazy var circleViewTopConstraint: NSLayoutConstraint = {
        return circleView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor)
    }()
    
    lazy var circleViewCenterConstraint: NSLayoutConstraint = {
        return circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
    }()
    
    lazy var imageViewCenterXConstraint: NSLayoutConstraint = {
        return imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor)
    }()
    
    lazy var imageViewCenterYConstraint: NSLayoutConstraint = {
        return imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
    }()
    
    lazy var titleLabelTopConstraint: NSLayoutConstraint = {
       return titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: Constants.circleLabelSpacing)
    }()
    
    lazy var titleLabelCenterConstraint: NSLayoutConstraint = {
        return titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
    }()
    
    lazy var titleLabelLeadingConstraint: NSLayoutConstraint = {
        return titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor)
    }()
    
    lazy var titleLabelTrailingConstraint: NSLayoutConstraint = {
        return trailingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.midY
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
        let constraints = [circleViewWidthConstraint,
                           circleViewHeightConstraint,
                           circleViewTopConstraint,
                           circleViewCenterConstraint,
                           imageViewCenterXConstraint,
                           imageViewCenterYConstraint,
                           titleLabelTopConstraint,
                           titleLabelCenterConstraint,
                           titleLabelLeadingConstraint,
                           titleLabelTrailingConstraint]
        NSLayoutConstraint.activate(constraints)
    }
}
