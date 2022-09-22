import UIKit

// :nodoc:
public typealias RoutesPreviewing = Previewing & RoutesPreviewDataSource

// :nodoc:
public protocol RoutesPreviewDataSource: AnyObject {
    
    var routesPreviewOptions: RoutesPreviewOptions { get }
}
