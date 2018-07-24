struct HighwayShield {
    
    enum RoadClass: String {
        case alternate, duplex, business, truck, bypass
        case oneB = "1b", twoA = "2a", twoB = "2b", b
    }
    
    enum RoadType {
        case generic, motorway, expressway, state(RoadClass), highway(RoadClass)
        case national, federal, main, road, primary, secondary, trunk, regional
        case voivodeship, county, communal, interstate(RoadClass)
    }
    
    enum Country {
        case us(RoadType), at(RoadType), bg(RoadType), br(RoadType), ch(RoadType)
        case cz(RoadType), de(RoadType), dk(RoadType), fi(RoadType), gr(RoadType)
        case hr(RoadType), hu(RoadType), `in`(RoadType), mx(RoadType), nz(RoadType)
        case pe(RoadType), pl(RoadType), ro(RoadType), rs(RoadType), se(RoadType)
        case si(RoadType), sk(RoadType), za(RoadType), e(RoadType)
        case `default`
        
        func textColor() -> UIColor {
            switch self {
            case .us(.interstate(let roadClass)):
                switch roadClass {
                case .duplex, .business, .truck:
                    return .white
                default:
                    return .black
                }
            case .us(.highway(let roadClass)):
                switch roadClass {
                case .duplex, .alternate, .business, .bypass, .truck: fallthrough
                default:
                    return .black
                }
            case .default:
                return .black
            case .at(.motorway):
                return .white
            case .at(.state(let roadClass)):
                switch roadClass {
                case .b:
                    return .white
                default:
                    return .black
                }
            default:
                return .black
            }
        }
    }
    
    enum Identifier: String {
        case generic = "default"
        case atMotorway = "at-motorway"
        case atExpressway = "at-expressway"
        case atStateB = "at-state-b"
        case bgMotorway = "bg-motorway"
        case bgNational = "bg-national"
        case brFederal = "br-federal"
        case brState = "br-state"
        case chMotorway = "ch-motorway"
        case chMain = "ch-main"
        case czMotorway = "cz-motorway"
        case czRoad = "cz-road"
        case deMotorway = "de-motorway"
        case deFederal = "de-federal"
        case dkPrimary = "dk-primary"
        case dkSecondary = "dk-secondary"
        case fiMain = "fi-main"
        case fiTrunk = "fi-trunk"
        case fiRegional = "fi-regional"
        case grMotorway = "gr-motorway"
        case grNational = "gr-national"
        case usHighway = "us-highway"
        
        func textColor() -> UIColor? {
            switch self {
            case .generic:
                return .black
            case .atMotorway:
                return .white
            case .atExpressway:
                return .white
            case .atStateB:
                return .white
            case .bgMotorway:
                return .white
            case .bgNational:
                return .white
            case .brFederal:
                return .black
            case .brState:
                return .black
            case .chMotorway:
                return .white
            case .chMain:
                return .white
            case .czMotorway:
                return .white
            case .czRoad:
                return .white
            case .deMotorway:
                return .white
            case .deFederal:
                return .black
            case .dkPrimary:
                return .black
            case .dkSecondary:
                return .black
            case .fiMain:
                return .white
            case .fiTrunk:
                return .black
            case .fiRegional:
                return .black
            case .grMotorway:
                return .white
            case .grNational:
                return .white
            case .usHighway:
                return .black
            }
        }
    }
}
