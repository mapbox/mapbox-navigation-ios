import Foundation
import CoreLocation
import UIKit
import MapboxDirections

/**
 The `NavigationEventsManager` is responsible for being the liaison between MapboxCoreNavigation and the Mapbox telemetry.
 */
open class NavigationEventsManager {
    static let applicationSessionIdentifier = UUID()

    let navNativeEventsManager: NavigationNativeEventsManager?
    let commonEventsManager: NavigationCommonEventsManager?

    private(set) var actualEventsManager: NavigationTelemetryManager
    
    // MARK: Configuring Events
    
    /**
     Optional application metadata that that can help Mapbox more reliably diagnose problems that occur in the SDK.
     For example, you can provide your application’s name and version, a unique identifier for the end user, and a session identifier.
     To include this information, use the following keys: "name", "version", "userId", and "sessionId".
     */
    public var userInfo: [String: String?]? {
        get { actualEventsManager.userInfo }
        set { actualEventsManager.userInfo = newValue }
    }
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    public var delaysEventFlushing: Bool {
        get { commonEventsManager?.delaysEventFlushing ?? true }
        set {  commonEventsManager?.delaysEventFlushing = newValue }
    }

    var activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? {
        get { commonEventsManager?.activeNavigationDataSource }
        set { commonEventsManager?.activeNavigationDataSource = newValue }
    }

    /**
     The unique identifier of the navigation session. Soon to be unused.
     */
    public var sessionId: String {
        commonEventsManager?.sessionId ?? NavigationEventsManager.applicationSessionIdentifier.uuidString
    }

