import SwiftUI
import UIKit

private struct SuiteSharedItems: Identifiable {
    let id = UUID()
    let items: [Any]
    let temporaryFile: URL?
}

struct SuiteReportView: View {
    let project: SuiteProject
    var draft = false
    @EnvironmentObject private var store: SuiteStore
    @Environment(\.dismiss) private var dismiss
    @State private var shared: SuiteSharedItems?
    @State private var temporaryFile: URL?
    @State private var exportError = false
    @State private var pro = false
    private var text: String {
        (draft ? S("ENTWURF · noch nicht gesichert\n\n", "DRAFT · not yet saved\n\n") : "") + project.reportText(language: suiteLanguage)
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { shared = SuiteSharedItems(items: [text], temporaryFile: nil) } label: { Label(S("Textbericht teilen", "Share text report"), systemImage: "square.and.arrow.up") }
                        .accessibilityIdentifier("report-share-text")
                    Button {
                        if !store.hasPro { pro = true; return }
                        do {
                            let file = try SuitePDF.write(text: text, title: project.name)
                            temporaryFile = file; shared = SuiteSharedItems(items: [file], temporaryFile: file)
                        } catch { exportError = true }
                    } label: { Label(S("PDF-Bericht teilen", "Share PDF report") + (store.hasPro ? "" : " · Pro"), systemImage: "doc.richtext") }
                        .accessibilityIdentifier("report-share-pdf")
                } footer: { Text(S("Der Bericht enthält deine erfassten Werte und ihre Berechnungsgrundlagen. Du wählst selbst, wohin du ihn teilst.", "The report contains recorded values and calculation assumptions. You choose where to share it.")) }
                Section { Text(text).font(.body).textSelection(.enabled).accessibilityIdentifier("report-body") }
            }.suiteFormSurface().navigationTitle(S("Projektbericht", "Project report")).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(S("Fertig", "Done")) { dismiss() } } }
        }
        .sheet(item: $shared, onDismiss: {
            if let temporaryFile { try? FileManager.default.removeItem(at: temporaryFile) }; temporaryFile = nil
        }) { value in SuiteActivitySheet(items: value.items).presentationDetents([.medium, .large]) }
        .sheet(isPresented: $pro) { NavigationStack { SuiteProView().toolbar { ToolbarItem(placement: .confirmationAction) { Button(S("Fertig", "Done")) { pro = false } } } } }
        .alert(S("PDF konnte nicht erstellt werden", "PDF could not be created"), isPresented: $exportError) { Button("OK") {} }
    }
}

private struct SuiteActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
