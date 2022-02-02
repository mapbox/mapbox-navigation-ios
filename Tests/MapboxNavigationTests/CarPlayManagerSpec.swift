import CarPlay
import Quick
import Nimble
import MapboxDirections
import TestHelper
import CarPlayTestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

@available(iOS 12.0, *)
class CarPlayManagerSpec: QuickSpec {
    
    override func spec() {
        
        var manager: CarPlayManager!
        var delegate: TestCarPlayManagerDelegate!
        
        beforeEach {
            NavigationSettings.shared.initialize(directions: .mocked,
                                                 tileStoreConfiguration: .default)
            let mockedHandler = BillingHandler.__createMockedHandler(with: BillingServiceMock())
            BillingHandler.__replaceSharedInstance(with: mockedHandler)
            Navigator.shared.navigator.reset { }
            Navigator._recreateNavigator()
            
            CarPlayMapViewController.swizzleMethods()
            manager = CarPlayManager(styles: nil, routingProvider: MapboxRoutingProvider(.offline), eventsManager: nil)
            delegate = TestCarPlayManagerDelegate()
            manager.delegate = delegate
            
            simulateCarPlayConnection(manager)
        }
        
        afterEach {
            CarPlayMapViewController.unswizzleMethods()
            //            manager = nil
            //            delegate = nil
        }
        
        // MARK: Previewing routes
        
        describe("Previewing routes") {
            // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
            guard #available(iOS 14, *) else { return }
            beforeEach {
                manager.mapTemplateProvider = MapTemplateSpyProvider()
            }
            
            afterEach {
                MapboxRoutingProvider.__testRoutesStub = nil
            }
            
            let previewRoutesAction = {
                let options = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                let route = Fixture.route(from: "route-with-banner-instructions", options: options)
                let waypoints = options.waypoints
                
                let fasterResponse = RouteResponse(httpResponse: nil,
                                                   identifier: nil,
                                                   routes: [route],
                                                   waypoints: waypoints,
                                                   options: .route(options),
                                                   credentials: Fixture.credentials)
                MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
                    completionHandler(Directions.Session(options, Fixture.credentials),
                                      .success(fasterResponse))
                    return nil
                }
                
                manager.previewRoutes(for: options, completionHandler: {})
            }
            
            context("when the trip is not customized by the developer") {
                beforeEach {
                    previewRoutesAction()
                }
                
                it("previews a route/options with the default configuration") {
                    let mapTemplateSpy = manager.interfaceController?.topTemplate as? MapTemplateSpy
                    
                    expect(mapTemplateSpy?.currentTripPreviews).toNot(beEmpty())
                    let expectedStartButtonTitle = NSLocalizedString("CARPLAY_GO",
                                                                     bundle: .mapboxNavigation,
                                                                     value: "Go",
                                                                     comment: "Title for start button in CPTripPreviewTextConfiguration")
                    expect(mapTemplateSpy?.currentPreviewTextConfiguration?.startButtonTitle).to(equal(expectedStartButtonTitle))
                }
            }
            
            context("when the delegate provides a custom trip") {
                var customTrip: CPTrip!
                
                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
                    customTripDelegate.customTrip = customTrip
                    manager.delegate = customTripDelegate
                    
                    previewRoutesAction()
                }
                
                it("shows trip previews for the custom trip") {
                    let mapTemplateSpy = manager.interfaceController?.topTemplate as? MapTemplateSpy
                    
                    expect(mapTemplateSpy?.currentTripPreviews).to(contain(customTrip))
                    expect(mapTemplateSpy?.currentPreviewTextConfiguration).toNot(beNil())
                }
            }
            
            context("when the delegate provides a custom trip preview text") {
                var customTripPreviewTextConfiguration: CPTripPreviewTextConfiguration!
                let customStartButtonTitleText = "Let's roll"
                
                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    customTripPreviewTextConfiguration = CPTripPreviewTextConfiguration(startButtonTitle: customStartButtonTitleText,
                                                                                        additionalRoutesButtonTitle: nil,
                                                                                        overviewButtonTitle: nil)
                    customTripDelegate.customTripPreviewTextConfiguration = customTripPreviewTextConfiguration
                    manager.delegate = customTripDelegate
                    
                    previewRoutesAction()
                }
                
