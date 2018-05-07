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
            
            attributedText = presenter.attributedText()
            instructionPresenter = presenter
        }
    }

    private var instructionPresenter: InstructionPresenter?
}
