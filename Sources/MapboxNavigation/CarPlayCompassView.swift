import UIKit
import CoreLocation
import MapboxMaps

/**
 A control indicating the direction that the vehicle is traveling towards.
 */
open class CarPlayCompassView: StylableView {
    weak var label: StylableLabel!
    
    // Round to closest 45° to only show main winds ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    static let granularity: CLLocationDirection = 360 / 8
    
    lazy var formatter: CompassDirectionFormatter = {
        let formatter = CompassDirectionFormatter()
        formatter.style = .short
        
        return formatter
    }()
    
    /**
     Sets the course, rounds it to closest 45°, and draws the cardinal direction on the label.
     */
    open var course: CLLocationDirection = 0 {
        didSet {
            if course >= 0 {
                snappedCourse = course.wrap(min: 0, max: 360)
            }
        }
    }
    
    fileprivate var _snappedCourse: CLLocationDirection = 0
    fileprivate var snappedCourse: CLLocationDirection {
        set {
            let snappedCourse = CarPlayCompassView.granularity * round(newValue / CarPlayCompassView.granularity)
            _snappedCourse = snappedCourse
            label.text = formatter.string(from: snappedCourse).uppercased()
        }
        get {
            return _snappedCourse
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    func commonInit() {
        isHidden = true
        let label = StylableLabel(frame: .zero)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        self.label = label
        
        course = 0
        
        widthAnchor.constraint(equalToConstant: 30).isActive = true
        heightAnchor.constraint(equalToConstant: 30).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2).isActive = true
        
        translatesAutoresizingMaskIntoConstraints = false
    }
}
