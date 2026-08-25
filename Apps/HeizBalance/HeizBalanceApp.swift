import SwiftUI

@main
struct HeizBalanceApp: App {
    var body: some Scene {
        WindowGroup {
            HeizBalanceView()
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
