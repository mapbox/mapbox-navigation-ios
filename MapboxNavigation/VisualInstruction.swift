import MapboxDirections
#if canImport(CarPlay)
import CarPlay
#endif

extension VisualInstruction {
    var laneComponents: [Component] {
        return components.filter { component -> Bool in
            if case VisualInstruction.Component.lane(indications: _, isUsable: _) = component {
                return true
            }
            return false
        }
    }
    
    func maneuverImage(side: DrivingSide, color: UIColor, size: CGSize) -> UIImage? {
        let mv = ManeuverView()
        mv.frame = CGRect(origin: .zero, size: size)
        mv.primaryColor = color
        mv.backgroundColor = .clear
        mv.scale = UIScreen.main.scale
        mv.visualInstruction = self
        let image = mv.imageRepresentation
        return shouldFlipImage(side: side) ? image?.withHorizontallyFlippedOrientation() : image
    }

#if canImport(CarPlay)
    /// Returns a `CPImageSet` representing the maneuver.
    @available(iOS 12.0, *)
    public func maneuverImageSet(side: DrivingSide) -> CPImageSet? {
        let colors: [UIColor] = [.black, .white]
        let blackAndWhiteManeuverIcons: [UIImage] = colors.compactMap { (color) in
            return maneuverImage(side: side, color: color, size: CGSize(width: 30, height: 30))
        }
        guard blackAndWhiteManeuverIcons.count == 2 else { return nil }
        return CPImageSet(lightContentImage: blackAndWhiteManeuverIcons[1], darkContentImage: blackAndWhiteManeuverIcons[0])
    }
    
    /// Returns whether the `VisualInstruction`’s maneuver image should be flipped according to the driving side.
    public func shouldFlipImage(side: DrivingSide) -> Bool {
        switch maneuverType ?? .turn {
        case .takeRoundabout,
             .turnAtRoundabout,
             .takeRotary,
             _ where maneuverDirection == .uTurn:
            return side == .left
        default:
            return [.left, .slightLeft, .sharpLeft].contains(maneuverDirection ?? .straightAhead)
        }
    }

    /**
     Glanceable instruction given the available space, appearance styling, and attachments.
     
     - parameter bounds: A closure that calculates the available bounds for the maneuver text.
     - parameter shieldHeight: The height of the shield.
     - parameter window: A `UIWindow` that holds the `UIAppearance` styling properties, preferably the CarPlay window.
     
     - returns: An `NSAttributedString` with maneuver instructions.
     */
    @available(iOS 12.0, *)
    public func carPlayManeuverLabelAttributedText(bounds: @escaping () -> (CGRect), shieldHeight: CGFloat, window: UIWindow?) -> NSAttributedString? {
        let instructionLabel = InstructionLabel()
        instructionLabel.availableBounds = bounds
        instructionLabel.shieldHeight = shieldHeight
        
        // Temporarily add the view to the view hierarchy for UIAppearance to work its magic.
        if let carWindow = window {
            carWindow.addSubview(instructionLabel)
            instructionLabel.instruction = self
            instructionLabel.removeFromSuperview()
        } else {
            instructionLabel.instruction = self
        }
        
        return instructionLabel.attributedText
    }
#endif
}
