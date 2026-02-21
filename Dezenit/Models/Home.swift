import Foundation
import SwiftData

enum YearRange: String, CaseIterable, Codable, Identifiable {
    case pre1970 = "Pre-1970"
    case y1970to1989 = "1970 to 1989"
    case y1990to2005 = "1990 to 2005"
    case y2006to2015 = "2006 to 2015"
    case y2016plus = "2016+"

    var id: String { rawValue }
}

@Model
final class Home {
    var id: UUID
    var name: String
    var address: String?
    var yearBuilt: String // YearRange.rawValue
    var totalSqFt: Double?
    var climateZone: String // ClimateZone.rawValue
    @Relationship(deleteRule: .cascade) var rooms: [Room]
    @Relationship(deleteRule: .cascade) var equipment: [Equipment]
    var createdAt: Date
    var updatedAt: Date

    init(
        name: String = "",
        address: String? = nil,
        yearBuilt: YearRange = .y1990to2005,
        totalSqFt: Double? = nil,
        climateZone: ClimateZone = .moderate
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.yearBuilt = yearBuilt.rawValue
        self.totalSqFt = totalSqFt
        self.climateZone = climateZone.rawValue
        self.rooms = []
        self.equipment = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var yearBuiltEnum: YearRange {
        YearRange(rawValue: yearBuilt) ?? .y1990to2005
    }

    var climateZoneEnum: ClimateZone {
        ClimateZone(rawValue: climateZone) ?? .moderate
    }

    var computedTotalSqFt: Double {
        if let manual = totalSqFt, manual > 0 { return manual }
        return rooms.reduce(0) { $0 + $1.squareFootage }
    }

    var totalBTU: Double {
        rooms.reduce(0) { $0 + $1.calculatedBTU }
    }
}
