import UIKit
import MapboxDirections
import MapboxCoreNavigation

/**
 The `VisualInstructionDelegate` protocol defines a method that allows an object to customize
 presented visual instructions.
 */
public protocol VisualInstructionDelegate: AnyObject, UnimplementedLogging {
    
    /**
     Called when an InstructionLabel will present a visual instruction.
     
     - parameter label: The label that the instruction will be presented on.
     - parameter instruction: The `VisualInstruction` that will be presented.
     - parameter presented: The formatted string that is provided by the instruction presenter
     - returns: Optionally, a customized NSAttributedString that will be presented instead
     of the default, or if nil, the default behavior will be used.
     */
    func label(_ label: InstructionLabel,
               willPresent instruction: VisualInstruction,
               as presented: NSAttributedString) -> NSAttributedString?
}

public extension VisualInstructionDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func label(_ label: InstructionLabel,
               willPresent instruction: VisualInstruction,
               as presented: NSAttributedString) -> NSAttributedString? {
        logUnimplemented(protocolType: VisualInstructionDelegate.self, level: .debug)
        return nil
    }
}
