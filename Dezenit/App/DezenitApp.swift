import SwiftUI
import SwiftData

@main
struct DezenitApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeListView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(for: [
            Home.self,
            Room.self,
            Equipment.self,
            Appliance.self,
            EnergyBill.self,
            AuditProgress.self
        ])
    }
}
