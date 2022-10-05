import UIKit

// :nodoc:
public typealias DestinationPreviewing = BannerPreviewing & DestinationDataSource

// :nodoc:
public protocol DestinationDataSource: AnyObject {
    
    var destinationOptions: DestinationOptions { get }
}
