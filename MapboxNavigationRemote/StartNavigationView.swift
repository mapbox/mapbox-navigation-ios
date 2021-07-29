import Foundation
import SwiftUI
import MapboxNavigationRemoteKit
import CoreLocation
import MultipeerKit

struct StartNavigationView: View {
    @State private var latitude: String = ""
    @State private var longitude: String = ""

    var body: some View {
        Form {
            CurrentLocationView(vm: Current.currentLocationVM)
            TextField("Latitude", text: $latitude)
            TextField("Longitude", text: $longitude)
            Button("Navigate") {
                guard let destination = parseDestination() else { return }
                Current.transceiver.send(StartNavigationAction(destination: destination),
                                         to: Current.peers)
            }
        }
        .padding()
    }

    private func parseDestination() -> CLLocationCoordinate2D? {
        guard let lat = CLLocationDegrees(latitude),
              let lon = CLLocationDegrees(longitude) else {
                  return nil
              }
        return .init(
            latitude: lat,
            longitude: lon
        )
    }
}
