import Foundation
import UIKit

var simulationIsEnabled = true

class ExampleContainerViewController: UITableViewController {
    @IBOutlet var beginNavigation: UIButton!
    @IBOutlet var simulateNavigation: UISwitch!

    var exampleClass: UIViewController.Type?
    var exampleName: String?
    var exampleDescription: String?
    var exampleStoryboard: UIStoryboard?
    var hasEnteredExample = false
    var pushExampleToViewController = false
    var hideOptions = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = exampleName

        if exampleClass == nil {
            beginNavigation.setTitle("Example Not Found", for: .normal)
            beginNavigation.isEnabled = false
            simulateNavigation.isEnabled = false
        }

        if hideOptions {
            tableView.sectionHeaderHeight = 0.0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasEnteredExample {
            view.subviews.last?.removeFromSuperview()
            children.last?.removeFromParent()
            hasEnteredExample = false
        }
    }

    @IBAction
    func didTapBeginNavigation(_ sender: Any) {
        let controller = instantiate(example: exampleClass!, from: exampleStoryboard)
        embed(controller: controller, shouldPush: pushExampleToViewController)
    }

    private func instantiate<T: UIViewController>(example: T.Type, from storyboard: UIStoryboard? = nil) -> T {
        return storyboard?.instantiateInitialViewController() as? T ?? example.init()
    }

    private func embed(controller: UIViewController, shouldPush: Bool) {
        addChild(controller)
        view.addSubview(controller.view)

        controller.didMove(toParent: self)
        if shouldPush {
            navigationController?.pushViewController(controller, animated: true)
        }
        hasEnteredExample = true
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let exampleDescription else { return nil }
        return section == tableView.numberOfSections - 1 ? exampleDescription : nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard hideOptions, section == 0 else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard hideOptions, section == 0 else {
            return super.tableView(tableView, titleForHeaderInSection: section)
        }
        return nil
    }

    @IBAction
    func didToggleSimulateNavigation(_ sender: Any) {
        simulationIsEnabled = simulateNavigation.isOn
    }
}
