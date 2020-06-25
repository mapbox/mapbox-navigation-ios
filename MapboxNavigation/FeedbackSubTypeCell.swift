import UIKit

class FeedbackSubTypeCell: UITableViewCell {

    override var reuseIdentifier: String? {
        return "feedbackSubTypeCell"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with title: String) {
        self.textLabel?.text = title
    }
}
