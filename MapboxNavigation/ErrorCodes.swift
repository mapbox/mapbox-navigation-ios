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
     An intruction interrupted another instruction.
     */
    case overlappingInstruction
    
    /**
     The audio player failed to play audio data.
     */
    case spokenInstructionAudioPlayerFailedToPlay
    
    /**
     The response did not include data
     */
    case noDataInSpokenInstructionResponse
    
    /**
     `UIBackgroundModes` missing from the app's plist.info.
     */
    case audioBackgroundModeMissing
}
