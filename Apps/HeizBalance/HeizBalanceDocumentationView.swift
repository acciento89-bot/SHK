import SwiftUI

struct HeizBalanceDocumentationView: View {
    @Environment(HeizBalanceDocumentationStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let projectID: UUID
    let projectName: String

    @State private var draft = HeizBalanceDocumentationMetadata()
    @State private var loaded = false

    var body: some View {
        Form {
            Section {
                TextField("Firma / Betrieb", text: $draft.companyName)
                TextField("Techniker vor Ort", text: $draft.technicianName)
                TextField("Bearbeiter / Ersteller", text: $draft.preparedBy)
            } header: {
                Text("Verantwortliche")
            } footer: {
                Text("Diese Angaben erscheinen im technischen Bericht und in der Baustellen-Einstellliste. Sie sind reine Projektdokumentation und keine normative Freigabe.")
            }

            Section {
                Picker("Projektstatus", selection: $draft.projectStatus) {
                    ForEach(HeizBalanceDocumentationMetadata.ProjectStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }

                Toggle("Ausführungstermin dokumentieren", isOn: executionDateEnabled)
                if draft.executionDate != nil {
                    DatePicker(
                        "Ausführung / Ortstermin",
                        selection: executionDateBinding,
                        displayedComponents: [.date]
                    )
                }
            } header: {
                Text("Arbeitsstand")
            } footer: {
                Text("Der Status wird ausdrücklich vom Bearbeiter gesetzt. Auch „Übergabe vorbereitet“ ist keine automatische DIN-, GEG-, BEG- oder Hersteller-Konformitätsaussage.")
            }

            Section {
                TextField("Übergabe an / Ansprechpartner", text: $draft.handoverRecipient)
                TextField("Übergabehinweis / Restpunkte", text: $draft.handoverNote, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Übergabe")
            }

            Section {
                TextField("Name in Druckschrift", text: $draft.signaturePrintedName)
                TextField("Ort", text: $draft.signaturePlace)
            } header: {
                Text("Unterschriftsbereich")
            } footer: {
                Text("Im PDF wird eine freie handschriftliche Unterschriftszeile erzeugt. Ein eingetragener Name dient nur als Druckschrift/Zuordnung; HeizBalance erzeugt keine digitale Signatur und keine automatische Abnahme.")
            }

            if let error = store.persistenceError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Dokumentation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    store.save(projectID: projectID, metadata: draft)
                    if store.persistenceError == nil {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            draft = store.metadata(projectID: projectID)
            loaded = true
        }
    }

    private var executionDateEnabled: Binding<Bool> {
        Binding(
            get: { draft.executionDate != nil },
            set: { enabled in
                draft.executionDate = enabled ? (draft.executionDate ?? Date()) : nil
            }
        )
    }

    private var executionDateBinding: Binding<Date> {
        Binding(
            get: { draft.executionDate ?? Date() },
            set: { draft.executionDate = $0 }
        )
    }
}
