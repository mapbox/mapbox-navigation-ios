import Foundation
import MapboxCoreNavigation

extension NavigationMapView: NavigatorAlternativesStoreObserver {
    public func alternativesStore(_ store: NavigatorAlternativesStore, didReportNewAlternatives: IndexSet, removedAlternatives: [AlternativeRoute]) {
        // get routes
        // draw alternatives + trim common part
        // hide removed
        show(store.alternatives)
    }
    
    public func alternativesStore(_: NavigatorAlternativesStore, didFailToUpdateAlternatives: AlternativeRouteError) {
        // do nothing?
        // or remove alternatives?
    }
}
