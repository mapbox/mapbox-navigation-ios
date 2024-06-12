import MapboxDirections
import Turf

extension SpokenInstruction {
    public static func mock(
        distanceAlongStep: LocationDistance = 100,
        text: String = "Instruction",
        ssmlText: String = "Instruction"
    ) -> Self {
        self.init(distanceAlongStep: distanceAlongStep, text: text, ssmlText: ssmlText)
    }
}
