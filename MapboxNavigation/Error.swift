import Foundation
import MapboxCoreNavigation

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    convenience init(code: MBErrorCode, localizedFailureReason: String, spokenInstructionCode: SpokenInstructionErrorCode? = nil) {
        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason
            ])
    }
}

