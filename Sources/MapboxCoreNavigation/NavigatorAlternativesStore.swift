import Foundation
import MapboxDirections
import MapboxNavigationNative


public protocol NavigatorAlternativesStoreObserver: AnyObject {
    func alternativesStore(_: NavigatorAlternativesStore, didReportNewAlternatives: IndexSet, removedAlternatives: [AlternativeRoute])
    func alternativesStore(_: NavigatorAlternativesStore, didFailToUpdateAlternatives: AlternativeRouteError)
}

public class NavigatorAlternativesStore {
    
    var observers: [NavigatorAlternativesStoreObserver] = []
    public private(set) var alternatives: [AlternativeRoute] = []
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
        
        let lastIndex = alternatives.endIndex
        alternatives = routeAlternatives.compactMap { AlternativeRoute(mainRoute: mainRoute,
                                                                       alternativeRoute: $0) }
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
    
    public func addObserver(_ observer: NavigatorAlternativesStoreObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
    }
    
    public func removeObserver(_ observer: NavigatorAlternativesStoreObserver) {
        if let index = observers.firstIndex(where: { $0 === observer }) {
            observers.remove(at: index)
        }
    }
}

public enum AlternativeRouteError: Swift.Error {
    case failedToUpdateAlternativeRoutes(reason: String)
}
