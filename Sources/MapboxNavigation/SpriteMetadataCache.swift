import UIKit

public struct SpriteMetaData: Codable, Equatable {
    var width: Int
    var height: Int
    var x: Int
    var y: Int
    var pixelRatio: Int
    var placeholder: [Int]?
    var visible: Bool
}

public class SpriteMetaDataWrapper<SpriteMetaData>: NSObject {
    let spriteMetaData: SpriteMetaData
    
    init(_ spriteMetaData: SpriteMetaData) {
        self.spriteMetaData = spriteMetaData
    }
}

public class SpriteMetaDataCache {
    let memoryCache: NSCache<NSString, SpriteMetaDataWrapper<SpriteMetaData>>

    public init() {
        memoryCache = NSCache<NSString, SpriteMetaDataWrapper<SpriteMetaData>>()
        memoryCache.name = "In-Memory SpriteMetaData Cache"
        NotificationCenter.default.addObserver(self, selector: #selector(SpriteMetaDataCache.clearMemory), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    /**
     Stores data in the memory cache.
     */
    public func store(_ data: Data) {
        guard let spriteMetaDataDictionary = parseSpriteMetatdata(data: data) else { return }
        spriteMetaDataDictionary.forEach({ storeDataInMemoryCache($0.value, forKey: $0.key) })
    }

    /**
     Returns `SpriteMetaData` from the cache for the given key from the memory cache.
     */
    public func spriteMetaData(forKey key: String?) -> SpriteMetaData? {
        guard let key = key else {
            return nil
        }

        if let spriteMetaData = dataFromMemoryCache(forKey: key) {
            return spriteMetaData
        }

        return nil
    }
    
    /**
     Parse data to the Sprite metadata.
     */
    public func parseSpriteMetatdata(data: Data) -> [String: SpriteMetaData]? {
        do {
            let decodedObject = try JSONDecoder().decode([String : SpriteMetaData].self, from: data)
            return decodedObject
        } catch {
            NSLog("Failed to parse requested data to Sprite metadata due to: \(error.localizedDescription).")
        }
        
        return nil
    }

    /**
     Clears out the memory cache.
     */
    @objc public func clearMemory() {
        memoryCache.removeAllObjects()
    }

    private func storeDataInMemoryCache(_ spriteMetaData: SpriteMetaData, forKey key: String) {
        memoryCache.setObject(SpriteMetaDataWrapper(spriteMetaData), forKey: key as NSString)
    }

    private func dataFromMemoryCache(forKey key: String) -> SpriteMetaData? {
        if let spriteMetaDataWrapper = memoryCache.object(forKey: key as NSString) {
            return spriteMetaDataWrapper.spriteMetaData as SpriteMetaData
        }
        return nil
    }
}
