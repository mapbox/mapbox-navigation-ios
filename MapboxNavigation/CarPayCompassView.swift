import UIKit
import Mapbox
import Turf
import MapboxCoreNavigation

@objc(MBCarPlayCompassView)
open class CarPlayCompassView: StylableView {
    
    @objc weak open var label: StylableLabel!
    
    // Round to closest 45° to only show main winds ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    static let granularity: CLLocationDirection = 360 / 8
    
    lazy var formatter: MGLCompassDirectionFormatter = {
        let formatter = MGLCompassDirectionFormatter()
        formatter.unitStyle = .short
        return formatter
    }()
    
    @objc
    open var course: CLLocationDirection = 0 {
        didSet {
            if course.isQualified {
                snappedCourse = course.wrap(min: 0, max: 360)
            }
        }
    }
    
    fileprivate var _snappedCourse: CLLocationDirection = 0
    fileprivate var snappedCourse: CLLocationDirection {
        set {
            let snappedCourse = CarPlayCompassView.granularity * round(newValue / CarPlayCompassView.granularity)
            _snappedCourse = snappedCourse
            label.text = formatter.string(fromDirection: snappedCourse).uppercased()
        }
        get {
            return _snappedCourse
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
        
        widthAnchor.constraint(equalToConstant: 30).isActive = true
        heightAnchor.constraint(equalToConstant: 30).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
    }
}
