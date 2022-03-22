import UIKit
import CoreLocation
import Solar
import MapboxCoreNavigation

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
        if currentStyleType != styleType {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(timeOfDayChanged), object: nil)
        }
        
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
    
    // Workaround to refresh appearance by removing all views and then adding them again.
    // UITextEffectsWindow will be created when system keyboard is shown and cannot be safely removed.
    func forceRefreshAppearance() {
        for window in UIApplication.shared.windows {
            if !window.isKind(of: NSClassFromString("UITextEffectsWindow") ?? NSString.classForCoder()) {
                for view in window.subviews {
                    view.removeFromSuperview()
                    window.addSubview(view)
                }
            }
        }
        
        delegate?.styleManagerDidRefreshAppearance(self)
    }
}
