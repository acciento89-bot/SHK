import SwiftUI

struct HeizBalanceCalculationStatusView: View {
    private let previewProfile = HeizBalanceCalculationProfile.technicalPreviewV1
    private let normativeProfile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020

    private var requiredModules: [HeizBalanceNormativeModuleID] {
        HeizBalanceNormativeReadiness.requiredModules(for: normativeProfile.engineID)
    }

    private var readiness: HeizBalanceNormativeReadinessReport {
        HeizBalanceNormativeReadiness.evaluate(profile: normativeProfile, evidence: [])
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Profil", value: previewProfile.displayName)
                LabeledContent("Status", value: previewProfile.validationState.displayName)
                LabeledContent("Normative Ausgabe") {
                    Label("Nein", systemImage: "xmark.shield")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Aktive Vorberechnung")
            } footer: {
                Text("Dieses Profil dient nur zur technischen Plausibilisierung der erfassten Projektdaten.")
            }

            Section {
                LabeledContent("Profil", value: normativeProfile.displayName)
                LabeledContent("Status", value: normativeProfile.validationState.displayName)
                LabeledContent("Freigabe") {
                    if readiness.canProduceNormativeOutput {
                        Label("Freigegeben", systemImage: "checkmark.seal.fill")
                    } else {
                        Label("Gesperrt", systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(normativeProfile.sourceEditions, id: \.document) { source in
                    LabeledContent(source.document, value: source.edition)
                }
            } header: {
                Text("Reserviertes Normprofil")
            } footer: {
                Text("Die Freigabe bleibt technisch gesperrt, bis Spezifikation, Referenzfälle und explizites Release-Gate erfüllt sind.")
            }

            Section {
                ForEach(requiredModules, id: \.self) { module in
                    HStack(alignment: .firstTextBaseline) {
                        Label(module.displayName, systemImage: "square.dashed")
                        Spacer()
                        Text("offen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Validierungsbausteine")
            } footer: {
                Text("Die Liste beschreibt die getrennten Rechen- und Prüfmodule. Ihre konkrete normative Ausgestaltung wird erst nach verifizierter Fachspezifikation implementiert.")
            }

            Section("Gate-Status") {
                LabeledContent("Spezifikationen offen") {
                    Text("\(readiness.missingSpecificationModules.count)")
                }
                LabeledContent("Referenzvalidierungen offen") {
                    Text("\(readiness.missingReferenceValidationModules.count)")
                }
                LabeledContent("Profil-Lifecycle") {
                    Text(readiness.profileLifecycleReady ? "bereit" : "nicht bereit")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Explizite Release-Freigabe") {
                    Text(readiness.explicitReleaseFlagEnabled ? "aktiv" : "aus")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Rechenstatus")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HeizBalanceCalculationStatusView()
    }
    .preferredColorScheme(.dark)
}
