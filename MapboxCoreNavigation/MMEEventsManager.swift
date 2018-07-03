import Polyline
import MapboxDirections
import AVFoundation
import MapboxMobileEvents


let SecondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20
let EventVersion = 8

extension MMEEventsManager {
    public static var unrated: Int { return -1 }
}

extension UIApplicationState {
    var telemetryString: String {
        get {
            switch self {
            case .active:
                return "Foreground"
            case .inactive:
                return "Inactive"
            case .background:
                return "Background"
            }
        }
    }
}

extension AVAudioSession {
    var audioType: String {
        if isOutputBluetooth() {
            return "bluetooth"
        }
        if isOutputHeadphones() {
            return "headphones"
        }
        if isOutputSpeaker() {
            return "speaker"
        }
        return "unknown"
    }
    
    func isOutputBluetooth() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputHeadphones() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortHeadphones, AVAudioSessionPortAirPlay, AVAudioSessionPortHDMI, AVAudioSessionPortLineOut].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputSpeaker() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBuiltInSpeaker, AVAudioSessionPortBuiltInReceiver].contains(output.portType) {
                return true
            }
        }
        return false
    }
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

