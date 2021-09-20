import SwiftUI
import MapboxCoreNavigation
import MapboxDirections
import CoreLocation

struct ContentView: View {
    var body: some View {
        VStack(spacing: 14) {
            Button("Request route") {
                let routeOptions = RouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 10, longitude: 10),
                    CLLocationCoordinate2D(latitude: 11, longitude: 11)
                ])
                Directions.shared.calculate(routeOptions) { _, result in
                    switch result {
                    case .success:
                        print("Success")
                    case .failure:
                        print("Failure")
                    }
                }
            }
            Button("Send CarPlay event") {
                let eventsManager = NavigationEventsManager()
                eventsManager.sendCarPlayConnectEvent()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
