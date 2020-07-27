
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
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxAPIURL ?? false
            guard isMapboxStyleURL else { return true }
            self.mapViewToken = request.url?.queryItem("sku")?.value
            self.semaphore.signal()
            return true
        }) { (_) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }
        
        // Force cache-cleaning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification,
                                        object: nil)
        
        MGLOfflineStorage.shared.clearAmbientCache { _ in
            self.mapView = NavigationMapView(frame: self.view.bounds)
            self.view.addSubview(self.mapView!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async {
            self.directionsToken = Directions.skuToken
            self.speechSynthesizerToken = SpeechSynthesizer.skuToken
            
            _ = self.semaphore.wait(timeout: .now() + 4)
            
            DispatchQueue.main.async {
                OHHTTPStubs.removeAllStubs()
                if self.mapViewToken != nil {
                    self.tokenExpectation?.fulfill()
                }
            }
        }
    }
}
