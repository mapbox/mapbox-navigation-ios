import Foundation
import MapboxDirections

/// :nodoc:
@objc(MBSpeedLimitSign)
open class SpeedLimitSign: UIStackView {
    var labels: [SpeedLimitLabel] = []
    
    let defaultText = NSLocalizedString("SPEED_LIMIT", bundle: .mapboxNavigation, value: "Speed Limit", comment: "Speed limit sign main text.")
    var defaultTextSplit: [String] {
        return defaultText.components(separatedBy: " ")
    }
    
    let paragraphStyle = NSMutableParagraphStyle()
    let fontSize: CGFloat = 14.0
    let strings = NSMutableAttributedString()
    let numberFormater = NumberFormatter()
    
    var circleBounds: CGRect {
        // TODO: adjust x and y location
        let padding: CGFloat = 20
        if bounds.width > bounds.height {
            return CGRect(x: 0, y: 0, width: bounds.width + padding, height: bounds.width + padding)
        } else {
            return CGRect(x: 0, y: 0, width: bounds.height + padding, height: bounds.height + padding)
        }
    }
    
    var region: SpeedLimitSignRegionType!
    
    var speedLimit: SpeedLimit? {
        didSet {
            guard let speedLimit = speedLimit else { return }
            guard let speedString = numberFormater.string(from: speedLimit.value as NSNumber) else { return }
            labels.removeAll()
            
            // Only include the string `SPEED LIMIT` for .unitedStates.
            if region == .unitedStates {
                let defaultLabels = defaultTextSplit.map { (string: String) -> SpeedLimitLabel in
                    let label: SpeedLimitLabel = .forAutoLayout()
                    label.attributedText = NSMutableAttributedString(string: string.uppercased(), attributes: [
                        .font: UIFont.systemFont(ofSize: fontSize * 0.9),
                        .paragraphStyle: paragraphStyle
                        ])
                    return label
                }
                labels.append(contentsOf: defaultLabels)
            }
            
            let speedLabel: SpeedLimitLabel = .forAutoLayout()
            speedLabel.attributedText = NSMutableAttributedString(string: speedString, attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize * 2)
                ])
            labels.append(speedLabel)
            
            let unitLabel: SpeedLimitLabel = .forAutoLayout()
            unitLabel.attributedText = NSMutableAttributedString(string: speedLimit.unit.localizedSpeedUnit, attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize * 0.7)
                ])
            labels.append(unitLabel)
            
            updateStackView(with: labels)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        isLayoutMarginsRelativeArrangement = true
        axis = .vertical
        alignment = .center
        contentMode = .scaleAspectFill
        distribution = .fillProportionally
    }
    
    func updateStackView(with labels: [SpeedLimitLabel]) {
        subviews.forEach { $0.removeFromSuperview() }
        addArrangedSubviews(labels)
        layoutIfNeeded()
    }
    
    func addBackground() {
        let background: UIView
        if region == .unitedStates {
            background = UnitedStatesSignBase(frame: bounds)
        } else {
            background = WorldSignBase(frame: circleBounds)
        }
        insertSubview(background, at: 0)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        addBackground()
    }
}

public enum SpeedLimitSignRegionType {
    case world
    case unitedStates
}

class WorldSignBase: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        layer.cornerRadius = bounds.size.width / 2
        layer.borderWidth = 5
        layer.borderColor = UIColor(red:0.93, green:0.11, blue:0.14, alpha:1.0).cgColor
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}


class UnitedStatesSignBase: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = .white
        layer.cornerRadius = 3
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.cgColor
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}

extension SpeedUnit {
    var localizedSpeedUnit: String {
        switch self {
        case .kilometersPerHour:
            return NSLocalizedString("KILOMETERS_PER_HOUR", bundle: .mapboxNavigation, value: "kph", comment: "Inform the user on limits for speed.")
        case .milesPerHour:
            return NSLocalizedString("MILES_PER_HOUR", bundle: .mapboxNavigation, value: "mph", comment: "Inform the user on limits for speed.")
        }
    }
}
