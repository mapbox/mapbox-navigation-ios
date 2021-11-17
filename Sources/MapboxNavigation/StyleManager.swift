import UIKit
import Solar
import MapboxCoreNavigation
import CoreLocation

/**
 The `StyleManagerDelegate` protocol defines a set of methods used for controlling the style.
 */
public protocol StyleManagerDelegate: AnyObject, UnimplementedLogging {
    /**
     Asks the delegate for a location to use when calculating sunset and sunrise
     */
    func location(for styleManager: StyleManager) -> CLLocation?
    
    /**
     Asks the delegate for the view to be used when refreshing appearance. 
     
     The default implementation of this method will attempt to cast the delegate to type
     `UIViewController` and use its `view` property.
     */
    func styleManager(_ styleManager: StyleManager, viewForApplying currentStyle: Style?) -> UIView?
    
    /**
     Informs the delegate that a style was applied.
     
     This delegate method is the equivalent of `Notification.Name.styleManagerDidApplyStyle`.
     */
    func styleManager(_ styleManager: StyleManager, didApply style: Style)
    
    /**
     Informs the delegate that the manager forcefully refreshed UIAppearance.
     */
    func styleManagerDidRefreshAppearance(_ styleManager: StyleManager)
}

public extension StyleManagerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func location(for styleManager: StyleManager) -> CLLocation? {
        logUnimplemented(protocolType: StyleManagerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        logUnimplemented(protocolType: StyleManagerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        logUnimplemented(protocolType: StyleManagerDelegate.self, level: .debug)
    }
    
    func styleManager(_ styleManager: StyleManager, viewForApplying currentStyle: Style?) -> UIView? {
        // Short-circuit refresh logic if the view hasn't yet loaded since we don't want the `self.view` 
        // call to trigger `loadView`.
        if let vc = self as? UIViewController, vc.isViewLoaded { 
            return vc.view
        }
        
        return nil
    }
}

/**
 A manager that handles `Style` objects. The manager listens for significant time changes
 and changes to the content size to apply an appropriate style for the given condition.
 */
open class StyleManager {
    /**
     The receiver of the delegate. See `StyleManagerDelegate` for more information.
     */
    public weak var delegate: StyleManagerDelegate?
    
    /**
     Determines whether the style manager should apply a new style given the time of day.
     
     - precondition: Two styles must be provided for this property to have any effect.
     */
    public var automaticallyAdjustsStyleForTimeOfDay = true {
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
    public var styles = [Style]() {
        didSet {
            applyStyle()
            resetTimeOfDayTimer()
        }
    }
    
    internal var date: Date?
    private var timeOfDayTimer: Timer?
    
    /**
     The currently applied style. Use `StyleManager.applyStyle(type:)` to update this value.
     */
    public private(set) var currentStyleType: StyleType?
    
    /**
     The current style associated with `currentStyleType`. Calling `StyleManager.applyStyle(type:)` will
     result in this value being updated.
     */
    public private(set) var currentStyle: Style? {
        didSet {
            guard let style = currentStyle else { return }
            postDidApplyStyleNotification(style: style)
        }
    }
    
    public init() {
        resumeNotifications()
        resetTimeOfDayTimer()
    }
    
    deinit {
        suspendNotifications()
        timeOfDayTimer?.invalidate()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(timeOfDayChanged), name: UIApplication.significantTimeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(preferredContentSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.significantTimeChangeNotification, object: nil)
    }
    
    func resetTimeOfDayTimer() {
        timeOfDayTimer?.invalidate()
        
        guard automaticallyAdjustsStyleForTimeOfDay && styles.count > 1 else { return }
        guard let location = delegate?.location(for:self) else { return }
        
        guard let solar = Solar(date: date, coordinate: location.coordinate),
              let sunrise = solar.sunrise,
              let sunset = solar.sunset else {
            return
        }
        
        guard let interval = solar.date.intervalUntilTimeOfDayChanges(sunrise: sunrise, sunset: sunset) else {
            print("Unable to get sunrise or sunset. Automatic style switching has been disabled.")
            return
        }

        timeOfDayTimer = Timer.scheduledTimer(withTimeInterval: interval + 1, repeats: false) { [weak self] _ in
            self?.timeOfDayChanged()
        }
    }
    
    @objc func preferredContentSizeChanged(_ notification: Notification) {
        applyStyle()
    }
    
    @objc func timeOfDayChanged() {
        forceRefreshAppearanceIfNeeded()
        resetTimeOfDayTimer()
    }
    
    /**
     Applies the `Style` with type matching `type`and notifies `StyleManager.delegate` upon completion. 
     */
    public func applyStyle(type styleType: StyleType) {
        guard currentStyleType != styleType else { return }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeOfDayChanged), object: nil)
        
        for style in styles {
            if style.styleType == styleType {
                style.apply()
                currentStyleType = styleType
                currentStyle = style
                delegate?.styleManager(self, didApply: style)
                break
            }
        }
        
        forceRefreshAppearance()
    }
    
    func applyStyle() {
        guard let location = delegate?.location(for: self) else {
            // We can't calculate sunset or sunrise w/o a location so just apply the first style
            if let style = styles.first, currentStyleType != style.styleType {
                style.apply()
                currentStyleType = style.styleType
                currentStyle = style
                delegate?.styleManager(self, didApply: style)
                forceRefreshAppearance()
            }
            return
        }
        
        // Single style usage
        guard styles.count > 1 else {
            if let style = styles.first, currentStyleType != style.styleType {
                style.apply()
                currentStyleType = style.styleType
                currentStyle = style
                delegate?.styleManager(self, didApply: style)
                forceRefreshAppearance()
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
    
    private func postDidApplyStyleNotification(style: Style) {
        NotificationCenter.default.post(name: .styleManagerDidApplyStyle, object: self, userInfo: [
            StyleManagerNotificationUserInfoKey.styleKey: style,
            StyleManagerNotificationUserInfoKey.styleManagerKey: self
        ])
    }
    
    func forceRefreshAppearanceIfNeeded() {
        guard let location = delegate?.location(for: self) else { return }
        
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
    
    // workaround to refresh appearance by removing the view and then adding it again
    func forceRefreshAppearance() {
        if 
            let view = delegate?.styleManager(self, viewForApplying: currentStyle), 
            let superview = view.superview, 
            let index = superview.subviews.firstIndex(of: view) 
        {
            view.removeFromSuperview()
            superview.insertSubview(view, at: index)
        }
        
        delegate?.styleManagerDidRefreshAppearance(self)
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
        let currentSecondsFromMidnight = calendar.component(.hour, from: self) * 3600 + calendar.component(.minute, from: self) * 60 + calendar.component(.second, from: self)
        let sunriseSecondsFromMidnight = calendar.component(.hour, from: sunrise) * 3600 + calendar.component(.minute, from: sunrise) * 60 + calendar.component(.second, from: sunrise)
        let sunsetSecondsFromMidnight = calendar.component(.hour, from: sunset) * 3600 + calendar.component(.minute, from: sunset) * 60 + calendar.component(.second, from: sunset)
        return currentSecondsFromMidnight < sunriseSecondsFromMidnight || currentSecondsFromMidnight > sunsetSecondsFromMidnight
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
