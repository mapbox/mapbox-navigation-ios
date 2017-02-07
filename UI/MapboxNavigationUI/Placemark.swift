import Foundation
import MapboxGeocoder
import Mapbox

let distanceFormatter = DistanceFormatter()

extension MapboxGeocoder.GeocodedPlacemark {
    
    func localizedDistance(to destination: CLLocation, unitStyle: Formatter.UnitStyle) -> String {
        let distance = location.distance(from: destination)
        distanceFormatter.unitStyle = unitStyle
        return distanceFormatter.string(from: distance)
    }
    
    var coordinateBounds: MGLCoordinateBounds? {
        if let rectangularRegion = region as? RectangularRegion {
            return MGLCoordinateBounds(sw: rectangularRegion.southWest, ne: rectangularRegion.northEast)
        }
        return nil
    }
    
    var preferredZoomLevel: Double {
        switch scope {
        case PlacemarkScope.pointOfInterest, PlacemarkScope.address:
            return 18
        case PlacemarkScope.neighborhood:
            return 16
        case PlacemarkScope.locality, PlacemarkScope.postalCode:
            return 14
        case PlacemarkScope.place:
            return 12
        case PlacemarkScope.district:
            return 10
        case PlacemarkScope.region:
            return 8
        case PlacemarkScope.country:
            return 6
        default:
            return 6
        }
    }
    
    var subtitle: String? {
        if let addressDictionary = addressDictionary, var lines = addressDictionary["formattedAddressLines"] as? [String] {
            // Chinese addresses have no commas and are reversed.
            if scope == .address {
                if qualifiedName.contains(", ") {
                    lines.removeFirst()
                } else {
                    lines.removeLast()
                }
            }
            
            if let regionCode = administrativeRegion?.code {
                // Ignore codes such as CN-15 that probably don’t correspond to postal abbreviations.
                if let abbreviatedRegion = regionCode.components(separatedBy: "-").last, (abbreviatedRegion as NSString).intValue == 0 {
                    // TODO: Show country if not the current country.
                    // Cut off country and postal code and add abbreviated state/region code at the end.

                    let stitle = lines.prefix(upTo: 2).joined(separator: NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))

                    if scope == .region || scope == .district || scope == .place || scope == .postalCode {
                        return stitle
                    }
                    return stitle.appending("\(NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))\(abbreviatedRegion)")
                }
            }
            if scope == .country {
                return ""
            }
            if qualifiedName.contains(", ") {
                return lines.joined(separator: NSLocalizedString("ADDRESS_LINE_SEPARATOR", value: ", ", comment: "Delimiter between lines in an address when displayed inline"))
            }
            return lines.joined()
        }
        return description
    }
}
