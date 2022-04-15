import Foundation
import MapboxDirections
import MapboxNavigationNative

/**
 `NavigatorAlternativesStore` observer to track alternative routes updates.
 */
public protocol NavigatorAlternativesStoreObserver: AnyObject {
    /**
     Called when store has detected a change in alternative routes list.
     
     - parameter store: `NavigatorAlternativesStore` reporting an update
     - parameter didReportNewAlternatives: Indicies within `NavigatorAlternativesStore.alternatives` array where new alternative routes are appended.
     - parameter removedAlternatives: Array of alternative routes which are no longer actual.
     */
    func alternativesStore(_ store: NavigatorAlternativesStore, didReportNewAlternatives: IndexSet, removedAlternatives: [AlternativeRoute])
    
    /**
     Called when store has failed to  change alternative routes list.
     
     - parameter store: `NavigatorAlternativesStore` reporting an update
     - parameter didFailToUpdateAlternatives: An error occured.
     */
    func alternativesStore(_ store: NavigatorAlternativesStore, didFailToUpdateAlternatives: AlternativeRouteError)
}

/**
 Provides notifications and access to `AlternativeRoute`s found during navigation.
 */
public class NavigatorAlternativesStore {

    var observers: [NavigatorAlternativesStoreObserver] = []
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
                                               selector: #selector(navigatorFailToChangeAlternativeRoutes),
                                               name: .navigatorFailToChangeAlternativeRoutes,
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

        alternatives.removeAll {
            let willBeRemoved = removedIds.contains($0.id)
            if willBeRemoved {
                removedRoutes.append($0)
            }
            return willBeRemoved
        }

        let existingIds = Set(alternatives.map(\.id))
        let newAlternatives = routeAlternatives.filter {
            !existingIds.contains($0.id)
        }
        
        let lastIndex = alternatives.endIndex
        alternatives.append(contentsOf: newAlternatives.compactMap {
            AlternativeRoute(mainRoute: mainRoute,
                             alternativeRoute: $0)
        })
        let newIndices = IndexSet(integersIn: lastIndex..<alternatives.endIndex)
        
        observers.forEach {
            $0.alternativesStore(self,
                                 didReportNewAlternatives: newIndices,
                                 removedAlternatives: removedRoutes)
        }
    }

    @objc private func navigatorFailToChangeAlternativeRoutes(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo[Navigator.NotificationUserInfoKey.messageKey] as? String else {
                  return
              }

        let error = AlternativeRouteError.failedToUpdateAlternativeRoutes(reason: message)
        observers.forEach {
            $0.alternativesStore(self,
                                 didFailToUpdateAlternatives: error)
        }
    }

    /// Subscribes an observer for alternative routes updates.
    ///
    /// New observer will be instantly updated with existing `AlternativeRoute`s if any.
    public func addObserver(_ observer: NavigatorAlternativesStoreObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
            
            if !alternatives.isEmpty {
                
                observer.alternativesStore(self,
                                           didReportNewAlternatives: IndexSet(alternatives.indices),
                                           removedAlternatives: [])
            }
        }
    }

    /// Unsubscribes an observer from alternative routes updates.
    public func removeObserver(_ observer: NavigatorAlternativesStoreObserver) {
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
