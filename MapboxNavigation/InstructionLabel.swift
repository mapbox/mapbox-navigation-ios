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
                return
            }
            instructionPresenter.instruction = instruction
            attributedText = instructionPresenter.attributedTextForLabel(self)
        }
    }

    private lazy var instructionPresenter: InstructionPresenter = {
        let presenter = InstructionPresenter()
        presenter.onShieldDownload = { [unowned self] (attributedText: NSAttributedString) in
            self.attributedText = attributedText
        }
        return presenter
    }()
}
