import SwiftUI
import SwiftData

struct ApplianceDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let home: Home
    var room: Room? = nil
    var prefilledCategory: ApplianceCategory? = nil
    var prefilledWattage: Double? = nil
    var prefilledImage: UIImage? = nil
    var detectionMethod: String = "manual"
    var onComplete: (() -> Void)? = nil

    @State private var category: ApplianceCategory = .other
    @State private var name: String = ""
    @State private var wattage: String = ""
    @State private var hoursPerDay: String = ""
    @State private var quantity: Int = 1
    @State private var selectedRoom: Room?
    @State private var showingResult = false
    @State private var savedAppliance: Appliance?

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                detailsSection
                usageSection
                roomSection
                previewSection
            }
            .navigationTitle("Add Appliance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAppliance() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Constants.accentColor)
                }
            }
            .onAppear { applyPrefills() }
            .navigationDestination(isPresented: $showingResult) {
                if let appliance = savedAppliance {
                    ApplianceResultView(appliance: appliance, onComplete: onComplete ?? { dismiss() })
                }
            }
        }
    }

    // MARK: - Sections

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(groupedCategories, id: \.key) { group, categories in
                    Section(group) {
                        ForEach(categories) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: category) { _, newValue in
                if name.isEmpty || name == category.rawValue {
                    name = newValue.rawValue
                }
                if wattage.isEmpty {
                    wattage = String(Int(newValue.defaultWattage))
                }
                if hoursPerDay.isEmpty {
                    hoursPerDay = formatHours(newValue.defaultHoursPerDay)
                }
            }

            if let image = prefilledImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Name", text: $name)

            HStack {
                Text("Wattage")
                Spacer()
                TextField("W", text: $wattage)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("W")
                    .foregroundStyle(.secondary)
            }

            if wattage.isEmpty {
                Text("Default: \(Int(category.defaultWattage))W for \(category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var usageSection: some View {
        Section("Usage") {
            HStack {
                Text("Hours per day")
                Spacer()
                TextField("hrs", text: $hoursPerDay)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("hrs")
                    .foregroundStyle(.secondary)
            }

            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...50)
        }
    }

    private var roomSection: some View {
        Section("Room (Optional)") {
            if home.rooms.isEmpty {
                Text("No rooms added yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Assign to room", selection: $selectedRoom) {
                    Text("None").tag(nil as Room?)
                    ForEach(home.rooms) { r in
                        Text(r.name.isEmpty ? "Unnamed Room" : r.name).tag(r as Room?)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    private var previewSection: some View {
        Section("Energy Preview") {
            let w = Double(wattage) ?? category.defaultWattage
            let h = Double(hoursPerDay) ?? category.defaultHoursPerDay
            let annualKWh = w * h * 365.0 / 1000.0 * Double(quantity)
            let annualCost = annualKWh * Constants.defaultElectricityRate

            HStack {
                Text("Annual Energy")
                Spacer()
                Text("\(Int(annualKWh)) kWh/yr")
                    .font(.subheadline.bold().monospacedDigit())
            }

            HStack {
                Text("Annual Cost")
                Spacer()
                Text("$\(Int(annualCost))/yr")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Constants.accentColor)
            }

            if category.isPhantomLoadRelevant {
                HStack {
                    Text("Standby Power")
                    Spacer()
                    Text("\(Int(category.phantomWatts))W when off")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Helpers

    private var groupedCategories: [(key: String, value: [ApplianceCategory])] {
        let grouped = Dictionary(grouping: ApplianceCategory.allCases, by: \.categoryGroup)
        return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, value: $0.value) }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours == floor(hours) {
            return String(Int(hours))
        }
        return String(format: "%.1f", hours)
    }

    private func applyPrefills() {
        if let cat = prefilledCategory {
            category = cat
            name = cat.rawValue
            wattage = String(Int(cat.defaultWattage))
            hoursPerDay = formatHours(cat.defaultHoursPerDay)
        }
        if let w = prefilledWattage {
            wattage = String(Int(w))
        }
        if let r = room {
            selectedRoom = r
        }
    }

    private func saveAppliance() {
        guard savedAppliance == nil else {
            showingResult = true
            return
        }

        let w = Double(wattage) ?? category.defaultWattage
        let h = Double(hoursPerDay) ?? category.defaultHoursPerDay

        let appliance = Appliance(
            category: category,
            name: name.isEmpty ? category.rawValue : name,
            estimatedWattage: w,
            hoursPerDay: h,
            quantity: quantity,
            detectionMethod: detectionMethod,
            photoData: prefilledImage?.jpegData(compressionQuality: 0.7)
        )

        appliance.home = home
        appliance.room = selectedRoom
        modelContext.insert(appliance)
        home.updatedAt = Date()

        savedAppliance = appliance
        showingResult = true
    }
}
