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
    @objc func locationFor(styleManager: StyleManager) -> CLLocation?
    
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
    
    /**
     The receiver of the delegate. See `StyleManagerDelegate` for more information.
     */
    @objc public weak var delegate: StyleManagerDelegate?
    
    /**
     Determines whether the style manager should apply a new style given the time of day.
     
     - precondition: Two styles must be provided for this property to have any effect.
     */
    @objc public var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            resetTimeOfDayTimer()
        }
    }
    
    /**
     The styles that are in circulation. Active style is set based on
     the sunrise and sunset at your current location. A change of
     preferred content size by the user will also trigger an update.
     
     - precondition: Two styles must be provided for
     `StyleManager.automaticallyAdjustsStyleForTimeOfDay` to have any effect.
     */
    @objc public var styles = [Style]() {
        didSet {
            applyStyle()
            resetTimeOfDayTimer()
        }
    }
    
    internal var date: Date?
    
    var currentStyleType: StyleType?
    
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
        
        guard automaticallyAdjustsStyleForTimeOfDay && styles.count > 1 else { return }
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
    
    func applyStyle(type styleType: StyleType) {
        guard currentStyleType != styleType else { return }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeOfDayChanged), object: nil)
        
        for style in styles {
            if style.styleType == styleType {
                style.apply()
                currentStyleType = styleType
                delegate?.styleManager?(self, didApply: style)
            }
        }
        
        forceRefreshAppearance()
    }
    
    func applyStyle() {
        guard let location = delegate?.locationFor(styleManager: self) else {
            // We can't calculate sunset or sunrise w/o a location so just apply the first style
            if let style = styles.first, currentStyleType != style.styleType {
                currentStyleType = style.styleType
                style.apply()
                delegate?.styleManager?(self, didApply: style)
            }
            return
        }
        
        // Single style usage
        guard styles.count > 1 else {
            if let style = styles.first, currentStyleType != style.styleType {
                currentStyleType = style.styleType
                style.apply()
                delegate?.styleManager?(self, didApply: style)
            }
            return
        }
        
        let styleTypeForTimeOfDay = styleType(for: location)
        applyStyle(type: styleTypeForTimeOfDay)
    }
    
    func styleType(for location: CLLocation) -> StyleType {
        guard let solar = Solar(date: date, coordinate: location.coordinate),
            let sunrise = solar.sunrise,
            let sunset = solar.sunset else {
                return .day
        }
        
        return solar.date.isNighttime(sunrise: sunrise, sunset: sunset) ? .night : .day
    }
    
    func forceRefreshAppearanceIfNeeded() {
        guard let location = delegate?.locationFor(styleManager: self) else { return }
        
        let styleTypeForLocation = styleType(for: location)
        
        // If `styles` does not contain at least one style for the selected location, don't try and apply it.
        let availableStyleTypesForLocation = styles.filter { $0.styleType == styleTypeForLocation }
        guard availableStyleTypesForLocation.count > 0 else { return }
        
        guard currentStyleType != styleTypeForLocation else {
            return
        }
        
        applyStyle()
        forceRefreshAppearance()
    }
    
    func forceRefreshAppearance() {
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
            let interval = sunriseDate.timeIntervalSince(date)
            return interval >= 0 ? interval : (interval + 24 * 3600)
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
