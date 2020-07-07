
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
    
    override func loadView() {
        super.loadView()
        
        let mapView = NavigationMapView()
        view.addSubview(mapView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Force cache-cleaning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification,
                                        object: nil)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxAPIURL ?? false
            guard isMapboxStyleURL else { return true }
            self.mapViewToken = request.url?.queryItem("sku")?.value
            semaphore.signal()
            return true
        }) { (_) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }
        
        DispatchQueue.global().async {
            self.directionsToken = Directions.skuToken
            self.speechSynthesizerToken = SpeechSynthesizer.skuToken
            
            _ = semaphore.wait(timeout: .now() + 4)
            
            DispatchQueue.main.async {
                OHHTTPStubs.removeAllStubs()
                self.tokenExpectation?.fulfill()
            }
        }
    }
}
