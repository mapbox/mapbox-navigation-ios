import UIKit
import SDWebImage

extension UIImage {
    
    static let shieldURLCache = NSCache<NSString, NSURL>()
    static let shieldImageCache = NSCache<NSString, UIImage>()
    
    static func shieldKey(_ network: String, number: String, height: CGFloat) -> String {
        return "\(network)-\(number)-\(Int(height))"
    }
    
    static func cachedShield(_ shieldKey: String) -> UIImage? {
        return UIImage.shieldImageCache.object(forKey: shieldKey as NSString)
    }
    
    static func shieldImage(_ network: String, number: String, height: CGFloat, scale: CGFloat = UIScreen.main.scale, completion: @escaping (UIImage?) -> Void) {
        
        let shieldKey = self.shieldKey(network, number: number, height: height)
        
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
            
            guard let shieldURL = URL.shieldURL(network: network, number: number, height: height * scale) else {
                completion(nil)
                return
            }
            
            URL.shieldImageURL(shieldURL: shieldURL, completion: { (imageURL) in
                UIImage.shieldURLCache.setObject(shieldURL as NSURL, forKey: shieldKey as NSString)
                
                SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil, completed: { (image, data, error, successful) in
                    guard let imageData = data else { return }
                    guard let downscaledImage = UIImage(data: imageData, scale: scale) else {
                        completion(nil)
                        return
                    }
                    UIImage.shieldImageCache.setObject(downscaledImage, forKey: shieldKey as NSString)
                    completion(downscaledImage)
                })
            })
        }
    }
}
