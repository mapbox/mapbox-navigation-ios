import Foundation
@_implementationOnly import MapboxCommon_Private

extension Result {
    
    init(expected: Expected<AnyObject, AnyObject>) {
        if expected.isValue(), let value = expected.value {
            guard let typedValue = value as? Success else {
                preconditionFailure("Result value can't be constructed. Unknown expected value type.")
            }
            self = .success(typedValue)
        } else if expected.isError(), let error = expected.error {
            guard let typedError = error as? Failure else {
                preconditionFailure("Result error can't be constructed. Unknown expected error type.")
            }
            self = .failure(typedError)
        } else {
            preconditionFailure("Expected type is neither a value nor an error.")
        }
    }
}
