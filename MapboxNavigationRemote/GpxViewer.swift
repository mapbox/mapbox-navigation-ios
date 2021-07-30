import SwiftUI
import CoreGPX
import MapKit
import AppKit
import MapboxNavigationRemoteKit

struct GpxViewer: View {
    struct Annotation: Identifiable {
        let id: UUID = .init()
        let coordinate: CLLocationCoordinate2D
    }

    @Environment(\.presentationMode) var presentationMode

    let gpx: GPXRoot?
    let coordinates: [CLLocationCoordinate2D]
    let rawGpx: String
    let name: String

    init(rawGpx: String, name: String) {
        self.rawGpx = rawGpx
        self.name = name
        gpx = GPXParser(withRawString: rawGpx)?.parsedData()
        coordinates = gpx?.waypoints.compactMap({ waypoint in
            guard let lat = waypoint.latitude,
                  let lon = waypoint.longitude else { return nil }
            return .init(latitude: lat, longitude: lon)
        }) ?? []
    }

    var body: some View {
        Group {
            HStack {
                if let gpx = gpx {
                    GroupBox("Coordinates") {
                        List(gpx.waypoints, id: \.self) { waypoint in
                            Text("\((waypoint.latitude ?? -1).description);\((waypoint.longitude ?? -1).description)")
                                .textSelection(.enabled)
                        }
                    }
                    .frame(width: 250)
                }
                else {
                    HStack {
                        Label("Coudln't parse gpx", systemImage: "xmark.octagon.fill").tint(.red)
                    }
                }

                MapView(coordinates: coordinates)
            }

            HStack {
                Button("Dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Save") {
                    guard let data = rawGpx.data(using: .utf8) else { return }
                    saveFile(data: data, name: name)
                }
                Button("Simulate") {
                    Current.transceiver.send(SimulateLocationAction(coordinates: coordinates), to: Current.peers)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct MapView: NSViewRepresentable {

    typealias NSViewType = MKMapView

    let coordinates: [CLLocationCoordinate2D]

    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator()
    }

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        let p = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(p)
        mapView.setVisibleMapRect(
            p.boundingMapRect,
            edgePadding: NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
            animated: true)
        return mapView
    }

    func updateNSView(_ nsView: MKMapView, context: Context) {

    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
    }
}
