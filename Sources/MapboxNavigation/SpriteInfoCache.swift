import UIKit

struct SpriteInfo: Codable, Equatable {
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var pixelRatio: Int
    var placeholder: [Double]?
    var visible: Bool
}

class SpriteInfoWrapper<SpriteSpriteInfo>: NSObject {
    let spriteInfo: SpriteInfo
    
    init(_ spriteInfo: SpriteInfo) {
        self.spriteInfo = spriteInfo
    }
}

class SpriteInfoCache {
    let memoryCache: NSCache<NSString, SpriteInfoWrapper<SpriteInfo>>

    public init() {
        memoryCache = NSCache<NSString, SpriteInfoWrapper<SpriteInfo>>()
        memoryCache.name = "In-Memory SpriteInfo Cache"
        NotificationCenter.default.addObserver(self, selector: #selector(SpriteInfoCache.clearMemory), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /**
     Stores data in the memory cache.
     
     - parameter data: The `Data` that will be parsed and stored in the memory.
     - returns: `true` if the data was successful parsed to SpriteInfo Dictionary and saved in the memory.
     */
    @discardableResult
    func store(_ data: Data) -> Bool {
        guard let spriteInfoDictionary = parseSpriteInfo(data: data) else { return false }
        spriteInfoDictionary.forEach({ storeDataInMemoryCache($0.value, forKey: $0.key) })
        return true
    }

    /**
     Returns `SpriteInfo` from the cache for the given key from the memory cache.
     */
    func spriteInfo(forKey key: String?) -> SpriteInfo? {
        guard let key = key else {
            return nil
        }

        if let spriteInfo = dataFromMemoryCache(forKey: key) {
            return spriteInfo
        }

        return nil
    }
    
    /**
     Parse data to the Sprite info.
     */
    private func parseSpriteInfo(data: Data) -> [String: SpriteInfo]? {
        do {
            let decodedObject = try JSONDecoder().decode([String : SpriteInfo].self, from: data)
            return decodedObject
        } catch {
            NSLog("Failed to parse requested data to Sprite info due to: \(error.localizedDescription).")
        }
        
        return nil
    }

    /**
     Clears out the memory cache.
     */
    @objc func clearMemory() {
        memoryCache.removeAllObjects()
    }

    private func storeDataInMemoryCache(_ spriteInfo: SpriteInfo, forKey key: String) {
        memoryCache.setObject(SpriteInfoWrapper(spriteInfo), forKey: key as NSString)
    }

    private func dataFromMemoryCache(forKey key: String) -> SpriteInfo? {
        if let spriteInfoWrapper = memoryCache.object(forKey: key as NSString) {
            return spriteInfoWrapper.spriteInfo as SpriteInfo
        }
        return nil
    }
}
