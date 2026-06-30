import CarPlay
import CarPlayTestHelper
import CoreLocation
import Foundation
@testable import MapboxDirections
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import UIKit
import XCTest

@MainActor
final class CarPlaySpeedLimitViewConfigurationTests: TestCase {
    func testSpeedLimitViewLayoutDefaultsInBrowsing() {
        let viewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )
        viewController.currentActivity = .browsing
        viewController.loadViewIfNeeded()

        assertSpeedLimitViewLayout(in: viewController, speedLimitView: viewController.speedLimitView)
    }

    func testSpeedLimitViewLayoutUsesMutcdTopPaddingInBrowsing() {
        let viewController = CarPlayMapViewController(
            core: navigationProvider.mapboxNavigation,
            styles: [StandardDayStyle(), StandardNightStyle()]
        )
        viewController.currentActivity = .browsing
        viewController.loadViewIfNeeded()

        viewController.speedLimitView.signStandard = .mutcd
        viewController.updateSpeedLimitViewLayout()

        assertSpeedLimitViewLayout(in: viewController, speedLimitView: viewController.speedLimitView)
    }

    func testSpeedLimitViewLayoutConfigurationUsesSignStandardSpecificPadding() {
        XCTAssertEqual(
            CarPlaySpeedLimitViewConfiguration.layout(for: nil),
            .init(size: CGSize(width: 36, height: 36), topPadding: 3, sidePadding: 3)
        )
        XCTAssertEqual(
            CarPlaySpeedLimitViewConfiguration.layout(for: .viennaConvention),
            .init(size: CGSize(width: 36, height: 36), topPadding: 3, sidePadding: 3)
        )
        XCTAssertEqual(
            CarPlaySpeedLimitViewConfiguration.layout(for: .mutcd),
            .init(size: CGSize(width: 36, height: 36), topPadding: 6, sidePadding: 3)
        )
    }

    func testSpeedLimitViewLayoutDefaultsInActiveNavigation() async {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        let routes = await Fixture.navigationRoutes(from: "route-with-banner-instructions", options: routeOptions)
        let mapTemplate = CPMapTemplate()
        mapTemplate.currentActivity = .navigating

        let viewController = CarPlayNavigationViewController(
            accessToken: .mockedAccessToken,
            core: navigationProvider.mapboxNavigation,
            mapTemplate: mapTemplate,
            interfaceController: FakeCPInterfaceController(context: #function),
            manager: CarPlayManager(navigationProvider: navigationProvider),
            styles: nil,
            navigationRoutes: routes
        )
        viewController.loadViewIfNeeded()

        assertSpeedLimitViewLayout(
            in: viewController,
            speedLimitView: viewController.speedLimitView,
            compassView: viewController.compassView
        )
    }

    func testSafeTrailingConstraintTriggerUsesBothHorizontalSafeAreaInsets() {
        XCTAssertFalse(
            CarPlayUtilities.usesSafeTrailingConstraint(for: .zero)
        )
        XCTAssertTrue(
            CarPlayUtilities.usesSafeTrailingConstraint(
                for: UIEdgeInsets(top: 0, left: 39, bottom: 0, right: 0)
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.usesSafeTrailingConstraint(
                for: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 39)
            )
        )
    }

    func testCarPlayControlsVisibilityUsesTopInsetAndHorizontalBaseline() {
        var baseline = CarPlaySafeAreaInsetsBaseline()
        baseline.update(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80))

        XCTAssertFalse(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80),
                baseline: baseline
            )
        )
        XCTAssertFalse(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 38, bottom: 0, right: 80),
                baseline: baseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 39, left: 0, bottom: 0, right: 80),
                baseline: baseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 39, bottom: 0, right: 80),
                baseline: baseline
            )
        )
    }

    func testCarPlayControlsVisibilityDetectsHorizontalControlsOnEitherSide() {
        var leftPanelBaseline = CarPlaySafeAreaInsetsBaseline()
        leftPanelBaseline.update(with: UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0))

        XCTAssertFalse(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0),
                baseline: leftPanelBaseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 39),
                baseline: leftPanelBaseline
            )
        )

        var rightPanelBaseline = CarPlaySafeAreaInsetsBaseline()
        rightPanelBaseline.update(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80))

        XCTAssertFalse(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80),
                baseline: rightPanelBaseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 39, bottom: 0, right: 80),
                baseline: rightPanelBaseline
            )
        )
    }

    func testCarPlayControlsVisibilityUsesSettledSafeAreaInsetsAsBaseline() {
        var baseline = CarPlaySafeAreaInsetsBaseline()
        baseline.update(with: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0))
        baseline.update(with: UIEdgeInsets(top: 44, left: 40, bottom: 0, right: 49))
        baseline.update(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 49))

        XCTAssertFalse(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 49),
                baseline: baseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 49),
                baseline: baseline
            )
        )
        XCTAssertTrue(
            CarPlayUtilities.carPlayControlsAreVisible(
                for: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 49),
                baseline: baseline
            )
        )
    }

    func testMapButtonsPlacementUsesPersistentReservedSide() {
        XCTAssertEqual(
            CarPlaySafeAreaInsetsBaseline().mapButtonsPlacement(for: .zero),
            .trailing
        )

        var leftPanelBaseline = CarPlaySafeAreaInsetsBaseline()
        leftPanelBaseline.update(with: UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0))
        XCTAssertEqual(
            leftPanelBaseline.mapButtonsPlacement(for: UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 0)),
            .trailing
        )

        var rightPanelBaseline = CarPlaySafeAreaInsetsBaseline()
        rightPanelBaseline.update(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80))
        XCTAssertEqual(
            rightPanelBaseline.mapButtonsPlacement(for: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 80)),
            .leading
        )
    }

    func testMapButtonsPlacementUsesCurrentInsetsBeforeSettledBaselineIsLearned() {
        var baseline = CarPlaySafeAreaInsetsBaseline()
        baseline.update(with: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0))

        XCTAssertEqual(
            baseline.mapButtonsPlacement(for: UIEdgeInsets(top: 44, left: 40, bottom: 0, right: 49)),
            .leading
        )
    }

    func testVisibilityRulesHideForExplicitCarPlayOverlaysAndNonFollowingCamera() {
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .browsing,
                cameraState: .following,
                areCarPlayControlsVisible: true,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .panningInBrowsingMode,
                cameraState: .following,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .panningInNavigationMode,
                cameraState: .following,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .previewing,
                cameraState: .following,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .navigating,
                cameraState: .overview,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .browsing,
                cameraState: .idle,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: true
            )
        )
        XCTAssertTrue(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .navigating,
                cameraState: .idle,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
        XCTAssertFalse(
            CarPlaySpeedLimitViewConfiguration.shouldHideSpeedLimitView(
                activity: .navigating,
                cameraState: .following,
                areCarPlayControlsVisible: false,
                isCameraRecenterOffered: false
            )
        )
    }

    func testSpeedLimitViewDrawabilityDoesNotDependOnContainerVisibility() {
        let containerView = UIView()
        let speedLimitView = SpeedLimitView()
        containerView.addSubview(speedLimitView)

        speedLimitView.signStandard = .mutcd
        speedLimitView.speedLimit = Measurement(value: 35, unit: UnitSpeed.milesPerHour)

        XCTAssertFalse(speedLimitView.isHidden)

        containerView.isHidden = true
        XCTAssertTrue(containerView.isHidden)
        XCTAssertFalse(speedLimitView.isHidden)

        containerView.isHidden = false
        XCTAssertFalse(containerView.isHidden)
        XCTAssertFalse(speedLimitView.isHidden)

        speedLimitView.speedLimit = nil
        XCTAssertTrue(speedLimitView.isHidden)
    }

    private func assertSpeedLimitViewLayout(
        in viewController: UIViewController,
        speedLimitView: SpeedLimitView,
        compassView: UIView? = nil
    ) {
        guard let speedLimitViewContainer = speedLimitView.superview else {
            XCTFail("SpeedLimitView should be wrapped in a container view.")
            return
        }
        let layout = CarPlaySpeedLimitViewConfiguration.layout(for: speedLimitView.signStandard)

        viewController.view.setNeedsUpdateConstraints()
        viewController.updateViewConstraints()

        XCTAssertEqual(
            speedLimitViewContainer.constraints.first { $0.firstAttribute == .width }?.constant,
            layout.size.width
        )
        XCTAssertEqual(
            speedLimitViewContainer.constraints.first { $0.firstAttribute == .height }?.constant,
            layout.size.height
        )

        let topConstraint = viewController.view.constraints.first {
            $0.firstItem === speedLimitViewContainer && $0.firstAttribute == .top
        }
        XCTAssertEqual(topConstraint?.constant, layout.topPadding)
        if let compassView {
            XCTAssertFalse((topConstraint?.secondItem as? UIView) === compassView)
        }

        let trailingConstraint = viewController.view.constraints.first {
            $0.firstItem === speedLimitViewContainer && $0.firstAttribute == .trailing && $0.isActive
        }
        XCTAssertEqual(trailingConstraint?.constant, -layout.sidePadding)
    }
}
