import Foundation
import MapboxCoreNavigation
import MapboxDirections

//extension NSError {
//    /**
//     Creates a custom `Error` object.
//     */
//    convenience init(code: MBErrorCode, localizedFailureReason: String, spokenInstructionCode: SpokenInstructionErrorCode? = nil) {
//        var userInfo = [
//            NSLocalizedFailureReasonErrorKey: localizedFailureReason
//        ]
//        if let spokenInstructionCode = spokenInstructionCode {
//            userInfo[SpokenInstructionErrorCodeKey] = String(spokenInstructionCode.rawValue)
//        }
//        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: userInfo)
//    }
//}

enum SpeechRequestFailureReason: String {
    case noData, apiError
}

enum SpeechError: LocalizedError {
    case apiRequestFailed(instruction: SpokenInstruction, reason: SpeechRequestFailureReason, underlying: Error?)
    case unknown(instruction: SpokenInstruction, underlying: Error)
}
