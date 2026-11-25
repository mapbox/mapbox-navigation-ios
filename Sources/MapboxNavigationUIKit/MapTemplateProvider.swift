import CarPlay

class MapTemplateProvider: NSObject {
    weak var delegate: MapTemplateProviderDelegate?

    func previewMapTemplate(
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) -> CPMapTemplate {
        mapTemplate(forActivity: .previewing, traitCollection: traitCollection, mapDelegate: mapDelegate)
    }

    func configurePreviewMapTemplate(
        _ mapTemplate: CPMapTemplate,
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) {
        configureMapTemplate(
            mapTemplate,
            forActivity: .previewing,
            traitCollection: traitCollection,
            mapDelegate: mapDelegate
        )
    }

    func mapTemplate(
        forActivity activity: CarPlayActivity,
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) -> CPMapTemplate {
        let mapTemplate = createMapTemplate()
        configureMapTemplate(
            mapTemplate,
            forActivity: activity,
            traitCollection: traitCollection,
            mapDelegate: mapDelegate
        )
        return mapTemplate
    }

    private func configureMapTemplate(
        _ mapTemplate: CPMapTemplate,
        forActivity activity: CarPlayActivity,
        traitCollection: UITraitCollection,
        mapDelegate: CPMapTemplateDelegate
    ) {
        mapTemplate.mapDelegate = mapDelegate

        let currentActivity: CarPlayActivity = activity

        mapTemplate.leadingNavigationBarButtons = delegate?.mapTemplateProvider(
            self,
            mapTemplate: mapTemplate,
            leadingNavigationBarButtonsCompatibleWith: traitCollection,
            for: currentActivity
        ) ?? []

        mapTemplate.trailingNavigationBarButtons = delegate?.mapTemplateProvider(
            self,
            mapTemplate: mapTemplate,
            trailingNavigationBarButtonsCompatibleWith: traitCollection,
            for: currentActivity
        ) ?? []

        mapTemplate.currentActivity = activity
    }

    func createMapTemplate() -> CPMapTemplate {
        return CPMapTemplate()
    }
}
