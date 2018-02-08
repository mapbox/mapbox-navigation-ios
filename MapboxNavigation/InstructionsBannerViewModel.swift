import UIKit
import MapboxDirections
import MapboxCoreNavigation

class InstructionsBannerState {
    var maneuverViewStep: RouteStep?
    var distanceRemaining: CLLocationDistance?
    var primaryInstruction: [VisualInstructionComponent]?
    var secondaryInstruction: [VisualInstructionComponent]?
    var usesTwoLinesOfInstructions: Bool = true
    
    init(maneuverViewStep: RouteStep?,
         distanceRemaining: CLLocationDistance? = nil,
         primaryInstruction: [VisualInstructionComponent]?,
         secondaryInstruction: [VisualInstructionComponent]?,
         usesTwoLinesOfInstructions: Bool = false) {
        self.maneuverViewStep = maneuverViewStep
        self.distanceRemaining = distanceRemaining
        self.primaryInstruction = primaryInstruction
        self.secondaryInstruction = secondaryInstruction
        self.usesTwoLinesOfInstructions = usesTwoLinesOfInstructions
    }
}

class InstructionsBannerViewModel {
    typealias InstructionsCallback = ((_ viewModel: InstructionsBannerViewModel, _ state: InstructionsBannerState) -> Void)
    var callback: InstructionsCallback
    var state: InstructionsBannerState { didSet { callback(self, state) } }
    private let distanceFormatter = DistanceFormatter(approximate: true)
    
    init(callback: @escaping InstructionsCallback) {
        self.state = InstructionsBannerState(maneuverViewStep: nil, primaryInstruction: nil, secondaryInstruction: nil)
        self.callback = callback
        self.callback(self, state)
    }
    
    /**
     Updates the instructions banner’s view model for a given `RouteProgress`.
     */
    public func update(for routeProgress: RouteProgress) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        let visualInstructions = routeProgress.currentLegProgress.currentStep.instructionsDisplayedAlongStep?.last
        let usesTwoLinesOfInstructions = visualInstructions?.secondaryTextComponents == nil
        
        state = InstructionsBannerState(maneuverViewStep: routeProgress.currentLegProgress.upComingStep,
                                        distanceRemaining: distanceRemaining > 5 ? distanceRemaining : 0,
                                        primaryInstruction: visualInstructions?.primaryTextComponents,
                                        secondaryInstruction: visualInstructions?.secondaryTextComponents,
                                        usesTwoLinesOfInstructions: usesTwoLinesOfInstructions)
    }
    
    public func attributedDistanceString(from distance: CLLocationDistance?, for distanceLabel: DistanceLabel) -> NSAttributedString? {
        return distanceFormatter.attributedDistanceString(from: distance, for: distanceLabel)
    }
}

extension DistanceFormatter {
    func attributedDistanceString(from distance: CLLocationDistance?, for distanceLabel: DistanceLabel) -> NSAttributedString? {
        guard let distance = distance else { return nil }
        
        let distanceString = self.string(from: distance)
        let distanceUnit = self.unitString(fromValue: distance, unit: self.unit)
        
        guard let unitRange = distanceString.range(of: distanceUnit) else { return nil }
        let distanceValue = distanceString.replacingOccurrences(of: distanceUnit, with: "")
        guard let valueRange = distanceString.range(of: distanceValue) else { return nil }
        
        let valueAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: distanceLabel.valueTextColor, .font: distanceLabel.valueFont]
        let unitAttributes: [NSAttributedStringKey: Any] = [.foregroundColor: distanceLabel.unitTextColor, .font: distanceLabel.unitFont]
        
        let valueSubstring = distanceString[valueRange].trimmingCharacters(in: .whitespaces)
        let unitSubstring = distanceString[unitRange].trimmingCharacters(in: .whitespaces)
        let valueAttributedString = NSAttributedString(string: valueSubstring, attributes: valueAttributes)
        let unitAttributedString = NSAttributedString(string: unitSubstring, attributes: unitAttributes)
        
        let startsWithUnit = unitRange.lowerBound == distanceString.wholeRange.lowerBound
        let attributedString = NSMutableAttributedString()
        
        attributedString.append(startsWithUnit ? unitAttributedString : valueAttributedString)
        attributedString.append(NSAttributedString(string: "\u{200A}", attributes: unitAttributes))
        attributedString.append(startsWithUnit ? valueAttributedString : unitAttributedString)
        
        return attributedString
    }
}

