import MapboxNavigationCore

enum CarPlayWayNameViewConfiguration {
    static func shouldHideWayNameView(
        activity: CarPlayActivity?,
        cameraState: NavigationCameraState
    ) -> Bool {
        guard cameraState == .following else { return true }

        switch activity {
        case .panningInBrowsingMode, .panningInNavigationMode, .previewing:
            return true
        case .browsing, .navigating, nil:
            return false
        }
    }
}
