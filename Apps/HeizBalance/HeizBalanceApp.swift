import SwiftUI

@main
struct HeizBalanceApp: App {
    @State private var projectStore = HeizBalanceProjectStore()
    @State private var radiatorDatasetStore = HeizBalanceRadiatorDatasetStore()
    @State private var valveDatasetStore = HeizBalanceValveDatasetStore()

    var body: some Scene {
        WindowGroup {
            HeizBalanceView()
                .environment(projectStore)
                .environment(radiatorDatasetStore)
                .environment(valveDatasetStore)
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
