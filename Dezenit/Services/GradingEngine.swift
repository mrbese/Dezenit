import Foundation

enum EfficiencyGrade: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case f = "F"

    var color: String {
        switch self {
        case .a: return "green"
        case .b: return "blue"
        case .c: return "yellow"
        case .d: return "orange"
        case .f: return "red"
        }
    }

    var summary: String {
        switch self {
        case .a: return "Excellent efficiency. Your home is near best-in-class."
        case .b: return "Good efficiency with some room for improvement."
        case .c: return "Average efficiency. Several upgrades would help."
        case .d: return "Below average. Significant upgrades recommended."
        case .f: return "Poor efficiency. Major upgrades needed for savings."
        }
    }
}

enum GradingEngine {

    static func grade(for equipment: [Equipment]) -> EfficiencyGrade {
        guard !equipment.isEmpty else { return .c }

        let ratio = weightedEfficiencyRatio(for: equipment)
        return gradeFromRatio(ratio)
    }

    static func weightedEfficiencyRatio(for equipment: [Equipment]) -> Double {
        guard !equipment.isEmpty else { return 0.5 }

        var weightedSum: Double = 0
        var totalWeight: Double = 0

        for item in equipment {
            let type = item.typeEnum
            let spec = EfficiencyDatabase.lookup(type: type, age: item.ageRangeEnum)

            let worst = worstCase(for: type)
            let best = spec.bestInClass
            let current = item.estimatedEfficiency > 0 ? item.estimatedEfficiency : spec.estimated

            let ratio: Double
            if type == .windows {
                // U-factor: lower is better, invert the ratio
                let range = worst - best
                ratio = range > 0 ? (worst - current) / range : 0.5
            } else {
                let range = best - worst
                ratio = range > 0 ? (current - worst) / range : 0.5
            }

            let clampedRatio = min(max(ratio, 0), 1)
            let weight = type.energyShareWeight
            weightedSum += clampedRatio * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 0.5 }
        return weightedSum / totalWeight
    }

    static func gradeFromRatio(_ ratio: Double) -> EfficiencyGrade {
        switch ratio {
        case 0.85...1.0: return .a
        case 0.70..<0.85: return .b
        case 0.55..<0.70: return .c
        case 0.40..<0.55: return .d
        default: return .f
        }
    }

    // Worst-case efficiency values for each equipment type
    private static func worstCase(for type: EquipmentType) -> Double {
        switch type {
        case .centralAC:            return 8.0
        case .heatPump:             return 8.0
        case .furnace:              return 60.0
        case .waterHeater:          return 0.45
        case .waterHeaterTankless:  return 0.80
        case .windowUnit:           return 7.0
        case .thermostat:           return 0.0
        case .insulation:           return 5.0
        case .windows:              return 1.2 // worst U-factor (highest = worst)
        case .washer:               return 0.8
        case .dryer:                return 2.0
        }
    }
}
