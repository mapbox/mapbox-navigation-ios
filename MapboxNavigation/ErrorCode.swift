import Foundation

/**
 Enum used for indicating the type of error occured while speaking an instruction.
 */
public enum SpokenInstructionErrorCode: Int {
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
    case emptyAwsResponse
}

/**
 High level error type.
 */
public enum MBErrorCode: Int {
    /**
     Unknown type of error.
     */
    case unknown
    
    /**
     A spoken instruction failed to be read aloud.
     */
    case spokenInstructionFailed
}
