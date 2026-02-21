import SwiftUI

struct HomeReportView: View {
    let home: Home

    private var grade: EfficiencyGrade {
        GradingEngine.grade(for: home.equipment)
    }

    private var upgrades: [UpgradeItem] {
        home.equipment.compactMap { eq in
            let spec = EfficiencyDatabase.lookup(type: eq.typeEnum, age: eq.ageRangeEnum)
            let savings = EfficiencyDatabase.estimateAnnualSavings(
                type: eq.typeEnum,
                currentEfficiency: eq.estimatedEfficiency,
                targetEfficiency: spec.bestInClass,
                homeSqFt: home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500,
                climateZone: home.climateZoneEnum
            )
            guard savings > 10 else { return nil }
            let payback = EfficiencyDatabase.paybackYears(upgradeCost: spec.upgradeCost, annualSavings: savings)
            return UpgradeItem(
                equipment: eq,
                annualSavings: savings,
                upgradeCost: spec.upgradeCost,
                paybackYears: payback,
                targetEfficiency: spec.bestInClass
            )
        }.sorted { ($0.paybackYears ?? 999) < ($1.paybackYears ?? 999) }
    }

    private var totalCurrentCost: Double {
        home.equipment.reduce(0) { sum, eq in
            sum + EfficiencyDatabase.estimateAnnualCost(
                type: eq.typeEnum,
                efficiency: eq.estimatedEfficiency,
                homeSqFt: home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500,
                climateZone: home.climateZoneEnum
            )
        }
    }

    private var totalUpgradedCost: Double {
        home.equipment.reduce(0) { sum, eq in
            let spec = EfficiencyDatabase.lookup(type: eq.typeEnum, age: eq.ageRangeEnum)
            return sum + EfficiencyDatabase.estimateAnnualCost(
                type: eq.typeEnum,
                efficiency: spec.bestInClass,
                homeSqFt: home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500,
                climateZone: home.climateZoneEnum
            )
        }
    }

    private var totalSavings: Double {
        max(totalCurrentCost - totalUpgradedCost, 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summarySection
                if !home.equipment.isEmpty {
                    costSection
                }
                if !upgrades.isEmpty {
                    upgradesSection
                }
                batterySynergySection
                shareSection
            }
            .padding()
        }
        .navigationTitle("Home Report")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(home.name.isEmpty ? "Home Assessment" : home.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    if home.computedTotalSqFt > 0 {
                        Text("\(Int(home.computedTotalSqFt)) sq ft")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(grade.rawValue)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Grade")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Divider().background(.white.opacity(0.3))

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(home.rooms.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Rooms")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                VStack(spacing: 2) {
                    Text("\(home.equipment.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Equipment")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                if home.totalBTU > 0 {
                    VStack(spacing: 2) {
                        Text("\(Int(home.totalBTU / 12000))")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Tons HVAC")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            Text(grade.summary)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Constants.accentColor, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Cost

    private var costSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy Cost Estimate")
                .font(.headline)

            HStack {
                Text("Current Annual Cost")
                    .font(.subheadline)
                Spacer()
                Text("$\(Int(totalCurrentCost).formatted())/yr")
                    .font(.title3.bold())
            }

            if totalSavings > 0 {
                HStack {
                    Text("After All Upgrades")
                        .font(.subheadline)
                    Spacer()
                    Text("$\(Int(totalUpgradedCost).formatted())/yr")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }

                Divider()

                HStack {
                    Text("Potential Annual Savings")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("$\(Int(totalSavings).formatted())/yr")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Upgrades

    private var upgradesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prioritized Upgrades")
                .font(.headline)

            Text("Sorted by payback period (shortest first)")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(upgrades) { item in
                upgradeRow(item)
            }
        }
    }

    private func upgradeRow(_ item: UpgradeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.equipment.typeEnum.icon)
                    .foregroundStyle(Constants.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.equipment.typeEnum.rawValue)
                        .font(.subheadline.bold())
                    Text("Current: \(String(format: "%.1f", item.equipment.estimatedEfficiency)) \(item.equipment.typeEnum.efficiencyUnit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let pb = item.paybackYears {
                    priorityBadge(payback: pb)
                }
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Savings")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("$\(Int(item.annualSavings))/yr")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Cost")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("$\(Int(item.upgradeCost).formatted())")
                        .font(.caption.bold())
                }
                if let pb = item.paybackYears {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Payback")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f yr", pb))
                            .font(.caption.bold())
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", item.targetEfficiency)) \(item.equipment.typeEnum.efficiencyUnit)")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func priorityBadge(payback: Double) -> some View {
        let (label, color): (String, Color) = {
            if payback < 3 { return ("Quick Win", .green) }
            if payback < 7 { return ("Strong Investment", .orange) }
            return ("Long Term", .secondary)
        }()

        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Battery Synergy

    private var batterySynergySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "battery.100.bolt")
                    .foregroundStyle(Constants.accentColor)
                Text("Battery Synergy")
                    .font(.headline)
            }

