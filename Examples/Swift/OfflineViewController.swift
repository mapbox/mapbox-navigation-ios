import UIKit
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

class OfflineViewController: UIViewController {
    
    var mapView: MGLMapView!
    var resizableView: ResizableView!
    var backgroundLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        view.addSubview(mapView)
        
        backgroundLayer.frame = view.bounds
        backgroundLayer.fillColor = #colorLiteral(red: 0.1450980392, green: 0.2588235294, blue: 0.3725490196, alpha: 0.196852993).cgColor
        view.layer.addSublayer(backgroundLayer)
        
        resizableView = ResizableView(frame: CGRect(origin: view.center,
                                                    size: CGSize(width: 50, height: 50)), backgroundLayer: backgroundLayer)
        view.addSubview(resizableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .done, target: self, action: #selector(downloadRegion))
    }
    
    @objc func downloadRegion() {
        
        let northWest = mapView.convert(resizableView.frame.minXY, toCoordinateFrom: nil)
        let southEast = mapView.convert(resizableView.frame.maxXY, toCoordinateFrom: nil)
        
        let boundingBox = BoundingBox([northWest, southEast])
        
        Directions.shared.availableOfflineVersions { (versions, error) in
            guard let version = versions?.first else { return }
            
            Directions.shared.downloadTiles(for: boundingBox, version: version, completionHandler: { (url, response, error) in
                
                guard let url = url else { return assert(false, "Unable to locate temporary file") }
                let outputDirectory = Bundle.mapboxCoreNavigation.suggestedTilePath(for: version)
                outputDirectory?.ensureDirectoryExists()
                
                NavigationDirections.unpackTilePack(at: url, outputDirectory: outputDirectory!, progressHandler: { (totalBytes, bytesRemaining) in
                    
                }, completionHandler: { (result, error) in
                    
                    print("!!! Unpacking complete \(result) \(String(describing: error))")
                })
            }).resume()
        }.resume()
        
        navigationItem.rightBarButtonItem = nil
    }
}

extension CGRect {
    
    var minXY: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    
    var maxXY: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
}

extension URL {
    
    func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
    }
}
