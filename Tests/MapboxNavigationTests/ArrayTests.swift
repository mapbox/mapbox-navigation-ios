import Foundation
import XCTest
@testable import MapboxNavigation

final class ArrayTests: XCTestCase {
    static let largePointsArray: [CGPoint] = {
        var points: [CGPoint] = []
        for _ in 0..<100000 {
            points.append(
                .init(
                    x: CGFloat.random(in: 0..<1000),
                    y: CGFloat.random(in: 0..<1000)
                )
            )
        }
        return points
    }()

    func testBoundingBoxPointsPerformance() {
        let points = Self.largePointsArray

        measure {
            _ = points.boundingBoxPoints
        }
    }
}

