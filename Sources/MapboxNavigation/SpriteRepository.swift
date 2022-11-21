import UIKit
import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

class SpriteRepository {
    let baseURL: URL = URL(string: "https://api.mapbox.com/styles/v1")!
    private let defaultStyleURI: StyleURI = .navigationDay
    private let requestTimeOut: TimeInterval = 10
    private(set) var userInterfaceIdiomStyles = [UIUserInterfaceIdiom: StyleURI]()

    private(set) var imageDownloader: ReentrantImageDownloader
    let requestCache: URLCaching
    let derivedCache: BimodalImageCache

    var sessionConfiguration: URLSessionConfiguration {
        didSet {
            imageDownloader = ImageDownloader(sessionConfiguration: sessionConfiguration)
        }
    }

    static let shared = SpriteRepository.init()

    init(imageDownloader: ReentrantImageDownloader? = nil,
         requestCache: URLCaching = URLDataCache(),
         derivedCache: BimodalImageCache = ImageCache()) {
        self.sessionConfiguration = URLSessionConfiguration.default
        self.sessionConfiguration.timeoutIntervalForRequest = self.requestTimeOut
        self.requestCache = requestCache
        self.derivedCache = derivedCache

        self.imageDownloader = imageDownloader ?? ImageDownloader(sessionConfiguration: sessionConfiguration)
    }

    func updateStyle(styleURI: StyleURI?,
                     idiom: UIUserInterfaceIdiom = .phone,
                     completion: @escaping ImageDownloadCompletionHandler) {
        // If no valid StyleURI provided, use the default Day style.
        let newStyleURI = styleURI ?? defaultStyleURI
        userInterfaceIdiomStyles[idiom] = newStyleURI
        
        guard needToUpdateSprite(styleURI: newStyleURI) else {
            completion(nil)
            return
        }
        
        updateSprite(styleURI: newStyleURI, completion: completion)
    }

    func updateRepresentation(for representation: VisualInstruction.Component.ImageRepresentation?,
                              idiom: UIUserInterfaceIdiom = .phone,
                              completion: @escaping ImageDownloadCompletionHandler) {
        let dispatchGroup = DispatchGroup()
        var downloadError: DownloadError? = nil

        if userInterfaceIdiomStyles[idiom] == nil {
            userInterfaceIdiomStyles[idiom] = userInterfaceIdiomStyles.values.first ?? defaultStyleURI
        }
        
        if let styleURI = userInterfaceIdiomStyles[idiom], needToUpdateSprite(styleURI: styleURI) {
            dispatchGroup.enter()
            updateSprite(styleURI: styleURI) { (error) in
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
    
    func updateSprite(styleURI: StyleURI, completion: @escaping ImageDownloadCompletionHandler) {
        guard let styleID = styleID(for: styleURI),
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
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png) else {
            completion(.clientError)
            return
        }

        downloadImage(imageURL: legacyURL) { (image) in
            let downloadError: DownloadError? = (image == nil) ? .noImageData : nil
            completion(downloadError)
        }
    }
    
    func needToUpdateSprite(styleURI: StyleURI) -> Bool {
        return (getSpriteInfo(styleURI: styleURI) == nil || getSpriteImage(styleURI: styleURI) == nil)
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
    
    func roadShieldImage(from shieldRepresentation: VisualInstruction.Component.ShieldRepresentation?,
                         idiom: UIUserInterfaceIdiom = .phone) -> UIImage? {
        guard let styleURI = userInterfaceIdiomStyles[idiom],
              let styleID = styleID(for: styleURI),
              let shield = shieldRepresentation else { return nil }
        
        let iconLeght = max(shield.text.count, 2)
        let shieldKey = shield.name + "-\(iconLeght)"
        let compositeKey = shieldKey + "-\(styleID)"
        
        // Retrieve the single shield icon if it has been cached.
        if let shieldIcon = derivedCache.image(forKey: compositeKey) {
            return shieldIcon
        }
        
        guard let spriteImage = getSpriteImage(styleURI: styleURI),
              let spriteInfo = getSpriteInfo(styleURI: styleURI, with: shieldKey) else { return nil }
        
        let shieldRect = CGRect(x: spriteInfo.x, y: spriteInfo.y, width: spriteInfo.width, height: spriteInfo.height)
        if let croppedCGIImage = spriteImage.cgImage?.cropping(to: shieldRect) {
            
            // Cache the single shield icon if it hasn't been stored.
            let shieldIcon = UIImage(cgImage: croppedCGIImage)
            derivedCache.store(shieldIcon, forKey: compositeKey, toDisk: true, completion: nil)
            
            return shieldIcon
        }
        
        return nil
    }
    
    func shieldCached(for representation: VisualInstruction.Component.ImageRepresentation?,
                      idiom: UIUserInterfaceIdiom = .phone) -> Bool {
        let generalShieldCached = roadShieldImage(from: representation?.shield, idiom: idiom) != nil
        return generalShieldCached || (getLegacyShield(with: representation) != nil)
    }
    
    func getLegacyShield(with representation: VisualInstruction.Component.ImageRepresentation?) -> UIImage? {
        guard let legacyURL = representation?.imageURL(scale: VisualInstruction.Component.scale, format: .png) else {
            return nil
        }
        return getImage(with: legacyURL)
    }
    
    func styleID(for styleURI: StyleURI) -> String? {
        return styleURI.rawValue.components(separatedBy: "styles")[safe: 1]
    }
    
    func styleID(for idiom: UIUserInterfaceIdiom) -> String? {
        guard let styleURI = userInterfaceIdiomStyles[idiom] else { return nil }
        return styleID(for: styleURI)
    }
    
    func getImage(with url: URL) -> UIImage? {
        guard let data = requestCache.response(for: url)?.data else {
            return nil
        }
        return UIImage(data: data, scale: VisualInstruction.Component.scale)
    }
    
    func getSpriteImage(styleURI: StyleURI) -> UIImage? {
        // Use the styleID of current repository to retrieve Sprite image.
        guard let styleID = styleID(for: styleURI),
              let spriteURL = spriteURL(isImage: true, styleID: styleID) else { return nil }
        return getImage(with: spriteURL)
    }
    
    func getSpriteInfo(styleURI: StyleURI) -> Data? {
        guard let styleID = styleID(for: styleURI),
              let infoURL = spriteURL(isImage: false, styleID: styleID) else { return  nil }
        return requestCache.response(for: infoURL)?.data
    }
    
    func getSpriteInfo(styleURI: StyleURI, with key: String) -> SpriteInfo? {
        guard let data = getSpriteInfo(styleURI: styleURI),
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
    
    func removeStyleCacheFor(_ styleURI: StyleURI) {
        guard let styleID = styleID(for: styleURI),
              let infoRequestURL = spriteURL(isImage: false, styleID: styleID),
              let spriteRequestURL = spriteURL(isImage: true, styleID: styleID) else { return }
        requestCache.removeCache(for: infoRequestURL)
        requestCache.removeCache(for: spriteRequestURL)
    }
    
    func resetCache(completion: CompletionHandler? = nil) {
        userInterfaceIdiomStyles.removeAll()
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
