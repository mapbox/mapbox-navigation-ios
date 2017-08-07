import Foundation
import CoreLocation

extension Array {
    
    /**
     Initializes a [CLLocation] from a JSON string at a given filePath.
     
     The JSON string must conform to the following structure:
     [{
         "latitude": 37.8,          // latitude or lat
         "longitude": -122.4        // longitude, lng, or lon
         "verticalAccuracy": 4,
         "speed": 21.0
         "horizontalAccuracy": 5,
         "course": 0.48
         "timestamp": 1497475447,   // timestamp as unix timestamp or ISO8601Date
         "altitude": 57.26
     }]
     
     - parameter filePath: The file’s path.
     - returns: A [CLLocation].
     */
    public static func locations(from filePath: String) -> [CLLocation]! {
        let url = URL(fileURLWithPath: filePath)
        
        do {
            let data = try Data(contentsOf: url)
            let serialized = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String: Any]]
            
            var locations = [CLLocation]()
            for dict in serialized {
                locations.append(CLLocation(dictionary: dict))
            }
            
            return locations.sorted { $0.timestamp < $1.timestamp }
            
        } catch {
            return []
        }
    }
}
