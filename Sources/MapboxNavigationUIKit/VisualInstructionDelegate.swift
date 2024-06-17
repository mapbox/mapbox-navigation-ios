import MapboxDirections
import MapboxNavigationCore
import UIKit

/// The ``VisualInstructionDelegate`` protocol defines a method that allows an object to customize presented visual
/// instructions.
public protocol VisualInstructionDelegate: AnyObject, UnimplementedLogging {
    /// Called when an ``InstructionLabel`` will present a visual instruction.
    /// - Parameters:
    ///   - label: The label that the instruction will be presented on.
    ///   - instruction: The `VisualInstruction` that will be presented.
    ///   - presented: The formatted string that is provided by the instruction presenter
    /// - Returns: Optionally, a customized NSAttributedString that will be presented instead of the default, or if nil,
    /// the default behavior will be used.
    func label(
        _ label: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString?
}

extension VisualInstructionDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func label(
        _ label: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString? {
        logUnimplemented(protocolType: VisualInstructionDelegate.self, level: .debug)
        return nil
    }
}
