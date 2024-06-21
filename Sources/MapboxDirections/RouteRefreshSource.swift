import Foundation

/// A skeletal route containing infromation to refresh ``Route`` object attributes.
public protocol RouteRefreshSource {
    var refreshedLegs: [RouteLegRefreshSource] { get }
}

/// A skeletal route leg containing infromation to refresh ``RouteLeg`` object attributes.
public protocol RouteLegRefreshSource {
    var refreshedAttributes: RouteLeg.Attributes { get }
    var refreshedIncidents: [Incident]? { get }
    var refreshedClosures: [RouteLeg.Closure]? { get }
}

extension RouteLegRefreshSource {
    public var refreshedIncidents: [Incident]? {
        return nil
    }

    public var refreshedClosures: [RouteLeg.Closure]? {
        return nil
    }
}

extension Route: RouteRefreshSource {
    public var refreshedLegs: [RouteLegRefreshSource] {
        legs
    }
}

extension RouteLeg: RouteLegRefreshSource {
    public var refreshedAttributes: Attributes {
        attributes
    }

    public var refreshedIncidents: [Incident]? {
        incidents
    }

    public var refreshedClosures: [RouteLeg.Closure]? {
        closures
    }
}

extension RefreshedRoute: RouteRefreshSource {
    public var refreshedLegs: [RouteLegRefreshSource] {
        legs
    }
}

extension RefreshedRouteLeg: RouteLegRefreshSource {
    public var refreshedAttributes: RouteLeg.Attributes {
        attributes
    }

    public var refreshedIncidents: [Incident]? {
        incidents
    }

    public var refreshedClosures: [RouteLeg.Closure]? {
        closures
    }
}
