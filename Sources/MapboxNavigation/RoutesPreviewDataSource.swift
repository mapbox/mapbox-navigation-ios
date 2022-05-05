import UIKit

@_spi(Experimental) public typealias RoutesPreviewing = UIViewController & RoutesPreviewDataSource

@_spi(Experimental) public protocol RoutesPreviewDataSource: AnyObject {
    
    var routesPreviewOptions: RoutesPreviewOptions { get }
}
