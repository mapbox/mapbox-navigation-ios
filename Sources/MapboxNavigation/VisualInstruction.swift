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

    func maneuverViewImage(drivingSide: DrivingSide,
                           color: UIColor,
                           size: CGSize) -> UIImage? {
        let maneuverView = ManeuverView()
        maneuverView.frame = CGRect(origin: .zero, size: size)
        maneuverView.primaryColor = color
        maneuverView.backgroundColor = .clear
        maneuverView.scale = UIScreen.main.scale
        maneuverView.visualInstruction = self
        maneuverView.drivingSide = drivingSide
        
        return maneuverView.imageRepresentation
    }

    func laneViewImage(drivingSide: DrivingSide,
                       indication: LaneIndication,
                       maneuverDirection: ManeuverDirection?,
                       isUsable: Bool,
                       useableColor: UIColor,
                       unuseableColor: UIColor,
                       size: CGSize) -> UIImage? {
        let laneView = LaneView()
        laneView.frame = CGRect(origin: .zero, size: size)
        laneView.primaryColor = useableColor
        laneView.secondaryColor = unuseableColor
        laneView.backgroundColor = .clear
        laneView.maneuverDirection = maneuverDirection
        laneView.indications = indication
        laneView.isUsable = isUsable
        laneView.drivingSide = drivingSide
        
        return laneView.imageRepresentation
    }

    func lanesViewImage(drivingSide: DrivingSide,
                        direction: ManeuverDirection?,
                        useableColor: UIColor,
                        unuseableColor: UIColor,
                        size: CGSize,
                        scale: CGFloat) -> UIImage? {
        let subimages = components.compactMap { (component) -> UIImage? in
            if case let .lane(indications: indications, isUsable: isUsable, preferredDirection: preferredDirection) = component {
                return laneViewImage(drivingSide: drivingSide,
                                     indication: indications,
                                     maneuverDirection: preferredDirection ?? direction,
                                     isUsable: isUsable,
                                     useableColor: useableColor,
                                     unuseableColor: unuseableColor,
                                     size: CGSize(width: size.height, height: size.height))
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
    
    /**
     Returns a `CPImageSet` representing the maneuver.
     
     - parameter side: Driving side of the road cars and traffic flow.
     
     - returns: An image set with light and dark versions of an image.
     */
    @available(iOS 12.0, *)
    public func maneuverImageSet(side: DrivingSide) -> CPImageSet? {
        let colors: [UIColor] = [.black, .white]
        let maneuverIcons: [UIImage] = colors.compactMap { (color) in
            return maneuverViewImage(drivingSide: side,
                                     color: color,
                                     size: CGSize(width: 30, height: 30))
        }
        guard maneuverIcons.count == 2 else { return nil }
        
        // `CPImageSet` applies `lightContentImage` for dark appearance and `darkContentImage`
        // for light appearance, because of this white color is set for `lightContentImage` parameter.
        return CPImageSet(lightContentImage: maneuverIcons[1], darkContentImage: maneuverIcons[0])
    }
    
    /**
     Returns a `UIImage` representing the maneuver.
     
     - parameter side: Driving side of the road cars and traffic flow.
     - parameter userInterfaceStyle: The `UIUserInterfaceStyle` that the maneuver will be displayed in.
     
     - returns: A `UIImage` representing the maneuver.
     */
    @available(iOS 13.0, *)
    func maneuverImage(side: DrivingSide, userInterfaceStyle: UIUserInterfaceStyle) -> UIImage? {
        let color: UIColor
        switch userInterfaceStyle {
        case .unspecified:
            color = .black
        case .light:
            color = .black
        case .dark:
            color = .white
        @unknown default:
            Log.error("Error occured with unknown UIUserInterfaceStyle.", category: .navigationUI)
            return nil
        }
        return maneuverViewImage(drivingSide: side,
                                 color: color,
                                 size: CGSize(width: 30, height: 30))
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
     - parameter traitCollection: Custom `UITraitCollection` that is used to control color of
     the shield icons depending on various custom situations when actual trait collection is different
     (e.g. when driving through the tunnel).
     - parameter instructionLabelType: Type, which is inherited from `InstructionLabel` and will be
     used for showing a visual instruction.
     
     - returns: An `NSAttributedString` with maneuver instructions.
     */
    @available(iOS 12.0, *)
    public func carPlayManeuverLabelAttributedText<T: InstructionLabel>(bounds: @escaping () -> (CGRect),
                                                                        shieldHeight: CGFloat,
                                                                        window: UIWindow?,
                                                                        traitCollection: UITraitCollection? = nil,
                                                                        instructionLabelType: T.Type? = nil) -> NSAttributedString? {
        let instructionLabel = T.init()
        instructionLabel.customTraitCollection = traitCollection
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

    /**
     Returns a `CPImageSet` representing the maneuver lane configuration.
     
     - parameter side: Indicates which side of the road cars and traffic flow.
     - parameter direction: `ManeuverType` that contains directional information.
     - parameter scale: The natural scale factor associated with the CarPlay screen.
     
     - returns: Light and dark representations of an image that contains maneuver lane configuration.
     */
    @available(iOS 12.0, *)
    public func lanesImageSet(side: DrivingSide,
                              direction: ManeuverDirection?,
                              scale: CGFloat) -> CPImageSet? {
        // The `lanesImageMaxSize` size is an estimate of the CarPlay Lane Configuration View.
        // The dimensions are specified in the CarPlay App Programming Guide:
        // https://developer.apple.com/carplay/documentation/CarPlay-App-Programming-Guide.pdf#page=38
        let lanesImageMaxSize = CGSize(width: 120, height: 18)
        
        let lightTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .carPlay),
            UITraitCollection(userInterfaceStyle: .light)
        ])
        var lightLanesImage = lanesViewImage(drivingSide: side,
                                             direction: direction,
                                             useableColor: LaneView.appearance(for: lightTraitCollection).primaryColor,
                                             unuseableColor: LaneView.appearance(for: lightTraitCollection).secondaryColor,
                                             size: CGSize(width: CGFloat(laneComponents.count) * lanesImageMaxSize.height, height: lanesImageMaxSize.height),
                                             scale: scale)
        
        let darkTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .carPlay),
            UITraitCollection(userInterfaceStyle: .dark)
        ])
        var darkLanesImage = lanesViewImage(drivingSide: side,
                                            direction: direction,
                                            useableColor: LaneView.appearance(for: darkTraitCollection).primaryColor,
                                            unuseableColor: LaneView.appearance(for: darkTraitCollection).secondaryColor,
                                            size: CGSize(width: CGFloat(laneComponents.count) * lanesImageMaxSize.height, height: lanesImageMaxSize.height),
                                            scale: scale)
        
        if let lightImage = lightLanesImage,
           let darkImage = darkLanesImage,
           lightImage.size.width > lanesImageMaxSize.width {
            let aspectRatio = lanesImageMaxSize.width / lightImage.size.width
            let scaledSize = CGSize(width: lanesImageMaxSize.width, height: lanesImageMaxSize.height * aspectRatio)
            lightLanesImage = lightImage.scaled(to: scaledSize)
            darkLanesImage = darkImage.scaled(to: scaledSize)
        }
        
        if let lightImage = lightLanesImage,
           let darkImage = darkLanesImage {
            // `CPImageSet` applies `lightContentImage` for dark appearance and `d`arkContentImage`
            // for light appearance, because of this `darkImage` is set for `lightContentImage` parameter.
            return CPImageSet(lightContentImage: darkImage, darkContentImage: lightImage)
        }
        
        return nil
    }
}
