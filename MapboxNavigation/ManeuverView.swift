//
//  ManeuverView.swift
//  MapboxNavigation
//
//  Created by Jerrad Thramer on 10/12/17.
//  Copyright © 2017 Mapbox. All rights reserved.
//`import Foundation
import UIKit

/// :nodoc:
@objc(MBManeuverView)
public class ManeuverView: UIView, ContainerView, NibLoadable {
    
    //MARK: Constants
    private let nibName = "ManeuverView"
    
    //MARK: Outlets
    
    
    @IBOutlet weak var turnArrow: TurnArrowView!
    @IBOutlet weak var shield: UIImageView!
    @IBOutlet weak var distance: DistanceLabel!
    @IBOutlet weak var destination: DestinationLabel!
    @IBOutlet weak var containerView: UIView?
    
    //MARK: Initializers
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        loadFromNib()
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromNib()
    }
    
    private func loadFromNib() {
        let contentView = self.loadNib(from: localBundle, named: nibName)
        addSubview(contentView!)
        contentView!.pinToSuperview()
        
    }
    
    override public dynamic var backgroundColor: UIColor? {
        didSet {
            containerView?.backgroundColor = backgroundColor
            
        }
    }
}


//TRY MAKING ROOT XIB VIEW MANEUVER VIEW INSTEAD OF FILES OWNER -- AWAKE MAY WORK IN THIS CASE.
