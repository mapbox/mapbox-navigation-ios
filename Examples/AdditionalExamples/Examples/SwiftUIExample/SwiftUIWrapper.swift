import SwiftUI
import UIKit

func createSwiftUIExamplesController() -> UIViewController {
    let controller = UIHostingController(rootView: SwiftUIExamples())
    controller.title = "SwiftUI Example"
    controller.modalPresentationStyle = .fullScreen
    return controller
}
