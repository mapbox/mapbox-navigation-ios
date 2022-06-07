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
        
        var carPlayManager: CarPlayManager!
        var delegate: TestCarPlayManagerDelegate!
        
        beforeEach {
            NavigationSettings.shared.initialize(directions: .mocked,
                                                 tileStoreConfiguration: .default,
                                                 routingProviderSource: .offline,
                                                 alternativeRouteDetectionStrategy: .init())
            let mockedHandler = BillingHandler.__createMockedHandler(with: BillingServiceMock())
            BillingHandler.__replaceSharedInstance(with: mockedHandler)
            
            CarPlayMapViewController.swizzleMethods()
            carPlayManager = CarPlayManager(customRoutingProvider: MapboxRoutingProvider(.offline))
            delegate = TestCarPlayManagerDelegate()
            carPlayManager.delegate = delegate
            
            simulateCarPlayConnection(carPlayManager)
        }
        
        afterEach {
            CarPlayMapViewController.unswizzleMethods()
            carPlayManager = nil
            delegate = nil
        }
        
        describe("Previewing routes.") {
            // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
            guard #available(iOS 14, *) else { return }
            beforeEach {
                carPlayManager.mapTemplateProvider = MapTemplateSpyProvider()
            }
            
            afterEach {
                MapboxRoutingProvider.__testRoutesStub = nil
            }
            
            let previewRoutesAction = {
                let navigationRouteOptions = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                let route = Fixture.route(from: "route-with-banner-instructions",
                                          options: navigationRouteOptions)
                let waypoints = navigationRouteOptions.waypoints
                
                let fasterResponse = RouteResponse(httpResponse: nil,
                                                   identifier: nil,
                                                   routes: [route],
                                                   waypoints: waypoints,
                                                   options: .route(navigationRouteOptions),
                                                   credentials: Fixture.credentials)
                MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
                    completionHandler(Directions.Session(options, Fixture.credentials),
                                      .success(fasterResponse))
                    return nil
                }
                
                carPlayManager.previewRoutes(for: navigationRouteOptions, completionHandler: {})
            }
            
            context("When the trip is not customized by the developer.") {
                beforeEach {
                    previewRoutesAction()
                }
                
                it("Previews a route/options with the default configuration.") {
                    let mapTemplateSpy = carPlayManager.interfaceController?.topTemplate as? MapTemplateSpy
                    
                    expect(mapTemplateSpy?.currentTripPreviews).toNot(beEmpty())
                    let expectedStartButtonTitle = NSLocalizedString("CARPLAY_GO",
                                                                     bundle: .mapboxNavigation,
                                                                     value: "Go",
                                                                     comment: "Title for start button in CPTripPreviewTextConfiguration")
                    expect(mapTemplateSpy?.currentPreviewTextConfiguration?.startButtonTitle).to(equal(expectedStartButtonTitle))
                }
            }
            
            context("When the delegate provides a custom trip.") {
                var customTrip: CPTrip!
                
                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
                    customTripDelegate.customTrip = customTrip
                    carPlayManager.delegate = customTripDelegate
                    
                    previewRoutesAction()
                }
                
                it("Shows trip previews for the custom trip.") {
                    let mapTemplateSpy = carPlayManager.interfaceController?.topTemplate as? MapTemplateSpy
                    
                    expect(mapTemplateSpy?.currentTripPreviews).to(contain(customTrip))
                    expect(mapTemplateSpy?.currentPreviewTextConfiguration).toNot(beNil())
                }
            }
            
            context("When the delegate provides a custom trip preview text.") {
                let customStartButtonTitleText = "Let's roll"
                
                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    let customTripPreviewTextConfiguration = CPTripPreviewTextConfiguration(startButtonTitle: customStartButtonTitleText,
                                                                                            additionalRoutesButtonTitle: nil,
                                                                                            overviewButtonTitle: nil)
                    customTripDelegate.customTripPreviewTextConfiguration = customTripPreviewTextConfiguration
                    carPlayManager.delegate = customTripDelegate
                    
                    previewRoutesAction()
                }
                
                it("Previews a route/options with the custom trip configuration.") {
                    let mapTemplateSpy = carPlayManager.interfaceController?.topTemplate as? MapTemplateSpy
                    
                    expect(mapTemplateSpy?.currentTripPreviews).toNot(beEmpty())
                    expect(mapTemplateSpy?.currentPreviewTextConfiguration?.startButtonTitle).to(equal(customStartButtonTitleText))
                }
            }
        }
        
        describe("Starting a valid trip.") {
            let action = {
                let routeChoice = createValidRouteChoice()
                let trip = createTrip(routeChoice)
                let mapTemplate = CPMapTemplate()
                
                carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
                carPlayManager.carPlayNavigationViewController?.loadViewIfNeeded()
                
                let navigationService = delegate.currentService as? MapboxNavigationService
                navigationService?.start()
            }
            
            context("When configured to simulate.") {
                beforeEach {
                    carPlayManager.simulatesLocations = true
                    carPlayManager.simulatedSpeedMultiplier = 5.0
                }
                
                it("Starts navigation with a navigation service with simulation enabled.") {
                    action()
                    
                    expect(delegate.navigationInitiated).to(beTrue())
                    let navigationService = delegate.currentService as? MapboxNavigationService
                    
                    expect(navigationService?.simulationMode).to(equal(.always))
                    expect(navigationService?.simulationSpeedMultiplier).to(equal(5.0))
                }
            }
            
            context("When configured not to simulate.") {
                beforeEach {
                    carPlayManager.simulatesLocations = false
                }
                
                it("Starts navigation with a navigation service with simulation set to inTunnels by default.") {
                    action()
                    
                    expect(delegate.navigationInitiated).to(beTrue())
                    let navigationService = delegate.currentService as? MapboxNavigationService
                    
                    expect(navigationService?.simulationMode).to(equal(.inTunnels))
                }
            }
        }
#if arch(x86_64) && canImport(Darwin)
        describe("Starting an invalid trip.") {
            context("Precondition should be triggered if CPRouteChoice is invalid.") {
                let routeChoice = createInvalidRouteChoice()
                let trip = createTrip(routeChoice)
                let mapTemplate = CPMapTemplate()
                
                expect {
                    carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
                }.to(throwAssertion())
            }
        }
#endif
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
