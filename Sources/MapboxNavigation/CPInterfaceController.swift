import CarPlay

@available(iOS 12.0, *)
public extension CPInterfaceController {
    
    /**
     Allows to safely pop existing `CPTemplate`.
     
     In case if there is only one `CPTemplate` left in the stack of templates, popping operation
     will not be performed.
     
     - parameter animated: Boolean flag which determines whether `CPTemplate` popping will be
     animated or not.
     */
    func safePopTemplate(animated: Bool) {
        if templates.count == 1 { return }
        
        popTemplate(animated: animated)
    }
}
