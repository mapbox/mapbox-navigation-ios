import UIKit

// :nodoc:
public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
