import MapboxDirections
import UIKit

/// :nodoc:
public protocol InstructionsCardCollectionDelegate: InstructionsCardContainerViewDelegate {
    
    /**
     Called when previewing the steps on the current route.
     
     Implementing this method will allow developers to move focus to the maneuver that corresponds to the step currently previewed.
     - parameter instructionsCardCollection: The instructions card collection instance.
     - parameter step: The step for the maneuver instruction in preview.
     */
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                    didPreview step: RouteStep)
    
    /**
     Offers the delegate the opportunity to customize the size of a prototype collection view cell
     per the associated trait collection.
     
     - parameter instructionsCardCollection: The instructions card collection instance.
     - parameter traitCollection: The traitCollection associated to the current container view controller.
     - returns: The preferred size of the cards for each cell in the instructions card collection.
     */
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                    cardSizeFor traitCollection: UITraitCollection) -> CGSize?
}

public extension InstructionsCardCollectionDelegate {
    
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                    didPreview step: RouteStep) {
        logUnimplemented(protocolType: InstructionsCardCollectionDelegate.self, level: .debug)
    }
    
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                    cardSizeFor traitCollection: UITraitCollection) -> CGSize? {
        logUnimplemented(protocolType: InstructionsCardCollectionDelegate.self, level: .info)
        return nil
    }
}
