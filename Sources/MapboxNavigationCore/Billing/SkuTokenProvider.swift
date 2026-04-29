public struct SkuTokenProvider: Sendable {
    public let skuToken: @Sendable () -> String?

    public init(skuToken: @Sendable @escaping () -> String?) {
        self.skuToken = skuToken
    }
}
