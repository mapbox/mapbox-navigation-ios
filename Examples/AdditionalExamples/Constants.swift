import Foundation
import UIKit

typealias NamedController = (
    name: String,
    description: String,
    controller: UIViewController.Type,
    storyboard: UIStoryboard?,
    // Is the example containined in a storyboard? If so, we assume the Initial View Controller of the storyboard.
    pushExampleToViewController: Bool // If the example does not go directly into the example,(i.e. another map is
    // shown) set this value to true
)

let listOfExamples: [NamedController] = [
    (
        name: "Advanced Implementation",
        description: """
        Demonstrates how to display a custom map style and how to apply stylized components in the UI.
        This example also allows the user to select an alternate route. Long press on the map to begin.
        NavigationViewController reuses a NavigationMapView instance, allowing for a seamless transition
        between between a route preview and active turn-by-turn navigation.
        Note: The Directions API will not always return alternative routes.
        """,
        controller: AdvancedViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "Basic",
        description: "A basic hello world example showing how to create a navigation experience using the fewest lines of code possible.",
        controller: BasicViewController.self,
        storyboard: nil,
        pushExampleToViewController: false
    ),
    (
        name: "Custom Destination Marker",
        description: "Use a custom image for styling the destination marker.",
        controller: CustomDestinationMarkerController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "Embedded View Controller",
        description: "Demonstrates how to embed a NavigationViewController within a parent view controller.",
        controller: EmbeddedExampleViewController.self,
        storyboard: UIStoryboard(name: "EmbeddedExamples", bundle: nil),
        pushExampleToViewController: true
    ),
    (
        name: "Styled UI Elements",
        description: "Demonstrates how to customize various UI elements and also change the map style.",
        controller: CustomStyleUIElements.self,
        storyboard: nil,
        pushExampleToViewController: false
    ),
    (
        name: "Directions API beta query parameters",
        description: "Demonstrates how to subclass NavigationRouteOptions to take advantage of the beta query parameters available from the Directions API.",
        controller: BetaQueryViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "Custom Waypoint Styling",
        description: "Demonstrates how to customize waypoint styling.",
        controller: CustomWaypointsViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "Custom Voice Controller",
        description: "Add custom audio recordings for your instructions.",
        controller: CustomVoiceControllerUI.self,
        storyboard: nil,
        pushExampleToViewController: false
    ),
    (
        name: "Custom Top & Bottom Bars",
        description: "Use a custom UI for top and bottom bars during navigation.",
        controller: CustomBarsViewController.self,
        storyboard: nil,
        pushExampleToViewController: false
    ),
    (
        name: "Custom Route Lines Styling",
        description: "Demonstrates how to provide custom styling for the route lines.",
        controller: RouteLinesStylingViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "Offline Regions",
        description: "Demonstrates how to create a custom TileStore and handle offline regions.",
        controller: OfflineRegionsViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
    (
        name: "History Recording",
        description: "Demonstrates how to create history files in Free drive and Active turn-by-turn navigation.",
        controller: HistoryRecordingViewController.self,
        storyboard: nil,
        pushExampleToViewController: true
    ),
]
