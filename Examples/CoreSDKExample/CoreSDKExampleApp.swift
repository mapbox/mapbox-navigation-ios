import SwiftUI

@main
@MainActor
struct CoreSDKExampleApp: App {
    private let navigation = Navigation()

    var body: some Scene {
        WindowGroup {
            ContentView(navigation: navigation)
        }
    }
}
