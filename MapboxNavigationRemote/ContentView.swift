import SwiftUI
import MultipeerKit
import Combine

struct ContentView: View {
    @State private var showErrorAlert = false

    var body: some View {
        PeersListView()
            .listStyle(.sidebar)
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Please select a peer"), message: nil, dismissButton: nil)
            }
    }

}
