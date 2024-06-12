import MapboxNavigationCore
import SwiftUI

struct ContentView: View {
    @ObservedObject var navigation: Navigation

    var body: some View {
        ZStack {
            VStack {
                MapView(navigation: navigation)
                    .ignoresSafeArea(.all)
                HStack {
                    if navigation.currentPreviewRoutes == nil, !navigation.isInActiveNavigation {
                        Text("Long press anywhere to build a route")
                    } else if navigation.currentPreviewRoutes != nil {
                        Button("Clear") {
                            navigation.cancelPreview()
                        }
                        Spacer()
                        Button("Start navigation") {
                            navigation.startActiveNavigation()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 45)
            }
            if navigation.isInActiveNavigation {
                NavigationControlsView(navigation: navigation)
            } else {
                SettingsControlsView(navigation: navigation)
            }
        }
    }
}

#if swift(>=5.9)
#Preview {
    ContentView(navigation: Navigation())
}
#endif
