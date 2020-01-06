import MapboxDirections

extension Route {
    
    public var json: String? {
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let encoded = try? encoder.encode(self) else {
            return nil
        }
        let encodedString = String(data: encoded, encoding: .utf8)
        return encodedString
    }
}
