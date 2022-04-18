import UIKit

public typealias RoutesPreviewing = UIViewController & RoutesPreviewDataSource

public protocol RoutesPreviewDataSource: AnyObject {
    
    var routesPreviewOptions: RoutesPreviewOptions { get }
}
