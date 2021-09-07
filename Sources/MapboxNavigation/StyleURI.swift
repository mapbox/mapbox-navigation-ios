import MapboxMaps

extension StyleURI {
    /// Mapbox Navigation Day is a navigation-optimized style with a light backdrop for normal lighting conditions.
    public static var navigationDay: StyleURI {
        return ResourceOptionsManager.hasChinaBaseURL ? streetsChinese : StyleURI(url: URL(string:"mapbox://styles/mapbox/navigation-day-v1")!)!
    }
    
    /// Mapbox Navigation Night is a navigation-optimized style with a dark backdrop for low-light conditions.
    public static var navigationNight: StyleURI {
        return ResourceOptionsManager.hasChinaBaseURL ? darkChinese : StyleURI(url: URL(string:"mapbox://styles/mapbox/navigation-night-v1")!)!
    }
    
    /// Mapbox Streets Chinese is variation of `streets` optimized for use as an alternative to `navigationDay` in China.
    static let streetsChinese = StyleURI(url: URL(string: "mapbox://styles/mapbox/streets-zh-v1")!)!
    
    /// Mapbox Dark Chinese is variation of `dark` optimized for use as an alternative to `navigationNight` in China.
    static let darkChinese = StyleURI(url: URL(string:"mapbox://styles/mapbox/dark-zh-v1")!)!
}
