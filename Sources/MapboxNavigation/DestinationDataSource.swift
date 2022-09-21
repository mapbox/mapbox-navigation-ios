import UIKit

// :nodoc:
public typealias DestinationPreviewing = UIViewController & DestinationDataSource

// :nodoc:
public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
