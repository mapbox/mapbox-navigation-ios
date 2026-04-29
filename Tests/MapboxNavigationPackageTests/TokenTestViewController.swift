import Combine
import CoreLocation
import Foundation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationUIKit
import OHHTTPStubs
import TestHelper
import XCTest

#if DEBUG
class TokenTestViewController: UIViewController {
    var mapViewToken: String?
    var serviceSkuToken: String?

    var tokenExpectation: XCTestExpectation?

    let semaphore = DispatchSemaphore(value: 0)
    var mapView: NavigationMapView?

    var billingHandler: BillingHandler

    var routeProgressPublisher: CurrentValueSubject<RouteProgress?, Never> = .init(nil)
    var locationMatchingPublisher: CurrentValueSubject<CLLocation, Never> =
        .init(CLLocation(latitude: 9.519172, longitude: 47.210823))

    init(billingHandler: BillingHandler) {
        self.billingHandler = billingHandler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        HTTPStubs.stubRequests(passingTest: { request -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxAPIURL ?? false
            let mapViewToken = request.url?.queryItem("sku")?.value
            guard isMapboxStyleURL, mapViewToken?.isEmpty == .some(false) else { return true }
            self.mapViewToken = mapViewToken
            self.semaphore.signal()
            return true
        }) { _ -> HTTPStubsResponse in
            return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }

        // Force cache-cleaning
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        mapView = .init(
            location: locationMatchingPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )

        // TODO: Find a way to clean offline storage.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global().async {
            // waiting for MapView token to be extracted from a style request
            _ = self.semaphore.wait(timeout: .now() + 4)

            self.serviceSkuToken = self.billingHandler.serviceSkuToken

            DispatchQueue.main.async {
                HTTPStubs.removeAllStubs()
                if self.mapViewToken != nil {
                    self.tokenExpectation?.fulfill()
                }
            }
        }
    }
}
#endif
