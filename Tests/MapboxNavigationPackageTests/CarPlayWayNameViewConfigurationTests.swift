@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import XCTest

final class CarPlayWayNameViewConfigurationTests: XCTestCase {
    func testFollowingCameraShowsWayNameDuringBrowsingAndNavigation() {
        XCTAssertFalse(
            CarPlayWayNameViewConfiguration.shouldHideWayNameView(
                activity: .browsing,
                cameraState: .following
            )
        )
        XCTAssertFalse(
            CarPlayWayNameViewConfiguration.shouldHideWayNameView(
                activity: .navigating,
                cameraState: .following
            )
        )
    }

    func testWayNameIsHiddenForPanningAndPreviewActivities() {
        for activity in [
            CarPlayActivity.panningInBrowsingMode,
            .panningInNavigationMode,
            .previewing,
        ] {
            XCTAssertTrue(
                CarPlayWayNameViewConfiguration.shouldHideWayNameView(
                    activity: activity,
                    cameraState: .following
                )
            )
        }
    }

    func testWayNameIsHiddenWhenCameraIsNotFollowing() {
        XCTAssertTrue(
            CarPlayWayNameViewConfiguration.shouldHideWayNameView(
                activity: .browsing,
                cameraState: .idle
            )
        )
        XCTAssertTrue(
            CarPlayWayNameViewConfiguration.shouldHideWayNameView(
                activity: .navigating,
                cameraState: .overview
            )
        )
    }
}
