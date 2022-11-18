import UIKit

/**
 A protocol, that allows to provide routes related information.
 
 `Banner` instances should conform to this protocol, to provide the options that are required
 for the route(s) presentation in the `PreviewViewController`.
 
 By default Mapbox Navigation SDK provides `RoutePreviewViewController` that conforms to this
 protocol and allows to present banner that shows route related information (expected travel time,
 arrival time and duration).
 */
public protocol RoutePreviewDataSource: AnyObject {
    
    /**
     Options that are required to present route information.
     */
    var routePreviewOptions: RoutePreviewOptions { get }
}
