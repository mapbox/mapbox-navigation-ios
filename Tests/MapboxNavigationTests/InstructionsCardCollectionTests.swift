import XCTest
import MapboxDirections
import CoreLocation
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

/// :nodoc:
class InstructionsCardCollectionTests: TestCase {
    lazy var initialRouteResponse: RouteResponse = {
        return Fixture.routeResponse(from: jsonFileName, options: routeOptions)
    }()
    
    lazy var instructionsCardCollectionDataSource: (collection: InstructionsCardViewController, progress: RouteProgress, service: MapboxNavigationService, delegate: InstructionsCardCollectionDelegateSpy) = {
        let host = UIViewController(nibName: nil, bundle: nil)
        let container = UIView.forAutoLayout()
        let subject = InstructionsCardViewController(nibName: nil, bundle: nil)
        let delegate = InstructionsCardCollectionDelegateSpy()
        subject.cardCollectionDelegate = delegate
        
        host.view.addSubview(container)
        constrain(container, to: host.view)
        
        embed(parent: host, child: subject, in: container) { (parent, guidanceCard) -> [NSLayoutConstraint] in
            guidanceCard.view.translatesAutoresizingMaskIntoConstraints = false
            return guidanceCard.view.constraintsForPinning(to: container)
        }
        
        let fakeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        let fakeRoute = Fixture.route(from: "route-with-banner-instructions", options: fakeOptions)
        
        let service = MapboxNavigationService(routeResponse: initialRouteResponse, routeIndex: 0, routeOptions: fakeOptions, directions: DirectionsSpy(), simulating: .never)
        let routeProgress = RouteProgress(route: fakeRoute, options: fakeOptions)
        subject.routeProgress = routeProgress
        
        return (collection: subject, progress: routeProgress, service: service, delegate: delegate)
    }()
    
