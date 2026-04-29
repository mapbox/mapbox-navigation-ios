@testable import MapboxNavigationCore
import XCTest

final class UnimplementedLoggingTests: XCTestCase {
    class UnimplementedClass: UnimplementedLogging {
        func func1() {
            logUnimplemented(protocolType: self, level: .default)
        }

        func func2() {
            logUnimplemented(protocolType: self, level: .default)
        }

        func func3() {
            logUnimplemented(protocolType: self, level: .default)
        }
    }

    func testUnimplementedLoggingMultithreaded() {
        let iterations = 100
        let iterationsFinished = expectation(description: "Iterations finished")
        iterationsFinished.expectedFulfillmentCount = iterations
        let unimplementedClass = UnimplementedClass()
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            unimplementedClass.func1()
            unimplementedClass.func2()
            unimplementedClass.func3()
            iterationsFinished.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertEqual(_unimplementedLoggingState.countWarned(forTypeDescription: "UnimplementedClass"), 3)
    }

    func testUnimplementedLoggingPerformance() {
        measure {
            let iterations = 50
            for _ in 0..<iterations {
                let unimplementedClass = UnimplementedClass()
                unimplementedClass.func1()
                unimplementedClass.func2()
                unimplementedClass.func3()
            }
        }
    }
}
