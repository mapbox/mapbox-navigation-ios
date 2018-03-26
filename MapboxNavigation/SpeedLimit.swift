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
    let fontSize = UIFont.systemFontSize
    let strings = NSMutableAttributedString()
    let numberFormater = NumberFormatter()
    
    var speedLimit: SpeedLimit? {
        didSet {
            guard let speedLimit = speedLimit else { return }
            guard let speedString = numberFormater.string(from: speedLimit.value as NSNumber) else { return }
            
            labels.removeAll()
            
            let defaultLabels = defaultTextSplit.map { (string: String) -> SpeedLimitLabel in
                let label: SpeedLimitLabel = .forAutoLayout()
                label.attributedText = NSMutableAttributedString(string: string.uppercased(), attributes: [
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont.systemFont(ofSize: fontSize * 0.9)
                    ])
                return label
            }
            labels.append(contentsOf: defaultLabels)
            
            let speedLabel: SpeedLimitLabel = .forAutoLayout()
            speedLabel.attributedText = NSMutableAttributedString(string: speedString, attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize * 2),
                .paragraphStyle: paragraphStyle
                ])
            labels.append(speedLabel)
            
            let unitLabel: SpeedLimitLabel = .forAutoLayout()
            unitLabel.attributedText = NSMutableAttributedString(string: speedLimit.unit.localizedSpeedUnit, attributes: [
                .font: UIFont.boldSystemFont(ofSize: fontSize * 0.7),
                .paragraphStyle: paragraphStyle
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
        paragraphStyle.alignment = .center
        layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        axis = .vertical
        contentMode = .scaleAspectFill
        distribution = .equalSpacing
    }
    
    func updateStackView(with labels: [SpeedLimitLabel]) {
        subviews.forEach { $0.removeFromSuperview() }
        addArrangedSubviews(labels)
        layoutIfNeeded()
    }
    
    func addBackground() {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = .white
        subView.layer.cornerRadius = 3
        subView.layer.borderWidth = 1
        subView.layer.borderColor = UIColor.black.cgColor
        subView.layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        addBackground()
        layoutMargins = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
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
