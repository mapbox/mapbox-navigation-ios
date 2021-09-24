import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
open class InstructionLabel: StylableLabel, InstructionPresenterDataSource {
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    // This optional view can be used for calculating the available width when using e.g. a UITableView or a UICollectionView where the frame is unknown before the cells are displayed. The bounds of `InstructionLabel` will be used if this view is unset.
    weak var viewForAvailableBoundsCalculation: UIView?
    var shieldHeight: CGFloat = 30
    var imageRepository: ImageRepository = .shared
    var imageDownloadCompletion: (() -> Void)?
    weak var instructionDelegate: VisualInstructionDelegate?
    
    var instruction: VisualInstruction? {
        didSet {
            guard let instruction = instruction else {
                text = nil
                instructionPresenter = nil
                return
            }
            let update: InstructionPresenter.ShieldDownloadCompletion = { [weak self] (attributedText) in
                guard let self = self else { return }
                self.attributedText = attributedText
                self.imageDownloadCompletion?()
            }
            
            let presenter = InstructionPresenter(instruction,
                                                 dataSource: self,
                                                 imageRepository: imageRepository,
                                                 traitCollection: traitCollection,
                                                 downloadCompletion: update)
            
            let attributed = presenter.attributedText()
            attributedText = instructionDelegate?.label(self, willPresent: instruction, as: attributed) ?? attributed
            instructionPresenter = presenter
        }
    }

    open override func update() {
        let previousInstruction = instruction
        instruction = previousInstruction
        super.update()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
        imageRepository.resetImageCache(nil)
    }
    
    private var instructionPresenter: InstructionPresenter?
}

/**
 The `VisualInstructionDelegate` protocol defines a method that allows an object to customize presented visual instructions.
 */
public protocol VisualInstructionDelegate: AnyObject, UnimplementedLogging {
    /**
     Called when an InstructionLabel will present a visual instruction.
     
     - parameter label: The label that the instruction will be presented on.
     - parameter instruction: the `VisualInstruction` that will be presented.
     - parameter presented: the formatted string that is provided by the instruction presenter
     - returns: optionally, a customized NSAttributedString that will be presented instead of the default, or if nil, the default behavior will be used.
     */
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString?
}

public extension VisualInstructionDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        logUnimplemented(protocolType: InstructionLabel.self, level: .debug)
        return nil
    }
}
