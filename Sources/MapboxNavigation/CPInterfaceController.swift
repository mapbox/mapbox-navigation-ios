import CarPlay

public extension CPInterfaceController {
    
    /**
     Allows to safely pop existing `CPTemplate`.
     
     In case if there is only one `CPTemplate` left in the stack of templates, popping operation
     will not be performed.
     
     - parameter animated: Boolean flag which determines whether `CPTemplate` popping will be
     animated or not.
     */
    func safePopTemplate(animated: Bool) {
        guard templates.count > 1 else { return }

        popTemplate(animated: animated)
    }
}
