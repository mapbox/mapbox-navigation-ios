import CarPlay
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

@MainActor
var navigationProvider: MapboxNavigationProvider = {
    let config = CoreConfig(
        credentials: .init(), // You can pass a custom token if you need to
        historyRecordingConfig: HistoryRecordingConfig(historyDirectoryURL: defaultHistoryDirectoryURL())
    )
    return MapboxNavigationProvider(coreConfig: config)
}()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    weak var currentAppRootViewController: ViewController?

    var window: UIWindow?

    var _carPlayManager: Any? = nil
    var carPlayManager: CarPlayManager {
        if _carPlayManager == nil {
            _carPlayManager = CarPlayManager(navigationProvider: navigationProvider)
        }

        return _carPlayManager as! CarPlayManager
    }

    var _carPlaySearchController: Any? = nil
    var carPlaySearchController: CarPlaySearchController {
        if _carPlaySearchController == nil {
            _carPlaySearchController = CarPlaySearchController()
        }

        return _carPlaySearchController as! CarPlaySearchController
    }

    // `CLLocationManager` instance, which is going to be used to create a location, which is used as a
    // hint when looking up the specified address in `CarPlaySearchController`.
    static let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()

    var _recentSearchItems: [Any]? = nil
    var recentSearchItems: [CPListItem]? {
        get {
            _recentSearchItems as! [CPListItem]?
        }
        set {
            _recentSearchItems = newValue
        }
    }

    var recentItems: [RecentItem] = RecentItem.loadDefaults()
    var recentSearchText: String? = ""

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let historyDirectoryURL = defaultHistoryDirectoryURL()
        if !FileManager.default.fileExists(atPath: historyDirectoryURL.path) {
            try? FileManager.default.createDirectory(
                at: historyDirectoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        if isRunningTests() {
            if window == nil {
                window = UIWindow(frame: UIScreen.main.bounds)
            }
            window?.rootViewController = UIViewController()
        }

        listMapboxFrameworks()

        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }

    private func listMapboxFrameworks() {
        NSLog("Versions of linked Mapbox frameworks:")

        for framework in Bundle.allFrameworks {
            if let bundleIdentifier = framework.bundleIdentifier, bundleIdentifier.contains("mapbox") {
                let version = "CFBundleShortVersionString"
                NSLog("\(bundleIdentifier): \(framework.infoDictionary?[version] ?? "Unknown version")")
            }
        }
    }
}

// MARK: - UIWindowSceneDelegate methods

extension AppDelegate: UIWindowSceneDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            return UISceneConfiguration(
                name: "ExampleCarPlayApplicationConfiguration",
                sessionRole: connectingSceneSession.role
            )
        }

        return UISceneConfiguration(name: "ExampleAppConfiguration", sessionRole: connectingSceneSession.role)
    }
}

func defaultHistoryDirectoryURL() -> URL {
    let basePath = NSSearchPathForDirectoriesInDomains(
        .applicationSupportDirectory,
        .userDomainMask,
        true
    ).first ?? NSTemporaryDirectory()
    return URL(fileURLWithPath: basePath, isDirectory: true)
        .appendingPathComponent("historyRecordings")
}
