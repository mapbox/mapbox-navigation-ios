#!/usr/bin/env xcrun swift -F ./Carthage/Build/Mac

import Foundation
import SwiftCLI

let runPath = FileManager.default.currentDirectoryPath
let lprojPath = "\(runPath)/../../MapboxNavigation/Resources"
let plistFilename = "Abbreviations.plist"
let stringsFilename = "Abbreviations.strings"

enum AbbreviationType: String {
    case Directions = "directions"
    case Abbreviations = "abbreviations"
    case Classifications = "classifications"
    static let allValues = [Directions, Abbreviations, Classifications]
}

typealias Abbreviations = [String: [String: String]]

extension Dictionary where Key == String, Value == String {
    var localizedStrings: String {
        return flatMap({ "\"\($0.0)\" = \"\($0.1)\";" }).joined(separator: "\n").appending("\n");
    }
}

struct Plist {
    var content: Abbreviations!
    var filePath: URL
    
    init(filePath: URL) {
        self.filePath = filePath
        do {
            var format: PropertyListSerialization.PropertyListFormat = .xml
            guard let data = try String(contentsOf: filePath).data(using: .utf8) else { return }
            content = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: &format) as! Abbreviations
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var flattenedLocalizedStrings: [String] {
        var strings = [String]()
        for type in AbbreviationType.allValues {
            if let abbreviation = content[type.rawValue] {
                strings.append(abbreviation.localizedStrings)
            }
        }
        return strings
    }
    
    func write(to filePath: URL) {
        let dict = content! as NSDictionary
        dict.write(to: filePath, atomically: true)
    }
}

extension URL {
    static func plistFilePath(for language: String) -> URL {
        let filePath = "\(lprojPath)/\(language).lproj/\(plistFilename)"
        return URL(fileURLWithPath: filePath)
    }
    
    static func stringsFilePath(for language: String) -> URL {
        let filePath = "\(lprojPath)/\(language).lproj/\(stringsFilename)"
        return URL(fileURLWithPath: filePath)
    }
}

class ImportCommand: Command {
    let name = "import"
    let shortDescription = "Imports Abbreviations.strings into Abbreviations.plist"
    let param = OptionalParameter()
    var languages: [String] {
        return param.value?.components(separatedBy: ",") ?? ["Base"]
    }
    
    func execute() throws {
        print("Importing \(languages)")
        
        for language in languages {
            do {
                let strings = try String(contentsOf: .stringsFilePath(for: language)).propertyListFromStringsFileFormat()
                var plist = Plist(filePath: .plistFilePath(for: language))
                
                for type in plist.content {
                    for abbreviation in type.value {
                        guard let string = strings.filter({ $0.key == abbreviation.key }).first?.value else {
                            continue
                        }
                        plist.content[type.key]![abbreviation.key] = string
                    }
                }
                
                plist.write(to: .plistFilePath(for: language))
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

class ExportCommand: Command {
    let name = "export"
    let shortDescription = "Exports Abbreviations.plist to Abbreviations.strings"
    let param = OptionalParameter()
    var languages: [String] {
        return param.value?.components(separatedBy: ",") ?? ["Base"]
    }
    
    func execute() throws {
        print("Exporting \(languages) strings.")
        
        for language in languages {
            let plist = Plist(filePath: .plistFilePath(for: language))
            do {
                try plist.flattenedLocalizedStrings.joined().write(to: .stringsFilePath(for: language), atomically: true, encoding: .utf8)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

CLI.setup(name: "Localize abbreviations", version: "0.1", description: "Export from plist to strings or vice versa.")
CLI.register(command: ImportCommand())
CLI.register(command: ExportCommand())
_ = CLI.go()