                it("previews a route/options with the custom trip configuration") {
                    let interfaceController = manager.interfaceController as! FakeCPInterfaceController
                    let mapTemplateSpy: MapTemplateSpy = interfaceController.topTemplate as! MapTemplateSpy
                    
                    expect(mapTemplateSpy.currentTripPreviews).toNot(beEmpty())
                    expect(mapTemplateSpy.currentPreviewTextConfiguration?.startButtonTitle).to(equal(customStartButtonTitleText))
                }
            }
        }
        
        // MARK: Starting a trip
        
        describe("Starting a valid trip") {
            let action = {
                let fakeTemplate = CPMapTemplate()
                let fakeRouteChoice = CPRouteChoice(summaryVariants: ["summary1"],
                                                    additionalInformationVariants: ["addl1"],
                                                    selectionSummaryVariants: ["selection1"])
                let navigationRouteOptions = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                
                let routeResponseUserInfoKey = CPRouteChoice.RouteResponseUserInfo.key
                let routeResponse = Fixture.routeResponse(from: "route-with-banner-instructions",
                                                          options: navigationRouteOptions)
                let routeResponseUserInfo: CPRouteChoice.RouteResponseUserInfo = .init(response: routeResponse,
                                                                                       routeIndex: 0,
                                                                                       options: navigationRouteOptions)
                let userInfo: CarPlayUserInfo = [
                    routeResponseUserInfoKey: routeResponseUserInfo
                ]
                fakeRouteChoice.userInfo = userInfo
                
                let fakeTrip = CPTrip(origin: MKMapItem(),
                                      destination: MKMapItem(),
                                      routeChoices: [fakeRouteChoice])
                
                // Simulate starting a fake trip.
                manager.mapTemplate(fakeTemplate, startedTrip: fakeTrip, using: fakeRouteChoice)
                _ = manager.carPlayNavigationViewController?.view
                let navigationService = delegate.currentService as? MapboxNavigationService
                navigationService?.start()
            }
            
            context("When configured to simulate") {
                beforeEach {
                    manager.simulatesLocations = true
                    manager.simulatedSpeedMultiplier = 5.0
                }
                
                it("starts navigation with a navigation service with simulation enabled") {
                    action()
                    
                    expect(delegate.navigationInitiated).to(beTrue())
                    let service: MapboxNavigationService = delegate.currentService! as! MapboxNavigationService
                    
                    expect(service.simulationMode).to(equal(.always))
                    expect(service.simulationSpeedMultiplier).to(equal(5.0))
                }
            }
            
            context("When configured not to simulate") {
                beforeEach {
                    manager.simulatesLocations = false
                }
                
                it("starts navigation with a navigation service with simulation set to inTunnels by default") {
                    action()
                    
                    expect(delegate.navigationInitiated).to(beTrue())
                    let navigationService = delegate.currentService as? MapboxNavigationService
                    
                    expect(navigationService?.simulationMode).to(equal(.inTunnels))
                }
            }
        }
    }
    
    private class CustomTripPreviewDelegate: CarPlayManagerDelegate {
        
        var customTripPreviewTextConfiguration: CPTripPreviewTextConfiguration?
        var customTrip: CPTrip?
        
        func carPlayManager(_ carPlayManager: CarPlayManager,
                            willPreview trip: CPTrip) -> CPTrip {
            return customTrip ?? trip
        }
        
        func carPlayManager(_ carPlayManager: CarPlayManager,
                            willPreview trip: CPTrip,
                            with previewTextConfiguration: CPTripPreviewTextConfiguration) -> CPTripPreviewTextConfiguration {
            return customTripPreviewTextConfiguration ?? previewTextConfiguration
        }
    }
}
