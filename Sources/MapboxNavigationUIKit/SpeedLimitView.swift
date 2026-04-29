import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import UIKit

/// A view that displays a speed limit and resembles a real-world speed limit sign.
public class SpeedLimitView: UIView {
    // MARK: Styling the Sign

    /// The sign’s background color.
    @objc public dynamic var signBackColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            update()
        }
    }

    /// The color of the text on the sign.
    ///
    /// This color is also used for the border of an MUTCD-style sign.
    @objc public dynamic var textColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
        didSet {
            update()
        }
    }

    /// The color of the border of a regulatory sign according to the Vienna Convention.
    @objc public dynamic var regulatoryBorderColor: UIColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1) {
        didSet {
            update()
        }
    }

    // MARK: Populating the Sign

    /// The speed limit to display.
    ///
    /// The view displays the value of this property as is without converting it to another unit.
    public var speedLimit: Measurement<UnitSpeed>? {
        didSet {
            if speedLimit != oldValue {
                update()
            }
        }
    }

    /// The current speed to display.
    public var currentSpeed: CLLocationSpeed?

    /// The sign standard that specifies the design that the view depicts.
    public var signStandard: SignStandard? {
        didSet {
            if signStandard != oldValue {
                update()
            }
        }
    }

    /// Allows to completely hide ``SpeedLimitView``.
    public var isAlwaysHidden: Bool = false {
        didSet {
            update()
        }
    }

    /// Defines the view behavior if the ``SpeedLimitView/speedLimit`` property is `nil`.
    ///
    /// Setting this property to `true` will cause the view to display `"--"` as a speed limit instead of the
    /// ``SpeedLimitView`` being invisible.
    public var shouldShowUnknownSpeedLimit: Bool = false {
        didSet {
            update()
        }
    }

    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        // Mitigate rounding error when converting back and forth between kilometers per hour and miles per hour.
        formatter.numberFormatter.roundingIncrement = 5
        return formatter
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        isOpaque = false
    }

    var canDraw: Bool {
        return !isAlwaysHidden && signStandard != nil && (speedLimit != nil || shouldShowUnknownSpeedLimit)
    }

    func update() {
        let wasHidden = isHidden
        isHidden = !canDraw
        setNeedsDisplay()
        if canDraw, !wasHidden {
            blinkIn()
        }
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let signStandard else { return }

        let formattedSpeedLimit: String

        if let speedLimit {
            if speedLimit.value.isInfinite || speedLimit.value == 0 {
                formattedSpeedLimit = "∞"
            } else {
                formattedSpeedLimit = measurementFormatter.numberFormatter
                    .string(for: speedLimit.value) ?? "\(speedLimit.value)"
            }
        } else if shouldShowUnknownSpeedLimit {
            formattedSpeedLimit = "--"
        } else {
            return
        }

        switch signStandard {
        case .mutcd:
            let legend = "SPEED_LIMIT_LEGEND".localizedString(
                value: "Max",
                comment: "Label above the speed limit in an MUTCD-style speed limit sign. Keep as short as possible."
            ).uppercased()
            SpeedLimitStyleKit.drawMUTCD(
                frame: bounds,
                resizing: .aspectFit,
                signBackColor: signBackColor,
                strokeColor: textColor,
                limit: formattedSpeedLimit,
                legend: legend
            )
        case .viennaConvention:
            if let speedLimit, speedLimit.value.isInfinite || speedLimit.value == 0 {
                let image = UIImage(named: "infinite-speed-limit", in: .mapboxNavigation, compatibleWith: nil)
                image?.draw(in: bounds)
            } else {
                SpeedLimitStyleKit.drawVienna(
                    frame: bounds,
                    resizing: .aspectFit,
                    signBackColor: signBackColor,
                    strokeColor: textColor,
                    regulatoryColor: regulatoryBorderColor,
                    limit: formattedSpeedLimit
                )
            }
        }
    }

    func blinkIn() {
        UIView.animate(
            withDuration: 0.1,
            delay: 0.1,
            options: [.beginFromCurrentState, .curveEaseOut],
            animations: { [weak self] in
                UIView.modifyAnimations(withRepeatCount: 1, autoreverses: true) {
                    self?.layer.opacity = 0
                }
            }
        ) { [weak self] _ in
            self?.layer.opacity = 1
        }
    }
}
