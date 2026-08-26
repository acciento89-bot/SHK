import SwiftUI

@main
struct HeizBalanceApp: App {
    @State private var projectStore = HeizBalanceProjectStore()
    @State private var radiatorDatasetStore = HeizBalanceRadiatorDatasetStore()
    @State private var valveDatasetStore = HeizBalanceValveDatasetStore()
    @State private var pumpDatasetStore = HeizBalancePumpDatasetStore()
    @State private var pumpSelectionStore = HeizBalancePumpSelectionStore.shared
    @State private var componentFavoriteStore = HeizBalanceComponentFavoriteStore()
    @State private var hydraulicCaptureTemplateStore = HeizBalanceHydraulicCaptureTemplateStore()
    @State private var valveSettingSelectionStore = HeizBalanceValveSettingSelectionStore()
    @State private var documentationStore = HeizBalanceDocumentationStore()
    @State private var normativeEvidenceCandidateStore = HeizBalanceNormativeEvidenceCandidateStore()

    var body: some Scene {
        WindowGroup {
            HeizBalanceView()
                .environment(projectStore)
                .environment(radiatorDatasetStore)
                .environment(valveDatasetStore)
                .environment(pumpDatasetStore)
                .environment(pumpSelectionStore)
                .environment(componentFavoriteStore)
                .environment(hydraulicCaptureTemplateStore)
                .environment(valveSettingSelectionStore)
                .environment(documentationStore)
                .environment(normativeEvidenceCandidateStore)
                .preferredColorScheme(.dark)
                .shkKeyboardDismissal()
        }
    }
}
