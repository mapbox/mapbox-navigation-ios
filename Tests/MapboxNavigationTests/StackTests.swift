import XCTest
@testable import MapboxNavigation

final class StackTests: XCTestCase {
    
    func testStackOperations() {
        var stack = Stack<Int>()
        XCTAssertEqual(stack.count, 0)
        
        let element = 1
        stack.push(element)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.peek(), element)
        
        let removedElement = stack.pop()
        XCTAssertEqual(removedElement, element)
        XCTAssertEqual(stack.count, 0)
        XCTAssertEqual(stack.pop(), nil)
    }
}
