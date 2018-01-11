//
//  TopBannerViewController.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 1/11/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import UIKit
import MapboxCoreNavigation
import MapboxDirections

class TopBannerViewController: UIViewController, StatusViewDelegate, InstructionsBannerViewDelegate {
    //MARK: - Class Constants
    static let lanesBackgroundColor: UIColor = UIColor(white: 247/255, alpha: 1.0)
    static let statusBackgroundColor: UIColor = UIColor.black.withAlphaComponent(2/3)
    
    //MARK: - Outlets
    @IBOutlet weak var instructions: InstructionsBannerView!
    @IBOutlet weak var lanes: LanesView!
    @IBOutlet weak var nextBanner: NextBannerView!
    @IBOutlet weak var status: StatusView!
    
    //MARK: - Properties
    var delegate: TopBannerViewControllerDelegate?
    var isSimulatedNavigation: Bool = false
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setBackgroundColors()
    }
    
    // MARK: - Initial State
    private func setupUI() {
        instructions.delegate = self
        status.delegate = self
        [lanes, nextBanner, status].forEach { $0.isHidden = true }
    }
    
    private func setBackgroundColors() {
        instructions.backgroundColor = .white
        lanes.backgroundColor = TopBannerViewController.lanesBackgroundColor
        nextBanner.backgroundColor = .white
        status.backgroundColor = TopBannerViewController.statusBackgroundColor
    }

    // MARK: - Model Updating
    func update(progress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        //update banner
        instructions.update(progress: progress.currentLegProgress, location: location, secondsRemaining: secondsRemaining)
        
        //update lanes
        if let upComingStep = progress.currentLegProgress?.upComingStep, !progress.currentLegProgress.userHasArrivedAtWaypoint {
            updateLaneViews(step: upComingStep, durationRemaining: progress.currentLegProgress.currentStepProgress.durationRemaining)
        }
        
        //update next
        updateNextBanner(routeProgress: progress)
        
    }

    // MARK: - UI Manipulation
    func showStatus(text: String, for duration: TimeInterval, showingSpinner: Bool = false, animated: Bool = true) {
        status.show(text, showSpinner: showingSpinner, animated: animated)
        status.hide(delay: duration, animated: animated)
    }
    
    // MARK: Lane Views
    func updateLaneViews(step: RouteStep, durationRemaining: TimeInterval) {
        lanes.updateLaneViews(step: step, durationRemaining: durationRemaining)
        lanes.count > 0 ? show(view: lanes) : hide(view: lanes)
    }
    
    // MARK: Next Banner
    func updateNextBanner(routeProgress: RouteProgress) {
        //FIXME: Testing override - Remove this!
        let tooLong = Double.greatestFiniteMagnitude //RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier
        
        guard let progress = routeProgress.currentLegProgress,
            let upcoming = progress.upComingStep,
            let next = progress.stepAfter(upcoming),
            lanes.isHidden, //banner should not show if the lane view is visible
            next.expectedTravelTime <= tooLong, //banner should not show if the current step's completion is time-consuming.
            upcoming.expectedTravelTime <= tooLong,  //banner should not show if the upcoming step is time-consuming.
            let instruction = upcoming.instructionsDisplayedAlongStep?.last else {  //banner should not show if the upcoming step contains no instructions.
                hide(view: nextBanner)
                return
        }
        
        nextBanner.update(step: next, instruction: instruction)
        show(view: nextBanner)
    }
    
    
    //MARK: - Utility Functions
    func show(view: UIView, animated: Bool = true) {
        guard view.isHidden else { return }
        let show = { view.isHidden = false }
        animated ? UIView.defaultAnimation(0.3, animations:show, completion: nil) : show()
    }
    
    func hide(view: UIView, animated: Bool = true) {
        guard !view.isHidden else { return }
        let hide = { view.isHidden = true }
        animated ? UIView.defaultAnimation(0.3, animations:hide, completion: nil) : hide()
    }

    //MARK: - InstructionsBannerViewDelegate
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        delegate?.didTapInstructionsBanner(sender)
    }

    //MARK: StatusViewDelegate
    func statusView(_ statusView: StatusView, valueChangedTo value: Double) {
        delegate?.statusView(statusView, valueChangedTo: value)
    }
}

//MARK: - TopBannerViewControllerDelegate
protocol TopBannerViewControllerDelegate: StatusViewDelegate, InstructionsBannerViewDelegate {}
