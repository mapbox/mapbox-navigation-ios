import UIKit
import CoreLocation
import Solar
import MapboxCoreNavigation
import CarPlay

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
    
    /**
     Trait collection that contains user interface idiom value, so that `StyleManager` can
     update style whenever it changes only for that specific user interface idiom (e.g. when changing
     style on CarPlay, style on iOS should remain unchanged).
     */
    var traitCollection: UITraitCollection!
    
    public init() {
        commonInit()
    }
    
    init(traitCollection: UITraitCollection = UITraitCollection(traitsFrom: [
        UITraitCollection(userInterfaceIdiom: .phone),
        UITraitCollection(userInterfaceIdiom: .pad),
    ])) {
        commonInit()
        self.traitCollection = traitCollection
    }
    
    func commonInit() {
        let phoneAndPadTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .phone),
            UITraitCollection(userInterfaceIdiom: .pad),
        ])
        
        traitCollection = phoneAndPadTraitCollection
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
            Log.error("Unable to get sunrise or sunset. Automatic style switching has been disabled.", category: .navigationUI)
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
                // Before applying actual style set trait collection that is used in `StyleManager`
                // so that style knows what platform should be updated (either iOS or CarPlay).
                style.traitCollection = traitCollection
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
    
    func forceRefreshAppearance() {
        // Use trait collection to detect what window should be updated.
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach {
                if let windowScene = $0 as? UIWindowScene,
                   windowScene.traitCollection.userInterfaceIdiom == .phone {
                    refreshAppearance(for: windowScene.windows)
                } else if let templateApplicationScene = $0 as? CPTemplateApplicationScene,
                          traitCollection.userInterfaceIdiom == .carPlay {
                    let window = templateApplicationScene.carWindow
                    refreshAppearance(for: [window])
                }
            }
        } else {
            refreshAppearance(for: UIApplication.shared.windows)
        }
        
        delegate?.styleManagerDidRefreshAppearance(self)
    }
    
    /**
     Workaround to refresh appearance by removing all views and then adding them again.
     UITextEffectsWindow will be created when system keyboard is shown and cannot be safely removed.
     */
    func refreshAppearance(for windows: [UIWindow]) {
        for window in windows {
            if window.isKind(of: NSClassFromString("UITextEffectsWindow") ?? NSString.classForCoder()) {
                continue
            }
            
            for view in window.subviews {
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
    }
}
