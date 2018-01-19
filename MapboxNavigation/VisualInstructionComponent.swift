import UIKit
import SDWebImage
import MapboxDirections

extension VisualInstructionComponent {
    
    static let scale = UIScreen.main.scale
    static var useDiskCache = true
    
    func shieldKey() -> String? {
        guard let imageURL = imageURL else { return nil }
        return "\(imageURL.absoluteString)-\(VisualInstructionComponent.scale)"
    }
    
    func cachedShield(_ shieldKey: String) -> UIImage? {
        return SDImageCache.shared().imageFromCache(forKey: shieldKey)
    }
    
    func shieldImage(height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = imageURL else { return }
        guard let shieldKey = self.shieldKey() else { return }
        
        if let cachedImage = self.cachedShield(shieldKey) {
            completion(cachedImage)
            return
        }
            
        SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil, completed: { (image, data, error, successful) in
            guard let image = image else {
                completion(nil)
                return
            }
            
            SDImageCache.shared().store(image, forKey: shieldKey, toDisk: VisualInstructionComponent.useDiskCache, completion: {
                completion(image)
            })
        })
    }

    static func disableDiskCache() {
        useDiskCache = false
    }
}
