import Foundation

extension URL {
    
    static func shieldURL(network: String, number: String, height: CGFloat) -> URL? {
        guard let imageNamePattern = ShieldImageNamesByPrefix[network] else { return nil }
        let imageName = imageNamePattern.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "{ref}", with: number)
        return URL(string: "https://commons.wikimedia.org/w/api.php?action=query&format=json&maxage=86400&prop=imageinfo&titles=File%3A\(imageName)&iiprop=url%7Csize&iiurlheight=\(Int(round(height)))")
    }
    
    static func shieldImageURL(shieldURL: URL, completion: @escaping (URL?) -> Void) {
        URLSession.shared.dataTask(with: shieldURL) { (data, response, error) in
            var json: [String: Any] = [:]
            if let data = data, response?.mimeType == "application/json" {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                } catch {
                    assert(false, "Invalid data")
                }
            }
            
            guard data != nil && error == nil else {
                completion(nil)
                return
            }
            
            guard let query = json["query"] as? [String: Any],
                let pages = query["pages"] as? [String: Any], let page = pages.first?.1 as? [String: Any],
                let imageInfos = page["imageinfo"] as? [[String: Any]], let imageInfo = imageInfos.first,
                let thumbURLString = imageInfo["thumburl"] as? String, let thumbURL = URL(string: thumbURLString) else {
                    completion(nil)
                    return
            }
            
            completion(thumbURL)
        }.resume()
    }
}
