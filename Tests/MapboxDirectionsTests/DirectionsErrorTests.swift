import Foundation
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MapboxDirections

class DirectionsErrorTests: XCTestCase {
    func testFailureReasons() {
        XCTAssertNotNil(DirectionsError.noData.failureReason)
        XCTAssertNotNil(DirectionsError.invalidResponse(nil).failureReason)
        XCTAssertNotNil(DirectionsError.unableToRoute.failureReason)
        XCTAssertNotNil(DirectionsError.noMatches.failureReason)
        XCTAssertNotNil(DirectionsError.tooManyCoordinates.failureReason)
        XCTAssertNotNil(DirectionsError.unableToLocate.failureReason)
        XCTAssertNotNil(DirectionsError.profileNotFound.failureReason)
        XCTAssertNotNil(DirectionsError.requestTooLarge.failureReason)
        XCTAssertEqual(DirectionsError.invalidInput(message: nil).failureReason, nil)
        XCTAssertEqual(DirectionsError.invalidInput(message: "").failureReason, "")
        XCTAssertNotNil(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil)
                .failureReason
        )
        XCTAssertNotNil(DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil).failureReason)
    }

    func testRecoverySuggestions() {
        XCTAssertNil(DirectionsError.noData.recoverySuggestion)
        XCTAssertNil(DirectionsError.invalidResponse(nil).recoverySuggestion)
        XCTAssertNotNil(DirectionsError.unableToRoute.recoverySuggestion)
        XCTAssertNotNil(DirectionsError.noMatches.recoverySuggestion)
        XCTAssertNotNil(DirectionsError.tooManyCoordinates.recoverySuggestion)
        XCTAssertNotNil(DirectionsError.unableToLocate.recoverySuggestion)
        XCTAssertNotNil(DirectionsError.profileNotFound.recoverySuggestion)
        XCTAssertNotNil(DirectionsError.requestTooLarge.recoverySuggestion)
        XCTAssertNil(DirectionsError.invalidInput(message: nil).recoverySuggestion)
        XCTAssertNil(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil)
                .recoverySuggestion
        )
        XCTAssertNotNil(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: .distantFuture)
                .recoverySuggestion
        )
        XCTAssertNil(
            DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil)
                .recoverySuggestion
        )

        let underlyingError = NSError(
            domain: "com.example",
            code: 02134,
            userInfo: [NSLocalizedRecoverySuggestionErrorKey: "Try harder"]
        )
        XCTAssertEqual(
            DirectionsError.unknown(response: nil, underlying: underlyingError, code: nil, message: nil)
                .recoverySuggestion,
            "Try harder"
        )
    }

    func testEquality() {
        XCTAssertEqual(DirectionsError.noData, .noData)

        XCTAssertEqual(DirectionsError.invalidInput(message: nil), .invalidInput(message: nil))
        XCTAssertNotEqual(DirectionsError.invalidInput(message: nil), .invalidInput(message: ""))

        XCTAssertEqual(DirectionsError.invalidResponse(nil), .invalidResponse(nil))

        XCTAssertEqual(DirectionsError.unableToRoute, .unableToRoute)
        XCTAssertEqual(DirectionsError.noMatches, .noMatches)
        XCTAssertEqual(DirectionsError.tooManyCoordinates, .tooManyCoordinates)
        XCTAssertEqual(DirectionsError.unableToLocate, .unableToLocate)
        XCTAssertEqual(DirectionsError.profileNotFound, .profileNotFound)
        XCTAssertEqual(DirectionsError.requestTooLarge, .requestTooLarge)

        XCTAssertEqual(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil),
            .rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil),
            .rateLimited(rateLimitInterval: 0, rateLimit: nil, resetTime: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil),
            .rateLimited(rateLimitInterval: nil, rateLimit: 0, resetTime: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil),
            .rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: .distantPast)
        )

        enum BogusError: Error {
            case bug
        }

        XCTAssertEqual(
            DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil),
            .unknown(response: nil, underlying: nil, code: nil, message: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil),
            .unknown(response: nil, underlying: BogusError.bug, code: nil, message: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil),
            .unknown(response: nil, underlying: nil, code: "", message: nil)
        )
        XCTAssertNotEqual(
            DirectionsError.unknown(response: nil, underlying: nil, code: nil, message: nil),
            .unknown(response: nil, underlying: nil, code: nil, message: "")
        )

        XCTAssertNotEqual(DirectionsError.noData, .invalidResponse(nil))
        XCTAssertNotEqual(DirectionsError.noData, .unableToRoute)
        XCTAssertNotEqual(DirectionsError.noData, .noMatches)
        XCTAssertNotEqual(DirectionsError.noData, .tooManyCoordinates)
        XCTAssertNotEqual(DirectionsError.noData, .unableToLocate)
        XCTAssertNotEqual(DirectionsError.noData, .profileNotFound)
        XCTAssertNotEqual(DirectionsError.noData, .requestTooLarge)
        XCTAssertNotEqual(DirectionsError.noData, .invalidInput(message: nil))
        XCTAssertNotEqual(DirectionsError.noData, .rateLimited(rateLimitInterval: nil, rateLimit: nil, resetTime: nil))
        XCTAssertNotEqual(DirectionsError.noData, .unknown(response: nil, underlying: nil, code: nil, message: ""))
    }
}
