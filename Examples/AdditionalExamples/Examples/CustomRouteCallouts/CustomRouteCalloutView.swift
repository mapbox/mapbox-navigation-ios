import MapboxMaps
import UIKit

final class CustomRouteCalloutView: UIView {
    private let contentHStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: []).autoresizing()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = iconViewHorizontalPadding
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
        UIImage(systemName: "dollarsign.circle.fill")
    }

    private let mainCalloutShapeLayer = CAShapeLayer()
    private let calloutTailShapeLayer = CAShapeLayer()

    private let textColor: UIColor
    private let outlineColor: UIColor
    private let contentPadding = UIEdgeInsets(top: 6.0, left: 10.0, bottom: 6.0, right: 10.0)
    private let tollIconSize: CGSize = .init(width: 18.0, height: 18.0)
    private static let cornerRadius: CGFloat = 3.0
    static let tailLineLength: CGFloat = 14.0
    static let tailAnchorCircleRadius: CGFloat = 3.0
    private static let tailPaddingValue: CGFloat = tailLineLength + 2 * tailAnchorCircleRadius
    static let cornerTailHorizontalOffset: CGFloat = 12.0
    private static let iconViewHorizontalPadding: CGFloat = 4.0

    private var contentHStackLeadingConstraint: NSLayoutConstraint?
    private var contentHStackTrailingConstraint: NSLayoutConstraint?
    private var contentHStackTopConstraint: NSLayoutConstraint?
    private var contentHStackBottomConstraint: NSLayoutConstraint?

    private static var calloutTextFont: UIFont = .systemFont(ofSize: 18, weight: .semibold)
    private static var calloutSelectedOutlineColor: UIColor = #colorLiteral(red: 0.01960784314, green: 0.02745098039, blue: 0.03921568627, alpha: 1)
    private static var calloutOutlineColor: UIColor = #colorLiteral(red: 0.01960784314, green: 0.02745098039, blue: 0.03921568627, alpha: 1)
    private static var calloutSelectedTextColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private static var calloutNotSelectedTextColor: UIColor = #colorLiteral(red: 0.4121863544, green: 0.4459083676, blue: 0.494659543, alpha: 1)
    private static var calloutSelectedBackgroundColor: UIColor = #colorLiteral(red: 0.1882352941, green: 0.4470588235, blue: 0.9607843137, alpha: 1)
    private static var calloutNotSelectedBackgroundColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private static var calloutRelativeFasterTextColor: UIColor = #colorLiteral(red: 0, green: 0.417086184, blue: 0, alpha: 1)
    private static var calloutRelativeSlowerTextColor: UIColor = #colorLiteral(red: 0.5471024513, green: 0, blue: 0.01493015699, alpha: 1)

    private var text: String {
        didSet {
            guard oldValue != text else { return }
            label.text = text
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
            configureStack()
            setNeedsLayout()
        }
    }

    /// Change of this property triggers layout update, so that correct anchor is rendered.
    var anchor: ViewAnnotationAnchor? {
        didSet {
            guard oldValue != anchor else { return }
            updateContentPaddingConstraints()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    convenience init(
        text: String,
        isSelected: Bool,
        containsTolls: Bool,
        isRelative: Bool = false,
        isFaster: Bool = false
    ) {
        var textColor: UIColor
        let outlineColor: UIColor
        if isSelected {
            textColor = Self.calloutSelectedTextColor
            outlineColor = Self.calloutSelectedOutlineColor
        } else {
            textColor = Self.calloutNotSelectedTextColor
            outlineColor = Self.calloutOutlineColor
        }

        if isRelative {
            textColor =
                isFaster ? Self.calloutRelativeFasterTextColor : Self.calloutRelativeSlowerTextColor
        }

        self.init(
            text: text,
            containsTolls: containsTolls,
            textColor: textColor,
            outlineColor: outlineColor,
            baloonColor: isSelected ?
                Self.calloutSelectedBackgroundColor : Self.calloutNotSelectedBackgroundColor
        )
    }

    convenience init(
        eta: TimeInterval,
        captionText: String? = nil,
        isSelected: Bool,
        containsTolls: Bool
    ) {
        let calloutText = DateComponentsFormatter.travelTimeString(eta, signed: false)

        let textColor: UIColor
        let outlineColor: UIColor
        if isSelected {
            textColor = Self.calloutSelectedTextColor
            outlineColor = Self.calloutSelectedOutlineColor
        } else {
            textColor = Self.calloutNotSelectedTextColor
            outlineColor = Self.calloutOutlineColor
        }

        self.init(
            text: calloutText,
            containsTolls: containsTolls,
            textColor: textColor,
            outlineColor: outlineColor,
            baloonColor: isSelected ?
                Self.calloutSelectedBackgroundColor : Self.calloutNotSelectedBackgroundColor
        )
    }

    init(
        text: String,
        containsTolls: Bool,
        textColor: UIColor,
        outlineColor: UIColor,
        baloonColor: UIColor
    ) {
        self.text = text
        self.textColor = textColor
        self.outlineColor = outlineColor
        self.containsTolls = containsTolls
        super.init(frame: .zero)

        label.text = text
        label.font = Self.calloutTextFont
        label.textColor = textColor

        layer.addSublayer(mainCalloutShapeLayer)
        mainCalloutShapeLayer.shadowRadius = 8.0
        mainCalloutShapeLayer.shadowOffset = CGSize(width: 0, height: 4.0)
        mainCalloutShapeLayer.shadowColor = UIColor(white: 0.0, alpha: 0.3).cgColor
        mainCalloutShapeLayer.shadowOpacity = 1.0
        mainCalloutShapeLayer.strokeColor = outlineColor.cgColor
        mainCalloutShapeLayer.fillColor = baloonColor.cgColor
        mainCalloutShapeLayer.lineWidth = 1.0

        layer.addSublayer(calloutTailShapeLayer)
        calloutTailShapeLayer.shadowRadius = 8.0
        calloutTailShapeLayer.shadowOffset = CGSize(width: 0, height: 2.0)
        calloutTailShapeLayer.shadowColor = UIColor(white: 0.0, alpha: 0.3).cgColor
        calloutTailShapeLayer.shadowOpacity = 1.0
        calloutTailShapeLayer.strokeColor = outlineColor.cgColor
        calloutTailShapeLayer.fillColor = outlineColor.cgColor
        calloutTailShapeLayer.lineWidth = 1.0

        addSubview(contentHStack)

        if containsTolls {
            self.iconView = UIImageView(image: tollImage).autoresizing()
            iconView?.tintColor = textColor
        }

        setupContentConstraints()
        initSizeConstraints() // required becaause didSet observers are not called in init
        configureStack()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContentConstraints() {
        let totalPadding = contentPadding + tailInsets

        let leading = contentHStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: totalPadding.left)
        let trailing = contentHStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -totalPadding.right)
        let top = contentHStack.topAnchor.constraint(equalTo: topAnchor, constant: totalPadding.top)
        let bottom = contentHStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -totalPadding.bottom)

        NSLayoutConstraint.activate([leading, trailing, top, bottom])

        contentHStackLeadingConstraint = leading
        contentHStackTrailingConstraint = trailing
        contentHStackTopConstraint = top
        contentHStackBottomConstraint = bottom
    }

    func initSizeConstraints() {
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
        }
    }

    override var intrinsicContentSize: CGSize {
        // UIStackView can calculate size correctly with systemLayoutSizeFitting(_:)
        // however in case of custom constructed auto-layout views the correct
        // size calculation might need implementation from scratch.
        let maxTailPadding = CGSize(width: Self.tailPaddingValue, height: Self.tailPaddingValue)
        let totalPadding = maxTailPadding + contentPadding
        return contentHStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) + totalPadding
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        // This is an important override, as systemLayoutSizeFitting(_:) is used by
        // the map view to determine route callout size and choose proper place
        // to display it on the map.
        intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    func configureStack() {
        contentHStack.arrangedSubviews.forEach(contentHStack.removeArrangedSubview)

        switch layoutType {
        case .mainLabelOnly:
            contentHStack.addArrangedSubview(label)

        case .mainLabelToll:
            contentHStack.addArrangedSubview(label)
            contentHStack.addArrangedSubview(iconView ?? UIView())
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let mainCalloutPath = UIBezierPath.mainCalloutPath(
            size: bounds.size,
            cornerRadius: Self.cornerRadius,
            tailInsets: tailInsets
        )
        mainCalloutShapeLayer.path = mainCalloutPath.cgPath
        mainCalloutShapeLayer.frame = bounds

        let calloutTailPath = UIBezierPath.calloutTailPath(
            size: bounds.size,
            tailLineLength: Self.tailLineLength,
            tailAnchorCircleRadius: Self.tailAnchorCircleRadius,
            cornerTailHorizontalOffset: Self.cornerTailHorizontalOffset,
            anchor: resolvedAnchor
        )
        calloutTailShapeLayer.path = calloutTailPath.cgPath
        calloutTailShapeLayer.frame = bounds
    }

    private var resolvedAnchor: ViewAnnotationAnchor {
        anchor ?? .bottom
    }

    private var tailInsets: UIEdgeInsets {
        let p = Self.tailPaddingValue
        return switch resolvedAnchor {
        case .top:
            UIEdgeInsets(top: p, left: 0, bottom: 0, right: 0)
        case .bottom:
            UIEdgeInsets(top: 0, left: 0, bottom: p, right: 0)
        case .left:
            UIEdgeInsets(top: 0, left: p, bottom: 0, right: 0)
        case .right:
            UIEdgeInsets(top: 0, left: 0, bottom: 0, right: p)
        case .topLeft:
            UIEdgeInsets(top: p, left: p, bottom: 0, right: 0)
        case .topRight:
            UIEdgeInsets(top: p, left: 0, bottom: 0, right: p)
        case .bottomLeft:
            UIEdgeInsets(top: 0, left: p, bottom: p, right: 0)
        case .bottomRight:
            UIEdgeInsets(top: 0, left: 0, bottom: p, right: p)
        default:
            UIEdgeInsets.zero
        }
    }

    private func updateContentPaddingConstraints() {
        let totalPadding = contentPadding + tailInsets
        contentHStackLeadingConstraint?.constant = totalPadding.left
        contentHStackTrailingConstraint?.constant = -totalPadding.right
        contentHStackTopConstraint?.constant = totalPadding.top
        contentHStackBottomConstraint?.constant = -totalPadding.bottom
    }
}

