import Foundation
import MapboxDirections
import MapboxNavigationNative

class SkuTokenProvider: SkuTokenSource {
    
    private var directionCredentials: DirectionsCredentials
    
    init(with credentials: DirectionsCredentials) {
        directionCredentials = credentials
    }
    
    func getToken() -> String {
        return directionCredentials.skuToken ?? ""
    }
}
