import UIKit

@IBDesignable
class StaticTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: CellTitleLabel!
    @IBOutlet weak var iconImageView: IconImageView!
}

@IBDesignable
class SeparatorTableViewCell: UITableViewCell {
}

@IBDesignable
class StaticToggleTableViewCell: StaticTableViewCell {
    @IBOutlet weak var toggleView: ToggleView!
}
