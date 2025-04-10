import MapboxMaps
import UIKit

final class RouteCalloutView: UIView {
    private let contentVStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: []).autoresizing()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = captionLabelVerticalPadding
        return stackView
    }()

    private let rowHStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: []).autoresizing()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = iconViewHorizontalPadding
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()

    private let label = {
        let label = UILabel().autoresizing()
        label.textAlignment = .left
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private var captionLabel = {
        let captionLabel = UILabel().autoresizing()
        captionLabel.textAlignment = .left
        captionLabel.setContentHuggingPriority(.required, for: .horizontal)
        captionLabel.setContentHuggingPriority(.required, for: .vertical)
        captionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        captionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return captionLabel
    }()

    private var iconView: UIImageView? {
        didSet {
            guard let iconView, oldValue != iconView else { return }

            iconView.setContentHuggingPriority(.required, for: .horizontal)
            iconView.setContentHuggingPriority(.required, for: .vertical)
            iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
            iconView.setContentCompressionResistancePriority(.required, for: .vertical)

            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: tollIconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: tollIconSize.height),
            ])
        }
    }

    private var tollImage: UIImage? {
        UIImage(named: "icon_toll", in: .module, with: nil)
    }

    private let backgroundShapeLayer = CAShapeLayer()

    let mapStyleConfig: MapStyleConfig
    private let textColor: UIColor
    private let baloonColor: UIColor
    private let contentPadding = UIEdgeInsets(top: 6.0, left: 10.0, bottom: 6.0, right: 10.0)
    private let tollIconSize: CGSize = .init(width: 18.0, height: 18.0)
    private let tailPadding = UIEdgeInsets(allEdges: tailSize)
    private static let cornerRadius: CGFloat = 10.0
    private static let tailSize: CGFloat = 7.0
    private static let captionLabelVerticalPadding: CGFloat = 2.0
    private static let iconViewHorizontalPadding: CGFloat = 4.0

    private var text: String {
        didSet {
            guard oldValue != text else { return }
            label.text = text
            NSLayoutConstraint.activate([
                label.widthAnchor.constraint(equalToConstant: label.textSize.width),
                label.heightAnchor.constraint(equalToConstant: label.textSize.height),
            ])
            setNeedsLayout()
        }
    }

    private var captionText: String? {
        didSet {
            guard oldValue != captionText else { return }
            captionLabel.text = captionText
            let constraints = [
                captionLabel.widthAnchor.constraint(equalToConstant: captionLabel.textSize.width),
                captionLabel.heightAnchor.constraint(equalToConstant: captionLabel.textSize.height),
            ]
            if hasCaption {
                NSLayoutConstraint.activate(constraints)
            } else {
                NSLayoutConstraint.deactivate(constraints)
            }
            configureStacks()
            setNeedsLayout()
        }
    }

    private var containsTolls: Bool {
        didSet {
            guard oldValue != containsTolls else { return }

            if containsTolls, iconView == nil {
                iconView = UIImageView(image: tollImage).autoresizing()

            } else if iconView != nil, !containsTolls {
                iconView = nil
            }
            configureStacks()
            setNeedsLayout()
        }
    }

    var anchor: ViewAnnotationAnchor? {
        didSet { setNeedsLayout() }
    }

    convenience init(
        eta: TimeInterval,
        captionText: String? = nil,
        isSelected: Bool,
        containsTolls: Bool,
        mapStyleConfig: MapStyleConfig
    ) {
        let calloutText = DateComponentsFormatter.travelTimeString(eta, signed: false)

        let textColor: UIColor
        let baloonColor: UIColor
        if isSelected {
            textColor = mapStyleConfig.routeAnnotationSelectedTextColor
            baloonColor = mapStyleConfig.routeAnnotationSelectedColor
        } else {
            textColor = mapStyleConfig.routeAnnotationTextColor
            baloonColor = mapStyleConfig.routeAnnotationColor
        }

        self.init(
            text: calloutText,
            captionText: captionText,
            containsTolls: containsTolls,
            mapStyleConfig: mapStyleConfig,
            textColor: textColor,
            baloonColor: baloonColor
        )
    }

    convenience init(
        text: String,
        captionText: String? = nil,
        isSelected: Bool,
        containsTolls: Bool,
        mapStyleConfig: MapStyleConfig
    ) {
        let textColor: UIColor
        let baloonColor: UIColor
        if isSelected {
            textColor = mapStyleConfig.routeAnnotationSelectedTextColor
            baloonColor = mapStyleConfig.routeAnnotationSelectedColor
        } else {
            textColor = mapStyleConfig.routeAnnotationTextColor
            baloonColor = mapStyleConfig.routeAnnotationColor
        }

        self.init(
            text: text,
            captionText: captionText,
            containsTolls: containsTolls,
            mapStyleConfig: mapStyleConfig,
            textColor: textColor,
            baloonColor: baloonColor
        )
    }

    init(
        text: String,
        captionText: String? = nil,
        containsTolls: Bool,
        mapStyleConfig: MapStyleConfig,
        textColor: UIColor,
        baloonColor: UIColor
    ) {
        self.text = text
        self.captionText = captionText
        self.textColor = textColor
        self.baloonColor = baloonColor
        self.mapStyleConfig = mapStyleConfig
        self.containsTolls = containsTolls
        super.init(frame: .zero)

        label.text = text
        label.font = mapStyleConfig.routeAnnotationTextFont
        label.textColor = textColor
        captionLabel.text = captionText
        captionLabel.font = mapStyleConfig.routeAnnnotationCaptionTextFont
        captionLabel.textColor = textColor

        layer.addSublayer(backgroundShapeLayer)
        backgroundShapeLayer.shadowRadius = Self.cornerRadius
        backgroundShapeLayer.shadowOffset = CGSize(width: 0, height: 4.0)
        backgroundShapeLayer.shadowColor = UIColor(white: 0.0, alpha: 0.12).cgColor
        backgroundShapeLayer.shadowOpacity = 1.0
        backgroundShapeLayer.fillColor = baloonColor.cgColor

        addSubview(contentVStack)

        if containsTolls {
            self.iconView = UIImageView(image: tollImage).autoresizing()
        }

        setupPersistentConstraints()
        initSizeConstraints() // required becaause didSet observers are not called in init
        configureStacks()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPersistentConstraints() {
        let totalPadding = contentPadding + tailPadding
        NSLayoutConstraint.activate([
            contentVStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: totalPadding.left),
            contentVStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -totalPadding.right),
            contentVStack.topAnchor.constraint(equalTo: topAnchor, constant: totalPadding.top),
            contentVStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -totalPadding.bottom),
        ])
    }

    func initSizeConstraints() {
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: label.textSize.width),
            label.heightAnchor.constraint(equalToConstant: label.textSize.height),
        ])

        switch layoutType {
        case .mainLabelOnly:
            break
        case .mainLabelToll:
            guard let iconView else { break }
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: tollIconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: tollIconSize.height),
            ])

            iconView.setContentHuggingPriority(.required, for: .horizontal)
            iconView.setContentHuggingPriority(.required, for: .vertical)
            iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
            iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        case .mainLabelCaption:
            NSLayoutConstraint.activate([
                captionLabel.widthAnchor.constraint(equalToConstant: captionLabel.textSize.width),
                captionLabel.heightAnchor.constraint(equalToConstant: captionLabel.textSize.height),

            ])
        case .mainLabelCaptionToll:
            NSLayoutConstraint.activate([
                captionLabel.widthAnchor.constraint(equalToConstant: captionLabel.textSize.width),
                captionLabel.heightAnchor.constraint(equalToConstant: captionLabel.textSize.height),
            ])

            guard let iconView else { break }
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: tollIconSize.width),
                iconView.heightAnchor.constraint(equalToConstant: tollIconSize.height),
            ])

            iconView.setContentHuggingPriority(.required, for: .horizontal)
            iconView.setContentHuggingPriority(.required, for: .vertical)
            iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
            iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    override var intrinsicContentSize: CGSize {
        contentVStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) + contentPadding + tailPadding
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    func configureStacks() {
        rowHStack.arrangedSubviews.forEach(rowHStack.removeArrangedSubview)
        contentVStack.arrangedSubviews.forEach(contentVStack.removeArrangedSubview)

        switch layoutType {
        case .mainLabelOnly:
            contentVStack.addArrangedSubview(label)

        case .mainLabelToll:
            rowHStack.addArrangedSubview(label)
            rowHStack.addArrangedSubview(iconView ?? UIView())
            contentVStack.addArrangedSubview(rowHStack)

        case .mainLabelCaption:
            contentVStack.addArrangedSubview(label)
            contentVStack.addArrangedSubview(captionLabel)

        case .mainLabelCaptionToll:
            contentVStack.addArrangedSubview(label)
            rowHStack.addArrangedSubview(captionLabel)
            rowHStack.addArrangedSubview(iconView ?? UIView())
            contentVStack.addArrangedSubview(rowHStack)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let calloutPath = UIBezierPath.calloutPath(
            size: bounds.size,
            tailSize: Self.tailSize,
            cornerRadius: Self.cornerRadius,
            anchor: anchor ?? .center
        )
        backgroundShapeLayer.path = calloutPath.cgPath
        backgroundShapeLayer.frame = bounds
    }
}

