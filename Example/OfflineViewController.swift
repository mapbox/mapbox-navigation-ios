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
        
        resizableView = ResizableView(frame: CGRect(origin: view.center, size: CGSize(width: 50, height: 50)),
                                      backgroundLayer: backgroundLayer)
        
        view.addSubview(resizableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("OFFLINE_ITEM_DOWNLOAD", value: "Download", comment: "Title of button that downloads an offline region"), style: .done, target: self, action: #selector(downloadRegion))
    }
    
    @objc func downloadRegion() {
        
        // Hide the download button so we can't download the same region twice
        navigationItem.rightBarButtonItem = nil
        
        let northWest = mapView.convert(resizableView.frame.minXY, toCoordinateFrom: nil)
        let southEast = mapView.convert(resizableView.frame.maxXY, toCoordinateFrom: nil)
        
        let coordinateBounds = CoordinateBounds([northWest, southEast])
        
        updateTitle(NSLocalizedString("OFFLINE_TITLE_FETCHING_VERSIONS", value: "Fetching Versions…", comment: "Status item while downloading an offline region"))
        
        Directions.shared.fetchAvailableOfflineVersions { [weak self] (versions, error) in
            
            guard let version = versions?.first(where: { !$0.isEmpty } ) else { return }
            
            self?.updateTitle(NSLocalizedString("OFFLINE_TITLE_DOWNLOADING_TILES", value: "Downloading Tiles…", comment: "Status item while downloading an offline region"))
            
            Directions.shared.downloadTiles(in: coordinateBounds, version: version, completionHandler: { (url, response, error) in
                guard let url = url else { return assert(false, "Unable to locate temporary file") }
                
                let outputDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: version)
                outputDirectoryURL?.ensureDirectoryExists()
                
                NavigationDirections.unpackTilePack(at: url, outputDirectoryURL: outputDirectoryURL!, progressHandler: { (totalBytes, bytesRemaining) in

                    let progress = Float(bytesRemaining) / Float(totalBytes)
                    let formattedProgress = NumberFormatter.localizedString(from: progress as NSNumber, number: .percent)
                    let title = String.localizedStringWithFormat(NSLocalizedString("OFFLINE_TITLE_UNPACKING_FMT", value: "Unpacking… (%@)", comment: "Status item while downloading an offline region; 1 = percentage complete"), formattedProgress)
                    self?.updateTitle(title)

                }, completionHandler: { (result, error) in

                    self?.navigationController?.popViewController(animated: true)
                })
            }).resume()
        }.resume()
    }
    
    func updateTitle(_ string: String) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.title = string
        }
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
