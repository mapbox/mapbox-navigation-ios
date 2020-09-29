/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 Code modified by Mapbox to adjust API filetring criteria, original at https://github.com/material-motion/apidiff/blob/e78f92ae310cd4affc86a4510bb7b9f9609662d2/apple/diffreport/Sources/diffreportlib/diffreport.swift
 
 TODO: log briefly all code updates
 */

import Foundation

public typealias JSONObject = Any

typealias SourceKittenNode = [String: Any]
typealias APINode = [String: Any]
typealias ApiNameNodeMap = [String: APINode]

/** A type of API change. */
public enum ApiChange {
    case addition(apiType: String, name: String)
    case deletion(apiType: String, name: String)
    case modification(apiType: String, name: String, modificationType: String, from: String, to: String)
}

/** Generates an API diff report from two SourceKitten JSON outputs. */
public func diffreport(oldApi: JSONObject, newApi: JSONObject) throws -> [String: [ApiChange]] {
    let oldApiNameNodeMap = extractAPINodeMap(from: oldApi as! [SourceKittenNode])
    let newApiNameNodeMap = extractAPINodeMap(from: newApi as! [SourceKittenNode])
    
    let oldApiNames = Set(oldApiNameNodeMap.keys)
    let newApiNames = Set(newApiNameNodeMap.keys)
    
    let addedApiNames = newApiNames.subtracting(oldApiNames)
    let deletedApiNames = oldApiNames.subtracting(newApiNames)
    let persistedApiNames = oldApiNames.intersection(newApiNames)
    
    var changes: [String: [ApiChange]] = [:]
    
    // Additions
    
    for usr in (addedApiNames.map { usr in newApiNameNodeMap[usr]! }.sorted(by: apiNodeIsOrderedBefore)) {
        let apiType = prettyString(forKind: usr["key.kind"] as! String)
        let name = prettyName(forApi: usr, apis: newApiNameNodeMap)
        let root = rootName(forApi: usr, apis: newApiNameNodeMap)
        changes[root, withDefault: []].append(.addition(apiType: apiType, name: name))
    }
    
    // Deletions
    
    for usr in (deletedApiNames.map { usr in oldApiNameNodeMap[usr]! }.sorted(by: apiNodeIsOrderedBefore)) {
        let apiType = prettyString(forKind: usr["key.kind"] as! String)
        let name = prettyName(forApi: usr, apis: oldApiNameNodeMap)
        let root = rootName(forApi: usr, apis: oldApiNameNodeMap)
        changes[root, withDefault: []].append(.deletion(apiType: apiType, name: name))
    }
    
    // Modifications
    
    let ignoredKeys = Set(arrayLiteral: "key.doc.line", "key.parsed_scope.end", "key.parsed_scope.start", "key.doc.column", "key.doc.comment", "key.bodyoffset", "key.nameoffset", "key.doc.full_as_xml", "key.offset", "key.fully_annotated_decl", "key.length", "key.bodylength", "key.namelength", "key.annotated_decl", "key.doc.parameters", "key.elements", "key.related_decls",
                          "key.filepath", "key.attributes",
                          "key.parsed_declaration",
                          "key.docoffset", "key.attributes")
    
    for usr in persistedApiNames {
        let oldApi = oldApiNameNodeMap[usr]!
        let newApi = newApiNameNodeMap[usr]!
        let root = rootName(forApi: newApi, apis: newApiNameNodeMap)
        let allKeys = Set(oldApi.keys).union(Set(newApi.keys))
        
        for key in allKeys {
            if ignoredKeys.contains(key) {
                continue
            }
            if let oldValue = oldApi[key] as? String, let newValue = newApi[key] as? String, oldValue != newValue {
                let apiType = prettyString(forKind: newApi["key.kind"] as! String)
                let name = prettyName(forApi: newApi, apis: newApiNameNodeMap)
                let modificationType = prettyString(forModificationKind: key)
                if apiType == "class" && key == "key.parsed_declaration" {
                    // Ignore declarations for classes because it's a complete representation of the class's
                    // code, which is not helpful diff information.
                    continue
                }
                changes[root, withDefault: []].append(.modification(apiType: apiType,
                                                                    name: name,
                                                                    modificationType: modificationType,
                                                                    from: oldValue,
                                                                    to: newValue))
            }
        }
    }
    
    return changes
}

