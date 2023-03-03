import XCTest
@testable import TestHelper
@_spi(MapboxInternal) @testable import MapboxCoreNavigation
@_implementationOnly import MapboxNavigationNative_Private
import MapboxNavigationNative

final class FeedbackMetadataTests: TestCase {
    var feedbackMetadata: FeedbackMetadata!
    var feedbackMetadataWithNilCalculated: FeedbackMetadata!
    var feedbackMetadataWithNilScreenshot: FeedbackMetadata!

    var userFeedbackHandle: NativeUserFeedbackHandle!
    var userFeedbackMetadata: UserFeedbackMetadata!
    let screenshot = "screenshot string"

    override func setUp() {
        super.setUp()

        userFeedbackHandle = NativeUserFeedbackHandleSpy()
        let step = Step(distance: 1000,
                        distanceRemaining: 255.3,
                        duration: 330.5,
                        durationRemaining: 55.0,
                        upcomingName: "upcomingName",
                        upcomingType: "upcomingType",
                        upcomingModifier: "modifier",
                        upcomingInstruction: "instruction",
                        previousName: "previousName",
                        previousType: "previousType",
                        previousModifier: "previousModifier",
                        previousInstruction: "previousInstruction")
        let location1 = FixLocation(CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let location2 = FixLocation(CLLocation(latitude: 7.7, longitude: -100.0))
        userFeedbackMetadata = UserFeedbackMetadata(locationsBefore: [location1],
                                                    locationsAfter: [location2],
                                                    step: step)

        feedbackMetadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle,
                                            screenshot: screenshot,
                                            userFeedbackMetadata: userFeedbackMetadata)
        feedbackMetadataWithNilCalculated = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle,
                                                             screenshot: screenshot,
                                                             userFeedbackMetadata: nil)
        feedbackMetadataWithNilScreenshot = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle,
                                                             screenshot: nil,
                                                             userFeedbackMetadata: userFeedbackMetadata)
    }

    func testReturnUserMetadata() {
        XCTAssertEqual(feedbackMetadata.userFeedbackMetadata, userFeedbackMetadata)
        XCTAssertEqual(feedbackMetadataWithNilCalculated.userFeedbackMetadata, userFeedbackHandle.getMetadata())
    }

    func testCodable() {
        let encoded = try! JSONEncoder().encode(feedbackMetadata)
        let decoded = try! JSONDecoder().decode(FeedbackMetadata.self, from: encoded)

        XCTAssertEqual(decoded.userFeedbackMetadata?.isEqual(to: userFeedbackMetadata), true)
        XCTAssertEqual(decoded.screenshot, screenshot)
    }

    func testCodableIfNilScreenshot() {
        let encoded = try! JSONEncoder().encode(feedbackMetadataWithNilScreenshot)
        let decoded = try! JSONDecoder().decode(FeedbackMetadata.self, from: encoded)

        XCTAssertEqual(decoded.userFeedbackMetadata?.isEqual(to: userFeedbackMetadata), true)
        XCTAssertNil(decoded.screenshot)
    }

    func testCodableIfNilCalculated() {
        let encoded = try! JSONEncoder().encode(feedbackMetadataWithNilCalculated)
        let decoded = try! JSONDecoder().decode(FeedbackMetadata.self, from: encoded)

        XCTAssertEqual(decoded.userFeedbackMetadata?.isEqual(to: userFeedbackHandle.getMetadata()), true)
        XCTAssertEqual(decoded.screenshot, screenshot)
    }

    func testCodableIfNilStep() {
        let metadata = UserFeedbackMetadata(locationsBefore: userFeedbackMetadata.locationsBefore,
                                            locationsAfter: [],
                                            step: nil)
        let feedbackMetadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle,
                                                screenshot: screenshot,
                                                userFeedbackMetadata: metadata)
        let encoded = try! JSONEncoder().encode(feedbackMetadata)
        let decoded = try! JSONDecoder().decode(FeedbackMetadata.self, from: encoded)

        XCTAssertEqual(decoded.userFeedbackMetadata?.isEqual(to: metadata), true)
        XCTAssertEqual(decoded.screenshot, screenshot)
    }

    func testReturnContents() {
        let data = try! JSONEncoder().encode(feedbackMetadata)
        let decoded = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        let contents = feedbackMetadata.contents
        XCTAssertNotNil(contents)
        XCTAssertEqual(contents.keys, decoded?.keys)
    }

}

extension Step {
    func isEqual(to second: Step?) -> Bool {
        guard let second = second else { return false }
        return upcomingName == second.upcomingName &&
        upcomingType == second.upcomingType &&
        upcomingModifier == second.upcomingModifier &&
        upcomingInstruction == second.upcomingInstruction &&
        previousName == second.previousName &&
        previousType == second.previousType &&
        previousModifier == second.previousModifier &&
        previousInstruction == second.previousInstruction &&
        distance == second.distance &&
        distanceRemaining == second.distanceRemaining &&
        duration == second.duration &&
        durationRemaining == second.durationRemaining
    }
}

extension FixLocation {
    func isEqual(to second: FixLocation) -> Bool {
        return coordinate == second.coordinate &&
        monotonicTimestampNanoseconds == second.monotonicTimestampNanoseconds &&
        time == second.time &&
        speed == second.speed &&
        bearing == second.bearing &&
        altitude == second.altitude &&
        accuracyHorizontal == second.accuracyHorizontal &&
        provider == second.provider &&
        bearingAccuracy == second.bearingAccuracy &&
        speedAccuracy == second.speedAccuracy &&
        verticalAccuracy == second.verticalAccuracy &&
        isIsMock == second.isIsMock &&
        extras == second.extras
    }
}

extension Array where Element == FixLocation {
    func isEqual(to second: Array<Element>) -> Bool {
        guard self.count == second.count else { return false }
        return self.enumerated().filter { (i, element) in
            element.isEqual(to: second[i])
        }.isEmpty
    }
}

extension UserFeedbackMetadata {
    func isEqual(to second: UserFeedbackMetadata) -> Bool {
        return locationsAfter.isEqual(to: second.locationsAfter) &&
        locationsBefore.isEqual(to: second.locationsBefore) &&
        step?.isEqual(to: second.step) ?? (second.step == nil)
    }
}
