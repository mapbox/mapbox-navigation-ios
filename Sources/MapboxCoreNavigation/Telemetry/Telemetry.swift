import Foundation
@_implementationOnly import MapboxNavigationNative_Private

protocol NativeUserFeedbackHandle {
    func getMetadata() -> UserFeedbackMetadata
}

extension UserFeedbackHandle: NativeUserFeedbackHandle { }
