import UIKit
import SDWebImage

extension UIImage {
    
    static let shieldURLCache = NSCache<NSString, NSURL>()
    static let shieldImageCache = NSCache<NSString, UIImage>()
    
    static let scale = UIScreen.main.scale
    
    static func shieldKey(_ url: URL, height: CGFloat) -> String {
        return "\(url)-\(Int(height))-\(Int(scale))"
    }
    
    static func cachedShield(_ shieldKey: String) -> UIImage? {
        return UIImage.shieldImageCache.object(forKey: shieldKey as NSString)
    }
    
    static func shieldImage(_ url: URL, height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        
        let shieldKey = self.shieldKey(url, height: height)
        
        if let cachedImage = UIImage.cachedShield(shieldKey) {
            completion(cachedImage)
            return
        }
        
        if let cachedURL = UIImage.shieldURLCache.object(forKey: shieldKey as NSString) {
            
            SDWebImageDownloader.shared().downloadImage(with: (cachedURL as URL), options: [], progress: nil, completed: { (image, data, error, successful) in
                guard let imageData = data else { return }
                guard let downscaledImage = UIImage(data: imageData, scale: scale) else {
                    completion(nil)
                    return
                }
                
                UIImage.shieldImageCache.setObject(downscaledImage, forKey: shieldKey as NSString)
                completion(downscaledImage)
                return
            })
        } else {
            UIImage.shieldURLCache.setObject(url as NSURL, forKey: shieldKey as NSString)
            
            SDWebImageDownloader.shared().downloadImage(with: url, options: [], progress: nil, completed: { (image, data, error, successful) in
                guard let imageData = data else { return }
                guard let downscaledImage = UIImage(data: imageData, scale: scale) else {
                    completion(nil)
                    return
                }
                UIImage.shieldImageCache.setObject(downscaledImage, forKey: shieldKey as NSString)
                completion(downscaledImage)
            })
        }
    }
}
