import UIKit
import MapboxDirections

extension VisualInstructionComponent {
    
    static let scale = UIScreen.main.scale

    func shieldKey() -> String? {
        guard let imageURL = imageURL else { return nil }
        return "\(imageURL.absoluteString)-\(VisualInstructionComponent.scale)"
    }
}
