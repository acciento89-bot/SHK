import SwiftUI

struct SuiteProView: View {
    @EnvironmentObject private var store: SuiteStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image("AppBrand").resizable().scaledToFit().frame(width: 94, height: 94).clipShape(RoundedRectangle(cornerRadius: 22)).accessibilityHidden(true)
                Text(store.hasPro ? S("Deine Werkstatt ist komplett.", "Your workshop is complete.") : S("Mehr Projekte.\nEine Freischaltung.", "More projects.\nOne permanent unlock."))
                    .font(.system(.largeTitle, design: .rounded).bold()).fixedSize(horizontal: false, vertical: true)
                Text(S("SHK Werkstatt Pro ist ein dauerhafter Einmalkauf.", "SHK Werkstatt Pro is a permanent one-time purchase."))
                    .font(.headline).foregroundStyle(SuiteTheme.teal).accessibilityIdentifier("pro-permanent")
                SuiteCard {
                    VStack(alignment: .leading, spacing: 19) {
                        Label(S("Weitere Anlagen und Kundenprojekte speichern", "Save additional systems and customer projects"), systemImage: "square.stack.3d.up")
                        Label(S("Vollständige, mehrseitige PDF-Berichte teilen", "Share complete, multipage PDF reports"), systemImage: "doc.richtext")
                        Label(S("Auf iPhone und iPad mit demselben Apple-Konto wiederherstellbar", "Restorable on iPhone and iPad using the same Apple account"), systemImage: "iphone.and.ipad")
                    }.font(.body).fixedSize(horizontal: false, vertical: true)
                }
                if store.hasPro {
                    Label(S("Pro ist freigeschaltet", "Pro is unlocked"), systemImage: "checkmark.seal.fill").font(.title3.bold()).foregroundStyle(SuiteTheme.teal)
                } else {
                    Button { Task { await store.purchase() } } label: {
                        HStack {
                            if store.busy || store.loading { ProgressView().tint(.white) }
                            Text(store.product.map { S("Pro freischalten · ", "Unlock Pro · ") + $0.displayPrice } ?? S("Pro freischalten", "Unlock Pro"))
                        }.font(.headline).frame(maxWidth: .infinity, minHeight: 34)
                    }.buttonStyle(.borderedProminent).tint(SuiteTheme.action).controlSize(.large).disabled(store.product == nil || store.busy).accessibilityIdentifier("store-purchase")
                    if store.product == nil && !store.loading {
                        Text(S("Der Kauf konnte gerade nicht geladen werden. Die kostenlosen Funktionen stehen dir weiter zur Verfügung.", "The purchase could not be loaded. Free features remain available.")).font(.subheadline).foregroundStyle(SuiteTheme.secondary)
                        Button(S("Kauf erneut laden", "Load purchase again")) { Task { await store.loadProduct() } }.disabled(store.busy)
                    }
                }
                Button { Task { await store.restore() } } label: { Label(S("Käufe wiederherstellen", "Restore Purchases"), systemImage: "arrow.clockwise") }
                    .frame(minHeight: 44).disabled(store.busy).accessibilityIdentifier("store-restore-footer")
                Text(S("Kostenlos enthalten: alle Grundrechner, ein gespeichertes Projekt und der Textbericht. Bereits gespeicherte Projekte bleiben auch ohne aktive Pro-Freischaltung lesbar.", "Included for free: all basic calculators, one saved project and text reports. Existing projects remain readable without an active Pro entitlement.")).font(.footnote).foregroundStyle(SuiteTheme.secondary)
                HStack(spacing: 20) {
                    Link(S("Datenschutz", "Privacy"), destination: URL(string: "https://acciento89-bot.github.io/SHK/privacy/")!)
                    Link(S("Nutzungsbedingungen", "Terms of Use"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }.font(.footnote).padding(.vertical, 8)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(SuiteTheme.canvas).navigationTitle("Pro")
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button(S("Wiederherstellen", "Restore")) { Task { await store.restore() } }
                .disabled(store.busy).accessibilityIdentifier("store-restore")
        } }
    }
}

struct SuiteSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("suite-language") private var language = "system"
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(S("Sprache", "Language"), selection: $language) {
                        Text(S("Wie das Gerät", "Device setting")).tag("system")
                        Text("Deutsch").tag("de")
                        Text("English").tag("en")
                    }
                }
                Section(S("Deine Daten", "Your data")) {
                    Text(S("Projekte werden lokal auf diesem Gerät gespeichert. Teilen erfolgt nur, wenn du es auswählst. Bewahre wichtige Berichte zusätzlich selbst auf.", "Projects are stored locally on this device. Sharing happens only when you choose it. Keep your own copies of important reports."))
                    Link(S("Datenschutz öffnen", "Open privacy policy"), destination: URL(string: "https://acciento89-bot.github.io/SHK/privacy/")!)
                }
                Section(S("Zur Anwendung", "About")) {
                    Text(S("SHK Werkstatt verbindet sechs Fachbereiche in einer gemeinsamen Projektakte. Berechnungen ersetzen keine Herstellerangaben, Messungen oder fachliche Prüfung.", "SHK Workshop connects six disciplines in one project record. Calculations do not replace manufacturer data, measurements or professional inspection."))
                    Text("Kamilunavo · 1.0").foregroundStyle(SuiteTheme.secondary)
                }
            }.navigationTitle(S("Einstellungen", "Settings"))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(S("Fertig", "Done")) { dismiss() } } }
        }
    }
}
