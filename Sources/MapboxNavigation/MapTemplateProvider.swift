import CarPlay

@available(iOS 12.0, *)
class MapTemplateProvider: NSObject {
    
    weak var delegate: MapTemplateProviderDelegate?
    
    func mapTemplate(forPreviewing trip: CPTrip,
                     traitCollection: UITraitCollection,
                     mapDelegate: CPMapTemplateDelegate) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        mapTemplate.mapDelegate = mapDelegate
        
        if let leadingButtons = delegate?.mapTemplateProvider(self,
                                                              mapTemplate: mapTemplate,
                                                              leadingNavigationBarButtonsCompatibleWith: traitCollection,
                                                              for: .previewing) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }
        
        if let trailingButtons = delegate?.mapTemplateProvider(self,
                                                               mapTemplate: mapTemplate,
                                                               trailingNavigationBarButtonsCompatibleWith: traitCollection,
                                                               for: .previewing) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }
        
        return mapTemplate
    }
    
    func createMapTemplate() -> CPMapTemplate {
        return CPMapTemplate()
    }
}
