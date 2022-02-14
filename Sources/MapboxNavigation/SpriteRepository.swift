import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    let imageCache: BimodalImageCache
    let infoCache =  SpriteInfoCache()
    var styleURI: StyleURI = .navigationDay
    var baseURL: URL = URL(string: "https://api.mapbox.com/styles/v1")!
    
    public var sessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    public static let shared = SpriteRepository.init()
    fileprivate(set) var imageDownloader: ReentrantImageDownloader
    
    init(imageCache: BimodalImageCache = ImageCache(), withDownloader downloader: ReentrantImageDownloader = ImageDownloader()) {
        self.imageCache = imageCache
        self.imageDownloader = downloader
    }
    
    func updateRepository(styleURI: StyleURI? = nil, representation: VisualInstruction.Component.ImageRepresentation? = nil, completion: @escaping CompletionHandler) {
        let baseURL = representation?.shield?.baseURL ?? self.baseURL
        let styleURI = styleURI ?? self.styleURI
        
        resetCache()
        let dispatchGroup = DispatchGroup()
        
        if let styleID = styleURI.rawValue.components(separatedBy: "styles")[safe: 1] {
            if let infoRequestURL = spriteURL(isImage: false, baseURL: baseURL, styleID: styleID) {
                dispatchGroup.enter()
                downloadInfo(infoRequestURL) { (_) in
                    dispatchGroup.leave()
                }
            }
            
            if let spriteRequestURL = spriteURL(isImage: true, baseURL: baseURL, styleID: styleID) {
                dispatchGroup.enter()
                downloadSprite(spriteRequestURL) { (_) in
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.enter()
        downloadLegacyShield(representation: representation) { (_) in
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.styleURI = styleURI
            self.baseURL = baseURL
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

            guard error == nil else {
                completion(data)
                return
            }

            strongSelf.infoCache.store(data)
            completion(data)
        })
    }
    
    func downloadSprite(_ spriteURL: URL, completion: @escaping (UIImage?) -> Void) {
        let _ = imageDownloader.downloadImage(with: spriteURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            guard error == nil else {
                completion(image)
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

            guard error == nil else {
                completion(image)
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
