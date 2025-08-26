import CarPlay

@_spi(MapboxInternal)
public protocol CarPlaySearchControllerInternalDelegate {
    func selectSuggestion(item: CPSelectableListItem, completion: @escaping () -> Void)
}
