import Foundation

/**
  Feedback Model Object for End Of Route Experience.
 */
@objc open class EndOfRouteFeedback: NSObject {
    /**
     Rating: The user's rating for the route. Normalized between 0 and 100.
    */
    let rating: Int?
    
    /**
     Comment: Any comments that the user had about the route.
    */
    let comment: String?
    
    @nonobjc public init(rating: Int? = nil, comment: String? = nil) {
        self.rating = rating
        self.comment = comment
        super.init()
    }
    
    @objc public convenience init(rating: Int) {
        self.init(rating: rating, comment: nil)
    }
    @objc public convenience init(comment: String?) {
        self.init(rating: nil, comment: comment)
    }
    @objc public convenience init(rating: Int, comment: String?) {
        self.init(rating: rating, comment: comment)
    }
}
