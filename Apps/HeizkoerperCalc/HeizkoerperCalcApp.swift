import SwiftUI

@main
struct HeizkoerperCalcApp: App {
    var body: some Scene {
        WindowGroup {
            HeatSurveyHome()
                .shkKeyboardDismissal()
        }
    }
}
