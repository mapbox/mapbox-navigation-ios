import UIKit
import MapboxNavigation

class CustomBrowsingViewController: UIViewController, BannerPreviewing {
    
    var configuration: PreviewBannerConfiguration {
        PreviewBannerConfiguration(position: .bottomLeading)
    }
}
