#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject, CPInterfaceControllerDelegate, CPSearchTemplateDelegate {

    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?

    private static var privateShared: CarPlayManager?

    public static func shared() -> CarPlayManager {
        if let shared = privateShared {
            return shared
        }
        let shared = CarPlayManager()
        privateShared = shared
        return shared
    }

    public static func resetSharedInstance() {
        privateShared = nil
    }

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        let mapTemplate = CPMapTemplate()

        let searchTemplate = CPSearchTemplate()
        searchTemplate.delegate = self

        //TODO: find image or use built-in style?
        let searchButton: CPBarButton = CPBarButton(type: .image) { button in
            interfaceController.pushTemplate(searchTemplate, animated: true)
        }
        let favoriteButton: CPBarButton = CPBarButton(type: .image) { button in
            // TODO: push Favorite Template
        }
        
        searchButton.image = UIImage(named: "search-monocle", in: .mapboxNavigation, compatibleWith: nil)
        favoriteButton.image = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)
        
        mapTemplate.leadingNavigationBarButtons = [searchButton]
        mapTemplate.trailingNavigationBarButtons = [favoriteButton]
        
        interfaceController.setRootTemplate(mapTemplate, animated: false)
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        self.interfaceController = nil
        carWindow?.isHidden = true
    }

    // MARK: CPSearchTemplateDelegate

    private func cannedResults() -> Array<(String, CLLocationCoordinate2D)> {
        let nobHill: (String, CLLocationCoordinate2D) = ("Nob Hill", CLLocationCoordinate2D(latitude: 37.7910, longitude: -122.4131))
        return [nobHill]
    }

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String, completionHandler: @escaping ([CPListItem]) -> Void) {
        // TODO: autocomplete immediately based on Favorites; calls to the search/geocoding client might require a minimum number of characters before firing
        // Results passed into this completionHandler will be displayed directly on the search template. Might want to limit the results set based on available screen real estate after testing.
    }

    public func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        // TODO: based on this callback we should push a CPListTemplate with a longer list of results.
        // Need to coordinate delegation of list item selection from this template vs items displayed directly in the search template
    }

    public func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem, completionHandler: @escaping () -> Void) {

    }

}
#endif
