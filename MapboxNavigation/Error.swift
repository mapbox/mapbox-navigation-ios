import Foundation
import MapboxCoreNavigation

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    convenience init(code: MBErrorCode, localizedFailureReason: String, spokenInstructionCode: SpokenInstructionErrorCode? = nil) {
        var userInfo = [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason
        ]
        if let spokenInstructionCode = spokenInstructionCode {
            userInfo[MBSpokenInstructionErrorCodeKey] = String(spokenInstructionCode.rawValue)
        }
        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}
