import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents


let SecondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20
let EventVersion = 8

extension MMEEventsManager {
    public static var unrated: Int { return -1 }
}

extension UIDevice {
    @nonobjc var machine: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            return machineMirror.children.reduce("") { (identifier: String, element: Mirror.Child) in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        }
    }
}

extension RouteLegProgress {
    var stepDictionary: [String: Any] {
        get {
            return [
                "upcomingInstruction": upComingStep?.instructions ?? NSNull(),
                "upcomingType": upComingStep?.maneuverType.description ?? NSNull(),
                "upcomingModifier": upComingStep?.maneuverDirection.description ?? NSNull(),
                "upcomingName": upComingStep?.names?.joined(separator: ";") ?? NSNull(),
                "previousInstruction": currentStep.instructions,
                "previousType": currentStep.maneuverType.description,
                "previousModifier": currentStep.maneuverDirection.description,
                "previousName": currentStep.names?.joined(separator: ";") ?? NSNull(),
                "distance": Int(currentStep.distance),
                "duration": Int(currentStep.expectedTravelTime),
                "distanceRemaining": Int(currentStepProgress.distanceRemaining),
                "durationRemaining": Int(currentStepProgress.durationRemaining)
            ]
        }
    }
}

