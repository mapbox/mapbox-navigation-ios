import Foundation
import MapboxNavigationNative
import MapboxDirections

extension NavigationStatus {
    /// Legacy `roadName` property that returns first road name based on the `roads` array.
    var roadName: String {
        roads.map({ $0.text }).prefix(while: { $0 != "/" }).joined(separator: " ")
    }
    
    // This `routeShieldRepresentation` property returns the image representation of current road shield based on the `roads` array as the `VisualInstruction.Component.ImageRepresentation`.
    var routeShieldRepresentation: VisualInstruction.Component.ImageRepresentation {
        var shield: VisualInstruction.Component.ShieldRepresentation? = nil
        var imageBaseUrl: URL? = nil
        
        if let roadShield = roads.compactMap({ $0.shield }).first,
           let baseURL = URL(string: roadShield.baseUrl) {
            shield = VisualInstruction.Component.ShieldRepresentation(baseURL: baseURL, name: roadShield.name, textColor: roadShield.textColor, text: roadShield.displayRef)
        }
        
        if let imageBaseString = roads.compactMap({ $0.imageBaseUrl }).filter({ !$0.isEmpty }).first {
            imageBaseUrl = URL(string: imageBaseString)
        }
           
        return VisualInstruction.Component.ImageRepresentation(imageBaseURL: imageBaseUrl, shield: shield)
    }
}
