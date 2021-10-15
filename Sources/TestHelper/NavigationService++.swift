import Foundation
import MapboxCoreNavigation

extension NavigationService {
    public func waitUnitInitialized() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }
}
