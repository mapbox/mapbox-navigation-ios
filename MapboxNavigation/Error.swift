import Foundation
import MapboxCoreNavigation

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    public convenience init(localizedFailureReason: String, code: MapboxNavigationError = .defaultError) {
        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason,
            MBSpokenInstructionErrorCode: code
            ])
    }
}

