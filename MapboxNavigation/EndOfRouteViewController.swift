//
//  EndOfRouteViewController.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 10/17/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit
import MapboxDirections

open class EndOfRouteViewController: UIViewController, DismissDraggable {
    
    //MARK: Outlets
    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    
    @IBOutlet weak var stars: RatingControl!
    @IBOutlet weak var endNavigation: UIButton!
    
    
    //MARK: Properties
    var draggableHeight: CGFloat = 260.0
    
    var interactor = Interactor()
    var dismissal: (() -> Void)?
    
    open var destination: Waypoint? {
        didSet {
            if (isViewLoaded) {
                updateInterface()
            }
        }
    }

    public static func loadFromStoryboard() -> EndOfRouteViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: String(describing: EndOfRouteViewController.self)) as! EndOfRouteViewController
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        clearInterface()
        enableDraggableDismiss()
        updateInterface()
        // Do any additional setup after loading the view.
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        let path = UIBezierPath(roundedRect:view.bounds,
                                byRoundingCorners:[.topLeft, .topRight],
                                cornerRadii: CGSize(width: 5, height: 5))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func endNavigationPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //Mark: Interface
    private func updateInterface() {
        primary.text = destination?.name
        secondary.text = destination?.description
    }
    
    private func clearInterface() {
        [primary, secondary].forEach { $0.text = nil }
        stars.rating = 0
    }
    
    private func showTextField(animated: Bool = true) {
        
    }
    
    private func hideTextField(animated: Bool = true) {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//MARK: - UIViewControllerTransitioning

extension EndOfRouteViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
