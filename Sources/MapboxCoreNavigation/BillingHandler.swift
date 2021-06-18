import Foundation
@_implementationOnly import MapboxCommon_Private

class BillingHandler {
    
    typealias SessionId = Int
    typealias SessionBeginHadler = (SessionId) -> Void
    
    static let gracePeriod = 30.0
    static let shared = BillingHandler()
    
    enum SessionType: TimeInterval {
        case freeDrive = 3600 // 1h
        case activeGuidance = 43200 // 12h
    }
    
    private(set) var sessionId: SessionId? = nil
    
    private var billingTimer: Timer?
    private(set) var sessionIsPaused = false
    
    // MARK: - Internal methods
    
//    func getSKUToken() {} // unused
    
    func getSessionToken() -> String? {
        print(">>> get session token")
        if sessionId != nil {
            return nil //TokenGenerator.getSessionSKUToken(for: .navigationMAUS)
            
            /// do we still support this at all?
//            var billingMethodValue = Bundle.main.object(forInfoDictionaryKey: "MBXNavigationBillingMethod") as? String
//            if billingMethodValue == "" {
//                billingMethodValue = nil
//            }
//
//            switch NavigationBillingMethod(rawValue: billingMethodValue ?? NavigationBillingMethod.request.rawValue) {
//            case .user:
//                return TokenGenerator.getSKUToken(for: .navigationMAUS) // any changes here?
//            case .request:
//                return nil //TokenGenerator.getSessionSKUToken(for: .navigationMAUS)
//            case .none:
//                preconditionFailure("Unrecognized billing method \(String(describing: billingMethodValue)). Valid billing methods are: \(NavigationBillingMethod.allValues.map { $0.rawValue }).")
//            }
        } else {
            return nil
        }
    }
    
    func beginBillingSession(type: SessionType, sessionHandler: @escaping SessionBeginHadler) {
        restartBillingSession(Self.gracePeriod, sessionDuration: type.rawValue, sessionHandler: sessionHandler)
    }
    
    private func restartBillingSession(_ gracePeriod: TimeInterval, sessionDuration: TimeInterval, sessionHandler: @escaping SessionBeginHadler) {
        print(">>> restart billing session \(Date())")
        cancelBillingSession() // cancel any existing session
        var tick: TimeInterval = 0
        sessionIsPaused = false
        
        sessionId = Int.random(in: 1...999)
        print(">>> \(sessionId)")
//        sessionId = MapboxCommon.BillingService.beginBillingSession(accessToken: TokenGenerator.getSessionSKUToken(for: .navigationMAUS),
//                                                                    userAgent: URLSession.userAgent,
//                                                                    skuIdentifier: .navigationMaus,
//                                                                    callback: {
//                                                                        error in
//                                                                        //                                            print("Failed to begin billing session:\(error)")
//                                                                        //                                            preconditionFailure() // how do we handle error here??
//                                                                    },
//                                                                    countdown: UInt32(gracePeriod))
        sessionHandler(sessionId!)
        
        billingTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                            repeats: true,
                                            block: { [weak self] timer in
                                                guard let self = self, !self.sessionIsPaused else { return }
                                                tick += 1
                                                
                                                if abs(tick - gracePeriod) < 1 {
                                                    DispatchQueue.main.async { // main needed?
                                                        self.triggerBilligEvent()
                                                    }
                                                }
                                                if tick >= sessionDuration {
                                                    timer.invalidate()
                                                    DispatchQueue.main.async {
                                                        self.restartBillingSession(0.0, sessionDuration: sessionDuration, sessionHandler: sessionHandler)
                                                    }
                                                }
                                            })
    }
    
    func cancelBillingSession(with id: SessionId) {
        guard id == sessionId else {
            return
        }
        cancelBillingSession()
    }
    
    func pauseBillingSession() {
        sessionIsPaused = true
        print(">>> session paused")
    }
    func resumeBillingSession() {
        sessionIsPaused = false
        print(">>> session resumed")
    }
    
    // MARK: - Private methods
    
    private func triggerBilligEvent() {
        print(">>> trigger billing event \(Date())")
//        BillingService.triggerBillingEvent(accessToken: getSessionToken(),
//                                           userAgent: URLSession.userAgent,
//                                           skuIdentifier: .navigationMAUS,
//                                           callback: { error in
//                                            print("Failed to trigger billing event:\(error)")
//                                            preconditionFailure() // how do we handle error here??
//                                           })
    }
    
    private func cancelBillingSession() {
        print(">>> session cancelled")
        billingTimer?.invalidate()
        billingTimer = nil
        
        if let sessionId = sessionId {
            print(">>> confirmed session \(sessionId) cancel \(Date())")
//        MapboxCommon.BillingService.cancelBillingSession(id: sessionId)
            self.sessionId = nil
            sessionIsPaused = false
        }
    }
}