extension CustomRouteCalloutView {
    private enum LayoutType {
        case mainLabelOnly
        case mainLabelToll
    }

    private var layoutType: LayoutType {
        switch containsTolls {
        case false:
            return .mainLabelOnly
        case true:
            return .mainLabelToll
        }
    }
}

extension UIEdgeInsets {
    fileprivate init(allEdges value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }

    static func + (left: UIEdgeInsets, right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: left.top + right.top,
            left: left.left + right.left,
            bottom: left.bottom + right.bottom,
            right: left.right + right.right
        )
    }
}

extension CGSize {
    private func roundedUp() -> CGSize {
        CGSize(width: width.rounded(.up), height: height.rounded(.up))
    }
}

private func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

private func + (lhs: CGSize, rhs: UIEdgeInsets) -> CGSize {
    return CGSize(width: lhs.width + rhs.left + rhs.right, height: lhs.height + rhs.top + rhs.bottom)
}

private func - (lhs: CGSize, rhs: UIEdgeInsets) -> CGSize {
    return CGSize(width: lhs.width - rhs.left - rhs.right, height: lhs.height - rhs.top - rhs.bottom)
}

extension UIBezierPath {
    fileprivate static func mainCalloutPath(
        size: CGSize,
        cornerRadius: CGFloat,
        tailInsets: UIEdgeInsets
    ) -> UIBezierPath {
        let rect = CGRect(origin: .init(x: 0, y: 0), size: size)
        let bubbleRect = rect.inset(by: tailInsets)

        let path = UIBezierPath(
            roundedRect: bubbleRect,
            cornerRadius: cornerRadius
        )
        path.close()
        return path
    }