extension ApiChange {
    public func toMarkdown() -> String {
        switch self {
        case .addition(let apiType, let name):
            return "*new* \(apiType): \(name)"
        case .deletion(let apiType, let name):
            return "*removed* \(apiType): \(name)"
        case .modification(let apiType, let name, let modificationType, let from, let to):
            return [
                "*modified* \(apiType): \(name)",
                "",
                "| Type of change: | \(modificationType) |",
                "|---|---|",
                "| From: | `\(from.replacingOccurrences(of: "\n", with: " "))` |",
                "| To: | `\(to.replacingOccurrences(of: "\n", with: " "))` |"
                ].joined(separator: "\n")
        }
    }
}

extension ApiChange: Equatable {}

public func == (left: ApiChange, right: ApiChange) -> Bool {
    switch (left, right) {
    case (let .addition(apiType, name), let .addition(apiType2, name2)):
        return apiType == apiType2 && name == name2
    case (let .deletion(apiType, name), let .deletion(apiType2, name2)):
        return apiType == apiType2 && name == name2
    case (let .modification(apiType, name, modificationType, from, to),
          let .modification(apiType2, name2, modificationType2, from2, to2)):
        return apiType == apiType2 && name == name2 && modificationType == modificationType2 && from == from2 && to == to2
    default:
        return false
    }
}

/**
 get-with-default API for Dictionary
 
 Example usage: dict[key, withDefault: []]
 */
extension Dictionary {
    subscript(key: Key, withDefault value: @autoclosure () -> Value) -> Value {
        mutating get {
            if self[key] == nil {
                self[key] = value()
            }
            return self[key]!
        }
        set {
            self[key] = newValue
        }
    }
}

/**
 Sorting function for APINode instances.
 
 Sorts by filename.
 
 Example usage: sorted(by: apiNodeIsOrderedBefore)
 */
func apiNodeIsOrderedBefore(prev: APINode, next: APINode) -> Bool {
    if let prevFile = prev["key.doc.file"] as? String, let nextFile = next["key.doc.file"] as? String {
        return prevFile < nextFile
    }
    return false
}

/** Union two dictionaries, preferring existing values if they possess a parent.usr key. */
func += (left: inout ApiNameNodeMap, right: ApiNameNodeMap) {
    for (k, v) in right {
        if left[k] == nil {
            left.updateValue(v, forKey: k)
        } else if let object = left[k], object["parent.usr"] == nil {
            left.updateValue(v, forKey: k)
        }
    }
}

func prettyString(forKind kind: String) -> String {
    if let pretty = [
        // Objective-C
        "sourcekitten.source.lang.objc.decl.protocol": "protocol",
        "sourcekitten.source.lang.objc.decl.typedef": "typedef",
        "sourcekitten.source.lang.objc.decl.method.instance": "method",
        "sourcekitten.source.lang.objc.decl.property": "property",
        "sourcekitten.source.lang.objc.decl.class": "class",
        "sourcekitten.source.lang.objc.decl.constant": "constant",
        "sourcekitten.source.lang.objc.decl.enum": "enum",
        "sourcekitten.source.lang.objc.decl.enumcase": "enum value",
        "sourcekitten.source.lang.objc.decl.category": "category",
        "sourcekitten.source.lang.objc.decl.method.class": "class method",
        "sourcekitten.source.lang.objc.decl.struct": "struct",
        "sourcekitten.source.lang.objc.decl.field": "field",
        
        // Swift
        "source.lang.swift.decl.function.method.static": "static method",
        "source.lang.swift.decl.function.method.instance": "method",
        "source.lang.swift.decl.var.instance": "var",
        "source.lang.swift.decl.class": "class",
        "source.lang.swift.decl.var.static": "static var",
        "source.lang.swift.decl.enum": "enum",
        "source.lang.swift.decl.function.free": "function",
        "source.lang.swift.decl.var.global": "global var",
        "source.lang.swift.decl.protocol": "protocol",
        "source.lang.swift.decl.enumelement": "enum value"
        ][kind] {
        return pretty
    }
    return kind
}

