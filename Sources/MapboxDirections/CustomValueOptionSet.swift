import Foundation

/// Describes how ``CustomValueOptionSet/customOptionsByRawValue`` component is compared during logical operations in
/// ``CustomValueOptionSet``.
public enum CustomOptionComparisonPolicy: Equatable, Sendable {
    /// Custom options are equal if ``CustomValueOptionSet/customOptionsByRawValue``  key-value pairs are strictly equal
    ///
    /// Example:
    /// [1: "value1"] == [1: "value1"]
    /// [1: "value1"] != [1: "value2"]
    /// [1: "value1"] != [:]
    /// [:] == [:]
    case equal
    /// Custom options are equal if ``CustomValueOptionSet/customOptionsByRawValue``  by the given key is equal or `nil`
    ///
    /// Example:
    /// [1: "value1"] == [1: "value1"]
    /// [1: "value1"] != [1: "value2"]
    /// [1: "value1"] == [:]
    /// [:] == [:]
    case equalOrNull
    /// Custom options are not compared. Only `rawValue` is taken into account when comparing ``CustomValueOptionSet``s.
    ///
    /// Example:
    /// [1: "value1"] == [1: "value1"]
    /// [1: "value1"] == [1: "value2"]
    /// [1: "value1"] == [:]
    /// [:] == [:]
    case rawValueEqual
}

/// Option set implementation which allows each option to have custom string value attached.
public protocol CustomValueOptionSet: OptionSet where RawValue: FixedWidthInteger, Element == Self {
    associatedtype Element = Self
    associatedtype CustomValue: Equatable
    var rawValue: Self.RawValue { get set }

    /// Provides a text value description for user-provided options.
    ///
    /// The option set will recognize a custom option if it's unique `rawValue` flag is set and
    /// ``customOptionsByRawValue`` contains a description for that flag.
    /// Use the ``update(customOption:comparisonPolicy:)`` method to append a custom option.
    var customOptionsByRawValue: [RawValue: CustomValue] { get set }

