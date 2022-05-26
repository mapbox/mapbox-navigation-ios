import Foundation
import MapboxDirections
import MapboxNavigationNative

/**
 `AlternativeRoutesCenter` observer to track alternative routes updates.
 */
public protocol NavigatorAlternativesStoreDelegate: AnyObject {
    /**
     Called when center has detected a change in alternative routes list.
     
     - parameter center: `AlternativeRoutesCenter` reporting an update
     - parameter didReportNewAlternatives: Indicies within `AlternativeRoutesCenter.alternatives` array where new alternative routes are appended.
     - parameter removedAlternatives: Array of alternative routes which are no longer actual.
     */
    func alternativeRoutesCenter(_ center: AlternativeRoutesCenter, didReportNewAlternatives: IndexSet, removedAlternatives: [AlternativeRoute])
    
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
public class AlternativeRoutesCenter {
    
    var observers: [NavigatorAlternativesStoreDelegate] = []
    /// Array of known `AlternativeRoute`s.
    public private(set) var alternatives: [AlternativeRoute] = []
    /// The original route, relative to which all others are 'alternative'.
    public internal(set) var mainRoute: Route
    
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
        var removedRoutes: [AlternativeRoute] = []
        
        var updatedAlternatives = alternatives
        
        updatedAlternatives.removeAll {
            let willBeRemoved = removedIds.contains($0.id)
            if willBeRemoved {
                removedRoutes.append($0)
            }
            return willBeRemoved
        }
        
        let existingIds = Set(updatedAlternatives.map(\.id))
        let newAlternatives = routeAlternatives.filter {
            !existingIds.contains($0.id)
        }
        
        let lastIndex = updatedAlternatives.endIndex
        updatedAlternatives.append(contentsOf: newAlternatives.compactMap {
            AlternativeRoute(mainRoute: mainRoute,
                             alternativeRoute: $0)
        })
        let newIndices = IndexSet(integersIn: lastIndex..<updatedAlternatives.endIndex)
        
        alternatives = updatedAlternatives
        observers.forEach {
            $0.alternativeRoutesCenter(self,
                                       didReportNewAlternatives: newIndices,
                                       removedAlternatives: removedRoutes)
        }
    }
    
    @objc private func navigatorDidFailToChangeAlternativeRoutes(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo[Navigator.NotificationUserInfoKey.messageKey] as? String else {
            return
        }
        
        let error = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: message)
        observers.forEach {
            $0.alternativeRoutesCenter(self,
                                       didFailToUpdateAlternatives: error)
        }
    }
    
    /// Subscribes an observer for alternative routes updates.
    ///
    /// New observer will be instantly updated with existing `AlternativeRoute`s if any.
    public func addObserver(_ observer: NavigatorAlternativesStoreDelegate) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
            
            if !alternatives.isEmpty {
                observer.alternativeRoutesCenter(self,
                                                 didReportNewAlternatives: IndexSet(alternatives.indices),
                                                 removedAlternatives: [])
            }
        }
    }
    
    /// Unsubscribes an observer from alternative routes updates.
    public func removeObserver(_ observer: NavigatorAlternativesStoreDelegate) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }
}

/// Error type, describing the reason alternative routes failed to update.
public enum AlternativeRouteError: Swift.Error {
    /// The navigation engine has failed to provide alternatives.
    case failedToUpdateAlternativeRoutes(reason: String)
}
