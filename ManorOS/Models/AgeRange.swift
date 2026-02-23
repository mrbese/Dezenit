import Foundation

enum AgeRange: String, Codable, CaseIterable, Identifiable {
    case years0to5 = "0 to 5 years"
    case years5to10 = "5 to 10 years"
    case years10to15 = "10 to 15 years"
    case years15to20 = "15 to 20 years"
    case years20plus = "20+ years"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .years0to5: return "< 5 yr"
        case .years5to10: return "5-10 yr"
        case .years10to15: return "10-15 yr"
        case .years15to20: return "15-20 yr"
        case .years20plus: return "20+ yr"
        }
    }
}
