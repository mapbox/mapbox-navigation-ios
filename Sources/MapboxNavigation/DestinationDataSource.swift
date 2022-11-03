import UIKit

/**
 A protocol, that allows to provide destination information.
 
 `Banner` instances should conform to this protocol, to provide the options that are required
 for the destination presentation in the `PreviewViewController`.
 
 By default Mapbox Navigation SDK provides `DestinationPreviewViewController` that conforms to this
 protocol and allows to present banner that shows final destination related information.
 */
public protocol DestinationDataSource: AnyObject {
    
    /**
     Options that are required to present destination information.
     */
    var destinationOptions: DestinationOptions { get }
}
