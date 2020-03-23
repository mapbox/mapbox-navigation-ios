#if DEBUG
import Mapbox
import MapboxDirections
import MapboxSpeech
import OHHTTPStubs

extension ViewController {
    func testSKUTokens() {
        // Force cache-cleaning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification,
                                        object: nil)
        
        let semaphore = DispatchSemaphore(value: 0)
        var mapViewSkuToken: String?
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            let isMapboxStyleURL = request.url?.isMapboxAPIURL ?? false
            guard isMapboxStyleURL else { return true }
            mapViewSkuToken = request.url?.queryItem("sku")?.value
            semaphore.signal()
            return true
        }) { (_) -> OHHTTPStubsResponse in
            return OHHTTPStubsResponse(data: "".data(using: .utf8)!, statusCode: 200, headers: [:])
        }
        
        loadViewIfNeeded()
        
        DispatchQueue.global().async {
            let directionsSkuToken = Directions.skuToken
            let speechSkuToken = SpeechSynthesizer.skuToken
            
            _ = semaphore.wait(timeout: .now() + 4)
            
            DispatchQueue.main.async {
                if let directionsSkuToken = directionsSkuToken {
                    let label = UILabel(frame: .init(x: 8, y: 100, width: 200, height: 20))
                    label.text = directionsSkuToken
                    label.accessibilityIdentifier = "Directions SKU"
                    
                    self.view.addSubview(label)
                }
                if let speechSkuToken = speechSkuToken {
                    let label = UILabel(frame: .init(x: 8, y: 100 + 28, width: 200, height: 20))
                    label.text = speechSkuToken
                    label.accessibilityIdentifier = "SpeechSynthesizer SKU"
                    
                    self.view.addSubview(label)
                }
                if let mapViewSkuToken = mapViewSkuToken {
                    let label = UILabel(frame: .init(x: 8, y: 100 + 28 + 28, width: 200, height: 20))
                    label.text = mapViewSkuToken
                    label.accessibilityIdentifier = "MapView SKU"
                    
                    self.view.addSubview(label)
                }
                
                OHHTTPStubs.removeAllStubs()
            }
        }
    }
}

#endif
