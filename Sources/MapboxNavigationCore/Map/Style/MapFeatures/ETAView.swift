import MapboxMaps
import UIKit

final class ETAView: UIView {
    private let label = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    private var tail = UIView()
    private let backgroundShape = CAShapeLayer()
    let mapStyleConfig: MapStyleConfig

    let textColor: UIColor
    let baloonColor: UIColor
    var padding = UIEdgeInsets(allEdges: 10)
    var tailSize = 8.0
    var cornerRadius = 8.0

    var text: String {
        didSet { update() }
    }

    var anchor: ViewAnnotationAnchor? {
        didSet { setNeedsLayout() }
    }

    convenience init(
        eta: TimeInterval,
        isSelected: Bool,
        tollsHint: Bool?,
        mapStyleConfig: MapStyleConfig
    ) {
        let viewLabel = DateComponentsFormatter.travelTimeString(eta, signed: false)

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
            text: viewLabel,
            tollsHint: tollsHint,
            mapStyleConfig: mapStyleConfig,
            textColor: textColor,
            baloonColor: baloonColor
        )
    }

    convenience init(
        travelTimeDelta: TimeInterval,
        tollsHint: Bool?,
        mapStyleConfig: MapStyleConfig
    ) {
        let textColor: UIColor
        let timeDelta: String
        if abs(travelTimeDelta) >= 180 {
            textColor = if travelTimeDelta > 0 {
                mapStyleConfig.routeAnnotationMoreTimeTextColor
            } else {
                mapStyleConfig.routeAnnotationLessTimeTextColor
            }
            timeDelta = DateComponentsFormatter.travelTimeString(
                travelTimeDelta,
                signed: true
            )
        } else {
            textColor = mapStyleConfig.routeAnnotationTextColor
            timeDelta = "SAME_TIME".localizedString(
                value: "Similar ETA",
                comment: "Alternatives selection note about equal travel time."
            )
        }

        self.init(
            text: timeDelta,
            tollsHint: tollsHint,
            mapStyleConfig: mapStyleConfig,
            textColor: textColor,
            baloonColor: mapStyleConfig.routeAnnotationColor
        )
    }

    init(
        text: String,
        tollsHint: Bool?,
        mapStyleConfig: MapStyleConfig,
        textColor: UIColor = .darkText,
        baloonColor: UIColor = .white
    ) {
        var viewLabel = text
        switch tollsHint {
        case .none:
            label.numberOfLines = 1
        case .some(true):
            label.numberOfLines = 2
            viewLabel += "\n" + "ROUTE_HAS_TOLLS".localizedString(
                value: "Tolls",
                comment: "Route callout label, indicating there are tolls on the route.")
            if let symbol = Locale.current.currencySymbol {
                viewLabel += " " + symbol
            }
        case .some(false):
            label.numberOfLines = 2
            viewLabel += "\n" + "ROUTE_HAS_NO_TOLLS".localizedString(
                value: "No Tolls",
                comment: "Route callout label, indicating there are no tolls on the route.")
        }

        self.text = viewLabel
        self.textColor = textColor
        self.baloonColor = baloonColor
        self.mapStyleConfig = mapStyleConfig
        super.init(frame: .zero)
        layer.addSublayer(backgroundShape)
        backgroundShape.shadowRadius = 1.4
        backgroundShape.shadowOffset = CGSize(width: 0, height: 0.7)
        backgroundShape.shadowColor = UIColor.black.cgColor
        backgroundShape.shadowOpacity = 0.3

        addSubview(label)

        update()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var attributedText: NSAttributedString {
        let text = NSMutableAttributedString(
            attributedString: .labelText(
                text,
                font: mapStyleConfig.routeAnnotationTextFont,
                color: textColor
            )
        )
        return text
    }

    private func update() {
        backgroundShape.fillColor = baloonColor.cgColor
        label.attributedText = attributedText
    }

    struct Layout {
        var label: CGRect
        var bubble: CGRect
        var size: CGSize

        init(availableSize: CGSize, text: NSAttributedString, tailSize: CGFloat, padding: UIEdgeInsets) {
            let tailPadding = UIEdgeInsets(allEdges: tailSize)

            let textPadding = padding + tailPadding + UIEdgeInsets.zero
            let textAvailableSize = availableSize - textPadding
            let textSize = text.boundingRect(
                with: textAvailableSize,
                options: .usesLineFragmentOrigin, context: nil
            ).size.roundedUp()
            self.label = CGRect(padding: textPadding, size: textSize)
            self.bubble = CGRect(padding: tailPadding, size: textSize + textPadding - tailPadding)
            self.size = bubble.size + tailPadding
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        Layout(availableSize: size, text: attributedText, tailSize: tailSize, padding: padding).size
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let layout = Layout(availableSize: bounds.size, text: attributedText, tailSize: tailSize, padding: padding)
        label.frame = layout.label

        let calloutPath = UIBezierPath.calloutPath(
            size: bounds.size,
            tailSize: tailSize,
            cornerRadius: cornerRadius,
            anchor: anchor ?? .center
        )
        backgroundShape.path = calloutPath.cgPath
        backgroundShape.frame = bounds
    }
}

extension UIEdgeInsets {
    fileprivate init(allEdges value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }
}

extension NSAttributedString {
    fileprivate static func labelText(_ string: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: color,
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }
}

extension CGSize {
    fileprivate func roundedUp() -> CGSize {
        CGSize(width: width.rounded(.up), height: height.rounded(.up))
    }
}

extension CGRect {
    fileprivate init(padding: UIEdgeInsets, size: CGSize) {
        self.init(origin: CGPoint(x: padding.left, y: padding.top), size: size)
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
