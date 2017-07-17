#!/usr/bin/env xcrun swift -F ./Carthage/Build/Mac

import Foundation
import SwiftCLI

let runPath = FileManager.default.currentDirectoryPath
let lprojPath = "\(runPath)/../../MapboxNavigation/Resources"
let importFilename = "Abbreviations.plist"
let exportFilename = "Abbreviations.csv.plist"

enum AbbreviationType: String {
    case Directions = "directions"
    case Abbreviations = "abbreviations"
    case Classifications = "classifications"
    static let allValues = [Directions, Abbreviations, Classifications]
}

extension Dictionary where Key == String, Value == String {
    func asCSV() -> String {
        return flatMap({ "\"\($0.key)\", \"\($0.value)\"" }).joined(separator: "\n").appending("\n")
    }
}

extension URL {
    static func plistFilePath(for language: String) -> URL {
        let filePath = "\(lprojPath)/\(language).lproj/\(importFilename)"
        return URL(fileURLWithPath: filePath)
    }
    
    static func plistCSVStyleFilePath(for language: String) -> URL {
        let filePath = "\(lprojPath)/\(language).lproj/\(exportFilename)"
        return URL(fileURLWithPath: filePath)
    }
}

struct Plist {
    enum Style {
        case CSV
        case plain
    }
    
    var content: [String: AnyObject]!
    
    init(filePath: URL) {
        do {
            var format: PropertyListSerialization.PropertyListFormat = .xml
            guard let data = try String(contentsOf: filePath).data(using: .utf8) else { return }
            content = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: &format) as! [String : AnyObject]
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var csvStyleLocalizedStrings: [String: String] {
        var strings = [String: String]()
        for type in AbbreviationType.allValues {
            if let dict = content[type.rawValue] as? [String: String] {
                strings[type.rawValue] = dict.asCSV()
            }
        }
        return strings
    }
    
    mutating func importFromCSVStyledPlist(at filePath: URL) {
        let csvPlist = Plist(filePath: filePath)
        let csvContent = csvPlist.content as! [String: String]
        var newContent = [String: AnyObject]()
        
        for (type, csv) in csvContent {
            var abbreviationsByWord: [String: String] = [:]
            // Look for the following:
            // "word", "abbr."
            // "word" , "abbr."
            // "word", "abbr.",
            // "word ", " abbr."
            let scanner = Scanner(string: csv)
            scanner.charactersToBeSkipped = .whitespaces
            while !scanner.isAtEnd {
                guard scanner.scanString("\"", into: nil) else {
                    break
                }
                var key: NSString?
                guard scanner.scanUpTo("\"", into: &key), key != nil else {
                    break
                }
                guard scanner.scanString("\"", into: nil) else {
                    break
                }
                guard scanner.scanString(",", into: nil) else {
                    break
                }
                
                guard scanner.scanString("\"", into: nil) else {
                    break
                }
                var value: NSString?
                guard scanner.scanUpTo("\"", into: &value), value != nil else {
                    break
                }
                guard scanner.scanString("\"", into: nil) else {
                    break
                }
                
                abbreviationsByWord[key! as String] = value! as String
                
                scanner.scanString(",", into: nil)
                guard scanner.scanString("\n", into: nil) else {
                    break
                }
            }
            
            newContent[type] = abbreviationsByWord as NSDictionary
        }
        
        content = newContent
    }
    
    func save(as style: Style, filePath: URL) {
        var dict: NSDictionary
        switch style {
        case .CSV:
            dict = csvStyleLocalizedStrings as NSDictionary
            break
        case .plain:
            dict = content! as NSDictionary
            break
        }
        dict.write(to: filePath, atomically: true)
    }
}

class ImportCommand: Command {
    let name = "import"
    let shortDescription = "Imports \(exportFilename) into \(importFilename)"
    let param = OptionalParameter()
    var languages: [String] {
        return param.value?.components(separatedBy: ",") ?? ["Base"]
    }
    
    func execute() throws {
        print("Importing \(languages)")
        
        for language in languages {
            var plist = Plist(filePath: .plistFilePath(for: language))
            plist.importFromCSVStyledPlist(at: .plistCSVStyleFilePath(for: language))
            plist.save(as: .plain, filePath: .plistFilePath(for: language))
        }
    }
}

class ExportCommand: Command {
    let name = "export"
    let shortDescription = "Exports \(importFilename) to \(exportFilename)"
    let param = OptionalParameter()
    var languages: [String] {
        return param.value?.components(separatedBy: ",") ?? ["Base"]
    }
    
    func execute() throws {
        print("Exporting \(languages)")
        
        for language in languages {
            let plist = Plist(filePath: .plistFilePath(for: language))
            plist.save(as: .CSV, filePath: .plistCSVStyleFilePath(for: language))
        }
    }
}

CLI.setup(name: "Abbreviations", version: "0.1", description: "Converts abbreviations to a CSV-style dictionary and vice versa.")
CLI.register(command: ImportCommand())
CLI.register(command: ExportCommand())
_ = CLI.go()

