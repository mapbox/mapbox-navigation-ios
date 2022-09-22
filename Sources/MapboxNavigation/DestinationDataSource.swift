import UIKit

// :nodoc:
public typealias DestinationPreviewing = Previewing & DestinationDataSource

// :nodoc:
public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
