import SwiftUI

@main
struct RohrCalcApp: App {
    var body: some Scene {
        WindowGroup {
            RohrCalcView()
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
