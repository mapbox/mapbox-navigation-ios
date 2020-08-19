import Foundation
import MapboxDirections
import MapboxNavigationNative

private let tilesManager = NavigatorTilesManager()

extension Navigator {
    static func createWith(profile: SettingsProfile, config: NavigatorConfig, customConfig: String) -> Navigator {
        let navigator = Navigator(profile: profile, config: config, customConfig: customConfig)
        tilesManager.getVersion { version in
            guard let version = version else { return }
            navigator.updateTiles(version: version)
        }
        return navigator
    }

    /**
    Creates a cache for tiles of the given version and configures the navigator to use this cache.
    */
    func updateTiles(version: String) {
        let directions = Directions.shared
        let endpointConfig = TileEndpointConfiguration(directions: directions, tilesVersion: version)
        tilesManager.createFolder(forVersion: version)
        if let tilesURL = tilesManager.folder(forVersion: version) {
            let params = RouterParams(tilesPath: tilesURL.path, inMemoryTileCache: nil, mapMatchingSpatialCache: nil, threadsCount: nil, endpointConfig: endpointConfig)

            configureRouter(for: params)
        }
    }
}

class NavigatorTilesManager {
    enum Constants {
        static let tilesFolder = ".mapbox"
        static let tileNameFormat = "yyyy_MM_dd-HH_mm_ss"
        static let lastUpdated = "com.mapbox.NavigatorTilesManager.lastUpdated"
        static let dayInSeconds: TimeInterval = 24 * 60 * 60
    }

    private var versions: [String] = []
    private var lastUpdated: TimeInterval {
        get {
            UserDefaults.standard.double(forKey: Constants.lastUpdated)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.lastUpdated)
            DispatchQueue.main.async {
                self.removeOutdatedTiles()
            }
        }
    }

    func getVersion(completion: @escaping (String?) -> Void) {
        if Date().timeIntervalSince1970 - lastUpdated > Constants.dayInSeconds {
            completion(latestVersion())
        } else {
            updateVersionsList { [weak self] in
                completion(self?.latestVersion())
            }
        }
    }

    func latestVersion() -> String? {
        let versions = downloadedVersions()
        return versions.last
    }

    func folder(forVersion version: String) -> URL? {
        let fileManager = FileManager.default
        // ~/Library/Caches/tld.app.bundle.id/.mapbox/2020_08_08-03_00_00/
        var documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        documentsURL?.appendPathComponent(Constants.tilesFolder, isDirectory: true)
        documentsURL?.appendPathComponent(version, isDirectory: true)
        return documentsURL
    }

    func createFolder(forVersion version: String) {
        guard let folder = folder(forVersion: version) else { return }
        do {
            // Tiles with different versions shouldn't be mixed, it may cause inappropriate Navigator's behaviour
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
        }
    }

    func isDownloaded(version: String) -> Bool {
        let versions = downloadedVersions()
        return versions.contains(version)
    }

    func removeOutdatedTiles() {
        let tilesToRemove = downloadedVersions()
        let latestVersion = self.latestVersion()

        for tileVersion in tilesToRemove {
            if tileVersion != latestVersion {
                remove(version: tileVersion)
            }
        }
    }

    func remove(version: String) {
        let fileManager = FileManager.default
        var versionFolder = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        versionFolder.appendPathComponent(Constants.tilesFolder, isDirectory: true)
        versionFolder.appendPathComponent(version, isDirectory: false)
        do {
            try fileManager.removeItem(at: versionFolder)
        } catch {
        }
    }

    func downloadedVersions() -> [String] {
        let fileManager = FileManager.default
        var documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent(Constants.tilesFolder, isDirectory: true)
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let folders = fileURLs.map { fileURL in
                fileURL.lastPathComponent
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = Constants.tileNameFormat
            let versions = folders
                .compactMap { version in
                    dateFormatter.date(from: version)
                }.sorted {
                    $0 < $1
                }.map {
                    dateFormatter.string(from: $0)
                }
            return versions
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return []
    }

    func updateVersionsList(completion: @escaping () -> Void) {
        Directions.shared.fetchAvailableOfflineVersions { [weak self] (versions, error) in
            guard error == nil, let versions = versions?.filter({ !$0.isEmpty }) else { return }
            guard let last = versions.first else { return }
            self?.versions = versions
            if last != self?.latestVersion() {
                self?.createFolder(forVersion: last)
            }
            self?.lastUpdated = Date().timeIntervalSince1970
            completion()
        }
   }
}
