import UIKit
import Mapbox
import Turf
import MapboxDirections
import MapboxCoreNavigation

class OfflineViewController: UIViewController, MGLMapViewDelegate {
    var mapView: MGLMapView!
    var resizableView: ResizableView!
    var backgroundLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MGLMapView(frame: view.bounds)
        mapView.delegate = self

        view.addSubview(mapView)
        
        backgroundLayer.frame = view.bounds
        backgroundLayer.fillColor = #colorLiteral(red: 0.1450980392, green: 0.2588235294, blue: 0.3725490196, alpha: 0.196852993).cgColor
        view.layer.addSublayer(backgroundLayer)
        
        resizableView = ResizableView(frame: CGRect(origin: view.center, size: CGSize(width: 50, height: 50)),
                                      backgroundLayer: backgroundLayer)
        
        view.addSubview(resizableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("OFFLINE_ITEM_DOWNLOAD", value: "Download", comment: "Title of button that downloads an offline region"), style: .done, target: self, action: #selector(downloadRegion))
    }

    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        mapView.setUserTrackingMode(.follow, animated: false, completionHandler: nil)
        mapView.setZoomLevel(8, animated: false)
    }
    
    func disableUserInterface() {
        updateTitle(NSLocalizedString("OFFLINE_TITLE_FETCHING_VERSIONS", value: "Fetching Versions…", comment: "Status item while downloading an offline region"))
        navigationItem.rightBarButtonItem?.isEnabled = false
        view.isUserInteractionEnabled = false
    }
    
    func enableUserInterface() {
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.title = nil
        view.isUserInteractionEnabled = true
    }
    
    @objc func downloadRegion() {
        let mapCoordinateBounds = mapView.convert(resizableView.frame, toCoordinateBoundsFrom: nil)
        let coordinateBounds = BoundingBox(mapCoordinateBounds.sw, mapCoordinateBounds.ne)
        
        disableUserInterface()
        
        _ = Directions.shared.fetchAvailableOfflineVersions { [weak self] (versions, error) in
            guard let version = versions?.first(where: { !$0.isEmpty } ) else {
                let title = NSLocalizedString("OFFLINE_TITLE_VERSION_FETCHING_FAILED", value:"Unable to fetch available routing tile versions", comment: "Error title to display when no routing tile versions are available")
                let message = NSLocalizedString("OFFLINE_MESSAGE_VERSION_FETCHING_FAILED", value:"No routing tile versions are available for download. Please try again later.", comment: "Error message to display when no routing tile versions are available")
                self?.presentAlert(title, message: message)
                return
            }
            
            self?.updateTitle(NSLocalizedString("OFFLINE_TITLE_DOWNLOADING_TILES", value: "Downloading Tiles…", comment: "Status item while downloading an offline region"))
            
            _ = Directions.shared.downloadTiles(in: coordinateBounds, version: version) { (url, response, error) in
                guard let url = url else { return assert(false, "Unable to locate temporary file") }
                
                if let response = response as? HTTPURLResponse {
                    // if 402, need to upgrade the token
                    if response.statusCode == 402 {
                        DispatchQueue.main.async { [weak self] in
                            let title = NSLocalizedString("OFFLINE_TITLE_TILE_DOWNLOAD_FAILED", value: "Unable to fetch tiles", comment: "Title to display when tile downloading fails")
                            let message = NSLocalizedString("OFFLINE_MESSAGE_ENTERPRISE_TOKEN_NEEDED", value: "Before you can fetch routing tiles you must obtain an enterprise access token. Please contact us at support@mapbox.com", comment: "Message to display when the user needs to obtain an enterprise token")
                            self?.presentAlert(title, message: message)
                            self?.enableUserInterface()
                        }
                        return
                    }

                    // if 422, too many tiles were requested
                    if response.statusCode == 422 {
                        DispatchQueue.main.async { [weak self] in
                            let title = NSLocalizedString("OFFLINE_TITLE_TILE_DOWNLOAD_FAILED", value: "Unable to fetch tiles", comment: "Title to display when tile downloading fails")
                            let message = NSLocalizedString("OFFLINE_MESSAGE_USE_SMALLER_BOUNDING_BOX", value: "The bounding box you have specified is too large. Please select a smaller box and try again.", comment: "Message to display when the user needs to select a smaller bounding box")
                            self?.presentAlert(title, message: message)
                            self?.enableUserInterface()
                        }
                        return
                    }
                }
                
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
            }
        }
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
