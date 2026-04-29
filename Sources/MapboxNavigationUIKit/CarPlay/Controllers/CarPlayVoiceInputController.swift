//
//  CarPlayVoiceInputController.swift
//
//
//  Created by Maksim Chizhavko on 1/13/25.
//

import CarPlay
import Foundation

@_spi(MapboxInternal)
public final class CarPlayVoiceInputController {
    public struct State {
        let identifier: String
        let titleVariants: [String]
        let image: UIImage?
        let repeats: Bool

        public init(identifier: String, titleVariants: [String], image: UIImage?, repeats: Bool) {
            self.identifier = identifier
            self.titleVariants = titleVariants
            self.image = image
            self.repeats = repeats
        }
    }

    public let template: CPVoiceControlTemplate

    public init(states: [State]) {
        var vcs: [CPVoiceControlState] = []
        for state in states {
            let st = CPVoiceControlState(state)
            vcs.append(st)
        }
        self.template = .init(voiceControlStates: vcs)
    }

    public func update(state: State) {
        template.activateVoiceControlState(withIdentifier: state.identifier)
    }
}

extension CPVoiceControlState {
    convenience init(_ state: CarPlayVoiceInputController.State) {
        self.init(
            identifier: state.identifier,
            titleVariants: state.titleVariants,
            image: state.image,
            repeats: state.repeats
        )
    }
}
