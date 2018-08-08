import XCTest
import MapboxNavigation
import CarPlay

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

    //MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly

    // For some reason XCTest bundles ignore @available annotations, and this gets run on iOS < 12 :(
    // This is probably a bug in XCTest which will get fixed in the upcoming release.
    // TODO: open a radar
    func testWindowAndIntefaceControllerAreSetUpWhenConnected() {
        let interfaceControllerSpy = CPInterfaceControllerSpy(#function)
        let fakeWindow = CPWindow()

        manager?.application(UIApplication.shared, didConnectCarInterfaceController: interfaceControllerSpy, to: fakeWindow)

        let view = fakeWindow.rootViewController?.view
        XCTAssert((view?.isKind(of: NavigationMapView.self))!, "CarPlay window's root view should be a map view")

        let template: CPMapTemplate = interfaceControllerSpy.rootTemplate as! CPMapTemplate
        XCTAssertEqual(2, template.leadingNavigationBarButtons.count)
        XCTAssertEqual(2, template.trailingNavigationBarButtons.count)
    }

    //MARK: TODO:
    //MARK: Upon disconnecting CarPlay, cleanup happens (TBD)

}

@available(iOS 12.0, *)
class CPInterfaceControllerSpy: CPInterfaceController {

    /**
     * A simple stub which allows for instantiation of a CPInterfaceController for testing.
     * CPInterfaceController cannot be instantiated directly.
     */
    init(_ context: String) {
        self.context = context
    }

    let context: String

    override var debugDescription: String {
        return "CPInterfaceControllerSpy for \(context)"
    }

    //Uncomment and override as needed, if needed. At first inspection, some of these result in semaphore_wait_trap when invoked on an instance of CPInterfaceControllerSpy, but `rootTemplate` works as expected once set

    //TODO: solve for this duplication with introspection, à la Cedar::Doubles

//    weak open var delegate: CPInterfaceControllerDelegate?
//    open func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool)
//    open func pushTemplate(_ templateToPush: CPTemplate, animated: Bool)
//    open func popTemplate(animated: Bool)
//    open func popToRootTemplate(animated: Bool)
//    open func pop(to targetTemplate: CPTemplate, animated: Bool)
//    open func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool)
//    open func dismissTemplate(animated: Bool)
//    open var presentedTemplate: CPTemplate? { get }
//    open var rootTemplate: CPTemplate { get }
//    open var topTemplate: CPTemplate? { get }
//    open var templates: [CPTemplate] { get }
}
