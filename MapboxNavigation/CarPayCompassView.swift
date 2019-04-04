import UIKit
import Mapbox

@objc(MBCarPlayCompassView)
open class CarPlayCompassView: FloatingButton {
    
    @objc weak open var label: StylableLabel!
    
    lazy var formatter: MGLCompassDirectionFormatter = {
        let formatter = MGLCompassDirectionFormatter()
        formatter.unitStyle = .short
        return formatter
    }()
    
    @objc
    open var course: CLLocationDirection = 0 {
        didSet {
            label.text = formatter.string(fromDirection: course).uppercased()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    func commonInit() {
        let label = StylableLabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        self.label = label
        
        course = 0
        
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
    }
}
