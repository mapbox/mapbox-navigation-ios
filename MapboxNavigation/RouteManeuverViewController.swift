import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage

class RouteManeuverViewController: UIViewController {
    @IBOutlet fileprivate weak var distanceLabel: DistanceLabel!
    @IBOutlet fileprivate weak var shieldImageView: UIImageView!
    @IBOutlet weak var turnArrowView: TurnArrowView!
    @IBOutlet weak var destinationLabel: DestinationLabel!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    let visualInstructionFormatter = VisualInstructionFormatter()
    
    var step: RouteStep? {
        didSet {
            if isViewLoaded {
                roadCode = step?.codes?.first ?? step?.destinationCodes?.first ?? step?.destinations?.first
                updateStreetNameForStep()
            }
        }
    }
    
    var leg: RouteLeg? {
        didSet {
            if isViewLoaded {
                updateStreetNameForStep()
            }
        }
    }
    
    var distance: CLLocationDistance? {
        didSet {
            if let distance = distance {
                distanceLabel.isHidden = false
                distanceLabel.text = distanceFormatter.string(from: distance)
                destinationLabel.numberOfLines = numberOfDestinationLines
            } else {
                distanceLabel.isHidden = true
                distanceLabel.text = nil
                destinationLabel.numberOfLines = numberOfDestinationLines
            }
        }
    }
    
    var numberOfDestinationLines: Int {
        return distance != nil ? 2 : 3
    }
    
    var roadCode: String? {
        didSet {
            guard roadCode != oldValue, let components = roadCode?.components(separatedBy: " ") else {
                return
            }
            
            if components.count == 2 || (components.count == 3 && ["North", "South", "East", "West", "Nord", "Sud", "Est", "Ouest", "Norte", "Sur", "Este", "Oeste"].contains(components[2])) {
                shieldAPIDataTask = dataTaskForShieldImage(network: components[0], number: components[1], height: 32 * UIScreen.main.scale) { [weak self] (image) in
                    self?.shieldImage = image
                }
                shieldAPIDataTask?.resume()
                if shieldAPIDataTask == nil {
                    shieldImage = nil
                }
            } else {
                shieldImage = nil
            }
        }
    }
    var shieldImage: UIImage? {
        didSet {
            shieldImageView.image = shieldImage
            updateStreetNameForStep()
        }
    }
    
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    let webImageManager = SDWebImageManager.shared()
    
    var availableStreetLabelBounds: CGRect {
        return CGRect(origin: .zero, size: maximumAvailableStreetLabelSize)
    }
    
    /** 
     Returns maximum available size for street label with padding, turnArrowView and shieldImage taken into account. Multiple lines will be used if distance is nil.
     
     width = | -8- TurnArrowView -8- availableWidth -8- shieldImage -8- |
     */
    var maximumAvailableStreetLabelSize: CGSize {
        get {
            let height = ("|" as NSString).size(attributes: [NSFontAttributeName: destinationLabel.font]).height
            let lines = CGFloat(numberOfDestinationLines)
            let padding: CGFloat = 8*4
            return CGSize(width: view.bounds.width-padding-shieldImageView.bounds.size.width-turnArrowView.bounds.width, height: height*lines)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        turnArrowView.backgroundColor = .clear
        destinationLabel.availableBounds = {[weak self] in CGRect(origin: .zero, size: self != nil ? self!.maximumAvailableStreetLabelSize : .zero) }
    }
    
    deinit {
        webImageManager.cancelAll()
    }
    
    func notifyDidChange(routeProgress: RouteProgress, secondsRemaining: TimeInterval) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        
        distance = distanceRemaining > 5 ? distanceRemaining : 0
        
        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            distance = nil
            destinationLabel.unabridgedText = routeProgress.currentLeg.destination.name ?? routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep, legIndex: routeProgress.legIndex, numberOfLegs: routeProgress.route.legs.count, markUpWithSSML: false))
        } else {
            updateStreetNameForStep()
        }
        
        turnArrowView.step = routeProgress.currentLegProgress.upComingStep
    }

    func dataTaskForShieldImage(network: String, number: String, height: CGFloat, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let imageNamePattern = ShieldImageNamesByPrefix[network] else {
            return nil
        }

        let imageName = imageNamePattern.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "{ref}", with: number)
        let apiURL = URL(string: "https://commons.wikimedia.org/w/api.php?action=query&format=json&maxage=86400&prop=imageinfo&titles=File%3A\(imageName)&iiprop=url%7Csize&iiurlheight=\(Int(round(height)))")!

        shieldAPIDataTask?.cancel()
        return URLSession.shared.dataTask(with: apiURL) { [weak self] (data, response, error) in
            var json: [String: Any] = [:]
            if let data = data, response?.mimeType == "application/json" {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                } catch {
                    assert(false, "Invalid data")
                }
            }

            guard data != nil && error == nil else {
                return
            }

            guard let query = json["query"] as? [String: Any],
                let pages = query["pages"] as? [String: Any], let page = pages.first?.1 as? [String: Any],
                let imageInfos = page["imageinfo"] as? [[String: Any]], let imageInfo = imageInfos.first,
                let thumbURLString = imageInfo["thumburl"] as? String, let thumbURL = URL(string: thumbURLString) else {
                    return
            }

            if thumbURL != self?.shieldImageDownloadToken?.url {
                self?.webImageManager.imageDownloader?.cancel(self?.shieldImageDownloadToken)
            }
            self?.shieldImageDownloadToken = self?.webImageManager.imageDownloader?.downloadImage(with: thumbURL, options: .scaleDownLargeImages, progress: nil) { (image, data, error, isFinished) in
                completion(image)
            }
        }
    }
    
    func updateStreetNameForStep() {
        destinationLabel.unabridgedText = visualInstructionFormatter.string(leg: leg, step: step)
    }
}
