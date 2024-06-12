import Foundation
import MapboxDirections
import MapboxNavigationCore

/// The ``InstructionsCardContainerViewDelegate`` protocol defines methods that allow an object to customize presented
/// visual instructions within the instructions container view.
public protocol InstructionsCardContainerViewDelegate: VisualInstructionDelegate, UnimplementedLogging {
    /// Called when the Primary Label will present a visual instruction.
    /// - Parameters:
    ///   -  primaryLabel: The custom primary label that the instruction will be presented on.
    ///   - instruction: The `VisualInstruction` that will be presented.
    ///   - presented: The formatted string that is provided by the instruction presenter.
    /// - Returns: Optionally, a customized NSAttributedString that will be presented instead of the default, or if nil,
    /// the default behavior will be used.
    func primaryLabel(
        _ primaryLabel: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString?

    /// Called when the Secondary Label will present a visual instruction.
    /// - Parameters:
    /// - secondaryLabel: The custom secondary label that the instruction will be presented on.
    /// - instruction: The `VisualInstruction` that will be presented.
    /// - presented: The formatted string that is provided by the instruction presenter
    /// - Returns: Optionally, a customized NSAttributedString that will be presented instead of the default, or if nil,
    /// the default behavior will be used.
    func secondaryLabel(
        _ secondaryLabel: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString?
}

extension InstructionsCardContainerViewDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func primaryLabel(
        _ primaryLabel: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString? {
        logUnimplemented(protocolType: InstructionsCardContainerViewDelegate.self, level: .info)
        return nil
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func secondaryLabel(
        _ secondaryLabel: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString? {
        logUnimplemented(protocolType: InstructionsCardContainerViewDelegate.self, level: .info)
        return nil
    }
}
