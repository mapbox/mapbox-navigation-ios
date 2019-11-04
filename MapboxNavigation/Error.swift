import Foundation
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVKit

public enum SpeechRequestFailureReason: String {
    case noData, apiError
}

public enum SpeechFailureAction: String {
    case mix, duck, unduck, play
}

public enum SpeechEngine {
    case api(_: SpeechSynthesizer?)
    case native(_: AVSpeechSynthesizer)
    case unknown(_: Any)
}

public enum SpeechError: LocalizedError {
    case apiRequestFailed(instruction: SpokenInstruction, options: SpeechOptions, reason: SpeechRequestFailureReason, underlying: Error?)
    case unableToControlAudio(instruction: SpokenInstruction?, action: SpeechFailureAction, engine: SpeechEngine, underlying: Error?)
    case unableToInitalizePlayer(playerType: AVAudioPlayer.Type, instruction: SpokenInstruction, engine: SpeechEngine, underlying: Error)
    case undefinedSpeechLocale(instruction: SpokenInstruction, progress: RouteProgress)
    case unknown(instruction: SpokenInstruction, underlying: Error?)
}
