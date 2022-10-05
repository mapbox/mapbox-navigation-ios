import UIKit

// :nodoc:
public typealias RoutesPreviewing = BannerPreviewing & RoutesPreviewDataSource

// :nodoc:
public protocol RoutesPreviewDataSource: AnyObject {
    
    var routesPreviewOptions: RoutesPreviewOptions { get }
}
