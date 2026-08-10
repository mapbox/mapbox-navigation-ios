//
//  PointAnnotationsStorage.swift
//
//
//  Created by Maksim Chizhavko on 1/16/25.
//

import Foundation
import MapboxMaps

protocol PointAnnotatable {
    var coordinate: CLLocationCoordinate2D { get }
}

struct PointAnnotationsStorage<Element: PointAnnotatable> {
    private var elements: [String: Element] = [:]
    private var annotations: [PointAnnotation] = []

    mutating func create(_ object: Element) -> PointAnnotation {
        let annotation = PointAnnotation(coordinate: object.coordinate)
        elements[annotation.id] = object
        annotations.append(annotation)
        return annotation
    }

    mutating func remove(annotation: Annotation) {
        if elements.removeValue(forKey: annotation.id) != nil {
            if let idx = annotations.firstIndex(where: { $0.id == annotation.id }) {
                annotations.remove(at: idx)
            }
        }
    }

    mutating func removeAll() {
        elements.removeAll()
        annotations.removeAll()
    }

    subscript(_ annotation: Annotation) -> Element? {
        elements[annotation.id]
    }

    var isEmpty: Bool {
        elements.isEmpty
    }

    var ids: Set<String> {
        Set(annotations.map(\.id))
    }
}
