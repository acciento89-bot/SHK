import SwiftUI

@main
struct AnlagenCheckApp: App {
    var body: some Scene {
        WindowGroup {
            AnlagenCheckView()
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
