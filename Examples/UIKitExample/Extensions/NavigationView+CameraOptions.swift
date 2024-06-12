import MapboxNavigationUIKit
import UIKit

extension NavigationView {
    func configureViewportPadding() {
        navigationMapView.viewportPadding = previewCameraPadding()
    }

    private func previewCameraPadding() -> UIEdgeInsets {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let spacing = 50.0

        if traitCollection.verticalSizeClass == .regular {
            topInset = topBannerContainerView.frame.height
            bottomInset = bottomBannerContainerView.frame.height
            leftInset = 0
            rightInset = 0
        } else {
            topInset = 0
            bottomInset = 0
            leftInset = bottomBannerContainerView.frame.width
            rightInset = 0
        }

        return UIEdgeInsets(
            top: topInset + spacing,
            left: leftInset + spacing,
            bottom: bottomInset + spacing,
            right: rightInset + spacing
        )
    }
}
