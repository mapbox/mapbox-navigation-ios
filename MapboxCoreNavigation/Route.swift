import MapboxDirections

extension Route {
    
    var json: String? {
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(self) else {
            return nil
        }
        let encodedString = String(data: encoded, encoding: .utf8)
        return encodedString
    }
}
