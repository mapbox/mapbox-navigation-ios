import UIKit

enum ExitSide: String {
    case left, right
    
    var exitImage: UIImage {
        return self == .left ? ExitView.leftExitImage : ExitView.rightExitImage
    }
}

public class ExitView: StylableView {
    static let leftExitImage = UIImage(named: "exit-left", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    static let rightExitImage = UIImage(named: "exit-right", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
    
    static let labelFontSizeScaleFactor: CGFloat = 2.0/3.0
    
    @objc public dynamic var foregroundColor: UIColor? {
        didSet {
            layer.borderColor = foregroundColor?.cgColor
            imageView.tintColor = foregroundColor
            exitNumberLabel.textColor = foregroundColor
            setNeedsDisplay()
        }
    }
    
    var side: ExitSide = .right {
        didSet {
            populateExitImage()
            rebuildConstraints()
        }
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: self.side.exitImage)
        view.tintColor = foregroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var exitNumberLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.text = exitText
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: pointSize * ExitView.labelFontSizeScaleFactor)

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
            exitNumberLabel.font = exitNumberLabel.font.withSize(pointSize * ExitView.labelFontSizeScaleFactor)
            rebuildConstraints()
        }
    }
    
    func spacing(for side: ExitSide, direction: UIUserInterfaceLayoutDirection = UIApplication.shared.userInterfaceLayoutDirection) -> CGFloat {
        let space: (less: CGFloat, more: CGFloat) = (4.0, 6.0)
        let lessSide: ExitSide = (direction == .rightToLeft) ? .left : .right
        return side == lessSide ? space.less : space.more
    }
    
    convenience init(pointSize: CGFloat, side: ExitSide = .right, text: String) {
        self.init(frame: .zero)
        self.pointSize = pointSize
        self.side = side
        self.exitText = text
        commonInit()
    }
    
    override public init(frame: CGRect) {
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

        let children = [imageView, exitNumberLabel]
        addSubviews(children)
        buildConstraints()
        
        setNeedsLayout()
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
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
        let spacing = self.spacing(for: .right)
        let imageLabelSpacing = exitNumberLabel.trailingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -1 * spacing)
        let imageTrailing = trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8)
        return [labelLeading, imageLabelSpacing, imageTrailing]
    }
    
    func leftExitConstraints() -> [NSLayoutConstraint] {
        let imageLeading = imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        let spacing = self.spacing(for: .left)
        let imageLabelSpacing = imageView.trailingAnchor.constraint(equalTo: exitNumberLabel.leadingAnchor, constant: -1 * spacing)
        let labelTrailing = trailingAnchor.constraint(equalTo: exitNumberLabel.trailingAnchor, constant: 8)
        return [imageLeading, imageLabelSpacing, labelTrailing]
    }
    
    /**
     This generates the cache key needed to hold the `ExitView`'s `imageRepresentation` in the `ImageCache` caching engine.
     */
    static func criticalHash(side: ExitSide,
                             dataSource: DataSource,
                             traitCollection: UITraitCollection) -> String {
        var appearance = ExitView.appearance()
        if traitCollection.userInterfaceIdiom == .carPlay {
            if #available(iOS 12.0, *) {
                let carPlayTraitCollection = UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceIdiom: .carPlay),
                    UITraitCollection(userInterfaceStyle: traitCollection.userInterfaceStyle)
                ])
                
                appearance = ExitView.appearance(for: carPlayTraitCollection)
            } else {
                appearance = ExitView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay))
            }
        }
        
        var criticalProperties: [AnyHashable?] = [
            side,
            dataSource.font.pointSize,
            appearance.backgroundColor,
            appearance.foregroundColor,
            appearance.borderColor,
            appearance.borderWidth,
            appearance.cornerRadius,
            traitCollection.userInterfaceIdiom.rawValue,
        ]
        
        if #available(iOS 12.0, *) {
            criticalProperties.append(traitCollection.userInterfaceStyle.rawValue)
        }
        
        return String(describing: criticalProperties.reduce(0, { $0 ^ ($1?.hashValue ?? 0)}))
    }
}
