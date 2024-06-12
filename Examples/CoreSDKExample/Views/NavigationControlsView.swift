import CoreLocation
import MapboxNavigationCore
import SwiftUI

struct NavigationControlsView: View {
    @ObservedObject var navigation: Navigation

    var body: some View {
        VStack(spacing: 12) {
            NextInstructionView(visualInstruction: navigation.visualInstruction)

            HStack {
                Spacer()
                CameraButtonView(cameraState: $navigation.cameraState)
            }

            Spacer()

            NavigationProgressView(routeProgress: navigation.routeProgress) {
                navigation.stopActiveNavigation()
            }
        }
        .padding(12)
    }
}

struct NextInstructionView: View {
    let visualInstruction: VisualInstructionBanner?

    var body: some View {
        VStack(alignment: .leading) {
            if let distanceRemaining {
                Text(distanceFormatter.string(fromMeters: distanceRemaining))
                    .font(.title)
            }
            if let text = visualInstruction?.primaryInstruction.text {
                Text(text)
                    .font(.title2)
            }
        }
        .padding()
        .foregroundColor(Color(.label))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
    }

    private var distanceRemaining: CLLocationDistance? {
        visualInstruction?.distanceAlongStep
    }

    private let distanceFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        formatter.numberFormatter = numberFormatter
        return formatter
    }()
}

struct CameraButtonView: View {
    @Binding var cameraState: NavigationCameraState

    var body: some View {
        Button {
            cameraState = newCameraState
        } label: {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .padding()
                .animation(nil, value: imageName)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
    }

    private var imageName: String {
        switch cameraState {
        case .idle, .overview:
            return "location.circle"
        case .following:
            return "location.north.line"
        }
    }

    private var newCameraState: NavigationCameraState {
        switch cameraState {
        case .idle, .overview:
            return .following
        case .following:
            return .overview
        }
    }
}

struct NavigationProgressView: View {
    let routeProgress: RouteProgress?
    let onStopNavigation: () -> Void

    var body: some View {
        HStack {
            etaView
            Spacer()
            endNavigationButton
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
        .shadow(radius: 5)
    }

    private var endNavigationButton: some SwiftUI.View {
        Button {
            onStopNavigation()
        } label: {
            Image(systemName: "xmark.circle")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(Color(.label))
                .frame(width: 50, height: 50)
        }
    }

    private var etaView: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 0) {
            Text(arrivalTimeText)
                .font(.title3)
                .foregroundColor(Color(.label))
            Text(durationRemainingText)
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
            Text(distanceRemainingText)
                .font(.body)
                .foregroundColor(Color(.secondaryLabel))
        }
    }

    private var arrivalTimeText: String {
        durationRemaining
            .flatMap { Date().addingTimeInterval($0) }
            .flatMap { timeFormatter.string(from: $0).lowercased() } ?? "-"
    }

    private var distanceRemainingText: String {
        distanceRemaining.flatMap(distanceFormatter.string(fromMeters:)) ?? "-"
    }

    private var durationRemainingText: String {
        durationRemaining.flatMap(durationRemainingFormatter.string(from:)) ?? "-"
    }

    private var durationRemaining: TimeInterval? {
        routeProgress?.currentLegProgress.durationRemaining
    }

    private var distanceRemaining: CLLocationDistance? {
        routeProgress?.currentLegProgress.distanceRemaining
    }

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private let distanceFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter = numberFormatter
        return formatter
    }()

    private let durationRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
}

#if swift(>=5.9)
#Preview {
    ContentView(navigation: Navigation())
}
#endif
