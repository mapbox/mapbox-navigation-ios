import UIKit
import CoreLocation
import MapboxCoreNavigation

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
    @available(*, deprecated, message: "All views appearance will be refreshed without the `UITextEffectsWindow`.")
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
    
    @available(*, deprecated, message: "All views appearance will be refreshed without the `UITextEffectsWindow`.")
    func styleManager(_ styleManager: StyleManager, viewForApplying currentStyle: Style?) -> UIView? {
        // Short-circuit refresh logic if the view hasn't yet loaded since we don't want the `self.view`
        // call to trigger `loadView`.
        if let viewController = self as? UIViewController,
           viewController.isViewLoaded {
            return viewController.view
        }
        
        return nil
    }
}
