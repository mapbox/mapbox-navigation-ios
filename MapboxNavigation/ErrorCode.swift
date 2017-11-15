import Foundation

/**
 Enum used for indicating the type of error occured while speaking an instruction.
 */
public enum MapboxNavigationError: Int {
    /**
     Default error.
     */
    case defaultError = -1
    
    /**
     The audio player failed to play audio data.
     */
    case spokenInstructionAudioPlayerFailedToPlay
    
    /**
     The response did not include data
     */
    case noDataInSpokenInstructionResponse
}
