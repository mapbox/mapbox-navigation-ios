//
//  OSRMTextInstructions.swift
//
//  Created by Johan Uhle on 01.11.16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

// Will automatically read localized Instructions.plist
let OSRMTextInstructionsStrings = NSDictionary(contentsOfFile: Bundle.navigationUI.path(forResource: "Instructions", ofType: "plist")!)!

extension String {
    var sentenceCased: String {
        return String(characters.prefix(1)).uppercased() + String(characters.dropFirst())
    }
}

class OSRMInstructionFormatter: Formatter {
    let version: String
    let instructions: [String: Any]
    
    enum TokenType: String {
        case wayName = "way_name"
        case destination = "destination"
        case rotaryName = "rotary_name"
        case exit = "exit_number"
        case laneInstruction = "lane_instruction"
        case modifier = "modifier"
        case direction = "direction"
        case wayPoint = "way_point"
    }
    
    let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .ordinal
        return formatter
    }()
    
    internal init(version: String) {
        self.version = version
        self.instructions = OSRMTextInstructionsStrings[version] as! [String: Any]
        
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        if let version = decoder.decodeObject(of: NSString.self, forKey: "version") as? String {
            self.version = version
        } else {
            return nil
        }
        
        if let instructions = decoder.decodeObject(of: [NSDictionary.self, NSArray.self, NSString.self], forKey: "instructions") as? [String: Any] {
            self.instructions = instructions
        } else {
            return nil
        }
        
        super.init(coder: decoder)
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        coder.encode(version, forKey: "version")
        coder.encode(instructions, forKey: "instructions")
    }

    var constants: [String: Any] {
        return instructions["constants"] as! [String: Any]
    }
    
    func laneConfig(intersection: Intersection) -> String? {
        guard let approachLanes = intersection.approachLanes else {
            return ""
        }

        guard let useableApproachLanes = intersection.usableApproachLanes else {
            return ""
        }

        // find lane configuration
        var config = Array(repeating: "x", count: approachLanes.count)
        for index in useableApproachLanes {
            config[index] = "o"
        }

        // reduce lane configurations to common cases
        var current = ""
        return config.reduce("", {
            (result: String?, lane: String) -> String? in
            if (lane != current) {
                current = lane
                return result! + lane
            } else {
                return result
            }
        })
    }

    func directionFromDegree(degree: Int?) -> String {
        guard let degree = degree else {
            // step had no bearing_after degree, ignoring
            return ""
        }

        // fetch locatized compass directions strings
        let directions = constants["direction"] as! [String: String]

        // Transform degrees to their translated compass direction
        switch degree {
        case 340...360, 0...20:
            return directions["north"]!
        case 20..<70:
            return directions["northeast"]!
        case 70...110:
            return directions["east"]!
        case 110..<160:
            return directions["southeast"]!
        case 160...200:
            return directions["south"]!
        case 200..<250:
            return directions["southwest"]!
        case 250...290:
            return directions["west"]!
        case 290..<340:
            return directions["northwest"]!
        default:
            return "";
        }
    }
    
    typealias InstructionsByToken = [String: String]
    typealias InstructionsByModifier = [String: InstructionsByToken]
    
    override func string(for obj: Any?) -> String? {
        return string(for: obj, modifyValueByKey: nil)
    }
    
    func string(for obj: Any?, modifyValueByKey: ((TokenType, String) -> String)?) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        var type = step.maneuverType ?? .turn
        let modifier = step.maneuverDirection?.description
        let mode = step.transportType

        if type != .depart && type != .arrive && modifier == nil {
            return nil
        }

        if instructions[type.description] == nil {
            // OSRM specification assumes turn types can be added without
            // major version changes. Unknown types are to be treated as
            // type `turn` by clients
            type = .turn
        }

        var instructionObject: InstructionsByToken
        var rotaryName = ""
        var wayName: String
        switch type {
        case .takeRotary, .takeRoundabout:
            // Special instruction types have an intermediate level keyed to “default”.
            let instructionsByModifier = instructions[type.description] as! [String: InstructionsByModifier]
            let defaultInstructions = instructionsByModifier["default"]!
            
            wayName = step.exitNames?.first ?? ""
            if let _rotaryName = step.names?.first, let _ = step.exitIndex, let obj = defaultInstructions["name_exit"] {
                instructionObject = obj
                rotaryName = _rotaryName
            } else if let _rotaryName = step.names?.first, let obj = defaultInstructions["name"] {
                instructionObject = obj
                rotaryName = _rotaryName
            } else if let _ = step.exitIndex, let obj = defaultInstructions["exit"] {
                instructionObject = obj
            } else {
                instructionObject = defaultInstructions["default"]!
            }
        default:
            var typeInstructions = instructions[type.description] as! InstructionsByModifier
            let modesInstructions = instructions["modes"] as? InstructionsByModifier
            if let mode = mode, let modesInstructions = modesInstructions, let modesInstruction = modesInstructions[mode.description] {
                instructionObject = modesInstruction
            } else if let modifier = modifier, let typeInstruction = typeInstructions[modifier] {
                instructionObject = typeInstruction
            } else {
                instructionObject = typeInstructions["default"]!
            }
            
            // Set wayName
            let name = step.names?.first
            let ref = step.codes?.first
            
            if let name = name, let ref = ref, name != ref {
                wayName = modifyValueByKey != nil ? "\(modifyValueByKey!(.wayName, name)) (\(modifyValueByKey!(.wayName, ref)))" : "\(name) (\(ref))"
            } else if name == nil, let ref = ref {
                wayName = modifyValueByKey != nil ? "\(modifyValueByKey!(.wayName, ref))" : ref
            } else {
                wayName = name != nil ? modifyValueByKey != nil ? "\(modifyValueByKey!(.wayName, name!))" : name! : ""
            }
        }

        // Special case handling
        var laneInstruction: String?
        switch type {
        case .useLane:
            var laneConfig: String?
            if let intersection = step.intersections?.first {
                laneConfig = self.laneConfig(intersection: intersection)
            }
            let laneInstructions = constants["lanes"] as! [String: String]
            laneInstruction = laneInstructions[laneConfig ?? ""]

            if laneInstruction == nil {
                // Lane configuration is not found, default to continue
                let useLaneConfiguration = instructions["use lane"] as! InstructionsByModifier
                instructionObject = useLaneConfiguration["no_lanes"]!
            }
        default:
            break
        }

        // Decide which instruction string to use
        // Destination takes precedence over name
        var instruction: String
        if let _ = step.destinations, let obj = instructionObject["destination"] {
            instruction = obj
        } else if !wayName.isEmpty, let obj = instructionObject["name"] {
            instruction = obj
        } else {
            instruction = instructionObject["default"]!
        }

        // Prepare token replacements
        let nthWaypoint = "" // TODO: add correct waypoint counting
        let destination = step.destinations?.first ?? ""
        var exit: String = ""
        if let exitIndex = step.exitIndex, exitIndex <= 10 {
            exit = ordinalFormatter.string(from: exitIndex as NSNumber)!
        }
        let modifierConstants = constants["modifier"] as! [String: String]
        let modifierConstant = modifierConstants[modifier ?? "straight"]!
        var bearing: Int? = nil
        if step.finalHeading != nil { bearing = Int(step.finalHeading! as Double) }

        // Replace tokens
        let scanner = Scanner(string: instruction)
        scanner.charactersToBeSkipped = nil
        var result = ""
        while !scanner.isAtEnd {
            var buffer: NSString?

            if scanner.scanUpTo("{", into: &buffer) {
                result += buffer as! String
            }
            guard scanner.scanString("{", into: nil) else {
                continue
            }

            var token: NSString?
            guard scanner.scanUpTo("}", into: &token) else {
                continue
            }
            
            if scanner.scanString("}", into: nil) {
                if let tokenType = TokenType(rawValue: token as! String) {
                    var replacement: String
                    switch tokenType {
                    case .wayName: replacement = wayName
                    case .destination: replacement = destination
                    case .exit: replacement = exit
                    case .rotaryName: replacement = rotaryName
                    case .laneInstruction: replacement = laneInstruction ?? ""
                    case .modifier: replacement = modifierConstant
                    case .direction: replacement = directionFromDegree(degree: bearing)
                    case .wayPoint: replacement = nthWaypoint
                    }
                    if tokenType == .wayName {
                        result += replacement // already modified above
                    } else {
                        result += modifyValueByKey?(tokenType, replacement) ?? replacement
                    }
                }
            } else {
                result += token as! String
            }
            
        }

        // remove excess spaces
        result = result.replacingOccurrences(of: "\\s\\s", with: " ", options: .regularExpression)

        // capitalize
        let meta = OSRMTextInstructionsStrings["meta"] as! [String: Any]
        if meta["capitalizeFirstLetter"] as? Bool ?? false {
            result = result.sentenceCased
        }
        
        return result
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}
