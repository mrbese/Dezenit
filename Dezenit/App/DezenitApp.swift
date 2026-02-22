import SwiftUI
import SwiftData

@main
struct DezenitApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    let modelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: SchemaV1.self)
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: DezenitMigrationPlan.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                HomeListView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(modelContainer)
    }
}
