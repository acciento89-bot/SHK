# Calc field workflows — iOS 1.0 (5)

These are new app capabilities, not changes to icon color or a renamed calculator. Submit only after build 5 has been signed, uploaded and selected in App Store Connect. Do not claim the old build 4 contains them.

## HeizkörperCalc

**Subtitle DE:** Raumcheck für Wärmepumpen

**Subtitle EN:** Room capacity at lower temps

**Description DE**

Welche Räume kommen mit niedrigeren Systemtemperaturen aus? HeizkörperCalc verbindet deinen Heizkörperbestand mit einer raumweisen Leistungsprüfung.

Erfasse Gebäude, ermittelte Raumheizlast, ΔT50-Nennleistung, Herstellerexponent und Raumtemperatur. Wähle Vorlauf und Rücklauf und sieh, welche Räume ausreichend versorgt sind. Leistungsüberschüsse anderer Räume werden nicht mit Defiziten verrechnet. Zusätzliche Temperaturszenarien zeigen, wie sich die Deckung verändert.

Speichere mehrere Bestandsaufnahmen lokal, bearbeite sie vor Ort und teile einen Bericht mit Eingaben und Ergebnissen. Der Einzelrechner bleibt für Leistungsumrechnung und detaillierte Einzelprüfungen verfügbar.

Die App berechnet keine Raumheizlast. Herstellerdaten und eine extern ermittelte Heizlast bilden die Grundlage. Alle Berechnungen und Projekte funktionieren offline.

**Review note EN**

The new primary workflow is a building survey for low-temperature radiator suitability. It persists multiple named building inventories, compares each room against its own heat demand, reports uncompensated room shortfalls and compares system-temperature scenarios. The single radiator calculator is now a secondary tool.

Steps (English labels, German in parentheses): Survey (Bestand) → Start a survey (Bestandsaufnahme starten) → name the building → Add room (Raum hinzufügen) → enter room heat demand and radiator rating → Save (Speichern) → open the building. Change target flow/return under Edit (Bearbeiten). Review room coverage and temperature scenarios, then use Share survey report (Bestandsbericht teilen). Data persists after relaunch; no account is required.

## RohrCalc

**Subtitle DE:** Druckverlust ganzer Fließwege

**Subtitle EN:** Pressure loss across a route

**Description DE**

Beurteile den Druckverlust eines kompletten seriellen Fließwegs statt nur eines einzelnen Rohrs.

Erfasse Abschnitte in Fließrichtung mit Länge, Innendurchmesser, Rauheit und Widerstandsbeiwerten der Formstücke. RohrCalc summiert Rohrreibung und örtliche Verluste, zeigt die Verlustbeiträge als Diagramm und benennt den Abschnitt mit dem größten Beitrag. Strömungsgeschwindigkeit, Reynolds-Zahl, Wasserinhalt und Wassersäule machen die Ergebnisse nachvollziehbar.

Mehrere Fließwege lassen sich lokal speichern, bearbeiten, umsortieren und als Streckenbericht teilen. Für einzelne Dimensionierungsfragen stehen ergänzende Rechner bereit.

Die Streckenrechnung gilt für einen seriellen Fließweg mit gleichem Volumenstrom und Wasser bei etwa 20 °C. Geräteverluste, andere Kreise und geodätische Förderhöhe sind nicht enthalten. Alle Projekte funktionieren offline.

**Review note EN**

The new primary workflow assembles a serial hydraulic route from editable, reorderable pipe sections. It sums distributed friction and fitting losses, visualizes each section's contribution and identifies the largest loss contributor. This is a persisted multi-section analysis, distinct from our room-capacity, air-commissioning and refrigeration-service apps.

Steps: Routes (Strecken) → Create flow path (Fließweg anlegen) → name the route → Add section (Abschnitt hinzufügen), repeated for different sections → Save (Speichern) → open the route. Review total loss, contribution chart and section results. Edit (Bearbeiten) allows reordering. Share route report (Streckenbericht teilen) exports the assumptions and inputs. No account is required.

## LüftungsCalc

**Subtitle DE:** Luftmengen messen & abgleichen

**Subtitle EN:** Airflow commissioning records

**Description DE**

Vom geplanten Luftvolumenstrom zum nachvollziehbaren Einmessprotokoll: LüftungsCalc begleitet die Messung an einzelnen Zu- und Abluftauslässen.

Erfasse Auslässe mit Sollvolumenstrom und ergänze die gemessenen Werte vor Ort. Eine frei einstellbare Projekttoleranz zeigt Abweichungen; der Filter konzentriert die Liste auf offene und nachzuarbeitende Messpunkte. Noch nicht gemessene Auslässe bleiben ausdrücklich offen und werden nicht als Nullmessung behandelt. Vollständige Zu- und Abluftsummen ermöglichen einen Mengenvergleich.

