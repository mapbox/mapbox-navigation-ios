import Foundation
import MapboxCoreNavigation

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    convenience init(code: MBErrorCode, localizedFailureReason: String, spokenInstructionCode: SpokenInstructionErrorCode? = nil) {
        let userInfo = [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason
        ]
        if let spokenInstructionCode = spokenInstructionCode {
            userInfo[MBSpokenInstructionErrorCodeKey] = spokenInstructionCode
        }
        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

