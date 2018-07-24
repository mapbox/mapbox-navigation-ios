struct HighwayShield {
    
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
        
        func fillColor() -> UIColor {
            switch self {
            case .generic:
                return .white
            case .atMotorway:
                return .blue
            case .atExpressway:
                return .blue
            case .atStateB:
                return .blue
            case .bgMotorway:
                return .green
            case .bgNational:
                return .blue
            case .brFederal:
                return .white
            case .brState:
                return .white
            case .chMotorway:
                return .red
            case .chMain:
                return .blue
            case .czMotorway:
                return .blue
            case .czRoad:
                return .blue
            case .deMotorway:
                return .blue
            case .deFederal:
                return .yellow
            case .dkPrimary:
                return .yellow
            case .dkSecondary:
                return .white
            case .fiMain:
                return .red
            case .fiTrunk:
                return .yellow
            case .fiRegional:
                return .white
            case .grMotorway:
                return .green
            case .grNational:
                return .blue
            case .usHighway:
                return .white
            }
        }
        
        // TODO: borderColor
    }
}
