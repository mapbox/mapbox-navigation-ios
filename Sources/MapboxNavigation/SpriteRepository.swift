import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    let imageCache: BimodalImageCache
    let metadataCache =  SpriteMetaDataCache()
    var styleURI: StyleURI = .navigationDay
    var baseURL: String = "https://api.mapbox.com/styles/v1"
    
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
        let baseURL = shield?.baseURL.absoluteString ?? self.baseURL
        let styleURI = styleURI ?? self.styleURI
        
        guard let styleID = styleURI.rawValue.components(separatedBy: "styles")[safe: 1],
              let accessToken = NavigationSettings.shared.directions.credentials.accessToken,
              let spriteRequestURL = URL(string: baseURL + styleID + "/sprite@2x.png?access_token=" + accessToken),
              let metadataRequestURL = URL(string: baseURL + styleID + "/sprite@2x?access_token=" + accessToken) else {
                  return
              }

        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        downloadMetadata(metadataRequestURL) { (_) in
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        downLoadSprite(spriteRequestURL) { (_) in
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.styleURI = styleURI
            self.baseURL = baseURL
            completion()
        }
    }
    
    func downloadMetadata(_ metadataURL: URL, completion: @escaping (Data?) -> Void) {
        metadataCache.clearMemory()
        
        let _ = imageDownloader.downloadImage(with: metadataURL, completion: { [weak self] (_, data, error)  in
            guard let strongSelf = self, let data = data else {
                completion(nil)
                return
            }

            guard error == nil else {
                completion(data)
                return
            }

            strongSelf.metadataCache.store(data)
            completion(data)
        })
    }
    
    func downLoadSprite(_ spriteURL: URL, completion: @escaping (UIImage?) -> Void) {
        imageCache.clearMemory()
        
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
        let metadataName = name + "-\(iconLeght)"
        
        guard let spriteImage = imageCache.image(forKey: "Sprite"),
              let spriteMetaData = metadataCache.spriteMetaData(forKey: metadataName) else { return nil }
        
        let shieldRect = CGRect(x: spriteMetaData.x, y: spriteMetaData.y, width: spriteMetaData.width, height: spriteMetaData.height)
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
        metadataCache.clearMemory()
    }

}
