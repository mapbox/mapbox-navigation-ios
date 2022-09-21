import UIKit

// :nodoc:
public typealias RoutesPreviewing = UIViewController & RoutesPreviewDataSource

// :nodoc:
public protocol RoutesPreviewDataSource: AnyObject {
    
    var routesPreviewOptions: RoutesPreviewOptions { get }
}
