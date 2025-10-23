import _MapboxNavigationHelpers
import MapboxDirections
import SwiftUI
import UIKit

struct LaneRenderer: Renderer {
    /// The frame in the canvas where image will be drawn.
    let frame: CGRect

    let size: CGSize

    /// The direction or directions of travel that the lane is reserved for.
    let indications: LaneIndication

    /// Denotes which of the `indications` is applicable to the current route when there is more than one.
    let maneuverDirection: ManeuverDirection?

    /// Denotes whether or not the user can use this lane to continue along the current route.
    let isUsable: Bool

    /// Indicates which side of the road cars and traffic flow.
    let drivingSide: DrivingSide

    /// Color of the maneuver direction (applied only when `LanesRendered.isUsable` is set to `true`). In case if
    /// `LanesRendered.showHighlightedColors` is set to `true` this value is not used,
    /// `LanesRendered.primaryColorHighlighted` is used instead.
    let primaryColor: UIColor

    /// Color of the directions that the lane is reserved for (except the one that is applicable to the current route).
    /// In case if `LanesRendered.showHighlightedColors` is set to `true` this value is not used,
    /// `LanesRendered.secondaryColorHighlighted` is used instead.
    let secondaryColor: UIColor

    /// Highlighted color of the directions that the lane is reserved for (except the one that is applicable to the
    /// current route).
    let primaryColorHighlighted: UIColor

    /// Highlighted color of the directions that the lane is reserved for (except the one that is applicable to the
    /// current route).
    let secondaryColorHighlighted: UIColor

    /// Controls whether highlighted colors (either `LanesRendered.primaryColorHighlighted` or
    /// `LanesRendered.secondaryColorHighlighted`) should be used.
    let showHighlightedColors: Bool

    var appropriatePrimaryColor: UIColor {
        if isUsable {
            return showHighlightedColors ? primaryColorHighlighted : primaryColor
        } else {
            return showHighlightedColors ? secondaryColorHighlighted : secondaryColor
        }
    }

    var appropriateSecondaryColor: UIColor {
        return showHighlightedColors ? secondaryColorHighlighted : secondaryColor
    }

    func draw(in context: CGContext, for traitCollection: UITraitCollection) {
        let resizing = LanesStyleKit.ResizingBehavior.aspectFit
        let appropriateColor = (
            isUsable ? appropriatePrimaryColor : appropriateSecondaryColor
        ).resolvedColor(with: traitCollection)
        let appropriateSecondaryColor = appropriateSecondaryColor.resolvedColor(with: traitCollection)
        let appropriatePrimaryColor = appropriatePrimaryColor.resolvedColor(with: traitCollection)

        let isFlipped = indications.dominantSide(
            maneuverDirection: maneuverDirection,
            drivingSide: drivingSide
        ) == .left

        guard let styleKitMethod = LanesStyleKit.styleKitMethod(
            lane: indications,
            maneuverDirection: maneuverDirection,
            drivingSide: drivingSide
        ) else {
            return
        }

        switch styleKitMethod {
        case .symmetricOff(let method):
            method(context, frame, resizing, appropriateColor, size)
        case .symmetricOn(let method):
            method(context, frame, resizing, appropriateColor, size)
        case .asymmetricOff(let method):
            method(
                context,
                frame,
                resizing,
                appropriateSecondaryColor.resolvedColor(with: traitCollection),
                size,
                isFlipped
            )
        case .asymmetricMixed(let method):
            method(context, frame, resizing, appropriatePrimaryColor, appropriateSecondaryColor, size, isFlipped)
        case .asymmetricOn(let method):
            method(context, frame, resizing, appropriatePrimaryColor, size, isFlipped)
        }
    }
}

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
        return !laneComponents.isEmpty
    }
}
