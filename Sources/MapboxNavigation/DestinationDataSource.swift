import UIKit

@_spi(Experimental) public typealias DestinationPreviewing = UIViewController & DestinationDataSource

@_spi(Experimental) public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
