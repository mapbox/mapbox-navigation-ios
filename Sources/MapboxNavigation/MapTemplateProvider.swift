import CarPlay
import os.log

@available(iOS 12.0, *)
class MapTemplateProvider: NSObject {
    private let logger: OSLog = .init(subsystem: "com.mapbox.navigation", category: "MapTemplateProvider")
    
    weak var delegate: MapTemplateProviderDelegate?
    
    func mapTemplate(forPreviewing trip: CPTrip,
                     traitCollection: UITraitCollection,
                     mapDelegate: CPMapTemplateDelegate) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        mapTemplate.mapDelegate = mapDelegate
        
        let currentActivity: CarPlayActivity = .previewing
        os_log("CarPlayActivity changed to previewing", log: logger, type: .debug)
        
        if let leadingButtons = delegate?.mapTemplateProvider(self,
                                                              mapTemplate: mapTemplate,
                                                              leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                                              for: currentActivity) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        if let trailingButtons = delegate?.mapTemplateProvider(self,
                                                               mapTemplate: mapTemplate,
                                                               trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                                               for: currentActivity) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        
        mapTemplate.userInfo = [
            CarPlayManager.currentActivityKey: currentActivity
        ]
        
        return mapTemplate
    }
    
    func createMapTemplate() -> CPMapTemplate {
        return CPMapTemplate()
    }
}
