import UIKit
import SDWebImage

extension UIImage {
    
    static let shieldURLCache = NSCache<NSString, NSURL>()
    static let shieldImageCache = NSCache<NSString, UIImage>()
    
    static func shieldImage(_ network: String, number: String, height: CGFloat, completion: @escaping (UIImage?) -> Void) {
        
        let key = "\(network)\(number)" as NSString
        
        if let cachedImage = UIImage.shieldImageCache.object(forKey: key) {
            completion(cachedImage)
            return
        }
        
        if let cachedURL = UIImage.shieldURLCache.object(forKey: key) {
            
            SDWebImageDownloader.shared().downloadImage(with: (cachedURL as URL), options: [], progress: nil, completed: { (image, data, error, successful) in
                guard let imageData = data else { return }
                guard let downscaledImage = UIImage(data: imageData, scale: UIScreen.main.scale) else {
                    completion(nil)
                    return
                }
                
                UIImage.shieldImageCache.setObject(downscaledImage, forKey: key)
                completion(downscaledImage)
                return
            })
        } else {
            
            guard let shieldURL = URL.shieldURL(network: network, number: number, height: height) else {
                completion(nil)
                return
            }
            
            URL.shieldImageURL(shieldURL: shieldURL, completion: { (imageURL) in
                UIImage.shieldURLCache.setObject(shieldURL as NSURL, forKey: key)
                
                SDWebImageDownloader.shared().downloadImage(with: imageURL, options: [], progress: nil, completed: { (image, data, error, successful) in
                    guard let imageData = data else { return }
                    guard let downscaledImage = UIImage(data: imageData, scale: UIScreen.main.scale) else {
                        completion(nil)
                        return
                    }
                    
                    UIImage.shieldImageCache.setObject(downscaledImage, forKey: key)
                    completion(downscaledImage)
                })
            })
        }
    }
}
