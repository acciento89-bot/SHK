import SwiftUI

@main
struct HeizBalanceApp: App {
    @State private var projectStore = HeizBalanceProjectStore()
    @State private var radiatorDatasetStore = HeizBalanceRadiatorDatasetStore()

    var body: some Scene {
        WindowGroup {
            HeizBalanceView()
                .environment(projectStore)
                .environment(radiatorDatasetStore)
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
