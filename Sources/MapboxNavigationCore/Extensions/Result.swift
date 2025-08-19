import Foundation
import MapboxCommon_Private

extension Result {
    init?(expected: Expected<some Any, some Any>) {
        if expected.isValue(), let value = expected.value {
            guard let typedValue = value as? Success else {
                Log.info("Result value can't be constructed. Unknown expected value type.", category: .parsing)
                return nil
            }
            self = .success(typedValue)
        } else if expected.isError(), let error = expected.error {
            guard let typedError = error as? Failure else {
                Log.info("Result error can't be constructed. Unknown expected error type.", category: .parsing)
                return nil
            }
            self = .failure(typedError)
        } else {
            Log.info("Expected type is neither a value nor an error.", category: .parsing)
            return nil
        }
    }
}
