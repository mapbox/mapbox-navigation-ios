import UIKit
import Mapbox
import MapboxDirections


class OfflineViewController: UIViewController {
    
    var mapView: MGLMapView!
    var resizableView: ResizableView!
    var backgroundLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        view.addSubview(mapView)
        
        backgroundLayer.frame = view.bounds
        backgroundLayer.backgroundColor = #colorLiteral(red: 0.1450980392, green: 0.2588235294, blue: 0.3725490196, alpha: 0.196852993).cgColor
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
        
        let boundingBox = BoundingBox(northWest: northWest, southEast: southEast)
        
        Directions.shared.availableOfflineVersions { (versions, error) in
            guard let version = versions?.first else { return }
            
            Directions.shared.downloadTiles(for: boundingBox, version: version, progressHandler: { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                
            }, completionHandler: { (url, response, error) in
                print("Downloaded \(url!)")
                // TODO: Move temporary file to cache folder
            })
        }
        
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
