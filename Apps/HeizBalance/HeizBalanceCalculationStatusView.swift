import SwiftUI

struct HeizBalanceCalculationStatusView: View {
    private let previewProfile = HeizBalanceCalculationProfile.technicalPreviewV1
    private let normativeProfile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020

    private var publicSources: [HeizBalanceNormativeSourceRecord] {
        HeizBalanceNormativeEvidenceCatalog.germanRoomHeatLoad2017_2020PublicMetadata
    }

    private var sourceBasis: HeizBalanceNormativeSourceBasisReport {
        HeizBalanceNormativeEvidenceLedger.sourceBasis(
            profile: normativeProfile,
            sources: publicSources
        )
    }

    private var moduleEvidence: [HeizBalanceNormativeModuleEvidence] {
        HeizBalanceNormativeEvidenceLedger.moduleEvidence(
            profile: normativeProfile,
            sources: publicSources,
            specifications: [],
            referenceCases: []
        )
    }

    private var requiredModules: [HeizBalanceNormativeModuleID] {
        HeizBalanceNormativeReadiness.requiredModules(for: normativeProfile.engineID)
    }

    private var readiness: HeizBalanceNormativeReadinessReport {
        HeizBalanceNormativeReadiness.evaluate(
            profile: normativeProfile,
            evidence: moduleEvidence,
            sourceBasis: sourceBasis
        )
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
                Text("Die Freigabe bleibt technisch gesperrt, bis Quellenbasis, Spezifikation, unabhängige Referenzfälle und explizites Release-Gate erfüllt sind.")
            }

            Section {
                ForEach(publicSources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(source.document)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(source.edition)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Text(source.role == .successorDraft ? "Nachfolgeentwurf · Metadaten" : "Profilbasis · Metadaten")
                            .font(.caption)
                            .foregroundStyle(source.role == .successorDraft ? .orange : .secondary)

                        if let doi = source.doi {
                            Text("DOI \(doi)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Text("Metadaten geprüft: \(source.metadataVerifiedOn)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Öffentlich verifizierte Quellenmetadaten")
            } footer: {
                Text("Metadaten belegen Dokument, Ausgabe und Nachfolgehinweise – nicht das Recht zur Implementierung und nicht die fachliche Verifikation der Rechenvorschriften. Der Entwurf 2025 wird deshalb separat als offener Review-Punkt geführt.")
            }

            Section {
                ForEach(requiredModules, id: \.self) { module in
                    let evidence = moduleEvidence.first { $0.moduleID == module }
                    HStack(alignment: .firstTextBaseline) {
                        Label(module.displayName, systemImage: evidence?.referenceCoverageComplete == true && evidence?.specificationVerified == true ? "checkmark.square.fill" : "square.dashed")
                        Spacer()
                        Text(evidence?.specificationVerified == true && evidence?.referenceCoverageComplete == true ? "validiert" : "offen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Validierungsbausteine")
            } footer: {
                Text("Jedes Modul benötigt eine rechtlich qualifizierte, unabhängig geprüfte Spezifikation und mindestens einen unabhängigen Referenzfall mit dokumentierten Erwartungswerten. Technische Eigenregressionen zählen dafür nicht automatisch.")
            }

            Section("Gate-Status") {
                LabeledContent("Quellenbasis") {
                    Text(readiness.sourceBasisReady ? "bereit" : "gesperrt")
                        .foregroundStyle(readiness.sourceBasisReady ? .green : .orange)
                }
                LabeledContent("Basisrechte offen") {
                    Text("\(sourceBasis.implementationRightsMissingEditions.count)")
                }
                LabeledContent("Nachfolge-Reviews offen") {
                    Text("\(sourceBasis.pendingSuccessorDraftIDs.count)")
                }
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

            Section {
                NavigationLink {
                    HeizBalanceNormativeEvidenceCandidateManager()
                } label: {
                    Label("Evidenzpakete prüfen", systemImage: "tray.full")
                }

                LabeledContent("Importstatus") {
                    Text("Quarantäne")
                        .foregroundStyle(.orange)
                }
                LabeledContent("Direkter Gate-Einfluss") {
                    Text("Keiner")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Evidenz-Quarantäne")
            } footer: {
                Text("Importierte Kandidaten werden separat gespeichert und sind nicht mit der Readiness-Auswertung verbunden. Dadurch kann ein externes JSON-Paket die Normfreigabe nicht selbst aktivieren.")
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
