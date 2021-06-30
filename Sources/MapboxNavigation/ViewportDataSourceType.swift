/**
 Possible types of location related updates `NavigationViewportDataSource` can track.
 `ViewportDataSourceType` can also be used in custom implementations of classes, which conform to
 `ViewportDataSource`.
 */
public enum ViewportDataSourceType {
    
    /**
     If `.raw` type is specified `NavigationViewportDataSource` will register `LocationConsumer`
     provided by Maps SDK to be able to continuously get location updates from it.
     */
    case raw
    
    /**
     If `.passive` type is specified `NavigationViewportDataSource` will track location updates
     (snapped to road) during free drive navigation by subscribing to
     `Notification.Name.passiveLocationManagerDidUpdate` notifications.
     */
    case passive
    
    /**
     If `.active` type is specified `NavigationViewportDataSource` will track location updates
     (snapped to road) during active guidance navigation by subscribing to
     `Notification.Name.routeControllerProgressDidChange` notifications.
     */
    case active
}
