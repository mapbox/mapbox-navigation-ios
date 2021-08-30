import Foundation
import XCTest
import TestHelper
@testable import MapboxNavigation

class CGPointTests: TestCase {
    
    func testDistanceBetweenPoints() {
        var firstPoint = CGPoint(x: 0.0, y: 0.0)
        var secondPoint = CGPoint(x: 0.0, y: 1.0)
        
        XCTAssertEqual(firstPoint.distance(to: secondPoint), 1.0, "Distances between points should be equal.")
        
        firstPoint = CGPoint(x: 10.0, y: 10.0)
        secondPoint = CGPoint(x: -10.0, y: -10.0)
        
        XCTAssertEqual(firstPoint.distance(to: secondPoint), 28.284271247461902, "Distances between points should be equal.")
    }
}
