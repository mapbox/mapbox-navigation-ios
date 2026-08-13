import CarPlay

@_spi(MapboxCarPlaySearchInternal)
public protocol CarPlaySearchControllerInternalDelegate {
    func selectSuggestion(item: CPSelectableListItem, completion: @escaping () -> Void)
}