func prettyString(forModificationKind kind: String) -> String {
    switch kind {
    case "key.swift_declaration": return "Swift declaration"
    case "key.parsed_declaration": return "Declaration"
    case "key.doc.declaration": return "Declaration"
    case "key.typename": return "Declaration"
    case "key.always_deprecated": return "Deprecation"
    case "key.deprecation_message": return "Deprecation message"
    default: return kind
    }
}

/** Walk the APINode to the root node. */
func rootName(forApi api: APINode, apis: ApiNameNodeMap) -> String {
    let name = api["key.name"] as! String
    if let parentUsr = api["parent.usr"] as? String, let parentApi = apis[parentUsr] {
        return rootName(forApi: parentApi, apis: apis)
    }
    return name
}

func prettyName(forApi api: APINode, apis: ApiNameNodeMap) -> String {
    let name = api["key.name"] as! String
    if let parentUsr = api["parent.usr"] as? String, let parentApi = apis[parentUsr] {
        return "`\(name)` in \(prettyName(forApi: parentApi, apis: apis))"
    }
    return "`\(name)`"
}

/** Normalize data contained in an API node json dictionary. */
func apiNode(from sourceKittenNode: SourceKittenNode) -> APINode {
    var data = sourceKittenNode
    data.removeValue(forKey: "key.substructure")
    for (key, value) in data {
        data[key] = String(describing: value)
    }
    return data
}

/**
 Recursively iterate over each sourcekitten node and extract a flattened map of USR identifier to
 APINode instance.
 */
func extractAPINodeMap(from sourceKittenNodes: [SourceKittenNode]) -> ApiNameNodeMap {
    var map: ApiNameNodeMap = [:]
    for file in sourceKittenNodes {
        for (_, information) in file {
            let substructure = (information as! SourceKittenNode)["key.substructure"] as! [SourceKittenNode]
            for jsonNode in substructure {
                map += extractAPINodeMap(from: jsonNode)
            }
        }
    }
    return map
}

/**
 Recursively iterate over a sourcekitten node and extract a flattened map of USR identifier to
 APINode instance.
 */
func extractAPINodeMap(from sourceKittenNode: SourceKittenNode, parentUsr: String? = nil) -> ApiNameNodeMap {
    var map: ApiNameNodeMap = [:]
    for (key, value) in sourceKittenNode {
        switch key {
        case "key.usr":
            if let accessibility = sourceKittenNode["key.accessibility"] {
                if accessibility as! String != "source.lang.swift.accessibility.public" &&
                    accessibility as! String != "source.lang.swift.accessibility.open" {
                    continue
                }
            } else if let kind = sourceKittenNode["key.kind"] as? String, kind == "source.lang.swift.decl.extension" {
                continue
            }
            var node = apiNode(from: sourceKittenNode)
            
            // Create a reference to the parent node
            node["parent.usr"] = parentUsr
            
            // Store the API node in the map
            map[value as! String] = node
            
        case "key.substructure":
            let substructure = value as! [SourceKittenNode]
            for subSourceKittenNode in substructure {
                map += extractAPINodeMap(from: subSourceKittenNode, parentUsr: sourceKittenNode["key.usr"] as? String)
            }
        default:
            continue
        }
    }
    return map
}

/**
 Execute sourcekitten with a given umbrella header.
 
 Only meant to be used in unit test builds.
 
 @param header Absolute path to an umbrella header.
 */
func runSourceKitten(withHeader header: String) throws -> JSONObject {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = [
        "/usr/local/bin/sourcekitten",
        "doc",
        "--objc",
        header,
        "--",
        "-x",
        "objective-c",
    ]
    let standardOutput = Pipe()
    task.standardOutput = standardOutput
    task.launch()
    task.waitUntilExit()
    var data = standardOutput.fileHandleForReading.readDataToEndOfFile()
    let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"]!.replacingOccurrences(of: "/", with: "\\/")
    let string = String(data: data, encoding: String.Encoding.utf8)!
        .replacingOccurrences(of: tmpDir + "old\\/", with: "")
        .replacingOccurrences(of: tmpDir + "new\\/", with: "")
    data = string.data(using: String.Encoding.utf8)!
    return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
}
