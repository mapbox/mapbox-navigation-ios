import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    let imageCache = ImageCache()
    let infoCache =  SpriteInfoCache()
    var styleURI: StyleURI = .navigationDay
    var baseURL: URL = URL(string: "https://api.mapbox.com/styles/v1")!
    fileprivate(set) var imageDownloader: ReentrantImageDownloader = ImageDownloader()
    
    var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    func updateRepository(styleURI: StyleURI? = nil, representation: VisualInstruction.Component.ImageRepresentation? = nil, completion: @escaping CompletionHandler) {
        let dispatchGroup = DispatchGroup()

        // Reset cache and download the Sprite image and Sprite info only when the map style changes or the shield baseURL changes.
        if (styleURI != self.styleURI) || (representation?.shield?.baseURL != self.baseURL) {
            resetCache()
            let styleURI = styleURI ?? self.styleURI
            let baseURL = representation?.shield?.baseURL ?? self.baseURL
            
            if let styleID = styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
               let infoRequestURL = spriteURL(isImage: false, baseURL: baseURL, styleID: styleID),
               let spriteRequestURL = spriteURL(isImage: true, baseURL: baseURL, styleID: styleID) {
                
                dispatchGroup.enter()
                downloadInfo(infoRequestURL) { (_) in
                    dispatchGroup.leave()
                }
                
                dispatchGroup.enter()
                downloadSprite(spriteRequestURL) { (_) in
                    self.styleURI = styleURI
                    self.baseURL = baseURL
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.enter()
        downloadLegacyShield(representation: representation) { (_) in
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func spriteURL(isImage: Bool, baseURL: URL, styleID: String) -> URL? {
        guard var urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else { return nil }
        
        let requestType = isImage ? "/sprite@\(Int(VisualInstruction.Component.scale))x.png" : "/sprite@\(Int(VisualInstruction.Component.scale))x"
        urlComponent.path += styleID
        urlComponent.path += requestType
        urlComponent.queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        return urlComponent.url
    }
    
    func downloadInfo(_ infoURL: URL, completion: @escaping (Data?) -> Void) {
        let _ = imageDownloader.downloadImage(with: infoURL, completion: { [weak self] (_, data, error)  in
            guard let strongSelf = self, let data = data else {
                completion(nil)
                return
            }

            guard strongSelf.infoCache.store(data) else {
                completion(nil)
                return
            }
            
            completion(data)
        })
    }
    
    func downloadSprite(_ spriteURL: URL, completion: @escaping (UIImage?) -> Void) {
        let _ = imageDownloader.downloadImage(with: spriteURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            strongSelf.imageCache.store(image, forKey: "Sprite", toDisk: false, completion: {
                completion(image)
            })
        })
    }
    
    func downloadLegacyShield(representation: VisualInstruction.Component.ImageRepresentation? = nil, completion: @escaping (UIImage?) -> Void) {
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png) else {
            completion(nil)
            return
        }
        
        let _ = imageDownloader.downloadImage(with: legacyURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            strongSelf.imageCache.store(image, forKey: "Legacy", toDisk: false, completion: {
                completion(image)
            })
        })
    }
    
    func getShield(displayRef: String, name: String) -> UIImage? {
        let iconLeght = (displayRef.count < 2 ) ? 2 : displayRef.count
        let infoName = name + "-\(iconLeght)"
        
        // Retrieve the single shield icon if it has been cached.
        if let shieldIcon = imageCache.image(forKey: infoName) {
            return shieldIcon
        }
        
        guard let spriteImage = imageCache.image(forKey: "Sprite"),
              let spriteInfo = infoCache.spriteInfo(forKey: infoName) else { return nil }
        
        let shieldRect = CGRect(x: spriteInfo.x, y: spriteInfo.y, width: spriteInfo.width, height: spriteInfo.height)
        if let croppedCGIImage = spriteImage.cgImage?.cropping(to: shieldRect) {
            
            // Cache the single shield icon if it hasn't been stored.
            let shieldIcon = UIImage(cgImage: croppedCGIImage)
            imageCache.store(shieldIcon, forKey: infoName, toDisk: false, completion: nil)
            
            return UIImage(cgImage: croppedCGIImage)
        }
        
        return nil
    }
    
    func getLegacyShield() -> UIImage? {
        return imageCache.image(forKey: "Legacy")
    }
    
    func resetCache() {
        imageCache.clearMemory()
        infoCache.clearMemory()
    }

}
