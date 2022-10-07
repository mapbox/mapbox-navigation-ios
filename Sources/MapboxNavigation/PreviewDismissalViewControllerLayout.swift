import UIKit

extension PreviewDismissalViewController {
    
    func setupConstraints() {
        // TODO: Verify that back button is shown correctly for right-to-left languages.
        let backButtonLayoutConstraints = [
            backButton.widthAnchor.constraint(equalToConstant: 110.0),
            backButton.heightAnchor.constraint(equalToConstant: 50.0),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: 10.0),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                            constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(backButtonLayoutConstraints)
    }
}
