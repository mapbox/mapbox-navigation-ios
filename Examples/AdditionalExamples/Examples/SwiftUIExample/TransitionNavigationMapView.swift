import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI
import UIKit

struct TransitionNavigationMapView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Map()
            .mapStyle(.standard(lightPreset: .day))
            .ignoresSafeArea()
    }
}
