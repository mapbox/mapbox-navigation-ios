import MapboxNavigationCore
import SwiftUI

struct SessionControlsView: View {
    @ObservedObject var navigation: Navigation

    var body: some View {
        Button(action: {
            navigation.toggleNavigationSession()
        }) {
            Text(sessionButtonTitle)
                .fontWeight(.semibold)
                .foregroundColor(Color(.label))
                .padding(8)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 140)
        .background(Color.blue)
        .cornerRadius(8)
    }

    private var sessionButtonTitle: String {
        navigation.state == .idle ? "Resume session" : "Pause session"
    }
}