extension RouteCalloutView {
    private var hasCaption: Bool {
        captionText?.isEmpty == false
    }

    private enum LayoutType {
        case mainLabelOnly
        case mainLabelToll
        case mainLabelCaption
        case mainLabelCaptionToll
    }

    private var layoutType: LayoutType {
        switch (hasCaption, containsTolls) {
        case (false, false):
            return .mainLabelOnly
        case (false, true):
            return .mainLabelToll
        case (true, false):
            return .mainLabelCaption
        case (true, true):
            return .mainLabelCaptionToll
        }
    }
}

extension UIEdgeInsets {
    fileprivate init(allEdges value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }
}

extension String {
    fileprivate func size(withFont font: UIFont) -> CGSize {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        // swiftformat:disable:next redundantSelf
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return boundingBox.size.roundedUp()
    }
}

extension UILabel {
    fileprivate var textSize: CGSize {
        return text?.size(withFont: font) ?? CGSize.zero
    }
}

extension CGSize {
    fileprivate func roundedUp() -> CGSize {
        CGSize(width: width.rounded(.up), height: height.rounded(.up))
    }
}

extension CGSize {
    private func addHeightAndMaximizeWidth(
        _ operand: CGSize,
        withVerticalPadding verticalPadding: CGFloat = 0
    ) -> CGSize {
        CGSize(width: max(width, operand.width), height: height + operand.height + verticalPadding)
    }

