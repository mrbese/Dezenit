import SwiftUI

struct EnvelopeAssessmentView: View {
    @Bindable var home: Home
    var onComplete: () -> Void

    @State private var info: EnvelopeInfo
    @State private var step = 0
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 3

    init(home: Home, onComplete: @escaping () -> Void) {
        self.home = home
        self.onComplete = onComplete
        self._info = State(initialValue: home.envelope ?? EnvelopeInfo())
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            TabView(selection: $step) {
                insulationStep.tag(0)
                foundationStep.tag(1)
                summaryStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            navigationButtons
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Color.manor.primary : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Step 1: Insulation

    private var insulationStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepHeader(
                    title: "Insulation Assessment",
                    subtitle: "How well insulated is your home? Think about drafts in winter and heat in summer."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Attic Insulation")
                        .font(.subheadline.bold())
                    ForEach(InsulationQuality.allCases) { quality in
                        selectionCard(
                            selected: info.atticInsulation == quality,
                            title: quality.rawValue,
                            detail: quality.description
                        ) {
                            info.atticInsulation = quality
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Wall Insulation")
                        .font(.subheadline.bold())
                    ForEach(InsulationQuality.allCases) { quality in
                        selectionCard(
                            selected: info.wallInsulation == quality,
                            title: quality.rawValue,
                            detail: quality.description
                        ) {
                            info.wallInsulation = quality
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Step 2: Foundation & Air Sealing

    private var foundationStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepHeader(
                    title: "Foundation & Air Sealing",
                    subtitle: "Air leaks are a major source of energy waste. Check around doors, windows, and the basement."
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Basement / Crawlspace Insulation")
                        .font(.subheadline.bold())
                    ForEach(EnvelopeInfo.basementOptions, id: \.self) { option in
                        selectionCard(
                            selected: info.basementInsulation == option,
                            title: option,
                            detail: basementDetail(option)
                        ) {
                            info.basementInsulation = option
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Air Sealing")
                        .font(.subheadline.bold())
                    ForEach(EnvelopeInfo.sealingOptions, id: \.self) { option in
                        selectionCard(
                            selected: info.airSealing == option,
                            title: option,
                            detail: airSealingDetail(option)
                        ) {
                            info.airSealing = option
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Weatherstripping")
                        .font(.subheadline.bold())
                    ForEach(EnvelopeInfo.sealingOptions, id: \.self) { option in
                        selectionCard(
                            selected: info.weatherstripping == option,
                            title: option,
                            detail: weatherstripDetail(option)
                        ) {
                            info.weatherstripping = option
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Step 3: Summary

    private var summaryStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepHeader(
                    title: "Summary",
                    subtitle: "Review your building envelope assessment. Add any notes below."
                )

                VStack(spacing: 12) {
                    summaryRow(label: "Attic Insulation", value: info.atticInsulation.rawValue)
                    summaryRow(label: "Wall Insulation", value: info.wallInsulation.rawValue)
                    summaryRow(label: "Basement", value: info.basementInsulation)
                    summaryRow(label: "Air Sealing", value: info.airSealing)
                    summaryRow(label: "Weatherstripping", value: info.weatherstripping)
                }
                .padding(16)
                .background(Color.manor.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (optional)")
                        .font(.subheadline.bold())
                    TextField("Any observations about your home's envelope...", text: Binding(
                        get: { info.notes ?? "" },
                        set: { info.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
                }
            }
            .padding(20)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack {
            if step > 0 {
                Button {
                    withAnimation { step -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if step < totalSteps - 1 {
                Button {
                    withAnimation { step += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color.manor.onPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.manor.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    home.envelope = info
                    onComplete()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Save")
                    }
                    .foregroundStyle(Color.manor.onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.manor.primary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Shared Components

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectionCard(selected: Bool, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.manor.primary)
                }
            }
            .padding(14)
            .background(
                selected ? Color.manor.primary.opacity(0.08) : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.manor.primary : Color.gray.opacity(0.2), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Strings

    private func basementDetail(_ option: String) -> String {
        switch option {
        case "Uninsulated": return "No insulation in basement or crawlspace walls"
        case "Partial": return "Some areas insulated, others exposed"
        case "Full": return "Fully insulated basement/crawlspace walls and rim joists"
        default: return ""
        }
    }

    private func airSealingDetail(_ option: String) -> String {
        switch option {
        case "Good": return "No noticeable drafts, caulking intact around penetrations"
        case "Fair": return "Some drafts around outlets, pipes, or recessed lights"
        case "Poor": return "Significant drafts, visible gaps around doors/windows/pipes"
        default: return ""
        }
    }

    private func weatherstripDetail(_ option: String) -> String {
        switch option {
        case "Good": return "Doors and windows seal tightly, weatherstrip intact"
        case "Fair": return "Some gaps visible, weatherstrip worn in places"
        case "Poor": return "Missing or damaged weatherstrip, daylight visible around doors"
        default: return ""
        }
    }
}
