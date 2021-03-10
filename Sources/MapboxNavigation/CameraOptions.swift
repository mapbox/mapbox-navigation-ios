import MapboxMaps

extension CameraOptions {
    
    public override var description: String {
        var propertiesCount: UInt32 = 0
        let properties = class_copyPropertyList(CameraOptions.self, &propertiesCount)
        
        var description = [String]()
        for i in 0..<propertiesCount {
            guard let property = properties?[Int(i)] else { continue }
            let key = NSString(cString: property_getName(property), encoding: String.Encoding.utf8.rawValue) as String?

            if let key = key,
               key != "description",
               let value = self.value(forKey: key) {
                
                description.append("\(key): \(value)")
            }
        }
        
        return description.joined(separator: "\n")
    }
}
