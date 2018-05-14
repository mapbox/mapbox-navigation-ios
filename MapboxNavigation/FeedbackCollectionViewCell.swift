import Foundation
import UIKit


class FeedbackCollectionViewCell: UICollectionViewCell {
    static let defaultIdentifier = "MapboxFeedbackCell"
    
    struct Constants {
        static let imageSize: CGSize = 70.0
        static let padding: CGFloat = 8
        static let titleFont: UIFont = .systemFont(ofSize: 18.0)
    }
    
    lazy var imageView: UIImageView = .forAutoLayout()
    
    lazy var titleLabel: UILabel = {
        let title: UILabel = .forAutoLayout()
        title.numberOfLines = 2
        title.textAlignment = .center
        title.font = Constants.titleFont
        return title
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
        addSubview(imageView)
        addSubview(titleLabel)
    }
    
    func setupConstraints() {
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding).isActive = true
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: Constants.imageSize.height).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: Constants.imageSize.width).isActive = true
        
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Constants.padding).isActive = true
    }
}
