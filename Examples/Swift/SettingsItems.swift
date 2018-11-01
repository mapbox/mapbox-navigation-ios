import UIKit
import MapboxDirections


extension SettingsViewController {
    
    func sections() -> [Section] {
        
        let offlineItem = Item(title: "Offline", viewControllerType: OfflineViewController.self, payload: nil)
        let downloadSFItem = Item(title: "Download SF region", viewControllerType: nil, payload: {
            
            Directions.shared.availableOfflineVersions(completionHandler: { (versions, error) in
                guard let version = versions?.first else { return }
                let sfBoundingBox = BoundingBox([CLLocationCoordinate2D(latitude: 37.7890, longitude: -122.4337),
                                                 CLLocationCoordinate2D(latitude: 37.7881, longitude: -122.4318)])
                
                Directions.shared.downloadTiles(for: sfBoundingBox, version: version, completionHandler: { (url, response, error) in
                    guard let url = url else { return }
                    print("Downloaded \(url)")
                }).resume()
            }).resume()
        })
        
        return [[offlineItem, downloadSFItem]]
    }
    
}

