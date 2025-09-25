import CarPlay

class MapTemplateProvider: NSObject {
    weak var delegate: MapTemplateProviderDelegate?

    func previewMapTemplate(
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) -> CPMapTemplate {
        mapTemplate(forActivity: .previewing, traitCollection: traitCollection, mapDelegate: mapDelegate)
    }

    func mapTemplate(
        forActivity activity: CarPlayActivity,
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        mapTemplate.mapDelegate = mapDelegate

        let currentActivity: CarPlayActivity = activity

        if let leadingButtons = delegate?.mapTemplateProvider(
            self,
            mapTemplate: mapTemplate,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            for: currentActivity
        ) {
            mapTemplate.leadingNavigationBarButtons = leadingButtons
        }

        if let trailingButtons = delegate?.mapTemplateProvider(
            self,
            mapTemplate: mapTemplate,
            trailingNavigationBarButtonsCompatibleWith: traitCollection,
            for: currentActivity
        ) {
            mapTemplate.trailingNavigationBarButtons = trailingButtons
        }

        mapTemplate.currentActivity = activity

        return mapTemplate
    }

    func createMapTemplate() -> CPMapTemplate {
        return CPMapTemplate()
    }
}
