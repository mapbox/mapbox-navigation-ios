import Foundation
import Turf

/// Information about toll payment method.
public struct TollPaymentMethod: Hashable, Equatable, Sendable {
    /// Method identifier.
    public let identifier: String

    /// Payment is done by electronic toll collection.
    public static let electronicTollCollection = TollPaymentMethod(identifier: "etc")
    /// Payment is done by cash.
    public static let cash = TollPaymentMethod(identifier: "cash")
}

/// Categories by which toll fees are divided.
public struct TollCategory: Hashable, Equatable, Sendable {
    /// Category name.
    public let name: String

    /// A small sized vehicle.
    ///
    /// In Japan, this is a [standard vehicle size](https://en.wikipedia.org/wiki/Expressways_of_Japan#Tolls).
    public static let small = TollCategory(name: "small")
    /// A standard sized vehicle.
    ///
    /// In Japan, this is a [standard vehicle size](https://en.wikipedia.org/wiki/Expressways_of_Japan#Tolls).
    public static let standard = TollCategory(name: "standard")
    /// A middle sized vehicle.
    ///
    /// In Japan, this is a [standard vehicle size](https://en.wikipedia.org/wiki/Expressways_of_Japan#Tolls).
    public static let middle = TollCategory(name: "middle")
    /// A large sized vehicle.
    ///
    /// In Japan, this is a [standard vehicle size](https://en.wikipedia.org/wiki/Expressways_of_Japan#Tolls).
    public static let large = TollCategory(name: "large")
    /// A jumbo sized vehicle.
    ///
    /// In Japan, this is a [standard vehicle size](https://en.wikipedia.org/wiki/Expressways_of_Japan#Tolls).
    public static let jumbo = TollCategory(name: "jumbo")
}

/// Toll cost information for the ``Route``.
public struct TollPrice: Equatable, Hashable, ForeignMemberContainer, Sendable {
    public var foreignMembers: Turf.JSONObject = [:]

    /// Related currency code string.
    ///
    /// Uses ISO 4217 format. Refers to ``amount`` value.
    /// This value is compatible with `NumberFormatter().currencyCode`.
    public let currencyCode: String
    /// Information about toll payment.
    public let paymentMethod: TollPaymentMethod
    /// Toll category information.
    public let category: TollCategory
    /// The actual toll price in ``currencyCode`` currency.
    ///
    /// A toll cost of `0` is valid and simply means that no toll costs are incurred for this route.
    public let amount: Decimal

    init(currencyCode: String, paymentMethod: TollPaymentMethod, category: TollCategory, amount: Decimal) {
        self.currencyCode = currencyCode
        self.paymentMethod = paymentMethod
        self.category = category
        self.amount = amount
    }
}

struct TollPriceCoder: Codable, Sendable {
    let tollPrices: [TollPrice]

    init(tollPrices: [TollPrice]) {
        self.tollPrices = tollPrices
    }

    private class TollPriceItem: Codable, ForeignMemberContainerClass {
        var foreignMembers: Turf.JSONObject = [:]

        private enum CodingKeys: String, CodingKey, CaseIterable {
            case currency
            case paymentMethods = "payment_methods"
        }

        var currencyCode: String
        var paymentMethods: [String: [String: Decimal]] = [:]

        init(currencyCode: String) {
            self.currencyCode = currencyCode
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.currencyCode = try container.decode(String.self, forKey: .currency)
            self.paymentMethods = try container.decode([String: [String: Decimal]].self, forKey: .paymentMethods)

            try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(currencyCode, forKey: .currency)
            try container.encode(paymentMethods, forKey: .paymentMethods)

            try encodeForeignMembers(to: encoder)
        }
    }

    init(from decoder: Decoder) throws {
        let item = try TollPriceItem(from: decoder)

        var tollPrices = [TollPrice]()
        for method in item.paymentMethods {
            for category in method.value {
                var newItem = TollPrice(
                    currencyCode: item.currencyCode,
                    paymentMethod: TollPaymentMethod(identifier: method.key),
                    category: TollCategory(name: category.key),
                    amount: category.value
                )
                newItem.foreignMembers = item.foreignMembers
                tollPrices.append(newItem)
            }
        }
        self.tollPrices = tollPrices
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        var items: [TollPriceItem] = []

        for price in tollPrices {
            var item: TollPriceItem
            if let existingItem = items.first(where: { $0.currencyCode == price.currencyCode }) {
                item = existingItem
            } else {
                item = TollPriceItem(currencyCode: price.currencyCode)
                item.foreignMembers = price.foreignMembers
                items.append(item)
            }
            if item.paymentMethods[price.paymentMethod.identifier] == nil {
                item.paymentMethods[price.paymentMethod.identifier] = [:]
            }
            item.paymentMethods[price.paymentMethod.identifier]?[price.category.name] = price.amount
        }

        try container.encode(contentsOf: items)
    }
}
