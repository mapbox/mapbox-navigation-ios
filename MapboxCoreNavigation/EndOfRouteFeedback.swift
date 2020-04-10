import Foundation

/**
 Feedback Model Object for End Of Route Experience.
 */
open class EndOfRouteFeedback {
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
    }
    public convenience init(rating ratingNumber: NSNumber?, comment: String?) {
        let rating = ratingNumber?.intValue
        self.init(rating: rating, comment: comment)
    }
}
