struct HighwayShield {
    
    enum RoadClass: String {
        case alternate, duplex, business, truck, bypass, b
        case oneB = "1b", twoA = "2a", twoB = "2b"
    }
    
    enum RoadType: RawRepresentable {
        typealias RawValue = String
        typealias RoadTypeForLocaleRoadClassClosure = (Locale, RoadClass?) -> RoadType
        typealias RoadTypeForLocaleClosure = (Locale) -> RoadType
        
        var rawValue: String {
            switch self {
            case .generic:
                return "generic"
            case .motorway:
                return "motorway"
            case .expressway:
                return "expressway"
            case .state:
                return "state"
            case .highway:
                return "highway"
            case .national:
                return "national"
            case .federal:
                return "federal"
            case .main:
                return "main"
            case .road:
                return "road"
            case .primary:
                return "primary"
            case .secondary:
                return "secondary"
            case .trunk:
                return "trunk"
            case .regional:
                return "regional"
            case .voivodeship:
                return "voivodeship"
            case .county:
                return "county"
            case .communal:
                return "communal"
            case .interstate:
                return "interstate"
            case .metropolitan:
                return "metropolitan"
            case .provincial:
                return "provincial"
            }
        }
        
        init?(rawValue: RawValue) {
            let fields  = rawValue.split(separator: "-").compactMap(String.init(_:))
            switch fields.count {
            case 1 where rawValue == "default":
                self = .generic
            case 2:
                guard let roadType = RoadType.type(for: fields.last!),
                      let locale = Locale(rawValue: fields.first!) else {
                    return nil
                }
                self = roadType(locale, nil)
            case 3:
                guard let roadType = RoadType.type(for: fields[1]),
                      let locale = Locale(rawValue: fields[0]), let roadClass = RoadClass(rawValue: fields[2]) else {
                    return nil
                }
                self = roadType(locale, roadClass)
            default:
                return nil
            }
        }
        
        private static func type(for identifier: String) -> RoadTypeForLocaleRoadClassClosure? {
            switch identifier {
            case "motorway":
                return localeOnlyTransform(RoadType.motorway)
            case "expressway":
                return localeOnlyTransform(RoadType.expressway)
            case "national":
                return localeOnlyTransform(RoadType.national)
            case "federal":
                return localeOnlyTransform(RoadType.federal)
            case "main":
                return localeOnlyTransform(RoadType.main)
            case "road":
                return localeOnlyTransform(RoadType.road)
            case "primary":
                return localeOnlyTransform(RoadType.primary)
            case "secondary":
                return localeOnlyTransform(RoadType.secondary)
            case "trunk":
                return localeOnlyTransform(RoadType.trunk)
            case "regional":
                return localeOnlyTransform(RoadType.regional)
            case "voivodeship":
                return localeOnlyTransform(RoadType.voivodeship)
            case "county":
                return localeOnlyTransform(RoadType.county)
            case "communal":
                return localeOnlyTransform(RoadType.communal)
            case "provincial":
                return localeOnlyTransform(RoadType.provincial)
            case "metropolitan":
                return localeOnlyTransform(RoadType.metropolitan)
            case "state":
                return RoadType.state
            case "highway":
                return RoadType.highway
            case "interstate":
                return RoadType.interstate
            default:
                return nil
            }
        }
        
        
        static func localeOnlyTransform(_ closure: @escaping RoadTypeForLocaleClosure) -> RoadTypeForLocaleRoadClassClosure {
            return { locale, _ in
                return closure(locale)
            }
        }
        
        var textColor: UIColor? {
            switch self {
            case let .highway(locale, _):
                if locale == .slovakia {
                    return .white
                }
                return .black
            case .generic, .communal, .voivodeship, .trunk, .primary, .secondary:
                return .black
            case .motorway, .expressway, .road, .interstate:
                return .white
            case let .state(locale, roadClass):
                switch locale {
                case .austria, .croatia, .newZealand,
                     .serbia where roadClass == RoadClass.oneB:
                    return .white
                default:
                    return .black
                }
            case .regional, .metropolitan, .provincial:
                return .yellow
            case let .county(locale):
                if locale == .romania {
                    return .white
                }
                return .black
            case let .main(locale):
                if locale == .slovenia {
                    return .black
                }
                return .white
            case let .national(locale):
                switch locale {
                case .southAfrica:
                    return .yellow
                case .poland, .romania, .greece, .bulgeria:
                    return .white
                default:
                    return .black
                }
            default:
                return nil
            }
        }
        
        case generic, motorway(Locale), expressway(Locale), state(Locale, RoadClass?), highway(Locale, RoadClass?)
        case national(Locale), federal(Locale), main(Locale), road(Locale), primary(Locale), secondary(Locale), trunk(Locale), regional(Locale)
        case voivodeship(Locale), county(Locale), communal(Locale), interstate(Locale, RoadClass?), metropolitan(Locale), provincial(Locale)
    }
    
    enum Locale: String {
        case austria = "at", bulgeria = "bg", brazil = "br", switzerland = "ch", czech = "cz", germany = "de", denmark = "dk", finland = "fi", greece = "gr", croatia = "hr", hungary = "hu", india = "in", mexico = "mx", newZealand = "nz", peru = "pe", poland = "pl", romania = "ro", serbia = "rs", sweden = "se", slovenia = "si", slovakia = "sk", usa = "us", southAfrica = "za", e
    }
}
