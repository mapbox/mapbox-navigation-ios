import UIKit
//
//extension UIImage {
//    class func dataTaskForShieldImage(network: String, number: String, height: CGFloat, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
//        guard let imageNamePattern = ShieldImageNamesByPrefix[network] else {
//            return nil
//        }
//        
//        let imageName = imageNamePattern.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "{ref}", with: number)
//        let apiURL = URL(string: "https://commons.wikimedia.org/w/api.php?action=query&format=json&maxage=86400&prop=imageinfo&titles=File%3A\(imageName)&iiprop=url%7Csize&iiurlheight=\(Int(round(height)))")!
//        /*
//         shieldAPIDataTask = dataTaskForShieldImage(network: components[0], number: components[1], height: 32 * UIScreen.main.scale) { [weak self] (image) in
//         //self?.shieldImage = image
//         }
//         shieldAPIDataTask?.resume()
//         if shieldAPIDataTask == nil {
//         //shieldImage = nil
//         }
//         */
//        //shieldAPIDataTask?.cancel()
////        return URLSession.shared.dataTask(with: apiURL) { [weak self] (data, response, error) in
////            var json: [String: Any] = [:]
////            if let data = data, response?.mimeType == "application/json" {
////                do {
////                    json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
////                } catch {
////                    assert(false, "Invalid data")
////                }
////            }
////
////            guard data != nil && error == nil else {
////                return
////            }
////
////            guard let query = json["query"] as? [String: Any],
////                let pages = query["pages"] as? [String: Any], let page = pages.first?.1 as? [String: Any],
////                let imageInfos = page["imageinfo"] as? [[String: Any]], let imageInfo = imageInfos.first,
////                let thumbURLString = imageInfo["thumburl"] as? String, let thumbURL = URL(string: thumbURLString) else {
////                    return
////            }
//        
////            if thumbURL != self?.shieldImageDownloadToken?.url {
////                self?.webImageManager.imageDownloader?.cancel(self?.shieldImageDownloadToken)
////            }
////            self?.shieldImageDownloadToken = self?.webImageManager.imageDownloader?.downloadImage(with: thumbURL, options: .scaleDownLargeImages, progress: nil) { (image, data, error, isFinished) in
////                completion(image)
////            }
////        }
//    }
//}