    private func addWidthAndMaximizeHeight(
        _ operand: CGSize,
        withHorizontalPadding horizontalPadding: CGFloat = 0
    ) -> CGSize {
        CGSize(width: width + operand.width + horizontalPadding, height: max(height, operand.height))
    }
}

private func + (lhs: CGSize, rhs: UIEdgeInsets) -> CGSize {
    return CGSize(width: lhs.width + rhs.left + rhs.right, height: lhs.height + rhs.top + rhs.bottom)
}

private func - (lhs: CGSize, rhs: UIEdgeInsets) -> CGSize {
    return CGSize(width: lhs.width - rhs.left - rhs.right, height: lhs.height - rhs.top - rhs.bottom)
}

extension UIBezierPath {
    fileprivate static func calloutPath(
        size: CGSize,
        tailSize: CGFloat,
        cornerRadius: CGFloat,
        anchor: ViewAnnotationAnchor
    ) -> UIBezierPath {
        let rect = CGRect(origin: .init(x: 0, y: 0), size: size)
        let bubbleRect = rect.insetBy(dx: tailSize, dy: tailSize)

        let path = UIBezierPath(
            roundedRect: bubbleRect,
            cornerRadius: cornerRadius
        )

        let tailPath = UIBezierPath()
        let p = tailSize
        let h = size.height
        let w = size.width
        let r = cornerRadius
        let tailPoints: [CGPoint] = switch anchor {
        case .topLeft:
            [CGPoint(x: 0, y: 0), CGPoint(x: p + r, y: p), CGPoint(x: p, y: p + r)]
        case .top:
            [CGPoint(x: w / 2, y: 0), CGPoint(x: w / 2 - p, y: p), CGPoint(x: w / 2 + p, y: p)]
        case .topRight:
            [CGPoint(x: w, y: 0), CGPoint(x: w - p, y: p + r), CGPoint(x: w - 3 * p, y: p)]
        case .bottomLeft:
            [CGPoint(x: 0, y: h), CGPoint(x: p, y: h - (p + r)), CGPoint(x: p + r, y: h - p)]
        case .bottom:
            [CGPoint(x: w / 2, y: h), CGPoint(x: w / 2 - p, y: h - p), CGPoint(x: w / 2 + p, y: h - p)]
        case .bottomRight:
            [CGPoint(x: w, y: h), CGPoint(x: w - (p + r), y: h - p), CGPoint(x: w - p, y: h - (p + r))]
        case .left:
            [CGPoint(x: 0, y: h / 2), CGPoint(x: p, y: h / 2 - p), CGPoint(x: p, y: h / 2 + p)]
        case .right:
            [CGPoint(x: w, y: h / 2), CGPoint(x: w - p, y: h / 2 - p), CGPoint(x: w - p, y: h / 2 + p)]
        default:
            []
        }

        for (i, point) in tailPoints.enumerated() {
            if i == 0 {
                tailPath.move(to: point)
            } else {
                tailPath.addLine(to: point)
            }
        }
        tailPath.close()
        path.append(tailPath)
        return path
    }
}
