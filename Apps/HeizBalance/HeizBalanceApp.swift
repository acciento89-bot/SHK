import SwiftUI

@main
struct HeizBalanceApp: App {
    @State private var projectStore = HeizBalanceProjectStore()

    var body: some Scene {
        WindowGroup {
            HeizBalanceView()
                .environment(projectStore)
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
