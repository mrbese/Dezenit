import SwiftUI

struct EquipmentResultView: View {
    let equipment: Equipment
    let home: Home

    private var spec: EfficiencySpec {
        EfficiencyDatabase.lookup(type: equipment.typeEnum, age: equipment.ageRangeEnum)
    }

    private var upgrades: [UpgradeRecommendation] {
        UpgradeEngine.generateUpgrades(
            for: equipment,
            climateZone: home.climateZoneEnum,
            homeSqFt: home.computedTotalSqFt > 0 ? home.computedTotalSqFt : 1500
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroCard
                efficiencyComparisonCard
                if !upgrades.isEmpty {
                    upgradeOptionsSection
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

    // MARK: - Upgrade Options

    private var upgradeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upgrade Options")
                .font(.headline)

            Text("Good \u{2192} Better \u{2192} Best")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(upgrades) { rec in
                upgradeRecommendationCard(rec)
            }
        }
    }

    private func upgradeRecommendationCard(_ rec: UpgradeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Tier badge + title
            HStack(spacing: 8) {
                tierBadge(rec.tier)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.title)
                        .font(.subheadline.bold())
                    Text(rec.upgradeTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if rec.alreadyMeetsThisTier {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Your current equipment meets this tier")
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }

            // Cost range
            HStack {
                Text("Estimated Cost")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("$\(Int(rec.costLow).formatted()) – $\(Int(rec.costHigh).formatted())")
                    .font(.subheadline.bold())
            }

            // Annual savings
            if rec.annualSavings > 0 {
                HStack {
                    Text("Annual Savings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(Int(rec.annualSavings))/yr")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }

                // Payback
                if let pb = rec.paybackYears {
                    HStack {
                        Text("Simple Payback")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f years", pb))
                            .font(.caption.bold())
                            .foregroundStyle(pb < 3 ? .green : pb < 7 ? .orange : .secondary)
                    }
                }
            }

            // Tax credit
            if rec.taxCreditEligible && rec.taxCreditAmount > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Tax Credit: $\(Int(rec.taxCreditAmount))")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Spacer()
                    if let epb = rec.effectivePaybackYears, let pb = rec.paybackYears, epb < pb {
                        Text("Effective payback: \(String(format: "%.1f yr", epb))")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(8)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            // Technology note
            if let note = rec.technologyNote {
                DisclosureGroup {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } label: {
                    Text("Technology Details")
                        .font(.caption)
                        .foregroundStyle(Constants.accentColor)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func tierBadge(_ tier: UpgradeTier) -> some View {
        let (label, color): (String, Color) = {
            switch tier {
            case .good: return ("Good", .blue)
            case .better: return ("Better", .orange)
            case .best: return ("Best", .green)
            }
        }()

        return Text(label)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private func barColor(ratio: Double) -> Color {
        if ratio >= 0.7 { return .green }
        if ratio >= 0.4 { return .orange }
        return .red
    }
}
