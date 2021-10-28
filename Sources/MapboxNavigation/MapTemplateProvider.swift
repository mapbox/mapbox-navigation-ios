import CarPlay

@available(iOS 12.0, *)
class MapTemplateProvider: NSObject {
    
    weak var delegate: MapTemplateProviderDelegate?
    
    func mapTemplate(forPreviewing trip: CPTrip,
                     traitCollection: UITraitCollection,
                     mapDelegate: CPMapTemplateDelegate) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        mapTemplate.mapDelegate = mapDelegate
        
        let currentActivity: CarPlayActivity = .previewing
        
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
