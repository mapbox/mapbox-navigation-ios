import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    // Caching the Sprite and single shield icon images.
    let spriteCache = ImageCache()
    // Caching the single legacy shield icon images.
    let legacyCache = ImageCache()
    // Caching the metadata info for Sprite.
    let infoCache =  SpriteInfoCache()
    let baseURL: URL = URL(string: "https://api.mapbox.com/styles/v1")!
    var styleURI: StyleURI = .navigationDay
    fileprivate(set) var imageDownloader: ReentrantImageDownloader
    
    static let shared = SpriteRepository.init()
    
    private let requestTimeOut: TimeInterval = 10
    
    var styleID: String? {
        styleURI.rawValue.components(separatedBy: "styles")[safe: 1]
    }
    
    var sessionConfiguration: URLSessionConfiguration {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }
    
    init() {
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = self.requestTimeOut
        imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
    }
    
    func updateStyle(styleURI: StyleURI?, completion: @escaping ImageDownloadCompletionHandler) {
        // If no valid StyleURI provided, use the default Day style.
        let newStyleURI = styleURI ?? self.styleURI
        guard newStyleURI != self.styleURI || getSpriteImage() == nil else {
            completion(nil)
            return
        }
        
        spriteCache.clearMemory()
        infoCache.clearMemory()
        
        // Update the styleURI just after the Sprite memory reset. When the connection is poor, the next round of style update
        // or the representation update could use the correct ones.
        self.styleURI = newStyleURI
        updateSprite(completion: completion)
    }

    func updateRepresentation(for representation: VisualInstruction.Component.ImageRepresentation? = nil,
                              completion: @escaping ImageDownloadCompletionHandler) {
        let dispatchGroup = DispatchGroup()
        var downloadError: DownloadError? = nil

        if getSpriteImage() == nil {
            dispatchGroup.enter()
            updateSprite() { (error) in
                downloadError = error
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.enter()
        updateLegacy(representation: representation) { (error) in
            downloadError = error ?? downloadError
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(downloadError)
        }
    }
    
    func updateSprite(completion: @escaping ImageDownloadCompletionHandler) {
        guard let styleID = styleID,
              let infoRequestURL = spriteURL(isImage: false, styleID: styleID),
              let spriteRequestURL = spriteURL(isImage: true, styleID: styleID) else {
            completion(.clientError)
            return
        }
        
        var downloadError: DownloadError? = nil
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        downloadInfo(infoRequestURL, spriteKey: styleID) { (data) in
            downloadError = (data == nil) ? .noImageData : downloadError
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        downloadSprite(spriteRequestURL, spriteKey: styleID) { (image) in
            downloadError = (image == nil) ? .noImageData : downloadError
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(downloadError)
        }
    }
    
    func updateLegacy(representation: VisualInstruction.Component.ImageRepresentation? = nil,
                      completion: @escaping ImageDownloadCompletionHandler) {
        guard let cacheKey = representation?.legacyCacheKey else {
            completion(.clientError)
            return
        }
        
        if let _ = legacyCache.image(forKey: cacheKey) {
            completion(nil)
        } else {
            downloadLegacyShield(representation: representation) { (image) in
                let downloadError: DownloadError? = (image == nil) ? .noImageData : nil
                completion(downloadError)
            }
        }
    }
    
    func spriteURL(isImage: Bool, styleID: String) -> URL? {
        guard var urlComponent = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken else { return nil }
        
        let requestType = isImage ? "/sprite@\(Int(VisualInstruction.Component.scale))x.png" : "/sprite@\(Int(VisualInstruction.Component.scale))x"
        urlComponent.path += styleID
        urlComponent.path += requestType
        urlComponent.queryItems = [URLQueryItem(name: "access_token", value: accessToken)]
        return urlComponent.url
    }
    
    func downloadInfo(_ infoURL: URL, spriteKey: String, completion: @escaping (Data?) -> Void) {
        let _ = imageDownloader.downloadImage(with: infoURL, completion: { [weak self] (_, data, error)  in
            guard let strongSelf = self, let data = data else {
                completion(nil)
                return
            }

            guard strongSelf.infoCache.store(data, spriteKey: spriteKey) else {
                completion(nil)
                return
            }
            
            completion(data)
        })
    }
    
    func downloadSprite(_ spriteURL: URL, spriteKey: String, completion: @escaping (UIImage?) -> Void) {
        let _ = imageDownloader.downloadImage(with: spriteURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            strongSelf.spriteCache.store(image, forKey: spriteKey, toDisk: false, completion: {
                completion(image)
            })
        })
    }
    
    func downloadLegacyShield(representation: VisualInstruction.Component.ImageRepresentation? = nil, completion: @escaping (UIImage?) -> Void) {
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png),
              let cacheKey = representation?.legacyCacheKey else {
                  completion(nil)
                  return
              }
        
        let _ = imageDownloader.downloadImage(with: legacyURL, completion: { [weak self] (image, data, error) in
            guard let strongSelf = self, let image = image else {
                completion(nil)
                return
            }

            strongSelf.legacyCache.store(image, forKey: cacheKey, toDisk: false, completion: {
                completion(image)
            })
        })
    }
    
    func roadShieldImage(from shieldRepresentation: VisualInstruction.Component.ShieldRepresentation?) -> UIImage? {
        guard let shield = shieldRepresentation, let styleID = styleID else { return nil }
        
        let iconLeght = max(shield.text.count, 2)
        let shieldKey = shield.name + "-\(iconLeght)" + "-\(styleID)"
        
        // Retrieve the single shield icon if it has been cached.
        if let shieldIcon = spriteCache.image(forKey: shieldKey) {
            return shieldIcon
        }
        
        guard let spriteImage = spriteCache.image(forKey: styleID),
              let spriteInfo = infoCache.spriteInfo(forKey: shieldKey) else { return nil }
        
        let shieldRect = CGRect(x: spriteInfo.x, y: spriteInfo.y, width: spriteInfo.width, height: spriteInfo.height)
        if let croppedCGIImage = spriteImage.cgImage?.cropping(to: shieldRect) {
            
            // Cache the single shield icon if it hasn't been stored.
            let shieldIcon = UIImage(cgImage: croppedCGIImage)
            spriteCache.store(shieldIcon, forKey: shieldKey, toDisk: false, completion: nil)
            
            return shieldIcon
        }
        
        return nil
    }
    
    func legacyRoadShieldImage(from cacheKey: String?) -> UIImage? {
        return legacyCache.image(forKey: cacheKey)
    }
    
    func getSpriteImage() -> UIImage? {
        // Use the styleID of current repository to retrieve Sprite image.
        guard let styleID = styleID else { return nil }
        return spriteCache.image(forKey: styleID)
    }
    
    func resetCache() {
        spriteCache.clearMemory()
        infoCache.clearMemory()
        legacyCache.clearMemory()
    }

}
