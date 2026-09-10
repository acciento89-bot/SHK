import SwiftUI

@main
struct KalteCalcApp: App {
    var body: some Scene {
        WindowGroup {
            ColdSessionHome()
                .shkKeyboardDismissal()
        }
    }
}
