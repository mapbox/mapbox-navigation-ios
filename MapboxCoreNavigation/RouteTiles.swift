import Foundation
import MapboxDirections

private struct RouteTileVersion: Decodable {
    let availableVersions: [String]
}

/**
 `RouteTiles` object describes the meta-information about the route tiles.
 */
final class RouteTilesVersion {
    
    // MARK: Constants
    
    private enum Constants {
        /// Default route tile version to use.
        static let defaultVersion = "2020_07_03-03_00_00"
    }

    private enum UserDefaultsKey {
        /// The key in UserDefaults where is the current route tiles version is stored.
        static let currentRouteTilesVersion = "currentRouteTilesVersionKey"
    }
    
    // MARK: Initializers
    init(with credentials: DirectionsCredentials) {
        directionsCredentials = credentials
    }

    // MARK: Internal properties
    
    /// Current version of route tiles to use.
    var currentVersion: String {
        get {
            UserDefaults.standard.string(forKey: UserDefaultsKey.currentRouteTilesVersion) ?? Constants.defaultVersion
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: UserDefaultsKey.currentRouteTilesVersion)
        }
    }
    
    // MARK: Private properties

    private let directionsCredentials: DirectionsCredentials

    /// URL to request the availalbe version of route tiles format.
    private var requestVersionsURL: URL? {
        let requestVersionsURLString = directionsCredentials.host.absoluteString +
                                       "/route-tiles/v1/versions" +
                                       "?access_token=" + (directionsCredentials.accessToken ?? "")
        return URL(string: requestVersionsURLString)
    }
    
    // MARK: Private methods
    
    /**
     Gets available tiles versions.
     
     - Parameter completionHandlerQueue:
     - Parameter completion:
     */
    func getAvailableVersions(completionHandlerQueue: DispatchQueue = DispatchQueue.main,
                              completion: @escaping ([String]) -> ()) {
    
        guard let requestURL = requestVersionsURL else {
            completionHandlerQueue.async {
                completion([])
            }
            return
        }
    
        URLSession.shared.dataTask(with: requestURL) { data, response, error in
            guard
                error == nil, let data = data,
                let decodedData = try? JSONDecoder().decode(RouteTileVersion.self, from: data)
            else {
                completionHandlerQueue.async {
                    completion([])
                }
                return
            }

            completionHandlerQueue.async {
                completion(decodedData.availableVersions)
            }
        }.resume()
    }
}
