import XCTest
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

/// :nodoc:
class InstructionsCardCollectionTests: XCTestCase {
    lazy var initialRoute: Route = {
        return Fixture.route(from: jsonFileName, options: routeOptions)
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
        
        let service = MapboxNavigationService(route: initialRoute, routeOptions: fakeOptions, directions: DirectionsSpy(), simulating: .never)
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
    
    func testVerifyInstructionsCardCustomStyle() {
        let instructionsCardView = InstructionsCardView()
        XCTAssertTrue(instructionsCardView.style is DayInstructionsCardStyle)

        instructionsCardView.style = TestInstructionsCardStyle()
        XCTAssertTrue(instructionsCardView.style is TestInstructionsCardStyle)
    }
    
    func constrain(_ child: UIView, to parent: UIView) {
        let constraints = [
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: 30.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func embed(parent:UIViewController, child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: parent)
        parent.addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(parent, child) {
            parent.view.addConstraints(childConstraints)
        }
        child.didMove(toParent: parent)
    }
}

/// :nodoc:
class InstructionsCardCollectionDelegateSpy: NSObject, InstructionsCardCollectionDelegate {
    var step: RouteStep? = nil
    
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardViewController, didPreview step: RouteStep) {
        self.step = step
    }
}

/// :nodoc:
class TestInstructionsCardStyle: InstructionsCardStyle {
    var cornerRadius: CGFloat = 10.0
    var backgroundColor: UIColor = .purple
    var highlightedBackgroundColor: UIColor = .blue
    lazy var primaryLabelNormalFont: UIFont = {
        return UIFont.boldSystemFont(ofSize: 20.0)
    }()
    var primaryLabelTextColor: UIColor = .green
    var primaryLabelHighlightedTextColor: UIColor = .red
    var secondaryLabelNormalFont: UIFont = {
        return UIFont.systemFont(ofSize: 15.0)
    }()
    var secondaryLabelTextColor: UIColor = .darkGray
    var secondaryLabelHighlightedTextColor: UIColor = .gray
    lazy var distanceLabelNormalFont: UIFont = {
        return UIFont.systemFont(ofSize: 16.0)
    }()
    var distanceLabelValueTextColor: UIColor = .yellow
    var distanceLabelUnitTextColor: UIColor = .orange
    lazy var distanceLabelUnitFont: UIFont = {
        return UIFont.systemFont(ofSize: 20.0)
    }()
    lazy var distanceLabelValueFont: UIFont = {
        return UIFont.systemFont(ofSize: 12.0)
    }()
    var distanceLabelHighlightedTextColor: UIColor = .red
    var maneuverViewPrimaryColor: UIColor = .blue
    var maneuverViewSecondaryColor: UIColor = .clear
    var maneuverViewHighlightedColor: UIColor = .brown
    var maneuverViewSecondaryHighlightedColor: UIColor = .orange
    
    var nextBannerViewPrimaryColor: UIColor = .cardBlue
    var nextBannerViewSecondaryColor: UIColor = .cardLight
    var nextBannerInstructionLabelTextColor: UIColor = .cardDark
    var nextBannerInstructionHighlightedColor: UIColor = .cardLight
    var nextBannerInstructionSecondaryHighlightedColor: UIColor = .orange
    var lanesViewDefaultColor: UIColor = .cardBlue
    var lanesViewHighlightedColor: UIColor = .cardLight
    lazy var nextBannerInstructionLabelNormalFont: UIFont = {
        return CardFont.create(.regular, with: 14.0)
    }()
}
