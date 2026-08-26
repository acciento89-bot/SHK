import SwiftUI
import UniformTypeIdentifiers

struct HeizBalanceNormativeEvidenceCandidateManager: View {
    @Environment(HeizBalanceNormativeEvidenceCandidateStore.self) private var store
    @State private var showingImporter = false
    @State private var importMessage: String?

    var body: some View {
        List {
            Section {
                Label("Importierte Evidenzpakete sind niemals automatisch vertrauenswürdig.", systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                Text("Der Import prüft nur Schema, Referenzen und Wertebereiche. Rechteangaben, Spezifikationen und Erwartungswerte bleiben unbestätigte Kandidaten. Diese Quarantäne hat technisch keinen Pfad zur Normfreigabe.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Fail-closed")
            }

            Section {
                if store.candidates.isEmpty {
                    ContentUnavailableView(
                        "Keine Evidenzkandidaten",
                        systemImage: "tray.and.arrow.down",
                        description: Text("Importierte Pakete erscheinen hier ausschließlich in Quarantäne.")
                    )
                } else {
                    ForEach(store.candidates) { candidate in
                        NavigationLink {
                            HeizBalanceNormativeEvidenceCandidateDetail(candidate: candidate)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(candidate.package.id)
                                        .font(.headline)
                                    Spacer()
                                    Label("Quarantäne", systemImage: "lock.fill")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }

                                Text("Version \(candidate.package.packageVersion) · \(profileTitle(candidate.package.targetEngineID))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("\(candidate.package.specifications.count) Spezifikationen · \(candidate.package.referenceCases.count) Referenzfälle · \(candidate.package.sources.count) Quellen")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text("Importiert \(candidate.importedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.delete(id: candidate.id)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                Text("Quarantäne")
            } footer: {
                Text("Auch ein strukturell korrektes Paket bleibt unqualifiziert. Ein erneutes Laden aus dem lokalen Speicher setzt den Trust-State defensiv wieder auf Quarantäne.")
            }

            Section {
                Button {
                    showingImporter = true
                } label: {
                    Label("Evidenzpaket importieren", systemImage: "square.and.arrow.down")
                }

                if let importMessage {
                    Text(importMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let error = store.persistenceError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Unterstütztes Schema: \(HeizBalanceNormativeEvidenceCandidatePackage.schemaVersion). Das Paket darf Erwartungswerte transportieren, aber keinen vertrauensbildenden PASS-Status.")
            }

            Section("Normfreigabe") {
                LabeledContent("Einfluss dieser Quarantäne") {
                    Text("Keiner")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Automatische Freigabe") {
                    Text("Nicht möglich")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Evidenz-Quarantäne")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let data = try Data(contentsOf: url)
                let candidate = try store.importCandidate(data: data)
                importMessage = "In Quarantäne importiert: \(candidate.package.id) · kein Einfluss auf Normfreigabe"
            } catch {
                importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
            }

        case .failure(let error):
            importMessage = "Import fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func profileTitle(_ engineID: HeizBalanceCalculationEngineID) -> String {
        switch engineID {
        case .technicalPreviewV1: "Technische Vorberechnung"
        case .deRoomHeatLoad2017_2020: "Raumheizlast DE 2017/2020"
        }
    }
}

private struct HeizBalanceNormativeEvidenceCandidateDetail: View {
    let candidate: HeizBalanceNormativeEvidenceCandidateStore.StoredCandidate

    var body: some View {
        List {
            Section("Paket") {
                LabeledContent("ID", value: candidate.package.id)
                LabeledContent("Version", value: candidate.package.packageVersion)
                LabeledContent("Schema", value: candidate.package.schema)
                LabeledContent("Erstellt", value: candidate.package.createdOn)
                LabeledContent("Einreicher", value: candidate.package.submitter)
                LabeledContent("Trust-State") {
                    Label("Quarantäne", systemImage: "lock.fill")
                        .foregroundStyle(.orange)
                }
                LabeledContent("Normfreigabe-Einfluss") {
                    Text(candidate.canAffectNormativeReadiness ? "Ja" : "Nein")
                        .foregroundStyle(candidate.canAffectNormativeReadiness ? .orange : .secondary)
                }
                if let note = candidate.package.note, !note.isEmpty {
                    LabeledContent("Notiz") {
                        Text(note)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            Section {
                ForEach(candidate.package.sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(source.document)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(source.edition)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Text(sourceRoleTitle(source.role))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Metadaten: \(source.metadataReference)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Behauptete Rechte: \(sourceRightsTitle(source.rights))")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        if let reference = source.rightsReference, !reference.isEmpty {
                            Text("Rechte-Referenz: \(reference)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Quellenkandidaten")
            } footer: {
                Text("Rechteangaben aus einem importierten Paket sind Behauptungen des Pakets und gelten nicht als projektgeprüfter Nachweis.")
            }

            Section {
                if candidate.package.specifications.isEmpty {
                    Text("Keine Spezifikationskandidaten")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(candidate.package.specifications) { specification in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(specification.moduleID.displayName)
                                .font(.subheadline.weight(.semibold))
                            Text("Version \(specification.specificationVersion)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Referenz: \(specification.specificationReference)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Quelle: \(specification.sourceID)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Spezifikationskandidaten")
            } footer: {
                Text("Ein Kandidat ist noch keine unabhängig geprüfte Modulspezifikation.")
            }

            Section {
                if candidate.package.referenceCases.isEmpty {
                    Text("Keine Referenzfallkandidaten")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(candidate.package.referenceCases) { referenceCase in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(referenceCase.id)
                                .font(.subheadline.weight(.semibold))
                            Text(referenceCase.moduleIDs.map(\.displayName).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Fallreferenz: \(referenceCase.caseReference)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(referenceCase.expectations.count) Erwartungswerte")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            ForEach(referenceCase.expectations) { expectation in
                                HStack {
                                    Text(expectation.key)
                                        .font(.caption2.monospaced())
                                    Spacer()
                                    Text(expectation.expectedValue.formatted(.number.precision(.fractionLength(0...4))) + " ± " + expectation.absoluteTolerance.formatted(.number.precision(.fractionLength(0...4))))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            } header: {
                Text("Referenzfallkandidaten")
            } footer: {
                Text("Das Paket speichert Erwartungswerte, aber kein bestanden/nicht-bestanden als Vertrauensentscheidung. Die spätere Ausführung und unabhängige Qualifikation sind getrennte Schritte.")
            }
        }
        .navigationTitle(candidate.package.id)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sourceRoleTitle(_ role: HeizBalanceNormativeSourceRole) -> String {
        switch role {
        case .normativeBasis: "Normative Basis"
        case .successorDraft: "Nachfolgeentwurf"
        case .referenceCase: "Referenzfallquelle"
        }
    }

    private func sourceRightsTitle(_ rights: HeizBalanceNormativeSourceRights) -> String {
        switch rights {
        case .notDocumented: "nicht dokumentiert"
        case .implementationOnly: "Implementierung"
        case .referenceValidationOnly: "Referenzvalidierung"
        case .implementationAndReferenceValidation: "Implementierung + Referenzvalidierung"
        }
    }
}
