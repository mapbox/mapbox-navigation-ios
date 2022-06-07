import Foundation
import MapboxDirections
import MapboxNavigationNative

/**
 `AlternativeRoutesCenter` observer to track alternative routes updates.
 */
protocol AlternativeRoutesCenterDelegate: AnyObject {
    /**
     Called when center has detected a change in alternative routes list.
     
     - parameter center: `AlternativeRoutesCenter` reporting an update
     - parameter didUpdateAlternatives: Updated alternative routes array.
     - parameter removedAlternatives: Array of alternative routes which are no longer actual.
     */
    func alternativeRoutesCenter(_ center: AlternativeRoutesCenter, didUpdateAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute])
    
    /**
     Called when center has failed to  change alternative routes list.
     
     - parameter center: `AlternativeRoutesCenter` reporting an update
     - parameter didFailToUpdateAlternatives: An error occured.
     */
    func alternativeRoutesCenter(_ center: AlternativeRoutesCenter, didFailToUpdateAlternatives: AlternativeRouteError)
}

/**
 Provides notifications and access to `AlternativeRoute`s found during navigation.
 */
class AlternativeRoutesCenter {
    
    weak var delegate: AlternativeRoutesCenterDelegate?
    /// Array of known `AlternativeRoute`s.
    private(set) var alternatives: [AlternativeRoute] = []
    /// The original route, relative to which all others are 'alternative'.
    var mainRoute: Route
    
    init(mainRoute: Route) {
        self.mainRoute = mainRoute
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigatorDidChangeAlternativeRoutes),
                                               name: .navigatorDidChangeAlternativeRoutes,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigatorDidFailToChangeAlternativeRoutes),
                                               name: .navigatorDidFailToChangeAlternativeRoutes,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func navigatorDidChangeAlternativeRoutes(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let routeAlternatives = userInfo[Navigator.NotificationUserInfoKey.alternativesListKey] as? [RouteAlternative],
              let removed = userInfo[Navigator.NotificationUserInfoKey.removedAlternativesKey] as? [RouteAlternative] else {
            return
        }
        
        let removedIds = Set(removed.map(\.id))
        let removedRoutes = alternatives.filter {
            removedIds.contains($0.id)
        }
        
        alternatives = routeAlternatives.compactMap {
            AlternativeRoute(mainRoute: mainRoute,
                             alternativeRoute: $0)
        }
        delegate?.alternativeRoutesCenter(self,
                                          didUpdateAlternatives: alternatives,
                                          removedAlternatives: removedRoutes)
    }
    
    @objc private func navigatorDidFailToChangeAlternativeRoutes(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo[Navigator.NotificationUserInfoKey.messageKey] as? String else {
            return
        }
        
        let error = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: message)
        delegate?.alternativeRoutesCenter(self,
                                          didFailToUpdateAlternatives: error)
    }
}

/// Error type, describing the reason alternative routes failed to update.
public enum AlternativeRouteError: Swift.Error {
    /// The navigation engine has failed to provide alternatives.
    case failedToUpdateAlternativeRoutes(reason: String)
}
