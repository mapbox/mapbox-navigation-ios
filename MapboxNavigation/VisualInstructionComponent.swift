import UIKit
import SDWebImage
import MapboxDirections

extension VisualInstructionComponent {
    
    static let shieldURLCache = NSCache<NSString, NSURL>()
    static let shieldImageCache = NSCache<NSString, UIImage>()
    
    func shieldKey() -> String {
        return imageURL!.absoluteString
    }
    
    func cachedShield(_ shieldKey: String) -> UIImage? {
        return VisualInstructionComponent.shieldImageCache.object(forKey: shieldKey as NSString)
    }
    
    func shieldImage(height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = imageURL else { return }
        let shieldKey = self.shieldKey()
        
        if let cachedImage = self.cachedShield(shieldKey) {
            completion(cachedImage)
            return
        }
        
        if let cachedURL = VisualInstructionComponent.shieldURLCache.object(forKey: shieldKey as NSString) {
            SDWebImageDownloader.shared().downloadImage(with: (cachedURL as URL), options: [], progress: nil, completed: { (image, data, error, successful) in
                guard let imageData = data else { return }
                guard let downscaledImage = UIImage(data: imageData) else {
                    completion(nil)
                    return
                }
                
                VisualInstructionComponent.shieldImageCache.setObject(downscaledImage, forKey: shieldKey as NSString)
                completion(downscaledImage)
                return
            })
        } else {
            VisualInstructionComponent.shieldURLCache.setObject(imageURL as NSURL, forKey: shieldKey as NSString)
            
            SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil, completed: { (image, data, error, successful) in
                guard let imageData = data else { return }
                
                guard let downscaledImage = UIImage(data: imageData) else {
                    completion(nil)
                    return
                }
                VisualInstructionComponent.shieldImageCache.setObject(downscaledImage, forKey: shieldKey as NSString)
                completion(downscaledImage)
            })
        }
    }
}

