import Foundation
import MapboxNavigationNative

/**
 Functional road class
 See for details: https://wiki.openstreetmap.org/wiki/Key:highway
 */
public enum RoadClass {

    /**
     Describes a motorway RC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dmotorway for further details.
     */
    case motorway

    /**
     Describes a trunk RC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dtrunk for further details.
     */
    case trunk

    /**
     Describes a primary FRC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dprimary for further details.
     */
    case primary

    /**
     Describes a secondary FRC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dsecondary for further details.
     */
    case secondary

    /**
     Describes a tertiary FRC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dtertiary for further details.
     */
    case tertiary

    /**
     Describes an unclassified FRC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dunclassified for further details.
     */
    case unclassified

    /**
     Describes a residential FRC.

     See https://wiki.openstreetmap.org/wiki/Tag:highway%3Dresidential for further details.
     */
    case residential

    /**
     Describes a service other FRC.
     */
    case serviceOther

    init(_ native: MapboxNavigationNative.FunctionalRoadClass) {
        switch (native) {
        case .motorway:
            self = .motorway
        case .trunk:
            self = .trunk
        case .primary:
            self = .primary
        case .secondary:
            self = .secondary
        case .tertiary:
            self = .tertiary
        case .unclassified:
            self = .unclassified
        case .residential:
            self = .residential
        case .serviceOther:
            self = .serviceOther
        }
    }
}