    fileprivate static func calloutTailPath(
        size: CGSize,
        tailLineLength: CGFloat,
        tailAnchorCircleRadius: CGFloat,
        cornerTailHorizontalOffset: CGFloat,
        anchor: ViewAnnotationAnchor
    ) -> UIBezierPath {
        guard anchor != .center else { return UIBezierPath() }

        let tailPath = UIBezierPath()
        let p = tailLineLength + 2 * tailAnchorCircleRadius // padding
        let l = tailLineLength
        let o = cornerTailHorizontalOffset
        let h = size.height
        let w = size.width
        let r = tailAnchorCircleRadius

        let tailPoints: [CGPoint] = switch anchor {
        case .topLeft:
            [CGPoint(x: o + p, y: 2 * r + l), CGPoint(x: o + p, y: 2 * r)]
        case .top:
            [CGPoint(x: w / 2, y: 2 * r + l), CGPoint(x: w / 2, y: 2 * r)]
        case .topRight:
            [CGPoint(x: w - (o + p), y: 2 * r + l), CGPoint(x: w - (o + p), y: 2 * r)]
        case .bottomLeft:
            [CGPoint(x: o + p, y: h - (2 * r + l)), CGPoint(x: o + p, y: h - 2 * r)]
        case .bottom:
            [CGPoint(x: w / 2, y: h - (2 * r + l)), CGPoint(x: w / 2, y: h - 2 * r)]
        case .bottomRight:
            [CGPoint(x: w - (o + p), y: h - (2 * r + l)), CGPoint(x: w - (o + p), y: h - 2 * r)]
        case .left:
            [CGPoint(x: 2 * r + l, y: h / 2), CGPoint(x: 2 * r, y: h / 2)]
        case .right:
            [CGPoint(x: w - (2 * r + l), y: h / 2), CGPoint(x: w - 2 * r, y: h / 2)]
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
        if !tailPoints.isEmpty {
            tailPath.close()
        }

        let circleCenterPoint: CGPoint? = switch anchor {
        case .topLeft:
            CGPoint(x: o + p, y: r)
        case .top:
            CGPoint(x: w / 2, y: r)
        case .topRight:
            CGPoint(x: w - (o + p), y: r)
        case .bottomLeft:
            CGPoint(x: o + p, y: h - r)
        case .bottom:
            CGPoint(x: w / 2, y: h - r)
        case .bottomRight:
            CGPoint(x: w - (o + p), y: h - r)
        case .left:
            CGPoint(x: r, y: h / 2)
        case .right:
            CGPoint(x: w - r, y: h / 2)
        default:
            nil
        }

        if let circleCenterPoint {
            let circlePath = UIBezierPath(
                arcCenter: circleCenterPoint,
                radius: tailAnchorCircleRadius,
                startAngle: 0.0,
                endAngle: 2 * CGFloat.pi,
                clockwise: true
            )

            circlePath.close()
            tailPath.append(circlePath)
        }

        return tailPath
    }
}