    init(rawValue: Self.RawValue)

    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    ///
    /// This example uses the `contains(_:)` method to test whether an integer is
    /// a member of a set of prime numbers.
    ///
    ///     let primes: Set = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
    ///     let x = 5
    ///     if primes.contains(x) {
    ///         print("\(x) is prime!")
    ///     } else {
    ///         print("\(x). Not prime.")
    ///     }
    ///     // Prints "5 is prime!"
    ///
    /// - Parameter member: An element to look for in the set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if `member` exists in the set; otherwise, `false`.
    func contains(_ member: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
    /// Returns a new set with the elements of both this and the given set.
    ///
    /// In the following example, the `attendeesAndVisitors` set is made up
    /// of the elements of the `attendees` and `visitors` sets:
    ///
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Marcia", "Nathaniel"]
    ///     let attendeesAndVisitors = attendees.union(visitors)
    ///     print(attendeesAndVisitors)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     let initialIndices = Set(0..<5)
    ///     let expandedIndices = initialIndices.union([2, 3, 6, 7])
    ///     print(expandedIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: A new set with the unique elements of this set and `other`.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    func union(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element
    /// Adds the elements of the given set to the set.
    ///
    /// In the following example, the elements of the `visitors` set are added to
    /// the `attendees` set:
    ///
    ///     var attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors: Set = ["Diana", "Marcia", "Nathaniel"]
    ///     attendees.formUnion(visitors)
    ///     print(attendees)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     var initialIndices = Set(0..<5)
    ///     initialIndices.formUnion([2, 3, 6, 7])
    ///     print(initialIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    mutating func formUnion(_ other: Self, comparisonPolicy: CustomOptionComparisonPolicy)
    /// Returns a new set with the elements that are common to both this set and
    /// the given set.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: A new set.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    func intersection(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element
    /// Removes the elements of this set that aren't also in the given set.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// not also members of the `neighbors` set are removed. In particular, the
    /// names `"Alicia"`, `"Chris"`, and `"Diana"` are removed.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     employees.formIntersection(neighbors)
    ///     print(employees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    mutating func formIntersection(_ other: Self, comparisonPolicy: CustomOptionComparisonPolicy)
    /// Returns a new set with the elements that are either in this set or in the
    /// given set, but not in both.
    ///
    /// In the following example, the `eitherNeighborsOrEmployees` set is made up
    /// of the elements of the `employees` and `neighbors` sets that are not in
    /// both `employees` *and* `neighbors`. In particular, the names `"Bethany"`
    /// and `"Eric"` do not appear in `eitherNeighborsOrEmployees`.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     let eitherNeighborsOrEmployees = employees.symmetricDifference(neighbors)
    ///     print(eitherNeighborsOrEmployees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: A new set.
    func symmetricDifference(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element
    /// Removes the elements of the set that are also in the given set and adds
    /// the members of the given set that are not already in the set.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// also members of `neighbors` are removed from `employees`, while the
    /// elements of `neighbors` that are not members of `employees` are added to
    /// `employees`. In particular, the names `"Bethany"` and `"Eric"` are
    /// removed from `employees` while the name `"Forlani"` is added.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     employees.formSymmetricDifference(neighbors)
    ///     print(employees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    mutating func formSymmetricDifference(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy)
    /// Returns a new set containing the elements of this set that do not occur
    /// in the given set.
    ///
    /// In the following example, the `nonNeighbors` set is made up of the
    /// elements of the `employees` set that are not elements of `neighbors`:
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let nonNeighbors = employees.subtracting(neighbors)
    ///     print(nonNeighbors)
    ///     // Prints "["Diana", "Chris", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: A new set.
    func subtracting(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element
    /// Removes the elements of the given set from this set.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// also members of the `neighbors` set are removed. In particular, the
    /// names `"Bethany"` and `"Eric"` are removed from `employees`.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     employees.subtract(neighbors)
    ///     print(employees)
    ///     // Prints "["Diana", "Chris", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    mutating func subtract(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy)
    /// Inserts the given element in the set if it is not already present.
    ///
    /// If an element equal to `newMember` is already contained in the set, this method has no effect. In this example,
    /// a new element is inserted into `classDays`, a set of days of the week. When an existing element is inserted, the
    /// `classDays` set does not change.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.wednesday, .friday]
    ///     print(classDays.insert(.monday))
    ///     // Prints "(true, .monday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    ///     print(classDays.insert(.friday))
    ///     // Prints "(false, .friday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `(true, newMember)` if `newMember` was not contained in the set. If an element equal to `newMember`
    /// was already contained in the set, the method returns `(false, oldMember)`, where `oldMember` is the element that
    /// was equal to `newMember`. In some cases, `oldMember` may be distinguishable from `newMember` by identity
    /// comparison or some other means.
    mutating func insert(_ newMember: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy)
        -> (inserted: Bool, memberAfterInsert: Self.Element)
    /// Removes the given element and any elements subsumed by the given element.
    ///
    /// - Parameter member: The element of the set to remove.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: For ordinary sets, an element equal to `member` if `member` is contained in the set; otherwise,
    /// `nil`. In some cases, a returned element may be distinguishable from `member` by identity comparison or some
    /// other means.
    ///
    ///   For sets where the set type and element type are the same, like
    ///   `OptionSet` types, this method returns any intersection between the set
    ///   and `[member]`, or `nil` if the intersection is empty.
    mutating func remove(_ member: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element?
    /// Inserts the given element into the set unconditionally.
    ///
    /// If an element equal to `newMember` is already contained in the set,
    /// `newMember` replaces the existing element. In this example, an existing
    /// element is inserted into `classDays`, a set of days of the week.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.monday, .wednesday, .friday]
    ///     print(classDays.update(with: .monday))
    ///     // Prints "Optional(.monday)"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: For ordinary sets, an element equal to `newMember` if the set
    ///   already contained such a member; otherwise, `nil`. In some cases, the
    ///   returned element may be distinguishable from `newMember` by identity
    ///   comparison or some other means.
    ///
    ///   For sets where the set type and element type are the same, like
    ///   `OptionSet` types, this method returns any intersection between the
    ///   set and `[newMember]`, or `nil` if the intersection is empty.
    mutating func update(with newMember: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element?
    /// Inserts the given element into the set unconditionally.
    ///
    /// If an element equal to `customOption` is already contained in the set, `customOption` replaces the existing
    /// element. Otherwise - updates the set contents and fills ``customOptionsByRawValue`` accordingly.
    ///
    /// - Parameter customOption: An element to insert into the set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: For ordinary sets, an element equal to `customOption` if the set already contained such a member;
    /// otherwise, `nil`. In some cases, the returned element may be distinguishable from `customOption` by identity
    /// comparison or some other means.
    ///
    ///   For sets where the set type and element type are the same, like
    ///   `OptionSet` types, this method returns any intersection between the
    ///   set and `[customOption]`, or `nil` if the intersection is empty.
    mutating func update(customOption: (RawValue, CustomValue), comparisonPolicy: CustomOptionComparisonPolicy) -> Self
        .Element?
    /// Returns a Boolean value that indicates whether the set is a subset of
    /// another set.
    ///
    /// Set *A* is a subset of another set *B* if every member of *A* is also a
    /// member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isSubset(of: employees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
    func isSubset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
    /// Returns a Boolean value that indicates whether the set is a superset of
    /// the given set.
    ///
    /// Set *A* is a superset of another set *B* if every member of *B* is also a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isSuperset(of: attendees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if the set is a superset of `possibleSubset`;
    ///   otherwise, `false`.
    func isSuperset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
    /// Returns a Boolean value that indicates whether this set is a strict
    /// subset of the given set.
    ///
    /// Set *A* is a strict subset of another set *B* if every member of *A* is
    /// also a member of *B* and *B* contains at least one element that is not a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isStrictSubset(of: employees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict subset of itself:
    ///     print(attendees.isStrictSubset(of: attendees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if the set is a strict subset of `other`; otherwise,
    ///   `false`.
    func isStrictSubset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
    /// Returns a Boolean value that indicates whether this set is a strict
    /// superset of the given set.
    ///
    /// Set *A* is a strict superset of another set *B* if every member of *B* is
    /// also a member of *A* and *A* contains at least one element that is *not*
    /// a member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isStrictSuperset(of: attendees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict superset of itself:
    ///     print(employees.isStrictSuperset(of: employees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if the set is a strict superset of `other`; otherwise,
    ///   `false`.
    func isStrictSuperset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
    /// Returns a Boolean value that indicates whether the set has no members in
    /// common with the given set.
    ///
    /// In the following example, the `employees` set is disjoint with the
    /// `visitors` set because no name appears in both sets.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let visitors: Set = ["Marcia", "Nathaniel", "Olivia"]
    ///     print(employees.isDisjoint(with: visitors))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Parameter comparisonPolicy: comparison method to be used for ``customOptionsByRawValue``.
    /// - Returns: `true` if the set has no elements in common with `other`;
    ///   otherwise, `false`.
    func isDisjoint(with other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool
}

extension CustomValueOptionSet where Self == Self.Element {
    // MARK: Implemented methods

    private func customOptionIsEqual(
        _ lhs: [RawValue: CustomValue],
        _ rhs: [RawValue: CustomValue],
        key: RawValue,
        policy: CustomOptionComparisonPolicy
    ) -> Bool {
        switch policy {
        case .equal:
            return lhs[key] == rhs[key]
        case .equalOrNull:
            return lhs[key] == rhs[key] || lhs[key] == nil || rhs[key] == nil
        case .rawValueEqual:
            return true
        }
    }

    @discardableResult
    public func contains(_ member: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        let intersection = rawValue & member.rawValue
        guard intersection != 0 else {
            return false
        }

        for offset in 0..<intersection.bitWidth {
            guard customOptionIsEqual(
                customOptionsByRawValue,
                member.customOptionsByRawValue,
                key: intersection & 1 << offset,
                policy: comparisonPolicy
            ) else {
                return false
            }
        }
        return true
    }

    @discardableResult @inlinable
    public mutating func insert(
        _ newMember: Self.Element,
        comparisonPolicy: CustomOptionComparisonPolicy
    ) -> (inserted: Bool, memberAfterInsert: Self.Element) {
        if contains(newMember, comparisonPolicy: comparisonPolicy) {
            return (false, intersection(newMember, comparisonPolicy: comparisonPolicy))
        } else {
            rawValue = rawValue | newMember.rawValue
            customOptionsByRawValue.merge(newMember.customOptionsByRawValue) { current, _ in current }
            return (true, newMember)
        }
    }

    @discardableResult @inlinable
    public mutating func remove(_ member: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self
    .Element? {
        let intersection = intersection(member, comparisonPolicy: comparisonPolicy)
        if intersection.rawValue == 0 {
            return nil
        } else {
            rawValue -= intersection.rawValue
            customOptionsByRawValue = customOptionsByRawValue.filter { key, _ in
                rawValue & key != 0
            }
            return intersection
        }
    }

    @discardableResult @inlinable
    public mutating func update(with newMember: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self
    .Element? {
        let intersection = intersection(newMember, comparisonPolicy: comparisonPolicy)

        if intersection.rawValue == 0 {
            // insert
            rawValue = rawValue | newMember.rawValue
            customOptionsByRawValue.merge(newMember.customOptionsByRawValue) { current, _ in current }
            return nil
        } else {
            // update
            rawValue = rawValue | newMember.rawValue
            customOptionsByRawValue.merge(intersection.customOptionsByRawValue) { _, new in new }
            return intersection
        }
    }

    public mutating func formIntersection(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) {
        rawValue = rawValue & other.rawValue
        customOptionsByRawValue = customOptionsByRawValue.reduce(into: [:]) { partialResult, item in
            if customOptionIsEqual(
                customOptionsByRawValue,
                other.customOptionsByRawValue,
                key: item.key,
                policy: comparisonPolicy
            ) {
                partialResult[item.key] = item.value
            } else if rawValue & item.key != 0 {
                rawValue -= item.key
            }
        }
    }

    public mutating func subtract(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) {
        rawValue = rawValue ^ (rawValue & other.rawValue)
        customOptionsByRawValue = customOptionsByRawValue.reduce(into: [:]) { partialResult, item in
            if !customOptionIsEqual(
                customOptionsByRawValue,
                other.customOptionsByRawValue,
                key: item.key,
                policy: comparisonPolicy
            ) {
                partialResult[item.key] = item.value
            }
        }
    }

    // MARK: Deferring methods

    @discardableResult @inlinable
    public func union(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element {
        var union = self
        union.formUnion(other, comparisonPolicy: comparisonPolicy)
        return union
    }

    @discardableResult @inlinable
    public func intersection(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element {
        var intersection = self
        intersection.formIntersection(other, comparisonPolicy: comparisonPolicy)
        return intersection
    }

    @discardableResult @inlinable
    public func symmetricDifference(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self
    .Element {
        var difference = self
        difference.formSymmetricDifference(other, comparisonPolicy: comparisonPolicy)
        return difference
    }

    @discardableResult @inlinable
    public mutating func update(
        customOption: (RawValue, CustomValue),
        comparisonPolicy: CustomOptionComparisonPolicy
    ) -> Self.Element? {
        var newMember = Self(rawValue: customOption.0)
        newMember.customOptionsByRawValue[customOption.0] = customOption.1
        return update(with: newMember, comparisonPolicy: comparisonPolicy)
    }

    @inlinable
    public mutating func formUnion(_ other: Self, comparisonPolicy: CustomOptionComparisonPolicy) {
        _ = update(with: other, comparisonPolicy: comparisonPolicy)
    }

    @inlinable
    public mutating func formSymmetricDifference(
        _ other: Self.Element,
        comparisonPolicy: CustomOptionComparisonPolicy
    ) {
        let intersection = intersection(other, comparisonPolicy: comparisonPolicy)
        _ = remove(other, comparisonPolicy: comparisonPolicy)
        _ = insert(
            other.subtracting(
                intersection,
                comparisonPolicy: comparisonPolicy
            ),
            comparisonPolicy: comparisonPolicy
        )
    }

    @discardableResult @inlinable
    public func subtracting(_ other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Self.Element {
        var substracted = self
        substracted.subtract(other, comparisonPolicy: comparisonPolicy)
        return substracted
    }

    @discardableResult @inlinable
    public func isSubset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        return intersection(other, comparisonPolicy: comparisonPolicy) == self
    }

    @discardableResult @inlinable
    public func isDisjoint(with other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        return intersection(other, comparisonPolicy: comparisonPolicy).isEmpty
    }

    @discardableResult @inlinable
    public func isSuperset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        return other.isSubset(of: self, comparisonPolicy: comparisonPolicy)
    }

    @discardableResult @inlinable
    public func isStrictSuperset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        return isSuperset(of: other, comparisonPolicy: comparisonPolicy) && rawValue > other.rawValue
    }

    @discardableResult @inlinable
    public func isStrictSubset(of other: Self.Element, comparisonPolicy: CustomOptionComparisonPolicy) -> Bool {
        return other.isStrictSuperset(of: self, comparisonPolicy: comparisonPolicy)
    }
}

// MARK: - SetAlgebra implementation

extension CustomValueOptionSet {
    @discardableResult @inlinable
    public func contains(_ member: Self.Element) -> Bool {
        return contains(member, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func union(_ other: Self) -> Self {
        return union(other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func intersection(_ other: Self) -> Self {
        return intersection(other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func symmetricDifference(_ other: Self) -> Self {
        return symmetricDifference(other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public mutating func insert(_ newMember: Self.Element) -> (inserted: Bool, memberAfterInsert: Self.Element) {
        return insert(newMember, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public mutating func remove(_ member: Self.Element) -> Self.Element? {
        return remove(member, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public mutating func update(with newMember: Self.Element) -> Self.Element? {
        return update(with: newMember, comparisonPolicy: .equal)
    }

    @inlinable
    public mutating func formUnion(_ other: Self) {
        formUnion(other, comparisonPolicy: .equal)
    }

    @inlinable
    public mutating func formIntersection(_ other: Self) {
        formIntersection(other, comparisonPolicy: .equal)
    }

    @inlinable
    public mutating func formSymmetricDifference(_ other: Self) {
        formSymmetricDifference(other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func subtracting(_ other: Self) -> Self {
        return subtracting(other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func isSubset(of other: Self) -> Bool {
        return isSubset(of: other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func isDisjoint(with other: Self) -> Bool {
        return isDisjoint(with: other, comparisonPolicy: .equal)
    }

    @discardableResult @inlinable
    public func isSuperset(of other: Self) -> Bool {
        return isSuperset(of: other, comparisonPolicy: .equal)
    }

    @inlinable
    public mutating func subtract(_ other: Self) {
        subtract(other, comparisonPolicy: .equal)
    }
}
