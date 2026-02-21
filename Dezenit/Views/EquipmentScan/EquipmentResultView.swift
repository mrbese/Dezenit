import SwiftUI

struct EquipmentResultView: View {
    let equipment: Equipment
    let home: Home

    private var spec: EfficiencySpec {
        EfficiencyDatabase.lookup(type: equipment.typeEnum, age: equipment.ageRangeEnum)
    }

    private var annualSavings: Double {
        EfficiencyDatabase.estimateAnnualSavings(
            type: equipment.typeEnum,
            currentEfficiency: equipment.estimatedEfficiency,
            targetEfficiency: spec.bestInClass,
            homeSqFt: home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500,
            climateZone: home.climateZoneEnum
        )
    }

    private var payback: Double? {
        EfficiencyDatabase.paybackYears(upgradeCost: spec.upgradeCost, annualSavings: annualSavings)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                efficiencyComparisonCard
                if annualSavings > 0 {
                    upgradeCard
                }
            }
            .padding()
        }
        .navigationTitle(equipment.typeEnum.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 12) {
            Image(systemName: equipment.typeEnum.icon)
                .font(.system(size: 40))
                .foregroundStyle(.white)

            Text(equipment.typeEnum.rawValue)
                .font(.title2.bold())
                .foregroundStyle(.white)

            if let mfr = equipment.manufacturer {
                Text(mfr)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", equipment.estimatedEfficiency))
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Current \(equipment.typeEnum.efficiencyUnit)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                VStack(spacing: 2) {
                    Text(equipment.ageRangeEnum.shortLabel)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("Age")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Constants.accentColor, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Comparison

    private var efficiencyComparisonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Efficiency Comparison")
                .font(.headline)

            comparisonRow(label: "Your Equipment", value: equipment.estimatedEfficiency, unit: equipment.typeEnum.efficiencyUnit, highlight: false)
            comparisonRow(label: "Current Code Minimum", value: equipment.currentCodeMinimum, unit: equipment.typeEnum.efficiencyUnit, highlight: false)
            comparisonRow(label: "Best in Class", value: equipment.bestInClass, unit: equipment.typeEnum.efficiencyUnit, highlight: true)

            // Efficiency bar
            let ratio = GradingEngine.weightedEfficiencyRatio(for: [equipment])
            VStack(alignment: .leading, spacing: 4) {
                Text("Efficiency Rating")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.2))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(ratio: ratio))
                            .frame(width: geo.size.width * ratio, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func comparisonRow(label: String, value: Double, unit: String, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(highlight ? .green : .primary)
            Spacer()
            Text("\(String(format: "%.1f", value)) \(unit)")
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(highlight ? .green : .primary)
        }
    }

    // MARK: - Upgrade

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upgrade Recommendation")
                .font(.headline)

            HStack {
                Text("Estimated Annual Savings")
                    .font(.subheadline)
                Spacer()
                Text("$\(Int(annualSavings))/yr")
                    .font(.title3.bold())
                    .foregroundStyle(.green)
            }

            HStack {
                Text("Estimated Upgrade Cost")
                    .font(.subheadline)
                Spacer()
                Text("$\(Int(spec.upgradeCost).formatted())")
                    .font(.subheadline)
            }

            if let pb = payback {
                HStack {
                    Text("Simple Payback")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f years", pb))
                        .font(.subheadline.bold())
                        .foregroundStyle(pb < 3 ? .green : pb < 7 ? .orange : .secondary)
                }

                priorityBadge(payback: pb)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func priorityBadge(payback: Double) -> some View {
        let (label, color): (String, Color) = {
            if payback < 3 { return ("Quick Win", .green) }
            if payback < 7 { return ("Strong Investment", .orange) }
            return ("Long Term", .secondary)
        }()

        return HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(label)
                .font(.caption.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12), in: Capsule())
    }

    private func barColor(ratio: Double) -> Color {
        if ratio >= 0.7 { return .green }
        if ratio >= 0.4 { return .orange }
        return .red
    }
}