    @available(iOS 11.0, *)
    func testInstructionsCardCollectionScrollViewWillEndDragging_ShouldScrollToNextItem() {
        let subject = instructionsCardCollectionDataSource.collection
        let routeProgress = instructionsCardCollectionDataSource.progress
        let service = instructionsCardCollectionDataSource.service
        let instructionsCardCollectionSpy = instructionsCardCollectionDataSource.delegate
        
        let intersectionLocation = routeProgress.route.legs.first!.steps.first!.intersections!.first!.location
        let fakeLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        subject.navigationService(service, didUpdate: routeProgress, with: fakeLocation, rawLocation: fakeLocation)
        
        let activeCard = (subject.instructionCollectionView.dataSource!.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as! InstructionsCardCell).container!.instructionsCardView
        XCTAssertEqual(activeCard.step!.instructions, "Head north on 6th Avenue")
        
        let nextCard = (subject.instructionCollectionView.dataSource!.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 1, section: 0)) as! InstructionsCardCell).container!.instructionsCardView
        XCTAssertEqual(nextCard.step!.instructions, "Turn right onto Lincoln Way")
        
        /// Simulation: Scroll to the next card step instructions.
        let simulatedTargetContentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        simulatedTargetContentOffset.pointee = CGPoint(x: 0, y: 50)
        subject.scrollViewWillBeginDragging(subject.instructionCollectionView)
        subject.scrollViewWillEndDragging(subject.instructionCollectionView, withVelocity: CGPoint(x: 2.0, y: 0.0), targetContentOffset: simulatedTargetContentOffset)
        
        /// Validation: Preview step instructions should be equal to next card step instructions
        XCTAssertTrue(subject.isInPreview)
        let previewStep = instructionsCardCollectionSpy.step
        XCTAssertEqual(previewStep!.instructions, nextCard.step!.instructions)
    }
    
    @available(iOS 11.0, *)
    func testInstructionsCardCollectionScrollViewWillEndDragging_ShouldScrollToPreviousItem() {
        let subject = instructionsCardCollectionDataSource.collection
        let routeProgress = instructionsCardCollectionDataSource.progress
        let service = instructionsCardCollectionDataSource.service
        let instructionsCardCollectionSpy = instructionsCardCollectionDataSource.delegate

        let intersectionLocation = routeProgress.route.legs.first!.steps.first!.intersections!.first!.location
        let fakeLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        subject.navigationService(service, didUpdate: routeProgress, with: fakeLocation, rawLocation: fakeLocation)

        let activeCard = (subject.instructionCollectionView.dataSource!.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as! InstructionsCardCell).container!.instructionsCardView
        XCTAssertEqual(activeCard.step!.instructions, "Head north on 6th Avenue")

        let nextCard = (subject.instructionCollectionView.dataSource!.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 1, section: 0)) as! InstructionsCardCell).container!.instructionsCardView
        XCTAssertEqual(nextCard.step!.instructions, "Turn right onto Lincoln Way")

        /// Simulation: Scroll to the previous card step instructions.
        let simulatedTargetContentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        simulatedTargetContentOffset.pointee = CGPoint(x: 0, y: 50)
        subject.scrollViewWillBeginDragging(subject.instructionCollectionView)
        subject.scrollViewWillEndDragging(subject.instructionCollectionView, withVelocity: CGPoint(x: 2.0, y: 0.0), targetContentOffset: simulatedTargetContentOffset)

        /// Validation: Preview step instructions should be equal to next card step instructions
        XCTAssertTrue(subject.isInPreview)
        var previewStep = instructionsCardCollectionSpy.step
        XCTAssertEqual(previewStep!.instructions, "Turn right onto Lincoln Way")

        /// Validation: Preview step instructions should be equal to first card step instructions
        subject.scrollViewWillBeginDragging(subject.instructionCollectionView)
        subject.scrollViewWillEndDragging(subject.instructionCollectionView, withVelocity: CGPoint(x: -2.0, y: 0.0), targetContentOffset: simulatedTargetContentOffset)
        previewStep = instructionsCardCollectionSpy.step
        XCTAssertEqual(previewStep!.instructions, "Head north on 6th Avenue")
    }
    
    func testInstructionsCardCollectionScrollViewWillEndDragging_ScrollLessThanThresholdShouldNotScroll() {
        let subject = instructionsCardCollectionDataSource.collection
        let routeProgress = instructionsCardCollectionDataSource.progress
        let service = instructionsCardCollectionDataSource.service
        let instructionsCardCollectionSpy = instructionsCardCollectionDataSource.delegate

        let intersectionLocation = routeProgress.route.legs.first!.steps.first!.intersections!.first!.location
        let fakeLocation = CLLocation(latitude: intersectionLocation.latitude, longitude: intersectionLocation.longitude)
        subject.navigationService(service, didUpdate: routeProgress, with: fakeLocation, rawLocation: fakeLocation)

        let activeCard = (subject.instructionCollectionView.dataSource!.collectionView(subject.instructionCollectionView, cellForItemAt: IndexPath(row: 0, section: 0)) as! InstructionsCardCell).container!.instructionsCardView
        XCTAssertEqual(activeCard.step!.instructions, "Head north on 6th Avenue")

        /// Simulation: Attempt to scroll to the next card step instructions.
        let simulatedTargetContentOffset = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        simulatedTargetContentOffset.pointee = CGPoint(x: 0, y: 50)
        subject.scrollViewWillBeginDragging(subject.instructionCollectionView)
        subject.scrollViewWillEndDragging(subject.instructionCollectionView, withVelocity: CGPoint(x: 0.0, y: 0.0), targetContentOffset: simulatedTargetContentOffset)

        XCTAssertTrue(subject.isInPreview)
        XCTAssertNotNil(instructionsCardCollectionSpy.step)
    }
}

/// :nodoc:
class InstructionsCardCollectionDelegateSpy: NSObject, InstructionsCardCollectionDelegate {
    var step: RouteStep? = nil
    
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController, didPreview step: RouteStep) {
        self.step = step
    }
}
