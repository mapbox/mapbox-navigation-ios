import UIKit
import MapboxDirections

extension VisualInstructionComponent {
    
    static let scale = UIScreen.main.scale
    
    var cacheKey: String? {
        switch type {
        case .exit, .exitCode:
            guard let exitCode = self.text else { return nil }
            return "exit-" + exitCode + "-\(VisualInstructionComponent.scale)"
        case .image:
            guard let imageURL = imageURL else { return genericCacheKey }
            return "\(imageURL.absoluteString)-\(VisualInstructionComponent.scale)"
        case .text, .delimiter:
            return nil
        }
    }
    
    var genericCacheKey: String {
        return "generic-" + (text ?? "nil")
    }
}
