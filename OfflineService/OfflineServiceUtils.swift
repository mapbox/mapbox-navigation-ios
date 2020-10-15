import Foundation
import Mapbox

/**
 Method allows to clean-up ambient cache which was created by Maps SDK.
 */
func clearMapsAmbientCache() {
    MGLOfflineStorage.shared.clearAmbientCache { (error) in
        guard let error = error else { return }
        NSLog("Error occured while clearing ambient cache: \(error.localizedDescription)")
    }
}

/**
 Method allows to clean-up ambient cache which was created by Navigation SDK (e.g. during free-drive).
 */
func clearNavigationAmbientCache() {
    guard var tilesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        NSLog("Failed to locate tilesURL.")
        return
    }
    
    if let bundleIdentifier = Bundle.main.bundleIdentifier ?? Bundle.mapboxCoreNavigation.bundleIdentifier {
        tilesURL.appendPathComponent(bundleIdentifier, isDirectory: true)
    }
    tilesURL.appendPathComponent(".mapbox", isDirectory: true)
    
    do {
        NSLog("Removing navigation ambient cache (e.g. cache generated during free drive) at path: \(tilesURL.path)")
        try FileManager().removeItem(at: tilesURL)
    } catch {
        NSLog("Error occured while removing navigation ambient cache: \(error.localizedDescription)")
    }
}
