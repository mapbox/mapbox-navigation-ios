import Foundation
import MapboxNavigationNative

class SkuTokenProvider: SkuTokenSource {
    func getToken() -> String {
        return MBXAccounts.serviceSkuToken
    }
}
