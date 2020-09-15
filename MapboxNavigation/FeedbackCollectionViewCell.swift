import Foundation
import UIKit

class FeedbackCollectionViewCell: UICollectionViewCell {
    static let defaultIdentifier = "MapboxFeedbackCell"
    
    struct Constants {
        static let circleSize: CGSize = 70.0
        static let imageSize: CGSize = 36.0
        static let padding: CGFloat = 8
        static let verticalPadding: CGFloat = 32.0
        static let titleFont: UIFont = .systemFont(ofSize: 18.0)
    }

    lazy var circleView: UIView = .forAutoLayout()
    lazy var imageView: UIImageView = .forAutoLayout()
    
    lazy var titleLabel: UILabel = {
        let title: UILabel = .forAutoLayout()
        title.numberOfLines = 2
        title.adjustsFontSizeToFitWidth = true
        title.textAlignment = .center
        title.font = Constants.titleFont
        return title
    }()

    public var circleColor: UIColor = .black {
        didSet {
            circleView.backgroundColor = circleColor
        }
    }
    
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
        circleColor = .black
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
                    guard let originalTransform = self.originalTransform else { return }
                    self.imageView.transform = originalTransform
                }
            }, completion: nil)
        }
    }
    
    func setupViews() {
        addSubview(circleView)
        addSubview(imageView)
        addSubview(titleLabel)

        circleView.layer.cornerRadius = Constants.circleSize.height / 2
    }
    
    func setupConstraints() {
        circleView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        circleView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: Constants.circleSize.height).isActive = true
        circleView.widthAnchor.constraint(equalToConstant: Constants.circleSize.width).isActive = true

        imageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: Constants.padding).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding).isActive = true
    }
}
