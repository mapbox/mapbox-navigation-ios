import MapboxNavigationNative_Private

extension NavigatorConfig {
    public static func mock(
        voiceInstructionThreshold: NSNumber? = nil,
        electronicHorizonOptions: ElectronicHorizonOptions? = nil,
        polling: PollingConfig? = nil,
        incidentsOptions: IncidentsOptions? = nil,
        noSignalSimulationEnabled: NSNumber? = nil,
        useSensors: NSNumber? = nil,
        rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute = .rerouteDisabled,
        roadObjectsMatcherOptions: RoadObjectsMatcherOptions? = nil
    ) -> NavigatorConfig {
        NavigatorConfig(
            voiceInstructionThreshold: voiceInstructionThreshold,
            electronicHorizonOptions: electronicHorizonOptions,
            polling: polling,
            incidentsOptions: incidentsOptions,
            noSignalSimulationEnabled: noSignalSimulationEnabled,
            useSensors: useSensors,
            rerouteStrategyForMatchRoute: rerouteStrategyForMatchRoute,
            roadObjectsMatcherOptions: roadObjectsMatcherOptions
        )
    }
}
