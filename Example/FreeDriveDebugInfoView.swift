import MapboxDirections
import MapboxCoreNavigation
import CoreLocation
import UIKit

class FreeDriveDebugInfoView: UIView, UITableViewDataSource, UITableViewDelegate {
    private let rawLocationLabel: UILabel
    private let locationLabel: UILabel
    private let matchesTable: UITableView
    private var matches: [Match] = []
    var onUpdated: ((CLLocationCoordinate2D, CLLocationCoordinate2D)->Void)?

    init(onUpdated: ((CLLocationCoordinate2D, CLLocationCoordinate2D)->Void)? = nil) {
        self.onUpdated = onUpdated
        rawLocationLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 15))
        locationLabel = UILabel(frame: CGRect(x: 0, y: 15, width: 200, height: 15))
        matchesTable = UITableView(frame: CGRect(x: 0, y: 30, width: 200, height: 120))
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 200),
            heightAnchor.constraint(equalToConstant: 150)
        ])
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(rawLocationLabel)
        addSubview(locationLabel)
        rawLocationLabel.font = UIFont.systemFont(ofSize: 9)
        locationLabel.font = UIFont.systemFont(ofSize: 9)

        addSubview(matchesTable)
        matchesTable.dataSource = self
        matchesTable.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? matches.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "Match with probability: \(matches[indexPath.row].confidence)"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 9)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 15
    }
}

extension FreeDriveDebugInfoView: FreeDriveLocationManagerDelegate {
    func locationManager(_ manager: FreeDriveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
        rawLocationLabel.text = String(format: "RawLoc: %.8f, %.8f", rawLocation.coordinate.latitude, rawLocation.coordinate.longitude)
        locationLabel.text = String(format: "Loc: %.8f, %.8f", location.coordinate.latitude, location.coordinate.longitude)
        // TODO: Populate matches from notification.
        matchesTable.reloadData()
        onUpdated?(rawLocation.coordinate, location.coordinate)
    }
    
    func locationManager(_ manager: FreeDriveLocationManager, didUpdateHeading newHeading: CLHeading) {
    }
    
    func locationManager(_ manager: FreeDriveLocationManager, didFailWithError error: Error) {
    }
}
