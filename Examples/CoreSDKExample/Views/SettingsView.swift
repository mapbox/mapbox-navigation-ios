import MapboxNavigationCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var navigation: Navigation

    var body: some View {
        NavigationView {
            Form {
                Toggle("Map Matching Request", isOn: $navigation.shouldRequestMapMatching)
                Picker("Navigation Profile", selection: $navigation.profileIdentifier) {
                    ForEach(SettingsView.profiles, id: \.self) { profile in
                        Text(profile.displayName).tag(profile)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private static let profiles: [ProfileIdentifier] = [
        .automobileAvoidingTraffic,
        .automobile,
        .cycling,
        .walking,
    ]
}

struct SettingsControlsView: View {
    @ObservedObject var navigation: Navigation
    @State private var settingsVisible = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    settingsVisible.toggle()
                } label: {
                    Image(systemName: "gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
            Spacer()
        }
        .sheet(isPresented: $settingsVisible) {
            SettingsView(navigation: navigation)
        }
    }
}

extension ProfileIdentifier {
    var displayName: String {
        switch self {
        case .automobile:
            return "driving"
        case .automobileAvoidingTraffic:
            return "driving with traffic"
        case .cycling:
            return "cycling"
        case .walking:
            return "walking"
        default:
            return "-"
        }
    }
}
