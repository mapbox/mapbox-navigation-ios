import UIKit

class FeedbackSubtypeCollectionViewCell: UICollectionViewCell {
    static let defaultIdentifier = "MapboxFeedbackSubtypeCell"

    struct Constants {
        static let circleSize: CGSize = 36.0
        static let imageSize: CGSize = 36.0
        static let padding: CGFloat = 30
        static let titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold)
    }

    lazy var circleView: UIView = .forAutoLayout()

    lazy var separatorView: UIView = .forAutoLayout()

    lazy var titleLabel: UILabel = {
        let title: UILabel = .forAutoLayout()
        title.numberOfLines = 2
        title.font = Constants.titleFont
        return title
    }()

    public var circleColor: UIColor = .black {
        didSet {
            circleView.backgroundColor = circleColor
        }
    }

    public var circleOutlineColor: UIColor = .black {
        didSet {
            circleView.layer.borderColor = circleOutlineColor.cgColor
        }
    }

    public var separatorColor: UIColor = .lightGray {
        didSet {
            separatorView.backgroundColor = separatorColor
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
    }

    override var isHighlighted: Bool {
        didSet {
            if originalTransform == nil {
                originalTransform = self.circleView.transform
            }

            UIView.defaultSpringAnimation(0.3, animations: {
                if self.isHighlighted {
                    self.circleView.transform = self.circleView.transform.scaledBy(x: 0.85, y: 0.85)
                } else {
                    guard let originalTransform = self.originalTransform else { return }
                    self.circleView.transform = originalTransform
                }
            }, completion: nil)
        }
    }

    func setupViews() {
        addSubview(circleView)
        addSubview(titleLabel)
        addSubview(separatorView)

        if #available(iOS 13.0, *) {
            circleColor = .systemBackground
            circleOutlineColor = .label
        } else {
            circleColor = .white
            circleOutlineColor = .darkText
        }
        circleView.layer.cornerRadius = Constants.circleSize.height / 2
        circleView.layer.borderWidth = 1
    }

    func setupConstraints() {
        circleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding).isActive = true
        circleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: Constants.circleSize.height).isActive = true
        circleView.widthAnchor.constraint(equalToConstant: Constants.circleSize.width).isActive = true

        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: circleView.trailingAnchor, constant: Constants.padding).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Constants.padding).isActive = true

        separatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 12.0, *),
           previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            circleView.layer.borderColor = circleOutlineColor.cgColor
        }
    }
}
