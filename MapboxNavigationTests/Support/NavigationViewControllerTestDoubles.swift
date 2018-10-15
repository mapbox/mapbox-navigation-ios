import Foundation
import MapboxDirections
import MapboxCoreNavigation
@testable import MapboxNavigation

class TestableDayStyle: DayStyle {
    required init() {
        super.init()
        mapStyleURL = Fixture.blankStyle
    }
}

class RouteVoiceControllerStub: RouteVoiceController {

    override func speak(_ instruction: SpokenInstruction) {
        //no-op
    }

    override func pauseSpeechAndPlayReroutingDing(notification: NSNotification) {
        //no-op
    }
}

class NavigationLocationManagerStub: NavigationLocationManager {

    override func startUpdatingLocation() {
        return
    }

    override func startUpdatingHeading() {
        return
    }
}
