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

let Directions = [
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

extension String {
    var abbreviatedString: String {
        return characters.split(separator: " ").map(String.init).map { (word) -> String in
            let lowercaseWord = word.lowercased()
            return Abbreviations[lowercaseWord] ?? Directions[lowercaseWord] ?? Classifications[lowercaseWord] ?? word
            }.joined(separator: " ")
    }
}
