//
//  FeedbackOverviewTableViewController.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 9/26/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation

//MARK: - View Reuse Identifier Enum
enum ReuseIdentifier: String {
    case arrived, feedback
}


class FeedbackOverviewTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //MARK: - Models
    var route: Route? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var feedbacks: [FeedbackEvent]? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0) // Do not extend table view under status bar.
        tableView?.reloadData()
        // Uncomment the following line to preserve selection between presentations
        

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let feedbacks = feedbacks else { return 1 } // If we have no feedbacks, show only the arrival cell.
        
        return feedbacks.count + 1
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 300
        default:
            return feedbacks != nil ? 70 : 0
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row >= 1
    }
 
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return arrivedCell(for: tableView, indexPath: indexPath)
        default:
            return feedbackCell(for: tableView, indexPath: indexPath)
        }
    }
 
    //MARK: - Private Cell Dequeue Methods
    private func arrivedCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cell: .arrived, for: indexPath) as! ArrivedTableViewCell
            cell.route = route
            cell.feedbacks = feedbacks
        return cell
    }
   
    private func feedbackCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cell: .feedback, for: indexPath) as! FeedbackTableViewCell
        cell.feedback = feedbacks?[indexPath.row - 1]
        return cell
    }
    
    @IBAction func unwind(from segue: UIStoryboardSegue) {
        if let selected: IndexPath = tableView?.indexPathForSelectedRow {
            tableView?.deselectRow(at: selected, animated: false)
        }
        
        
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

private extension UITableView {
    func dequeue(cell identifier: ReuseIdentifier, for indexPath: IndexPath) -> UITableViewCell? {
        return self.dequeueReusableCell(withIdentifier: identifier.rawValue, for: indexPath)
    }
}
