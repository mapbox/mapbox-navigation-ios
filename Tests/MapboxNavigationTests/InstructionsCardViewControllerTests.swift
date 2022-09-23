import XCTest
import CoreLocation
import MapboxDirections
import TestHelper
import MapboxCoreNavigation
@testable import MapboxNavigation

class InstructionsCardViewControllerTests: TestCase {
    
    lazy var initialRouteResponse: RouteResponse = {
        return Fixture.routeResponse(from: jsonFileName, options: routeOptions)
    }()
    
    var dataSource: (
        instructionsCardViewController: InstructionsCardViewController,
        routeProgress: RouteProgress,
        navigationService: MapboxNavigationService,
        instructionsCardCollectionDelegate: InstructionsCardCollectionDelegateMock
    )!

    override func setUp() {
        super.setUp()

        dataSource = {
            let hostViewController = UIViewController(nibName: nil, bundle: nil)
            let containerView = UIView.forAutoLayout()
            let instructionsCardViewController = InstructionsCardViewController(nibName: nil, bundle: nil)
            let instructionsCardCollectionDelegateMock = InstructionsCardCollectionDelegateMock()
            instructionsCardViewController.cardCollectionDelegate = instructionsCardCollectionDelegateMock
            
            hostViewController.view.addSubview(containerView)
            constrain(containerView, to: hostViewController.view)
            
            hostViewController.embed(instructionsCardViewController,
                                     in: containerView) { (parent, instructionsCard) -> [NSLayoutConstraint] in
                instructionsCard.view.translatesAutoresizingMaskIntoConstraints = false
                return instructionsCard.view.constraintsForPinning(to: containerView)
            }
            
            let navigationRouteOptions = NavigationRouteOptions(coordinates: [
                CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
            ])
            
            let route = Fixture.route(from: "route-with-banner-instructions",
                                      options: navigationRouteOptions)
            
            let navigationService = MapboxNavigationService(indexedRouteResponse: IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: jsonFileName, options: routeOptions),
                                                                                                       routeIndex: 0),
                                                            customRoutingProvider: MapboxRoutingProvider(.offline),
                                                            credentials: Fixture.credentials,
                                                            simulating: .never)
            let routeProgress = RouteProgress(route: route, options: navigationRouteOptions)
            instructionsCardViewController.routeProgress = routeProgress
            
