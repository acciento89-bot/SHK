import SwiftUI

@main struct SHKWerkstattApp: App {
    @StateObject private var notebook = SuiteNotebook()
    @StateObject private var store = SuiteStore()
    @AppStorage("suite-language") private var language = "system"
    var body: some Scene {
        WindowGroup {
            SuiteRootView()
                .environmentObject(notebook).environmentObject(store)
                .environment(\.locale, language == "system" ? .current : Locale(identifier: language))
                .tint(SuiteTheme.teal)
                .preferredColorScheme(.dark)
                .task { await store.start() }
        }
    }
}
