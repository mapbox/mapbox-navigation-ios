import MapboxMaps
import UIKit

final class LaneGuidanceCalloutView: UIView {
    private let contentHStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: []).autoresizing()
        stackView.axis = .horizontal
        return stackView
    }()

    private let backgroundShapeLayer = CAShapeLayer()

    let mapStyleConfig: MapStyleConfig
    private let baloonColor: UIColor
    private let contentPadding = UIEdgeInsets(top: 6.0, left: 10.0, bottom: 6.0, right: 10.0)
    private static let tailSize: CGFloat = 7.0
    private let tailPadding = UIEdgeInsets(allEdges: tailSize)
    private static let laneViewSizeNormal: CGFloat = 20.0
    private static let laneViewSizeCompact: CGFloat = 16.0
    private let laneViewSize: CGFloat
    private static let cornerRadiusNormal: CGFloat = 10.0
    private static let cornerRadiusCompact: CGFloat = 8.0
    private let cornerRadius: CGFloat
    private static let compactSizeLanesCountThreshold: Int = 6

    var anchor: ViewAnnotationAnchor? {
        didSet { setNeedsLayout() }
    }

    init(laneGuidanceData: IntersectionLaneGuidanceData, mapStyleConfig: MapStyleConfig) {
        self.mapStyleConfig = mapStyleConfig
        self.baloonColor = mapStyleConfig.routeAnnotationSelectedColor
        let compact = laneGuidanceData.approachLanes.count > Self.compactSizeLanesCountThreshold
        self.laneViewSize = compact ? Self.laneViewSizeCompact : Self.laneViewSizeNormal
        self.cornerRadius = compact ? Self.cornerRadiusCompact : Self.cornerRadiusNormal
        super.init(frame: .zero)

        layer.addSublayer(backgroundShapeLayer)
        backgroundShapeLayer.shadowRadius = 8.0
        backgroundShapeLayer.shadowOffset = CGSize(width: 0, height: 4.0)
        backgroundShapeLayer.shadowColor = UIColor(white: 0.0, alpha: 0.12).cgColor
        backgroundShapeLayer.shadowOpacity = 1.0
        backgroundShapeLayer.fillColor = baloonColor.cgColor

        addSubview(contentHStack)

        setupPersistentConstraints()
        configureStack(laneGuidanceData: laneGuidanceData)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPersistentConstraints() {
        let totalPadding = contentPadding + tailPadding
        NSLayoutConstraint.activate([
            contentHStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: totalPadding.left),
            contentHStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -totalPadding.right),
            contentHStack.topAnchor.constraint(equalTo: topAnchor, constant: totalPadding.top),
            contentHStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -totalPadding.bottom),
        ])
    }

    override var intrinsicContentSize: CGSize {
        contentHStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) + contentPadding + tailPadding
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        intrinsicContentSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    func configureStack(laneGuidanceData: IntersectionLaneGuidanceData) {
        let laneViews = laneGuidanceData.approachLanes.enumerated().map { index, lane in
            LaneView(
                indications: lane,
                isUsable: laneGuidanceData.usableApproachLanes?.contains(index) ?? false,
                direction: laneGuidanceData.usableLaneIndication
            )
        }

        laneViews.forEach { view in
            view.primaryColor = mapStyleConfig.routeAnnotationSelectedTextColor
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: laneViewSize),
                view.heightAnchor.constraint(equalToConstant: laneViewSize),
            ])
            contentHStack.addArrangedSubview(view)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let calloutPath = UIBezierPath.calloutPath(
            size: bounds.size,
            tailSize: Self.tailSize,
            cornerRadius: cornerRadius,
            anchor: anchor ?? .center
        )
        backgroundShapeLayer.path = calloutPath.cgPath
        backgroundShapeLayer.frame = bounds
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
    private var textSize: CGSize {
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
