import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@objc(MBInstructionLabel)
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
                self?.attributedText = attributedText
                self?.imageDownloadCompletion?()
            }
            
            
            let presenter = InstructionPresenter(instruction, dataSource: self, imageRepository: imageRepository, downloadCompletion: update)
            
            let attributed = presenter.attributedText()
            attributedText = instructionDelegate?.label?(self, willPresent: instruction, as: attributed) ?? attributed
            instructionPresenter = presenter
        }
    }

    private var instructionPresenter: InstructionPresenter?
}

/**
 The `VoiceControllerDelegate` protocol defines a method that allows an object to customize presented visual instructions.
 */
@objc(MBVisualInstructionDelegate)
public protocol VisualInstructionDelegate: class {
    
    /**
     Called when an InstructionLabel will present a visual instruction.
     
     - parameter label: The label that the instruction will be presented on.
     - parameter instruction: the `VisualInstruction` that will be presented.
     - parameter presented: the formatted string that is provided by the instruction presenter
     - returns: optionally, a customized NSAttributedString that will be presented instead of the default, or if nil, the default behavior will be used.
     */
    @objc(label:willPresentVisualInstruction:asAttributedString:)
    optional func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString?
}
