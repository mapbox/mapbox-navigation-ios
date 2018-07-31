extension String {
    static var localizedSimulationSpeedSummary: String {
        return NSLocalizedString("USER_IN_SIMULATION_MODE", bundle: .mapboxNavigation, value: "Simulating Navigation at %d×", comment: "The text of a banner that appears during turn-by-turn navigation when route simulation is enabled.")
    }
}
