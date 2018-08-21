import XCTest
import MapboxNavigation


#if canImport(CarPlay)
import CarPlay

// For some reason XCTest bundles ignore @available annotations, and this gets run on iOS < 12 :(
// This is a bug in XCTest which will hopefully get fixed in an upcoming release.
// My radar/bug report was marked as a duplicate of another issue with a very low issue ID :(

@available(iOS 12.0, *)
class CarPlayManagerTests: XCTestCase {

    var manager: CarPlayManager?

    override func setUp() {
        manager = CarPlayManager.shared()
    }

    override func tearDown() {
        manager = nil
        CarPlayManager.resetSharedInstance()
    }

    func simulateCarPlayConnection() {
        let fakeInterfaceController = FakeCPInterfaceController(#function)
        let fakeWindow = CPWindow()

        manager?.application(UIApplication.shared, didConnectCarInterfaceController: fakeInterfaceController, to: fakeWindow)
    }

    // MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly
    // By default we should supply a search template with the Mapbox Geocoder hooked up (?)
    // we should also provide developers the opportunity to supply their own Favorites &/or History list.
    // We may wish to supply example implementations of these once we've rounded out the basic experience.

//    @available(iOS 12.0, *)
    func testWindowAndIntefaceControllerAreSetUpWithSearchAndExampleFavoritesWhenConnected() {
        // This line results in a warning, but is necessary as XCTest ignores the enclosing @available directive.
        // Not sure how to suppress the generated warning here, but this is currently needed for backwards compatibility
        guard #available(iOS 12, *) else { return }

        simulateCarPlayConnection()

        guard let fakeWindow = manager?.carWindow, let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let view = fakeWindow.rootViewController?.view
        XCTAssert((view?.isKind(of: NavigationMapView.self))!, "CarPlay window's root view should be a map view")

        let template: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(1, template.leadingNavigationBarButtons.count)
        XCTAssertEqual(1, template.trailingNavigationBarButtons.count)

        // simulate tap by invoking stored copy of handler
        let searchButton = template.leadingNavigationBarButtons.first!
        searchButton.handler!(searchButton)

        XCTAssert(fakeInterfaceController.topTemplate?.isKind(of: CPSearchTemplate.self) ?? false, "Expecting a search template to be on top")

        fakeInterfaceController.popTemplate(animated: false)

        let favoritesListButton = template.trailingNavigationBarButtons.last!
        favoritesListButton.handler!(favoritesListButton)

        XCTAssert(fakeInterfaceController.topTemplate?.isKind(of: CPListTemplate.self) ?? false, "Expecting a list template to be on top")
    }

    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfAvailable() {
        guard #available(iOS 12, *) else { return }

        let exampleDelegate = TestCarPlayManagerDelegate()
        exampleDelegate.leadingBarButtons = [CPBarButton(type: .text), CPBarButton(type: .text)]
        exampleDelegate.trailingBarButtons = [CPBarButton(type: .image), CPBarButton(type: .image)]

        manager?.delegate = exampleDelegate

        simulateCarPlayConnection()

        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let template: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(2, template.leadingNavigationBarButtons.count)
        XCTAssertEqual(2, template.trailingNavigationBarButtons.count)
    }

    //MARK: Upon disconnecting CarPlay, cleanup happens

}

//MARK: Test Objects / Classes.
//TODO: Extract into separate file at some point.

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {

    var leadingBarButtons: [CPBarButton]?
    var trailingBarButtons: [CPBarButton]?

    func leadingNavigationBarButtons(satisfying traitCollection: UITraitCollection) -> [CPBarButton]? {
        return leadingBarButtons
    }

    func trailingNavigationBarButtons(satisfying traitCollection: UITraitCollection) -> [CPBarButton]? {
        return trailingBarButtons
    }

}

@available(iOS 12.0, *)
class FakeCPInterfaceController: CPInterfaceController {

    /**
     * A simple stub which allows for instantiation of a CPInterfaceController for testing.
     * CPInterfaceController cannot be instantiated directly.
     */
    init(_ context: String) {
        self.context = context
    }

    let context: String
    var templateStack: [CPTemplate] = []

    override var debugDescription: String {
        return "CPInterfaceControllerSpy for \(context)"
    }

    // MARK - CPInterfaceController declarations and overrides

    //Uncomment and override as needed, if needed. At first inspection, some of these result in semaphore_wait_trap when invoked on an instance of CPInterfaceControllerSpy, but `rootTemplate` works as expected once set

    //TODO: solve for this duplication with introspection, à la Cedar::Doubles

//    weak open var delegate: CPInterfaceControllerDelegate?
//    open func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool)

    override open func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        templateStack.append(templateToPush)
    }

    override open func popTemplate(animated: Bool) {
        templateStack.removeLast()
    }

//    open func popToRootTemplate(animated: Bool)
//    open func pop(to targetTemplate: CPTemplate, animated: Bool)
//    open func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool)
//    open func dismissTemplate(animated: Bool)
//    open var presentedTemplate: CPTemplate? { get }
//    open var rootTemplate: CPTemplate { get }

    override open var topTemplate: CPTemplate? {
        get {
            return templateStack.last
        }
    }

    override open var templates: [CPTemplate] {
        get {
            return templateStack
        }
    }
}
#endif