            let sqFt = home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500
            let currentBaseLoad = sqFt * 5.0 / 1500.0 // ~5kW for 1500 sq ft baseline
            let savingsRatio = totalSavings > 0 ? totalSavings / max(totalCurrentCost, 1) : 0.15
            let upgradedBaseLoad = currentBaseLoad * (1.0 - savingsRatio * 0.6)
            let exportGain = currentBaseLoad - upgradedBaseLoad

            VStack(alignment: .leading, spacing: 8) {
                infoRow("Current estimated base load", "\(String(format: "%.1f", currentBaseLoad)) kW")
                infoRow("Estimated base load after upgrades", "\(String(format: "%.1f", upgradedBaseLoad)) kW")
                infoRow("Additional battery export capacity", "\(String(format: "%.1f", exportGain)) kW")

                let lowRevenue = Int(exportGain * 50) // ~50 hours at $2/kWh
                let highRevenue = Int(exportGain * 250) // ~50 hours at $5/kWh
                if lowRevenue > 0 {
                    infoRow("Additional grid export revenue", "$\(lowRevenue) to $\(highRevenue)/yr per battery")
                }
            }

            Text("Reducing your home's energy waste frees up more battery capacity for grid export during high-demand events when electricity prices spike to $2,000-$5,000/MWh. This makes home battery systems (Pila Energy, Tesla Powerwall, Base Power) significantly more valuable.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    // MARK: - Share

    private var shareSection: some View {
        VStack(spacing: 12) {
            ShareLink(item: generateReportText()) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Report")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Constants.accentColor, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
        }
    }

    private func generateReportText() -> String {
        var parts: [String] = []
        parts.append("DEZENIT HOME ENERGY REPORT")
        parts.append("=".repeated(40))
        parts.append("")
        parts.append("Home: \(home.name)")
        if let addr = home.address { parts.append("Address: \(addr)") }
        if home.computedTotalSqFt > 0 { parts.append("Total Area: \(Int(home.computedTotalSqFt)) sq ft") }
        parts.append("Climate Zone: \(home.climateZoneEnum.rawValue)")
        parts.append("Efficiency Grade: \(grade.rawValue)")
        parts.append("")

        if !home.equipment.isEmpty {
            parts.append("ENERGY COST ESTIMATE")
            parts.append("-".repeated(30))
            parts.append("Current Annual Cost: $\(Int(totalCurrentCost))")
            parts.append("After Upgrades: $\(Int(totalUpgradedCost))")
            parts.append("Potential Savings: $\(Int(totalSavings))/yr")
            parts.append("")
        }

        if !upgrades.isEmpty {
            parts.append("PRIORITIZED UPGRADES")
            parts.append("-".repeated(30))
            for item in upgrades {
                let pb = item.paybackYears.map { String(format: "%.1f yr payback", $0) } ?? "N/A"
                parts.append("- \(item.equipment.typeEnum.rawValue): $\(Int(item.annualSavings))/yr savings, $\(Int(item.upgradeCost)) cost, \(pb)")
            }
            parts.append("")
        }

        parts.append("Generated by Dezenit | dezenit.com | Built by Omer Bese")
        return parts.joined(separator: "\n")
    }
}

// MARK: - Models

private struct UpgradeItem: Identifiable {
    let id = UUID()
    let equipment: Equipment
    let annualSavings: Double
    let upgradeCost: Double
    let paybackYears: Double?
    let targetEfficiency: Double
}

// MARK: - String helper

private extension String {
    func repeated(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}
