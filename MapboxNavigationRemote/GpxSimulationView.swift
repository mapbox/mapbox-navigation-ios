import SwiftUI
import MapboxNavigationRemoteKit

struct GpxSimulationView: View {
    @State var rawGpx: String?
    @State var name: String?

    var body: some View {
        Form {
            Button("Open GPX File") {
                openFile { url in
                    do {
                        rawGpx = try String(contentsOf: url)
                        name = url.lastPathComponent
                    }
                    catch {
                        print(error)
                    }
                }
            }
            if let rawGpx = rawGpx {
                GpxViewer(rawGpx: rawGpx, name: name ?? "Error.gpx", dismissEnabled: false)
            }
        }
    }
}
