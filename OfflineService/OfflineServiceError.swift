import Foundation

/**
 A error type returned when encountering errors in Offline Service (e.g. when listing available regions).
 */
public enum OfflineServiceError: LocalizedError {
    
    /**
     Generic error which occured in Offline Service.
     - parameter message: actual error message.
     */
    case genericError(message: String)
}
