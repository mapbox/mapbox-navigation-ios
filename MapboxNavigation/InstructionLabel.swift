import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@objc(MBInstructionLabel)
open class InstructionLabel: StylableLabel {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    var shieldHeight: CGFloat = 30

    var instruction: [VisualInstructionComponent]? {
        didSet {
            guard let instruction = instruction else {
                text = nil
                instructionPresenter = nil
                return
            }
            let presenter = InstructionPresenter()
            presenter.instruction = instruction
            attributedText = presenter.attributedTextForLabel(self)
            presenter.onShieldDownload = { [weak self] (attributedText: NSAttributedString) in
                self?.attributedText = attributedText
            }
            instructionPresenter = presenter
        }
    }

    private var instructionPresenter: InstructionPresenter?
}
