import _MapboxNavigationHelpers

extension BillingHandler {
    func skuTokenProvider() -> SkuTokenProvider {
        .init {
            self.serviceSkuToken
        }
    }
}
