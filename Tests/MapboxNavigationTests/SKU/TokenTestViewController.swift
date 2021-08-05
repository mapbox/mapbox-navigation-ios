
import Foundation
import OHHTTPStubs
import XCTest
import MapboxNavigation
import MapboxDirections
import MapboxSpeech


class TokenTestViewController: UIViewController {
    
    var mapViewToken: String?
    var directionsToken: String?
    var speechSynthesizerToken: String?
    
    var tokenExpectation: XCTestExpectation?
    
    let semaphore = DispatchSemaphore(value: 0)
    var mapView: NavigationMapView?
    
    override func loadView() {
        super.loadView()
        
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxAPIURL ?? false
            guard isMapboxStyleURL else { return true }
            self.mapViewToken = request.url?.queryItem("sku")?.value
            self.semaphore.signal()
            return true
        }) { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }
        
        // Force cache-cleaning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification,
                                        object: nil)

        mapView = .init(frame: .zero)
        
        // TODO: Find a way to clean offline storage.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            
            // waiting for MapView token to be extracted from a style request
            _ = self.semaphore.wait(timeout: .now() + 4)

            self.directionsToken = Directions.skuToken
            self.speechSynthesizerToken = SpeechSynthesizer.skuToken
            
            DispatchQueue.main.async {
                HTTPStubs.removeAllStubs()
                if self.mapViewToken != nil {
                    self.tokenExpectation?.fulfill()
                }
            }
        }
    }
}
