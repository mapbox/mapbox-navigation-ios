import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
open class InstructionLabel: StylableLabel, InstructionPresenterDataSource {
    @objc dynamic var roadShieldBlackColor: UIColor = .roadShieldBlackColor
    @objc dynamic var roadShieldBlueColor: UIColor = .roadShieldBlueColor
    @objc dynamic var roadShieldGreenColor: UIColor = .roadShieldGreenColor
    @objc dynamic var roadShieldRedColor: UIColor = .roadShieldRedColor
    @objc dynamic var roadShieldWhiteColor: UIColor = .roadShieldWhiteColor
    @objc dynamic var roadShieldYellowColor: UIColor = .roadShieldYellowColor
    @objc dynamic var roadShieldOrangeColor: UIColor = .roadShieldOrangeColor
    @objc dynamic var roadShieldDefaultColor: UIColor = .roadShieldDefaultColor
    
    typealias AvailableBoundsHandler = () -> (CGRect)
    var availableBounds: AvailableBoundsHandler!
    // This optional view can be used for calculating the available width when using
    // e.g. a UITableView or a UICollectionView where the frame is unknown before the cells are
    // displayed. The bounds of `InstructionLabel` will be used if this view is unset.
    weak var viewForAvailableBoundsCalculation: UIView?
    var shieldHeight: CGFloat = 30
    var imageDownloadCompletion: (() -> Void)?
    weak var instructionDelegate: VisualInstructionDelegate?
    var customTraitCollection: UITraitCollection?

    var spriteRepository: SpriteRepository = .shared

    var instruction: VisualInstruction? {
        didSet {
            updateLabelAttributedText()
        }
    }
    
    private func updateLabelAttributedText() {
        guard let instruction = instruction else {
            text = nil
            return
        }
        
        let update: InstructionPresenter.ShieldDownloadCompletion = { [weak self] (attributedText) in
            guard let self = self else { return }
            self.attributedText = attributedText
            self.imageDownloadCompletion?()
        }
        
        let presenter = InstructionPresenter(instruction,
                                             dataSource: self,
                                             spriteRepository: spriteRepository,
                                             traitCollection: customTraitCollection ?? traitCollection,
                                             downloadCompletion: update,
                                             isHighlighted: showHighlightedTextColor)
        let attributed = presenter.attributedText()
        attributedText = instructionDelegate?.label(self, willPresent: instruction, as: attributed) ?? attributed
    }

    open override func update() {
        updateLabelAttributedText()
        super.update()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
    
    func shieldColor(from textColor: String) -> UIColor {
        switch textColor {
        case "black":
            return roadShieldBlackColor
        case "blue":
            return roadShieldBlueColor
        case "green":
            return roadShieldGreenColor
        case "red":
            return roadShieldRedColor
        case "white":
            return roadShieldWhiteColor
        case "yellow":
            return roadShieldYellowColor
        case "orange":
            return roadShieldOrangeColor
        default:
            return roadShieldDefaultColor
        }
    }
}

/// :nodoc:
@objc(MBPrimaryLabel)
open class PrimaryLabel: InstructionLabel {
    
}

/// :nodoc:
@objc(MBSecondaryLabel)
open class SecondaryLabel: InstructionLabel {
    
}
