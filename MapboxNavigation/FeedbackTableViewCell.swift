import UIKit
import MapboxCoreNavigation
import MapboxGeocoder

private extension FeedbackType {
    var color: UIColor {
        switch self {
        case .accident:
            return #colorLiteral(red: 1, green: 0.1857388616, blue: 0.5733950138, alpha: 1)
        case .general:
            return #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
        case .hazard:
            return #colorLiteral(red: 0.5808190107, green: 0.0884276256, blue: 0.3186392188, alpha: 1)
        case .roadClosed:
            return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        case .routingError:
            return #colorLiteral(red: 0.6078253984, green: 0.8280074596, blue: 0.9379094243, alpha: 1)
        case .unallowedTurn:
            return #colorLiteral(red: 0.8963318467, green: 0.127319634, blue: 0, alpha: 1)
        }
    }
}

class FeedbackTableViewCell: UITableViewCell {
    var feedback: FeedbackEvent? {
        didSet {
            updateInterface()
        }
    }
    
    var task: URLSessionDataTask?
    
    @IBOutlet weak var badge: CircularView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
    }
    
    deinit {
        task?.cancel()
        task = nil
    }
    
    private func updateInterface() {
        badge.backgroundColor = feedback?.type?.color
        typeLabel.text = feedback?.type?.description
        
        if let coordinate = feedback?.coordinate {
            locationLabel.text = "\(coordinate.latitude), \(coordinate.longitude)"
            
            let options = ReverseGeocodeOptions(coordinate: coordinate)
            task?.cancel()
            task = Geocoder.shared.geocode(options, completionHandler: { [weak self] (placemarks, attribution, error) in
                guard let placemark = placemarks?.first else { return }
                self?.locationLabel.text = placemark.name
            })
        }
    }
}
