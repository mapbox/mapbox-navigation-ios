import CarPlay

protocol MapTemplateProviderDelegate: AnyObject {
    func mapTemplateProvider(
        _ provider: MapTemplateProvider,
        mapTemplate: CPMapTemplate,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?

    func mapTemplateProvider(
        _ provider: MapTemplateProvider,
        mapTemplate: CPMapTemplate,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        for activity: CarPlayActivity
    ) -> [CPBarButton]?
}
