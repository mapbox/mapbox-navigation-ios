/**
 Possible types of location related updates `NavigationViewportDataSource` can track.
 `ViewportDataSourceType` can also be used in custom implementations of classes, which conform to
 `ViewportDataSource`.
 */
public enum ViewportDataSourceType {
    
    /**
     Type, which is used to track raw location updates. In case if such type is used
     `NavigationViewportDataSource` will register `LocationConsumer` provided by Maps SDK to be able to
     continiously get location updates from it.
     */
    case raw
    
    /**
     Type, which is used to track location updates (snapped to road) during free drive navigation.
     In case if this type is used `NavigationViewportDataSource` will subscribe to
     `Notification.Name.passiveLocationDataSourceDidUpdate` notifications.
     */
    case passive
    
    /**
     Type, which is used to track location updates (snapped to road) during active guidance navigation.
     In case if this type is used `NavigationViewportDataSource` will subscribe to
     `Notification.Name.routeControllerProgressDidChange` notifications.
     */
    case active
}
