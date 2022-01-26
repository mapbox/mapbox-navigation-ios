import MapboxDirections
import CarPlay

extension VisualInstruction {
    
    var laneComponents: [Component] {
        return components.filter { component -> Bool in
            if case .lane(indications: _, isUsable: _, preferredDirection: _) = component {
                return true
            }
            
            return false
        }
    }

    var containsLaneIndications: Bool {
        return laneComponents.count > 0
    }

    func maneuverImage(side: DrivingSide, color: UIColor, size: CGSize) -> UIImage? {
        let mv = ManeuverView()
        mv.frame = CGRect(origin: .zero, size: size)
        mv.primaryColor = color
        mv.backgroundColor = .clear
        mv.scale = UIScreen.main.scale
        mv.visualInstruction = self
        mv.drivingSide = side
        let image = mv.imageRepresentation
        return image
    }

    func laneImage(side: DrivingSide, indication: LaneIndication, maneuverDirection: ManeuverDirection?, isUsable: Bool, useableColor: UIColor, unuseableColor: UIColor, size: CGSize) -> UIImage? {
        let laneView = LaneView()
        laneView.frame = CGRect(origin: .zero, size: size)
        if isUsable {
            laneView.primaryColor = useableColor
            laneView.secondaryColor = unuseableColor
        } else {
            laneView.primaryColor = unuseableColor
            laneView.secondaryColor = unuseableColor
        }
        laneView.backgroundColor = .clear
        laneView.maneuverDirection = maneuverDirection
        laneView.indications = indication
        laneView.isValid = isUsable
        laneView.drivingSide = side
        let image = laneView.imageRepresentation

        return image
    }

    func lanesImage(side: DrivingSide, direction: ManeuverDirection?, useableColor: UIColor, unuseableColor: UIColor, size: CGSize, scale: CGFloat) -> UIImage? {
        let subimages = components.compactMap { (component) -> UIImage? in
            if case let .lane(indications: indications, isUsable: isUsable, preferredDirection: preferredDirection) = component {
                return laneImage(side: side, indication: indications, maneuverDirection: preferredDirection ?? direction, isUsable: isUsable, useableColor: useableColor, unuseableColor: unuseableColor, size: CGSize(width: size.height, height: size.height))
            } else {
                return nil
            }
        }

        guard subimages.count > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        for (index, image) in subimages.enumerated() {
            let areaSize = CGRect(x: CGFloat(index) * size.height, y: 0, width: size.height, height: size.height)
            image.draw(in: areaSize)
        }

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
    
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
        case _ where maneuverDirection == .uTurn:
            return side == .right
        case .takeRoundabout,
             .turnAtRoundabout,
             .takeRotary:
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
     - parameter instructionLabelType: Type, which is inherited from `InstructionLabel` and will be
     used for showing a visual instruction.
     
     - returns: An `NSAttributedString` with maneuver instructions.
     */
    @available(iOS 12.0, *)
    public func carPlayManeuverLabelAttributedText<T: InstructionLabel>(bounds: @escaping () -> (CGRect),
                                                                        shieldHeight: CGFloat,
                                                                        window: UIWindow?,
                                                                        instructionLabelType: T.Type? = nil) -> NSAttributedString? {
        let instructionLabel = T.init() 
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

    /// Returns a `CPImageSet` representing the maneuver lane configuration.
    @available(iOS 12.0, *)
    public func lanesImageSet(side: DrivingSide, direction: ManeuverDirection?, scale: CGFloat)  -> CPImageSet? {
        // create lanes visual banner
        // The `lanesImageMaxSize` size is an estimate of the CarPlay Lane Configuration View
        // The dimensions are specified in the CarPlay App Programming Guide - https://developer.apple.com/carplay/documentation/CarPlay-App-Programming-Guide.pdf#page=38
        let lanesImageMaxSize = CGSize(width: 120, height: 18)

        let lightUsableColor: UIColor
        let lightUnuseableColor: UIColor
        let darkUsableColor: UIColor
        let darkUnuseableColor: UIColor

        if #available(iOS 13.0, *) {
            let lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
            let darkTraitCollection = UITraitCollection(userInterfaceStyle: .dark)

            lightUsableColor = LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).primaryColor.resolvedColor(with: lightTraitCollection)
            lightUnuseableColor = LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).secondaryColor.resolvedColor(with: lightTraitCollection)

            darkUsableColor = LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).primaryColor.resolvedColor(with: darkTraitCollection)
            darkUnuseableColor = LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).secondaryColor.resolvedColor(with: darkTraitCollection)
        } else {
            // No light/dark traits are supported
            lightUsableColor = LaneView.appearance().primaryColor
            lightUnuseableColor = LaneView.appearance().secondaryColor

            darkUsableColor = LaneView.appearance().primaryColor
            darkUnuseableColor = LaneView.appearance().secondaryColor
        }

        var lightLanesImage = lanesImage(side: side, direction: direction, useableColor: lightUsableColor, unuseableColor: lightUnuseableColor, size: CGSize(width: CGFloat(laneComponents.count) * lanesImageMaxSize.height, height: lanesImageMaxSize.height), scale: scale)

        var darkLanesImage = lanesImage(side: side, direction: direction, useableColor: darkUsableColor, unuseableColor: darkUnuseableColor, size: CGSize(width: CGFloat(laneComponents.count) * lanesImageMaxSize.height, height: lanesImageMaxSize.height), scale: scale)

        if let image = lightLanesImage, let darkImage = darkLanesImage, image.size.width > lanesImageMaxSize.width {
            let aspectRatio = lanesImageMaxSize.width / image.size.width
            let scaledSize = CGSize(width: lanesImageMaxSize.width, height: lanesImageMaxSize.height * aspectRatio)
            lightLanesImage = image.scaled(to: scaledSize)
            darkLanesImage = darkImage.scaled(to: scaledSize)
        }
        if let image = lightLanesImage, let darkImage = darkLanesImage {
            return CPImageSet(lightContentImage: image, darkContentImage: darkImage)
        }
        return nil
    }
}
