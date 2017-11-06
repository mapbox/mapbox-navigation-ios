import Foundation

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    public convenience init(localizedFailureReason: String, detailedFailureReason: String, code: MapboxNavigationError = .defaultError) {
        self.init(domain: MGLErrorDomain, code: code.rawValue, userInfo: [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason,
            NSLocalizedDescriptionKey: detailedFailureReason
            ])
    }
}

