import MapboxNavigationNative

extension NavigatorConfig {
    public static func mock(
        voiceInstructionThreshold: NSNumber? = nil,
        electronicHorizonOptions: ElectronicHorizonOptions? = nil,
        polling: PollingConfig? = nil,
        incidentsOptions: IncidentsOptions? = nil,
        noSignalSimulationEnabled: NSNumber? = nil,
        useSensors: NSNumber? = nil,
        rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute = .rerouteDisabled
    ) -> NavigatorConfig {
        NavigatorConfig(
            voiceInstructionThreshold: voiceInstructionThreshold,
            electronicHorizonOptions: electronicHorizonOptions,
            polling: polling,
            incidentsOptions: incidentsOptions,
            noSignalSimulationEnabled: noSignalSimulationEnabled,
            useSensors: useSensors,
            rerouteStrategyForMatchRoute: rerouteStrategyForMatchRoute
        )
    }
}
