import UIKit

// http://wiki.openstreetmap.org/wiki/Name_finder:Abbreviations#English
let Abbreviations = [
    "apartments": "Apts",
    "center": "Ctr",
    "centre": "Ctr",
    "county": "Co",
    "creek": "Crk",
    "crossing": "Xing",
    "downtown": "Dtwn",
    "father": "Fr",
    "fort": "Ft",
    "heights": "Hts",
    "international": "Int’l",
    "junction": "Jct",
    "junior": "Jr",
    "lake": "Lk",
    "market": "Mkt",
    "memorial": "Mem",
    "mount": "Mt",
    "mountain": "Mtn",
    "national": "Nat’l",
    "park": "Pk",
    "point": "Pt",
    "river": "Riv",
    "route": "Rte",
    "saint": "St",
    "saints": "SS",
    "school": "Sch",
    "senior": "Sr",
    "sister": "Sr",
    "square": "Sq",
    "station": "Sta",
    "township": "Twp",
    "university": "Univ",
    "village": "Vil",
    "william": "Wm",
]

let CompassDirections = [
    "east": "E",
    "north": "N",
    "northeast": "NE",
    "northwest": "NW",
    "south": "S",
    "southeast": "SE",
    "southwest": "SW",
    "west": "W",
]

let Classifications = [
    "alley": "Aly",
    "avenue": "Ave",
    "boulevard": "Blvd",
    "bridge": "Br",
    "bypass": "Byp",
    "circle": "Cir",
    "court": "Ct",
    "cove": "Cv",
    "crescent": "Cres",
    "drive": "Dr",
    "expressway": "Expy",
    "freeway": "Fwy",
    "footway": "Ftwy",
    "highway": "Hwy",
    "lane": "Ln",
    "motorway": "Mwy",
    "parkway": "Pky",
    "plaza": "Plz",
    "pike": "Pk",
    "point": "Pt",
    "place": "Pl",
    "road": "Rd",
    "square": "Sq",
    "street": "St",
    "terrace": "Ter",
    "turnpike": "Tpk",
    "walk": "Wk",
    "walkway": "Wky",
]

/// Options that specify what kinds of words in a string should be abbreviated.
struct StringAbbreviationOptions : OptionSet {
    let rawValue: Int
    
    /// Abbreviates ordinary words that have common abbreviations.
    static let Abbreviations = StringAbbreviationOptions(rawValue: 1 << 0)
    /// Abbreviates directional words.
    static let Directions = StringAbbreviationOptions(rawValue: 1 << 1)
    /// Abbreviates road name suffixes.
    static let Classifications = StringAbbreviationOptions(rawValue: 1 << 2)
}

extension String {
    /// Returns an abbreviated copy of the string.
    func stringByAbbreviatingWithOptions(options: StringAbbreviationOptions) -> String {
        return characters.split(separator: " ").map(String.init).map { (word) -> String in
            let lowercaseWord = word.lowercased()
            if let abbreviation = Abbreviations[lowercaseWord], options.contains(.Abbreviations) {
                return abbreviation
            }
            if let direction = CompassDirections[lowercaseWord], options.contains(.Directions) {
                return direction
            }
            if let classification = Classifications[lowercaseWord], options.contains(.Classifications) {
                return classification
            }
            return word
            }.joined(separator: " ")
    }
    
    /// Returns the string abbreviated only as much as necessary to fit the given width and font.
    func stringByAbbreviatingToFitWidth(width: CGFloat, font: UIFont) -> String {
        var fittedString = self
        if fittedString.size(attributes: [NSFontAttributeName: font]).width <= width {
            return fittedString
        }
        fittedString = fittedString.stringByAbbreviatingWithOptions(options: [.Classifications])
        if fittedString.size(attributes: [NSFontAttributeName: font]).width <= width {
            return fittedString
        }
        fittedString = fittedString.stringByAbbreviatingWithOptions(options: [.Directions])
        if fittedString.size(attributes: [NSFontAttributeName: font]).width <= width {
            return fittedString
        }
        return fittedString.stringByAbbreviatingWithOptions(options: [.Abbreviations])
    }
}