    public required init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
                         passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
                         accessToken possibleToken: String? = nil) {
        if NavigationTelemetryConfiguration.useNavNativeTelemetryEvents {

            let navNativeEventsManager = NavigationNativeEventsManager.init(navigator: Navigator.shared)
            self.commonEventsManager = nil
            self.navNativeEventsManager = navNativeEventsManager
            self.actualEventsManager = navNativeEventsManager
        } else {
            let commonEventsManager = NavigationCommonEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                                                     passiveNavigationDataSource: passiveNavigationDataSource,
                                                                     accessToken: possibleToken)

            self.navNativeEventsManager = nil
            self.commonEventsManager = commonEventsManager
            self.actualEventsManager = commonEventsManager
        }
    }

    init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
         passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
         accessToken possibleToken: String? = nil,
         commonEventsManagerType: NavigationCommonEventsManager.Type = NavigationCommonEventsManager.self,
         navNativeEventsManagerType: NavigationNativeEventsManager.Type = NavigationNativeEventsManager.self,
         navigatorType: CoreNavigator.Type = Navigator.self) {
        if NavigationTelemetryConfiguration.useNavNativeTelemetryEvents {
            let navNativeEventsManager = navNativeEventsManagerType.init(navigator: navigatorType.shared)
            self.commonEventsManager = nil
            self.navNativeEventsManager = navNativeEventsManager
            self.actualEventsManager = navNativeEventsManager
        } else {
            let commonEventsManager = commonEventsManagerType.init(activeNavigationDataSource: activeNavigationDataSource,
                                                                   passiveNavigationDataSource: passiveNavigationDataSource,
                                                                   accessToken: possibleToken)
            self.navNativeEventsManager = nil
            self.commonEventsManager = commonEventsManager
            self.actualEventsManager = commonEventsManager
        }
    }
    
    // MARK: Sending Feedback Events
    
    /**
     Create feedback about the current road segment/maneuver to be sent to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - returns: Returns a feedback event.
     
     If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show the custom UI so the location and timestamp are more accurate.
     Alternatively, you can use `FeedbackViewContoller` which handles feedback lifecycle internally.
     
     - Postcondition:
     Call `sendFeedback(_:type:source:description:)` with the returned feedback to attach additional metadata to the feedback and send it.
     */
    public func createFeedback(screenshotOption: FeedbackScreenshotOption = .automatic) -> FeedbackEvent? {
        actualEventsManager.createFeedback(screenshotOption: screenshotOption)
    }
    
    /**
     Send active navigation feedback to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `ActiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     */
    public func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                             type: ActiveNavigationFeedbackType,
                                             description: String? = nil) {
        sendActiveNavigationFeedback(feedback,
                                     type: type,
                                     description: description,
                                     source: .user,
                                     completionHandler: nil)
    }
    
    /**
     Send passive navigation feedback to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `PassiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     */
    public func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                              type: PassiveNavigationFeedbackType,
                                              description: String? = nil) {
        sendPassiveNavigationFeedback(feedback,
                                      type: type,
                                      description: description,
                                      source: .user,
                                      completionHandler: nil)
    }

    /**
     :nodoc:
     Send active navigation feedback to the Mapbox data team.

     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.

     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `ActiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     - parameter source: A `FeedbackSource` used to specify feedback source.
     - parameter completionHandler: A `UserFeedbackCompletionHandler` which will be called when the user feedback is sent. Defaults to `nil`.     
     */
    @_spi(MapboxInternal)
    public func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                             type: ActiveNavigationFeedbackType,
                                             description: String?,
                                             source: FeedbackSource,
                                             completionHandler: UserFeedbackCompletionHandler? = nil) {
        actualEventsManager.sendActiveNavigationFeedback(feedback,
                                                         type: type,
                                                         description: description,
                                                         source: source,
                                                         completionHandler: completionHandler)
    }

    /**
     :nodoc:
     Send passive navigation feedback to the Mapbox data team.

     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.

     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `PassiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     - parameter source: A `FeedbackSource` used to specify feedback source.
     - parameter completionHandler: A `UserFeedbackCompletionHandler` which will be called when the user feedback is sent. Defaults to `nil`.
     */
    @_spi(MapboxInternal)
    public func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                              type: PassiveNavigationFeedbackType,
                                              description: String?,
                                              source: FeedbackSource,
                                              completionHandler: UserFeedbackCompletionHandler? = nil) {
        actualEventsManager.sendPassiveNavigationFeedback(feedback,
                                                          type: type,
                                                          description: description,
                                                          source: source,
                                                          completionHandler: completionHandler)
    }

    /**
     Send event that Car Play was connected.
     */
    public func sendCarPlayConnectEvent() {
        actualEventsManager.sendCarPlayConnectEvent()
    }

    /**
     Send event that Car Play was disconnected.
     */
    public func sendCarPlayDisconnectEvent() {
        actualEventsManager.sendCarPlayDisconnectEvent()
    }

    // MARK: Events sending, will be removed after testing with NavNative

    func sendRouteRetrievalEvent() {
        commonEventsManager?.sendRouteRetrievalEvent()
    }

    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        commonEventsManager?.sendCancelEvent(rating: rating, comment: comment)
    }

    func sendPassiveNavigationStart() {
        commonEventsManager?.sendPassiveNavigationStart()
    }

    func sendPassiveNavigationStop() {
        commonEventsManager?.sendPassiveNavigationStop()
    }

    func resetSession() {
        commonEventsManager?.resetSession()
    }

    func enqueueRerouteEvent() {
        commonEventsManager?.enqueueRerouteEvent()
    }

    func reportReroute(progress: RouteProgress, proactive: Bool) {
        commonEventsManager?.reportReroute(progress: progress, proactive: proactive)
    }

    func update(progress: RouteProgress) {
        commonEventsManager?.update(progress: progress)
    }

    func incrementDistanceTraveled(by distance: CLLocationDistance) {
        commonEventsManager?.incrementDistanceTraveled(by: distance)
    }

    func arriveAtWaypoint() {
        commonEventsManager?.arriveAtWaypoint()
    }

    func arriveAtDestination() {
        commonEventsManager?.arriveAtDestination()
    }

    func record(_ locations: [CLLocation]) {
        commonEventsManager?.record(locations)
    }

    func withBackupDataSource(active forcedActiveDataSource: ActiveNavigationEventsManagerDataSource?,
                              passive forcedPassiveDataSource: PassiveNavigationEventsManagerDataSource?,
                              action: () -> Void) {
        commonEventsManager?.withBackupDataSource(active: forcedActiveDataSource,
                                                  passive: forcedPassiveDataSource,
                                                  action: action)
    }
}
