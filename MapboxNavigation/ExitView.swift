import UIKit

enum ExitSide: String{
    case left, right, other
    
    var exitImage: UIImage {
        return self == .left ? ExitView.leftExitImage : ExitView.rightExitImage
    }
}

class ExitView: UIView {
    static let leftExitImage = UIImage(named: "exit-left", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    static let rightExitImage = UIImage(named: "exit-right", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    
    var side: ExitSide = .right {
        didSet {
            populateExitImage()
            rebuildConstraints()
        }
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: self.side.exitImage)
        view.tintColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var exitNumberLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.text = exitText
        label.textColor = .black
        print("system font size! \(UIFont.systemFontSize)")
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()

    var exitText: String? {
        didSet {
            exitNumberLabel.text = exitText
            invalidateIntrinsicContentSize()
        }
    }
    var pointSize: CGFloat {
        didSet {
            rebuildConstraints()
        }
    }
    
    convenience init(pointSize: CGFloat, side: ExitSide = .right, text: String) {
        self.init(frame: .zero)
        self.pointSize = pointSize
        self.side = side
        self.exitText = text
        commonInit()
    }
    
    override init(frame: CGRect) {
        pointSize = 0.0
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        pointSize = 0.0
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func rebuildConstraints() {
        NSLayoutConstraint.deactivate(self.constraints)
        buildConstraints()
    }
    
    func commonInit() {
        backgroundColor = .clear
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.black.cgColor
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        setupViews()
        buildConstraints()
    }
    func setupViews() {
        [imageView, exitNumberLabel].forEach(addSubview(_:))
    }
    
    func populateExitImage() {
        imageView.image = self.side.exitImage
    }
    
    func buildConstraints() {
        let height = heightAnchor.constraint(equalToConstant: pointSize * 1.2)

        let imageHeight = imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.4)
        let imageAspect = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: imageView.image?.size.aspectRatio ?? 1.0)

        let imageCenterY = imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        let labelCenterY = exitNumberLabel.centerYAnchor.constraint(equalTo: centerYAnchor)

        let sideConstraints = self.side != .left ? rightExitConstraints() : leftExitConstraints()
        
        let constraints = [height, imageHeight, imageAspect,
                           imageCenterY, labelCenterY] + sideConstraints
        
        addConstraints(constraints)
    }
    func rightExitConstraints() -> [NSLayoutConstraint] {
        let labelLeading = exitNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        let imageLabelSpacing = exitNumberLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -8)
        let imageTrailing = trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8)
        return [labelLeading, imageLabelSpacing, imageTrailing]
    }
    
    func leftExitConstraints() -> [NSLayoutConstraint] {
        let imageLeading = imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        let imageLabelSpacing = imageView.trailingAnchor.constraint(equalTo: exitNumberLabel.leadingAnchor, constant: -8)
        let labelTrailing = trailingAnchor.constraint(equalTo: exitNumberLabel.trailingAnchor, constant: 8)
        return [imageLeading, imageLabelSpacing, labelTrailing]
    }
}
