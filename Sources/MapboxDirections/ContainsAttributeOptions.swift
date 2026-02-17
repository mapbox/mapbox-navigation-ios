import Foundation

protocol ContainsAttributeOptions {}

extension MatrixOptions: ContainsAttributeOptions {}
extension DirectionsOptions: ContainsAttributeOptions {}

extension AttributeOptions {
    private static func allOptions() -> AttributeOptions {
        [
            .closures,
            .distance,
            .expectedTravelTime,
            .speed,
            .congestionLevel,
            .maximumSpeedLimit,
            .numericCongestionLevel,
            .trafficTendency,
        ]
    }

    func urlQueryItem(for target: ContainsAttributeOptions, key: String) -> URLQueryItem? {
        var supportedOptions: AttributeOptions
        switch target {
        case let options as RouteOptions:
            guard options.routeShapeResolution == .full else {
                return nil
            }
            supportedOptions = [
                .closures,
                .distance,
                .expectedTravelTime,
                .speed,
                .congestionLevel,
                .maximumSpeedLimit,
                .numericCongestionLevel,
            ]
            if !(options.profileIdentifier.isAutomobile || options.profileIdentifier.isAutomobileAvoidingTraffic) {
                supportedOptions.subtract([.maximumSpeedLimit])
            }
            if !options.profileIdentifier.isAutomobileAvoidingTraffic {
                supportedOptions.subtract([.congestionLevel, .numericCongestionLevel, .closures])
            }
        case let options as MatchOptions:
            guard options.routeShapeResolution == .full else {
                return nil
            }
            supportedOptions = [
                .distance,
                .expectedTravelTime,
                .speed,
                .congestionLevel,
                .maximumSpeedLimit,
                .numericCongestionLevel,
            ]
            if !(options.profileIdentifier.isAutomobile || options.profileIdentifier.isAutomobileAvoidingTraffic) {
                supportedOptions.subtract([.maximumSpeedLimit])
            }
            if !options.profileIdentifier.isAutomobileAvoidingTraffic {
                supportedOptions.subtract([.congestionLevel, .numericCongestionLevel])
            }
        case is MatrixOptions:
            supportedOptions = [.distance, .expectedTravelTime]
        default:
            let value = description
            return !value.isEmpty ? URLQueryItem(name: key, value: value) : nil
        }

        let customOptions = subtracting(AttributeOptions.allOptions())
        let commonOptions = intersection(supportedOptions)
        let value = customOptions.union(commonOptions).description

        return !value.isEmpty ? URLQueryItem(name: key, value: value) : nil
    }
}