            return (instructionsCardViewController: instructionsCardViewController,
                    routeProgress: routeProgress,
                    navigationService: navigationService,
                    instructionsCardCollectionDelegate: instructionsCardCollectionDelegateMock)
        }()
    }

    override func tearDown() {
        super.tearDown()
        
        dataSource = nil
    }

    func testShouldScrollToNextItem() {
        let instructionsCardViewController = dataSource.instructionsCardViewController
        let routeProgress = dataSource.routeProgress
        let navigationService = dataSource.navigationService
        let instructionsCardCollectionDelegate = dataSource.instructionsCardCollectionDelegate
        guard let instructionCollectionView = instructionsCardViewController.instructionCollectionView else {
            XCTFail("InstructionCollectionView should be valid.")
            return
        }
        
        guard let intersectionLocation = routeProgress.route.legs.first?.steps.first?.intersections?.first?.location else {
            XCTFail("Intersection location should be valid.")
            return
        }
        
        let location = CLLocation(latitude: intersectionLocation.latitude,
                                  longitude: intersectionLocation.longitude)
        
        instructionsCardViewController.navigationService(navigationService,
                                                         didUpdate: routeProgress,
                                                         with: location,
                                                         rawLocation: location)
        
        let currentIndexPath = IndexPath(row: 0, section: 0)
        guard let currentInstructionsCardCell = instructionCollectionView.dataSource?.collectionView(instructionCollectionView,
                                                                                                     cellForItemAt: currentIndexPath) as? InstructionsCardCell else {
            XCTFail("InstructionsCardCell should be valid.")
            return
        }
        instructionCollectionView.delegate?.collectionView?(instructionCollectionView,
                                                            willDisplay: currentInstructionsCardCell,
                                                            forItemAt: currentIndexPath)
        let currentInstructionsCardView = currentInstructionsCardCell.container.instructionsCardView
        XCTAssertEqual(currentInstructionsCardView.step?.instructions, "Head north on 6th Avenue")
        XCTAssertFalse(instructionsCardViewController.isInPreview, "InstructionsCardViewController should not be in preview.")
        
        let nextIndexPath = IndexPath(row: 1, section: 0)
        guard let nextInstructionsCardCell = instructionCollectionView.dataSource?.collectionView(instructionCollectionView,
                                                                                                  cellForItemAt: nextIndexPath) as? InstructionsCardCell else {
            XCTFail("InstructionsCardCell should be valid.")
            return
        }
        instructionCollectionView.delegate?.collectionView?(instructionCollectionView,
                                                            willDisplay: nextInstructionsCardCell,
                                                            forItemAt: nextIndexPath)
        let nextInstructionsCardView = nextInstructionsCardCell.container.instructionsCardView
        XCTAssertEqual(nextInstructionsCardView.step?.instructions, "Turn right onto Lincoln Way")
        
        // Scroll to the next card step instructions.
        let contentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        contentOffset.pointee = CGPoint(x: 0, y: 50)
        instructionsCardViewController.scrollViewWillBeginDragging(instructionsCardViewController.instructionCollectionView)
        instructionsCardViewController.scrollViewWillEndDragging(instructionsCardViewController.instructionCollectionView,
                                                                 withVelocity: CGPoint(x: 2.0, y: 0.0),
                                                                 targetContentOffset: contentOffset)
        
        // Preview step instructions should be equal to next card step instructions.
        XCTAssertTrue(instructionsCardViewController.isInPreview)
        let previewStep = instructionsCardCollectionDelegate.step
        XCTAssertEqual(previewStep?.instructions, nextInstructionsCardView.step?.instructions)
    }
    
    func testShouldScrollToPreviousItem() {
        let instructionsCardViewController = dataSource.instructionsCardViewController
        let routeProgress = dataSource.routeProgress
        let navigationService = dataSource.navigationService
        let instructionsCardCollectionDelegate = dataSource.instructionsCardCollectionDelegate
        guard let instructionCollectionView = instructionsCardViewController.instructionCollectionView else {
            XCTFail("InstructionCollectionView should be valid.")
            return
        }
        
        guard let intersectionLocation = routeProgress.route.legs.first?.steps.first?.intersections?.first?.location else {
            XCTFail("Intersection location should be valid.")
            return
        }
        
        let location = CLLocation(latitude: intersectionLocation.latitude,
                                  longitude: intersectionLocation.longitude)
        
        instructionsCardViewController.navigationService(navigationService,
                                                         didUpdate: routeProgress,
                                                         with: location,
                                                         rawLocation: location)
        
        let currentIndexPath = IndexPath(row: 0, section: 0)
        guard let currentInstructionsCardCell = instructionCollectionView.dataSource?.collectionView(instructionCollectionView,
                                                                                                     cellForItemAt: currentIndexPath) as? InstructionsCardCell else {
            XCTFail("InstructionsCardCell should be valid.")
            return
        }
        
        let currentInstructionsCardView = currentInstructionsCardCell.container.instructionsCardView
        instructionCollectionView.delegate?.collectionView?(instructionCollectionView,
                                                            willDisplay: currentInstructionsCardCell,
                                                            forItemAt: currentIndexPath)
        XCTAssertEqual(currentInstructionsCardView.step?.instructions, "Head north on 6th Avenue")
        XCTAssertFalse(instructionsCardViewController.isInPreview, "InstructionsCardViewController should not be in preview.")
        
        let nextIndexPath = IndexPath(row: 1, section: 0)
        guard let nextInstructionsCardCell = instructionCollectionView.dataSource?.collectionView(instructionCollectionView,
                                                                                                  cellForItemAt: nextIndexPath) as? InstructionsCardCell else {
            XCTFail("InstructionsCardCell should be valid.")
            return
        }
        instructionCollectionView.delegate?.collectionView?(instructionCollectionView,
                                                            willDisplay: nextInstructionsCardCell,
                                                            forItemAt: nextIndexPath)
        let nextInstructionsCardView = nextInstructionsCardCell.container.instructionsCardView
        XCTAssertEqual(nextInstructionsCardView.step?.instructions, "Turn right onto Lincoln Way")
        
        // Scroll to the previous card step instructions.
        let contentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        contentOffset.pointee = CGPoint(x: 0, y: 50)
        instructionsCardViewController.scrollViewWillBeginDragging(instructionCollectionView)
        instructionsCardViewController.scrollViewWillEndDragging(instructionCollectionView,
                                                                 withVelocity: CGPoint(x: 2.0, y: 0.0),
                                                                 targetContentOffset: contentOffset)
        
        // Preview step instructions should be equal to next card step instructions.
        XCTAssertTrue(instructionsCardViewController.isInPreview)
        
        var previewStep = instructionsCardCollectionDelegate.step
        XCTAssertEqual(previewStep?.instructions, "Turn right onto Lincoln Way")
        
        // Preview step instructions should be equal to first card step instructions.
        instructionsCardViewController.scrollViewWillBeginDragging(instructionCollectionView)
        instructionsCardViewController.scrollViewWillEndDragging(instructionCollectionView,
                                                                 withVelocity: CGPoint(x: -2.0, y: 0.0),
                                                                 targetContentOffset: contentOffset)
        previewStep = instructionsCardCollectionDelegate.step
        XCTAssertEqual(previewStep?.instructions, "Head north on 6th Avenue")
    }
    
    func testScrollLessThanThresholdShouldNotScroll() {
        let instructionsCardViewController = dataSource.instructionsCardViewController
        let routeProgress = dataSource.routeProgress
        let navigationService = dataSource.navigationService
        let instructionsCardCollectionDelegate = dataSource.instructionsCardCollectionDelegate
        guard let instructionCollectionView = instructionsCardViewController.instructionCollectionView else {
            XCTFail("InstructionCollectionView should be valid.")
            return
        }
        
        guard let intersectionLocation = routeProgress.route.legs.first?.steps.first?.intersections?.first?.location else {
            XCTFail("Intersection location should be valid.")
            return
        }
        
        let location = CLLocation(latitude: intersectionLocation.latitude,
                                  longitude: intersectionLocation.longitude)
        
        instructionsCardViewController.navigationService(navigationService,
                                                         didUpdate: routeProgress,
                                                         with: location,
                                                         rawLocation: location)
        
        let indexPath = IndexPath(row: 0, section: 0)
        guard let instructionsCardCell = instructionCollectionView.dataSource?.collectionView(instructionCollectionView,
                                                                                              cellForItemAt: indexPath) as? InstructionsCardCell else {
            XCTFail("InstructionsCardCell should be valid.")
            return
        }
        
        let instructionsCardView = instructionsCardCell.container.instructionsCardView
        instructionCollectionView.delegate?.collectionView?(instructionCollectionView,
                                                            willDisplay: instructionsCardCell,
                                                            forItemAt: indexPath)
        XCTAssertEqual(instructionsCardView.step?.instructions, "Head north on 6th Avenue")
        XCTAssertFalse(instructionsCardViewController.isInPreview, "InstructionsCardViewController should not be in preview.")
        
        // Attempt to scroll to the next card step instructions.
        let contentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        contentOffset.pointee = CGPoint(x: 0, y: 50)
        instructionsCardViewController.scrollViewWillBeginDragging(instructionCollectionView)
        instructionsCardViewController.scrollViewWillEndDragging(instructionCollectionView,
                                                                 withVelocity: CGPoint(x: 0.0, y: 0.0),
                                                                 targetContentOffset: contentOffset)
        
        XCTAssertTrue(instructionsCardViewController.isInPreview)
        XCTAssertNotNil(instructionsCardCollectionDelegate.step)
    }
}

class InstructionsCardCollectionDelegateMock: InstructionsCardCollectionDelegate {
    
    var step: RouteStep? = nil
    
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController,
                                    didPreview step: RouteStep) {
        self.step = step
    }
}
