import MapboxDirections
import Turf

extension VisualInstructionBanner {
    public static func mock(
        maneuverType: ManeuverType = .arrive,
        maneuverDirection: ManeuverDirection = .left,
        primaryInstruction: [VisualInstruction.Component] = [],
        secondaryInstruction: [VisualInstruction.Component]? = nil,
        drivingSide: DrivingSide = .right,
        distanceAlongStep: LocationDistance = 100,
        primaryInstructionText: String = "Instruction",
        secondaryInstructionText: String = "Instruction"
    ) -> Self {
        let primary = VisualInstruction(
            text: primaryInstructionText,
            maneuverType: maneuverType,
            maneuverDirection: maneuverDirection,
            components: primaryInstruction
        )
        var secondary: VisualInstruction? = nil
        if let secondaryInstruction {
            secondary = VisualInstruction(
                text: secondaryInstructionText,
                maneuverType: maneuverType,
                maneuverDirection: maneuverDirection,
                components: secondaryInstruction
            )
        }

        return VisualInstructionBanner(
            distanceAlongStep: distanceAlongStep,
            primary: primary,
            secondary: secondary,
            tertiary: nil,
            quaternary: nil,
            drivingSide: drivingSide
        )
    }
}
