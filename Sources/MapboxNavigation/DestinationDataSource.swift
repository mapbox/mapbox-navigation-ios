import UIKit

public typealias DestinationPreviewing = UIViewController & DestinationDataSource

public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
