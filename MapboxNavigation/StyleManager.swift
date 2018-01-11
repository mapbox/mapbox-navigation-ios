import UIKit
import Solar

/**
 The `StyleManagerDelegate` protocol defines a set of methods used for controlling the style.
 */
@objc(MBStyleManagerDelegate)
public protocol StyleManagerDelegate: NSObjectProtocol {
    /**
     Asks the delegate for a location to use when calculating sunset and sunrise.
     */
    @objc func locationFor(styleManager: StyleManager) -> CLLocation
    
    /**
     Informs the delegate that a style was applied.
     */
    @objc optional func styleManager(_ styleManager: StyleManager, didApply style: Style)
    
    /**
     Informs the delegate that the manager forcefully refreshed UIAppearance.
     */
    @objc optional func styleManagerDidRefreshAppearance(_ styleManager: StyleManager)
}

/**
 A manager that handles `Style` objects. The manager listens for significant time changes
 and changes to the content size to apply an approriate style for the given condition.
 */
@objc(MBStyleManager)
open class StyleManager: NSObject {
    
    weak var delegate: StyleManagerDelegate?
    
    internal var date: Date?
    var currentStyleType: StyleType?
    var styles = [Style]() { didSet { applyStyle() } }
    var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            resumeNotifications()
        }
    }
    
    /**
     Initializes a new `StyleManager`.
     
     - parameter delegate: The receiver’s delegate
     */
    required public init(_ delegate: StyleManagerDelegate) {
        self.delegate = delegate
        super.init()
        resumeNotifications()
        resetTimeOfDayTimer()
    }
    
    deinit {
        suspendNotifications()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeOfDayChanged), object: nil)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(timeOfDayChanged), name: .UIApplicationSignificantTimeChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: .UIContentSizeCategoryDidChange, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIContentSizeCategoryDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationSignificantTimeChange, object: nil)
    }
    
    func resetTimeOfDayTimer() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeOfDayChanged), object: nil)
        
        guard automaticallyAdjustsStyleForTimeOfDay else { return }
        guard let location = delegate?.locationFor(styleManager: self) else { return }
        
        guard let solar = Solar(date: date, coordinate: location.coordinate),
            let sunrise = solar.sunrise,
            let sunset = solar.sunset else {
                return
        }
        
        guard let interval = solar.date.intervalUntilTimeOfDayChanges(sunrise: sunrise, sunset: sunset) else {
            print("Unable to get sunrise or sunset. Automatic style switching has been disabled.")
            return
        }
        
        perform(#selector(timeOfDayChanged), with: nil, afterDelay: interval+1)
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
        applyStyle()
    }
    
    @objc func timeOfDayChanged() {
        forceRefreshAppearanceIfNeeded()
        resetTimeOfDayTimer()
    }
    
    func applyStyle() {
        guard let location = delegate?.locationFor(styleManager: self) else {
            // We can't calculate sunset or sunrise w/o a location so just apply the first style
            if let style = styles.first {
                style.apply()
                delegate?.styleManager?(self, didApply: style)
            }
            return
        }
        
        // Single style usage
        guard styles.count > 1 else {
            if let style = styles.first {
                style.apply()
                delegate?.styleManager?(self, didApply: style)
            }
            return
        }
        
        let styleTypeForTimeOfDay = styleType(for: location)
        
        for style in styles {
            if style.styleType == styleTypeForTimeOfDay {
                style.apply()
                currentStyleType = style.styleType
                delegate?.styleManager?(self, didApply: style)
            }
        }
    }
    
    func styleType(for location: CLLocation) -> StyleType {
        guard let solar = Solar(date: date, coordinate: location.coordinate),
            let sunrise = solar.sunrise,
            let sunset = solar.sunset else {
                return .dayStyle
        }
        
        return solar.date.isNighttime(sunrise: sunrise, sunset: sunset) ? .nightStyle : .dayStyle
    }
    
    func forceRefreshAppearanceIfNeeded() {
        guard let location = delegate?.locationFor(styleManager: self) else { return }
        
        guard currentStyleType != styleType(for: location) else {
            return
        }
        
        applyStyle()
        
        for window in UIApplication.shared.windows {
            for view in window.subviews {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
        
        delegate?.styleManagerDidRefreshAppearance?(self)
    }
}

extension Date {
    func intervalUntilTimeOfDayChanges(sunrise: Date, sunset: Date) -> TimeInterval? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        guard let date = calendar.date(from: components) else {
            return nil
        }
        
        if isNighttime(sunrise: sunrise, sunset: sunset) {
            let sunriseComponents = calendar.dateComponents([.hour, .minute, .second], from: sunrise)
            guard let sunriseDate = calendar.date(from: sunriseComponents) else {
                return nil
            }
            return sunriseDate.timeIntervalSince(date)
        } else {
            let sunsetComponents = calendar.dateComponents([.hour, .minute, .second], from: sunset)
            guard let sunsetDate = calendar.date(from: sunsetComponents) else {
                return nil
            }
            return sunsetDate.timeIntervalSince(date)
        }
    }
    
    fileprivate func isNighttime(sunrise: Date, sunset: Date) -> Bool {
        let calendar = Calendar.current
        let currentMinutesFromMidnight = calendar.component(.hour, from: self) * 60 + calendar.component(.minute, from: self)
        let sunriseMinutesFromMidnight = calendar.component(.hour, from: sunrise) * 60 + calendar.component(.minute, from: sunrise)
        let sunsetMinutesFromMidnight = calendar.component(.hour, from: sunset) * 60 + calendar.component(.minute, from: sunset)
        return currentMinutesFromMidnight < sunriseMinutesFromMidnight || currentMinutesFromMidnight > sunsetMinutesFromMidnight
    }
}

extension Solar {
    init?(date: Date?, coordinate: CLLocationCoordinate2D) {
        if let date = date {
            self.init(for: date, coordinate: coordinate)
        } else {
            self.init(coordinate: coordinate)
        }
    }
}
