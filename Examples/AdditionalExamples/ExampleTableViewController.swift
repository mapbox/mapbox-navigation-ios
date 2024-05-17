
import Foundation
import UIKit

class ExampleTableViewController: UITableViewController {
    override func viewDidLoad() {
        clearsSelectionOnViewWillAppear = false
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfExamples.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
        cell.textLabel?.text = listOfExamples[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "TableToExampleSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "TableToExampleSegue",
              let controller = segue.destination as? ExampleContainerViewController,
              let selectedCell = tableView.indexPathForSelectedRow else { return }

        let example = listOfExamples[selectedCell[1]]

        controller.exampleClass = example.controller
        controller.exampleName = example.name
        controller.exampleDescription = example.description
        controller.exampleStoryboard = example.storyboard
        controller.pushExampleToViewController = example.pushExampleToViewController
    }
}
