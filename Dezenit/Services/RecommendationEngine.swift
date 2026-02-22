import Foundation

struct Recommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let estimatedSavings: String?
}

enum RecommendationEngine {
    static func generate(
        squareFootage: Double,
        ceilingHeight: CeilingHeightOption,
        insulation: InsulationQuality,
        windows: [WindowInfo],
        breakdown: BTUBreakdown
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        // South/west window solar gain + not good insulation → low-e film
        let highGainWindows = windows.filter { $0.direction == .south || $0.direction == .west }
        if !highGainWindows.isEmpty && insulation != .good {
            let highGainBTU = highGainWindows.reduce(0) { $0 + $1.heatGainBTU }
            let savingsBTU = Int(highGainBTU * 0.275) // midpoint of 25-30%
            recommendations.append(Recommendation(
                icon: "sun.max",
                title: "Low-E Window Film",
                detail: "Your \(highGainWindows.count) south/west-facing window(s) contribute ~\(Int(highGainBTU).formatted()) BTU of solar heat gain. Low-emissivity window film can reduce this by 25–30%.",
                estimatedSavings: "Save ~\(savingsBTU.formatted()) BTU/hr peak load"
            ))
        }

        // Poor insulation → attic upgrade
        if insulation == .poor {
            recommendations.append(Recommendation(
                icon: "house.and.flag",
                title: "Upgrade to R-49 Attic Insulation",
                detail: "Poor insulation adds a 30% BTU penalty to your load. Upgrading attic insulation to R-49 can reduce peak HVAC load by 1.0–1.5 kW and dramatically improve envelope efficiency.",
                estimatedSavings: "1.0–1.5 kW peak load reduction"
            ))
        }

        // Excessive glazing (total window area > 30% of floor)
        let totalWindowArea = windows.reduce(0) { $0 + $1.size.sqFt }
        if totalWindowArea > squareFootage * 0.30 {
            recommendations.append(Recommendation(
                icon: "window.casement",
                title: "Reduce Thermal Glazing Exposure",
                detail: "Your window area (\(Int(totalWindowArea)) sq ft) exceeds 30% of your floor area (\(Int(squareFootage)) sq ft). Thermal cellular shades or insulated curtains can significantly cut heat gain/loss at the glass.",
                estimatedSavings: "10–20% reduction in window-related load"
            ))
        }

        // Ceiling height > 10ft → ceiling fans
        if ceilingHeight.feet > 10 {
            recommendations.append(Recommendation(
                icon: "fan",
                title: "Install Ceiling Fans for Destratification",
                detail: "At \(ceilingHeight.feet) ft ceiling height, hot air stratifies heavily. Ceiling fans in winter (reverse/clockwise at low speed) push warm air back down, reducing thermostat demand by 2–3°F.",
                estimatedSavings: "5–10% heating season savings"
            ))
        }

        // Always include duct sealing
        recommendations.append(Recommendation(
            icon: "arrow.triangle.branch",
            title: "Aerosol Duct Sealing",
            detail: "Leaky ductwork (industry average: 20–30% loss) undermines HVAC efficiency. Aerosol duct sealing to <4% leakage rate can recover 15–20% of lost conditioned air.",
            estimatedSavings: "15–20% conditioned air recovered"
        ))

        return recommendations
    }

    // MARK: - Home-Level Recommendations

    static func generateHomeRecommendations(for home: Home) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        let rate = home.actualElectricityRate

        // --- Envelope-based ---
        if let env = home.envelope {
            if env.atticInsulation == .poor {
                recommendations.append(Recommendation(
                    icon: "house.and.flag",
                    title: "Upgrade Attic Insulation",
                    detail: "Your attic insulation is rated Poor. Upgrading to R-49 can reduce heating/cooling costs by 15–25% and improve comfort year-round.",
                    estimatedSavings: "15–25% HVAC savings"
                ))
            }
            if env.airSealing == "Poor" {
                recommendations.append(Recommendation(
                    icon: "wind",
                    title: "Professional Air Sealing",
                    detail: "Poor air sealing allows conditioned air to escape through gaps around pipes, wiring, and ductwork. Professional sealing typically costs $350–$700 and pays back in 1–2 years.",
                    estimatedSavings: "$150–$300/yr"
                ))
            }
            if env.weatherstripping == "Poor" {
                recommendations.append(Recommendation(
                    icon: "door.left.hand.open",
                    title: "Replace Weatherstripping",
                    detail: "Worn weatherstripping around doors and windows lets drafts in. Replacement is a low-cost DIY project ($20–$50 per door) with immediate comfort improvement.",
                    estimatedSavings: "$50–$100/yr"
                ))
            }
        }

        // --- Appliance-based ---
        let incandescents = home.appliances.filter { $0.categoryEnum == .incandescentBulb }
        let totalIncandescentQty = incandescents.reduce(0) { $0 + $1.quantity }
        if totalIncandescentQty > 0 {
            // Calculate savings: incandescent ~60W → LED ~9W, delta = 51W per bulb
            let avgHours = incandescents.isEmpty ? 5.0 : incandescents.reduce(0.0) { $0 + $1.hoursPerDay } / Double(incandescents.count)
            let annualSavings = Double(totalIncandescentQty) * 0.051 * avgHours * 365 * rate
            recommendations.append(Recommendation(
                icon: "lightbulb.led",
                title: "Switch \(totalIncandescentQty) Incandescent Bulb\(totalIncandescentQty == 1 ? "" : "s") to LED",
                detail: "LED bulbs use ~85% less energy and last 15–25x longer. Switching \(totalIncandescentQty) incandescent bulb\(totalIncandescentQty == 1 ? "" : "s") saves energy immediately with no comfort trade-off.",
                estimatedSavings: "$\(Int(annualSavings))/yr"
            ))
        }

        let phantomKWh = home.totalPhantomAnnualKWh
        if phantomKWh > 100 {
            let phantomCost = phantomKWh * rate
            let savingsWithStrip = phantomCost * Constants.PhantomLoads.smartPowerStripSavings
            recommendations.append(Recommendation(
                icon: "powerplug",
                title: "Smart Power Strips for Phantom Loads",
                detail: "Your devices waste ~\(Int(phantomKWh)) kWh/yr ($\(Int(phantomCost))) on standby power. Smart power strips cut phantom loads by up to 75% by automatically disconnecting idle devices.",
                estimatedSavings: "$\(Int(savingsWithStrip))/yr"
            ))
        }

        // --- Behavioral ---
        recommendations.append(Recommendation(
            icon: "thermometer.and.target",
            title: "Thermostat Setback Schedule",
            detail: "Setting your thermostat back 7–10°F for 8 hours/day (while sleeping or away) can save up to 10% on heating and cooling annually — no equipment purchase needed.",
            estimatedSavings: "Up to 10% HVAC savings"
        ))

        if let billKWh = home.billBasedAnnualKWh, billKWh > 8000 {
            recommendations.append(Recommendation(
                icon: "clock.arrow.2.circlepath",
                title: "Shift Usage to Off-Peak Hours",
                detail: "With annual usage around \(Int(billKWh)) kWh, shifting laundry, dishwasher, and EV charging to off-peak hours (typically 9pm–6am) can reduce costs if your utility offers time-of-use rates.",
                estimatedSavings: "5–15% bill reduction"
            ))
        }

        return recommendations
    }
}