Speichere mehrere Protokolle mit Ventilstellungen, Messbedingungen und Notizen. Teile Sollwerte, Messwerte und Abweichungen für die Übergabe. Die ergänzende Auslegung bietet Rund- und Rechteckkanalvergleich, Raumluftwechsel und Einheitenumrechnung.

Die Oberfläche verwendet skalierende Systemschrift, klare Kontraste und vertikal angeordnete Eingaben auf iPhone und iPad. Alle Projekte sind lokal und offline nutzbar. Die Projekttoleranz ist keine automatische Norm- oder Abnahmebestätigung.

**Review note EN**

We replaced the previous dense sizing interface with native vertically arranged form controls, semantic text styles, accessible input labels and explicit invalid-value feedback. The former conflicting forced light/dark appearance has been removed from the ventilation app. Large text no longer relies on shrinking result labels or three narrow input columns.

The new primary feature is air-terminal commissioning: target/measured flow, supply/extract classification, configurable project tolerance, missing-measurement tracking, an attention filter and full measurement reports. Partial measured totals are never shown as complete.

Steps: Records (Protokolle) → Start commissioning (Einmessung beginnen) → name project → Add terminal (Auslass hinzufügen) → expand terminal → enter target and enable Measurement available (Messwert liegt vor) → enter measured flow → Save (Speichern). Open the project to review exceptions and totals. Sizing (Auslegung) opens the redesigned sizing forms. No login is required.

## KälteCalc

**Subtitle DE:** Servicewerte im Zeitverlauf

**Subtitle EN:** Refrigeration service trends

**Description DE**

Ein Messwert zeigt einen Zustand. Ein Messverlauf zeigt, was sich während des Serviceeinsatzes verändert.

KälteCalc dokumentiert zeitgestempelte Messungen von Sauggas-, Verdampfungs-, Kondensations- und Flüssigkeitstemperatur. Überhitzung und Unterkühlung werden berechnet, chronologisch aufbereitet und als Verlauf dargestellt. Notiere Eingriffe und Betriebszustände direkt an der Messung und vergleiche erste und letzte Überhitzung.

Speichere Einsätze mit Anlagenbezeichnung, Kältemittel und Notizen lokal. Der teilbare Bericht enthält Originaltemperaturen, abgeleitete Werte und Zeitpunkte. Zusätzliche Werkzeuge helfen bei Einzelberechnungen und Einheiten.

Sättigungstemperaturen werden aus geeigneten Messgeräten oder Herstellerdaten übernommen. Der Kältemittelname dient der Dokumentation; die App berechnet keine automatische Druck-Temperatur-Zuordnung. Zielwerte sind anhand der Herstellerangaben und Betriebsbedingungen zu beurteilen. Offline, ohne Benutzerkonto.

**Review note EN**

The app now centers on a persisted refrigeration-service time series. Each timestamped reading stores original temperatures and an intervention note. Superheat/subcooling trends, chronological history and first-to-last superheat change support before/after service documentation. Negative values remain visible with a check indication rather than being clipped.

Steps: Sessions (Messverlauf) → Start service session (Serviceverlauf starten) → name the system → Add reading (Messung hinzufügen) → expand and enter readings → add a second reading with a later time → Save (Speichern). Open the session for trend and chronology, then Share service report (Serviceprotokoll teilen). No refrigerant pressure-temperature table is inferred from a refrigerant name. No login is required.

## Release gates

- Core calculation tests, Debug simulator builds, unsigned Release builds and the persisted workflows on iPhone/iPad: passed in CI run 387. See [VALIDATION.md](VALIDATION.md) for the tested commit, scope and limits.
- Distribution signing/upload: requires the account's existing Xcode signing setup or a configured signing runner. No signing key has been created or replaced.
- App Store Connect: select the new build, replace screenshots with actual captures of the new workflows, use the app-specific review note, then submit. Acceptance remains Apple's review decision.

## Technical references

- Existing calculation definitions are reused from SHKCore. Refrigeration differences are consistent with Danfoss's [Fitters notes: Thermostatic expansion valves](https://assets.danfoss.com/documents/latest/50825/AX266348279899en-000101.pdf), page 5.
- Apple documents [archive export files and ExportOptions.plist](https://help.apple.com/xcode/mac/current/en.lproj/deva1f2ab5a2.html). The supplied upload script requires a Mac with the existing developer signing access; it has not performed an upload in this workspace.
