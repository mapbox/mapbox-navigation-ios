import XCTest

extension XCTestCase {
    /// Adds an expectation which is fullfilled when `predicate` returns true.
    @discardableResult
    public func expectation(description: String? = nil, for predicate: @escaping () -> Bool) -> XCTestExpectation {
        let predicate = NSPredicate { _, _ in
            predicate()
        }
        let addedExpectation = expectation(for: predicate, evaluatedWith: nil, handler: nil)
        if let description = description {
            addedExpectation.expectationDescription = description
        }
        return addedExpectation
    }
}
