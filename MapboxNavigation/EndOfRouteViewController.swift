//
//  EndOfRouteViewController.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 10/17/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//

import UIKit

class EndOfRouteViewController: UIViewController, DismissDraggable {
    static var presentationHeight: CGFloat = 260.0
    var interactor = Interactor()

    class func loadFromStoryboard() -> EndOfRouteViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: String(describing: EndOfRouteViewController.self)) as! EndOfRouteViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableDraggableDismiss()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator(height: EndOfRouteViewController.presentationHeight)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
