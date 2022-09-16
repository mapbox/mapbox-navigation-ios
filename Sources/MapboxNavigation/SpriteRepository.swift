import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    let baseURL: URL = URL(string: "https://api.mapbox.com/styles/v1")!
    var styleURI: StyleURI = .navigationDay
    fileprivate(set) var imageDownloader: ReentrantImageDownloader
    
    let requestCache: URLCaching
    let derivedCache: BimodalImageCache
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
        requestCache = URLDataCache()
        derivedCache = ImageCache()
    }
    
    func updateStyle(styleURI: StyleURI?, completion: @escaping ImageDownloadCompletionHandler) {
        // If no valid StyleURI provided, use the default Day style.
        let newStyleURI = styleURI ?? self.styleURI
        guard newStyleURI != self.styleURI || needToUpdateSprite() else {
            completion(nil)
            return
        }
        
        resetStyleCache()
        
        // Update the styleURI just after the Sprite memory reset. When the connection is poor, the next round of style update
        // or the representation update could use the correct ones.
        self.styleURI = newStyleURI
        updateSprite(completion: completion)
    }

    func updateRepresentation(for representation: VisualInstruction.Component.ImageRepresentation?,
                              completion: @escaping ImageDownloadCompletionHandler) {
        let dispatchGroup = DispatchGroup()
        var downloadError: DownloadError? = nil

        if needToUpdateSprite() {
            dispatchGroup.enter()
            updateSprite() { (error) in
                downloadError = error
                dispatchGroup.leave()
            }
        }
        
        if getLegacyShield(with: representation) == nil {
            dispatchGroup.enter()
            updateLegacy(representation: representation) { (error) in
                downloadError = error ?? downloadError
                dispatchGroup.leave()
            }
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
        downloadInfo(infoRequestURL) { (data) in
            downloadError = (data == nil) ? .noImageData : downloadError
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        downloadImage(imageURL: spriteRequestURL) { (image) in
            downloadError = (image == nil) ? .noImageData : downloadError
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(downloadError)
        }
    }
    
    func updateLegacy(representation: VisualInstruction.Component.ImageRepresentation?,
                      completion: @escaping ImageDownloadCompletionHandler) {
        guard representation?.imageBaseURL != nil else {
            completion(nil)
            return
        }
        
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png) else {
            completion(.clientError)
            return
        }

        downloadImage(imageURL: legacyURL) { (image) in
            let downloadError: DownloadError? = (image == nil) ? .noImageData : nil
            completion(downloadError)
        }
    }
    
    func needToUpdateSprite() -> Bool {
        return (getSpriteInfo() == nil || getSpriteImage() == nil)
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
    
    func downloadInfo(_ infoURL: URL, completion: @escaping (Data?) -> Void) {
        imageDownloader.download(with: infoURL, completion: { [weak self] (cachedResponse, error)  in
            guard let strongSelf = self, let cachedResponse = cachedResponse else {
                completion(nil)
                return
            }
            
            strongSelf.requestCache.store(cachedResponse, for: infoURL)
            completion(cachedResponse.data)
        })
    }
    
    func downloadImage(imageURL: URL, completion: @escaping (UIImage?) -> Void) {
        imageDownloader.download(with: imageURL, completion: { [weak self] (cachedResponse, error) in
            guard let strongSelf = self,
                  let cachedResponse = cachedResponse,
                  let image = UIImage(data: cachedResponse.data, scale: VisualInstruction.Component.scale) else {
                completion(nil)
                return
            }

            strongSelf.requestCache.store(cachedResponse, for: imageURL)
            completion(image)
        })
    }
    
    func roadShieldImage(from shieldRepresentation: VisualInstruction.Component.ShieldRepresentation?) -> UIImage? {
        guard let shield = shieldRepresentation, let styleID = styleID else { return nil }
        
        let iconLeght = max(shield.text.count, 2)
        let shieldKey = shield.name + "-\(iconLeght)"
        let compositeKey = shieldKey + "-\(styleID)"
        
        // Retrieve the single shield icon if it has been cached.
        if let shieldIcon = derivedCache.image(forKey: compositeKey) {
            return shieldIcon
        }
        
        guard let spriteImage = getSpriteImage(),
              let spriteInfo = getSpriteInfo(with: shieldKey) else { return nil }
        
        let shieldRect = CGRect(x: spriteInfo.x, y: spriteInfo.y, width: spriteInfo.width, height: spriteInfo.height)
        if let croppedCGIImage = spriteImage.cgImage?.cropping(to: shieldRect) {
            
            // Cache the single shield icon if it hasn't been stored.
            let shieldIcon = UIImage(cgImage: croppedCGIImage)
            derivedCache.store(shieldIcon, forKey: compositeKey, toDisk: true, completion: nil)
            
            return shieldIcon
        }
        
        return nil
    }
    
    func shieldCached(for representation: VisualInstruction.Component.ImageRepresentation?) -> Bool {
        return (roadShieldImage(from: representation?.shield) != nil) || (getLegacyShield(with: representation) != nil)
    }
    
    func getLegacyShield(with representation: VisualInstruction.Component.ImageRepresentation?) -> UIImage? {
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png) else {
            return nil
        }
        return getImage(with: legacyURL)
    }
    
    func getImage(with url: URL) -> UIImage? {
        guard let data = requestCache.response(for: url)?.data else {
            return nil
        }
        return UIImage(data: data, scale: VisualInstruction.Component.scale)
    }
    
    func getSpriteImage() -> UIImage? {
        // Use the styleID of current repository to retrieve Sprite image.
        guard let styleID = styleID,
              let spriteURL = spriteURL(isImage: true, styleID: styleID) else { return nil }
        return getImage(with: spriteURL)
    }
    
    func getSpriteInfo() -> Data? {
        guard let styleID = styleID,
              let infoURL = spriteURL(isImage: false, styleID: styleID) else { return nil }
        return requestCache.response(for: infoURL)?.data
    }
    
    func getSpriteInfo(with key: String) -> SpriteInfo? {
        guard let data = getSpriteInfo(),
              let spriteInfoDictionary = parseSpriteInfo(data: data) else {
            return nil
        }
        
        return spriteInfoDictionary[key]
    }
    
    func parseSpriteInfo(data: Data) -> [String: SpriteInfo]? {
        do {
            let decodedObject = try JSONDecoder().decode([String : SpriteInfo].self, from: data)
            return decodedObject
        } catch {
            Log.error("Failed to parse requested data to Sprite info due to: \(error.localizedDescription).", category: .navigationUI)
        }
        return nil
    }
    
    func resetStyleCache() {
        guard let styleID = styleID,
              let infoRequestURL = spriteURL(isImage: false, styleID: styleID),
              let spriteRequestURL = spriteURL(isImage: true, styleID: styleID) else { return }
        requestCache.removeCache(for: infoRequestURL)
        requestCache.removeCache(for: spriteRequestURL)
    }
    
    func resetCache(completion: CompletionHandler? = nil) {
        requestCache.clearCache()
        derivedCache.clearMemory()
        derivedCache.clearDisk(completion: completion)
    }

}

struct SpriteInfo: Codable, Equatable {
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var pixelRatio: Int
    var placeholder: [Double]?
    var visible: Bool
}
