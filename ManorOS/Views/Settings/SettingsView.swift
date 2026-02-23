import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var home: Home
    @Environment(\.modelContext) private var modelContext

    // Profile
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""

    // Energy Rates
    @AppStorage("electricityRate") private var electricityRate: Double = Constants.defaultElectricityRate
    @AppStorage("gasRate") private var gasRate: Double = Constants.defaultGasRate

    // Notifications
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    // Onboarding
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // Home details editing state
    @State private var sqFtText: String = ""
    @State private var electricityRateText: String = ""
    @State private var gasRateText: String = ""

    var body: some View {
        Form {
            profileSection
            homeDetailsSection
            energyRatesSection
            notificationsSection
            aboutSection
            dangerZoneSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            sqFtText = home.totalSqFt.map { String(Int($0)) } ?? ""
            electricityRateText = String(format: "%.3f", electricityRate)
            gasRateText = String(format: "%.2f", gasRate)
        }
    }

    // MARK: - Profile

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $userName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Email")
                Spacer()
                TextField("your@email.com", text: $userEmail)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
    }

    // MARK: - Home Details

    private var homeDetailsSection: some View {
        Section("Home Details") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Home name", text: $home.name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Address")
                Spacer()
                TextField("Address", text: Binding(
                    get: { home.address ?? "" },
                    set: { home.address = $0.isEmpty ? nil : $0 }
                ))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
                .textContentType(.fullStreetAddress)
            }

            Picker("Home Type", selection: Binding(
                get: { home.homeTypeEnum ?? .house },
                set: { home.homeType = $0.rawValue }
            )) {
                ForEach(HomeType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            Stepper("Bedrooms: \(home.bedroomCount ?? 2)", value: Binding(
                get: { home.bedroomCount ?? 2 },
                set: { home.bedroomCount = $0 }
            ), in: 0...20)

            Picker("Year Built", selection: Binding(
                get: { home.yearBuiltEnum },
                set: { home.yearBuilt = $0.rawValue }
            )) {
                ForEach(YearRange.allCases) { yr in
                    Text(yr.rawValue).tag(yr)
                }
            }

            HStack {
                Text("Total Sq Ft")
                Spacer()
                TextField("optional", text: $sqFtText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .onChange(of: sqFtText) { _, newValue in
                        home.totalSqFt = Double(newValue)
                    }
            }

            Picker("Climate Zone", selection: Binding(
                get: { home.climateZoneEnum },
                set: { home.climateZone = $0.rawValue }
            )) {
                ForEach(ClimateZone.allCases) { zone in
                    Text(zone.rawValue).tag(zone)
                }
            }
        }
    }

    // MARK: - Energy Rates

    private var energyRatesSection: some View {
        Section {
            HStack {
                Text("Electricity")
                Spacer()
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("0.160", text: $electricityRateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: electricityRateText) { _, newValue in
                        if let val = Double(newValue) {
                            electricityRate = val
                        }
                    }
                Text("/kWh")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Natural Gas")
                Spacer()
                Text("$")
                    .foregroundStyle(.secondary)
                TextField("1.20", text: $gasRateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: gasRateText) { _, newValue in
                        if let val = Double(newValue) {
                            gasRate = val
                        }
                    }
                Text("/therm")
                    .foregroundStyle(.secondary)
            }
            Button("Reset to Defaults") {
                electricityRate = Constants.defaultElectricityRate
                gasRate = Constants.defaultGasRate
                electricityRateText = String(format: "%.3f", electricityRate)
                gasRateText = String(format: "%.2f", gasRate)
            }
            .foregroundStyle(.red)
        } header: {
            Text("Energy Rates")
        } footer: {
            Text("These rates are used for cost estimates throughout the app.")
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .tint(Color.manor.primary)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundStyle(.secondary)
            }
            Link(destination: URL(string: "https://manoros.com/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://manoros.com/terms")!) {
                HStack {
                    Text("Terms of Service")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        Section {
            Button("Reset Onboarding") {
                hasSeenOnboarding = false
            }
            .foregroundStyle(.red)
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("This will show the onboarding flow again on next launch.")
        }
    }
}
