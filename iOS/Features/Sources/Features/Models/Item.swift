import Foundation

// MARK: - Supporting enums

public enum ItemLocation: String, Codable, CaseIterable, Equatable, Sendable {
    case fridge
    case pantry
    case freezer
    case custom

    public var displayName: String {
        switch self {
        case .fridge:  return "Fridge"
        case .pantry:  return "Pantry"
        case .freezer: return "Freezer"
        case .custom:  return "Custom"
        }
    }

    public var systemImage: String {
        switch self {
        case .fridge:  return "refrigerator"
        case .pantry:  return "cabinet"
        case .freezer: return "snowflake"
        case .custom:  return "ellipsis.circle"
        }
    }
}

public enum Freshness: Equatable, Sendable {
    case fresh
    case expiring
    case expired
}

// MARK: - Item

public struct Item: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var quantity: String?
    public var location: ItemLocation
    public var locationCustom: String?
    public var bestBeforeDate: Date
    public var addedDate: Date
    public var remindDaysBefore: Int
    public var remindOnDay: Bool
    public var isUsed: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: String? = nil,
        location: ItemLocation = .fridge,
        locationCustom: String? = nil,
        bestBeforeDate: Date,
        addedDate: Date = Date(),
        remindDaysBefore: Int = 3,
        remindOnDay: Bool = false,
        isUsed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.location = location
        self.locationCustom = locationCustom
        self.bestBeforeDate = bestBeforeDate
        self.addedDate = addedDate
        self.remindDaysBefore = remindDaysBefore
        self.remindOnDay = remindOnDay
        self.isUsed = isUsed
    }

    // MARK: - Computed

    public var daysLeft: Int {
        Calendar.current.dateComponents([.day], from: .now, to: bestBeforeDate).day ?? 0
    }

    public var remindOn: Date {
        Calendar.current.date(byAdding: .day, value: -remindDaysBefore, to: bestBeforeDate) ?? bestBeforeDate
    }

    public var freshness: Freshness {
        if daysLeft < 0 { return .expired }
        if daysLeft <= remindDaysBefore { return .expiring }
        return .fresh
    }

    public var locationLabel: String {
        location == .custom ? (locationCustom ?? location.displayName) : location.displayName
    }
}

// MARK: - ItemIn (API request body)

public struct ItemIn: Codable, Equatable, Sendable {
    public var name: String
    public var quantity: String?
    public var location: ItemLocation
    public var locationCustom: String?
    public var bestBeforeDate: Date
    public var remindDaysBefore: Int
    public var remindOnDay: Bool

    public init(
        name: String,
        quantity: String? = nil,
        location: ItemLocation = .fridge,
        locationCustom: String? = nil,
        bestBeforeDate: Date,
        remindDaysBefore: Int = 3,
        remindOnDay: Bool = false
    ) {
        self.name = name
        self.quantity = quantity
        self.location = location
        self.locationCustom = locationCustom
        self.bestBeforeDate = bestBeforeDate
        self.remindDaysBefore = remindDaysBefore
        self.remindOnDay = remindOnDay
    }
}
