extension String {
    enum Localized {
        static func simulationStatus(speed: Int) -> String {
            let format = NSLocalizedString("USER_IN_SIMULATION_MODE", bundle: .mapboxNavigation, value: "Simulating Navigation at %d×", comment: "The text of a banner that appears during turn-by-turn navigation when route simulation is enabled.")
            return String.localizedStringWithFormat(format, speed)
        }
    }
}
