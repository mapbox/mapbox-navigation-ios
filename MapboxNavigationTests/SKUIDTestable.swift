#if DEBUG
extension String {
    var skuId: String {
        return String(prefix(3).dropFirst())
    }
}

enum SkuID: String {
    typealias RawValue = String
    case mapsUser = "00"
    case navigationUser = "02"
    case navigationSession = "03"
}
#endif
