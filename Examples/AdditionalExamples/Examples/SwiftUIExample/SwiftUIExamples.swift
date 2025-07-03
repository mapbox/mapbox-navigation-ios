import MapboxNavigationUIKit
import SwiftUI

struct SwiftUIExamples: View {
    var body: some View {
        List {
            ExampleLink(
                "Single Map",
                note: "Reuse the same NavigationMapView in route preview and active guidance.",
                destination: ReuseNavigationMapView()
            )
//            ExampleLink(
//                "Map transition",
//                note: "Transition from MapView to NavigationMapView and back.",
//                destination: TransitionNavigationMapView()
//            )
        }
    }
}

struct ExampleLink<S, Destination>: View where S: StringProtocol, Destination: View {
    var title: S
    var note: S?
    var destination: () -> Destination
    init(_ title: S, note: S? = nil, destination: @escaping @autoclosure () -> Destination) {
        self.title = title
        self.note = note
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading) {
                Text(title)
                note.map {
                    Text($0)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
