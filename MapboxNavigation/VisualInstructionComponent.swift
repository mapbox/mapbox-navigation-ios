import UIKit
import SDWebImage
import MapboxDirections

extension VisualInstructionComponent {
    
    static let scale = UIScreen.main.scale
    
    func shieldKey() -> String {
        return "\(imageURL!.absoluteString)-\(VisualInstructionComponent.scale)"
    }
    
    func cachedShield(_ shieldKey: String) -> UIImage? {
        return SDImageCache.shared().imageFromCache(forKey: shieldKey)
    }
    
    func shieldImage(height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = imageURL else { return }
        let shieldKey = self.shieldKey()
        
        if let cachedImage = self.cachedShield(shieldKey) {
            completion(cachedImage)
            return
        }
        
            
        SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil, completed: { (image, data, error, successful) in
            guard let imageData = data else { return }
            
            guard let downscaledImage = UIImage(data: imageData, scale: VisualInstructionComponent.scale) else {
                completion(nil)
                return
            }
            
            SDImageCache.shared().store(downscaledImage, forKey: shieldKey, toDisk: true, completion: nil)
            completion(downscaledImage)
        })
    }
}

