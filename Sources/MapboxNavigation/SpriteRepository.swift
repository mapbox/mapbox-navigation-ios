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
    
    func updateRepository(styleURI: StyleURI? = nil, shield: VisualInstruction.Component.ShieldRepresentation? = nil, completion: @escaping CompletionHandler) {
        let baseURL = shield?.baseURL ?? self.baseURL
        let styleURI = styleURI ?? self.styleURI
        resetCache()
        
        guard let styleID = styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let spriteRequestURL = spriteURL(isImage: true, baseURL: baseURL, styleID: styleID),
              let infoRequestURL = spriteURL(isImage: false, baseURL: baseURL, styleID: styleID) else {
                  return
              }

        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        downloadInfo(infoRequestURL) { (_) in
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        downloadSprite(spriteRequestURL) { (_) in
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
        
        let requestType = isImage ? "/sprite@2x.png" : "/sprite@2x"
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
    
    func getShield(displayRef: String, name: String) -> UIImage? {
        let iconLeght = (displayRef.count < 2 ) ? 2 : displayRef.count
        let infoName = name + "-\(iconLeght)"
        
        guard let spriteImage = imageCache.image(forKey: "Sprite"),
              let spriteInfo = infoCache.spriteInfo(forKey: infoName) else { return nil }
        
        let shieldRect = CGRect(x: spriteInfo.x, y: spriteInfo.y, width: spriteInfo.width, height: spriteInfo.height)
        if let croppedCGIImage = spriteImage.cgImage?.cropping(to: shieldRect) {
            return UIImage(cgImage: croppedCGIImage)
        }
        
        return nil
    }
    
    func getLegacyShield(imageBaseUrl: String, completion: @escaping (UIImage?) -> Void) {
        guard let requestURL = URL(string: imageBaseUrl + "@2x.png") else {
            completion(nil)
            return
        }
        
        let _ = imageDownloader.downloadImage(with: requestURL, completion: { (image, data, error) in
            guard let image = image else {
                completion(nil)
                return
            }

            guard error == nil else {
                completion(image)
                return
            }

            completion(image)
            return
        })
    }
    
    func resetCache() {
        imageCache.clearMemory()
        infoCache.clearMemory()
    }

}
