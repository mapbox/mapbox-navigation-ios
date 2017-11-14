import Foundation


/**
 Custom Error code key used in returned in `voiceController(_:didInterrupt:with:)`.
 */
public let SpokenInstructionErrorCodeKey = "SpokenInstructionErrorCodeKey"

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    public convenience init(localizedFailureReason: String, detailedFailureReason: String, code: MapboxNavigationError = .defaultError) {
        self.init(domain: MGLErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason,
            SpokenInstructionErrorCodeKey: detailedFailureReason
            ])
    }
}

