# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung, Vor-Ort-Aufnahme und nachvollziehbare Baustellen-/Übergabedokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12

## Norm- und Compliance-Strategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-/VDI-Texte, Tabellen, Grafiken, VdZ-Formularlayouts oder ungeklärten Herstellerdaten werden in App oder Repository kopiert.
- Rechenengine, Produktdatenadapter, Auswahl-Snapshots und Berichte werden versioniert.
- Technische Vorbereitungen werden nicht als Norm-Heizlast, Verfahren-B-Nachweis, GEG-/BEG-Nachweis, Wärmepumpenauslegung oder Herstellerfreigabe bezeichnet.
- Das reservierte Profil `de-room-heat-load-2017-2020` bleibt technisch gesperrt, bis Spezifikation und Referenzfälle vollständig fachlich verifiziert sind.
- Regelwerks-/Quellenstand: `docs/HEIZBALANCE_NORM_RESEARCH.md`.
- Referenz-/Regressionstrategie: `docs/HEIZBALANCE_REFERENCE_CASES.md`.
- Hydraulik-/Produktdatenrecherche: `docs/HEIZBALANCE_HYDRAULIC_RESEARCH.md`.
- Produktionsbericht-Vertrag: `docs/HEIZBALANCE_PRODUCTION_REPORT.md`.

## Harte Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Keine GEG-/BEG-/Verfahren-B-/Norm-Konformitätsaussage ohne vollständige fachliche Prüfung.
3. Normative Ausgabe bleibt technisch gesperrt, solange Spezifikation/Referenzfälle nicht vollständig verifiziert sind.
4. Hersteller-Voreinstellungen nur aus dokumentierten, rechtmäßig nutzbaren Produktdaten und nur durch ausdrückliche Benutzerentscheidung.
5. Keine versteckten Fluid-, Rohr-, U-Wert-, Luftwechsel-, Pumpenreserve- oder Herstellerannahmen.
6. Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, vollständigen Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
7. Pumpen-Betriebspunkt nur bei vollständigen Verbraucherströmen und vollständigen Kreis-Druckverlusten.
8. Parallelkreis-Druckverluste werden nicht addiert; maßgebend ist der hydraulisch ungünstigste vollständige Kreis.
9. Pumpenkennlinien werden außerhalb ihres dokumentierten Q-Bereichs nicht extrapoliert.
10. Festgehaltene Pumpen-/Ventilentscheidungen werden eingefroren und bei relevanten Änderungen als `neu bewerten` markiert, niemals still ersetzt.
11. Schnellvorlagen/Kopien dürfen keine alten Last-, Flow-, Δp-, Vollständigkeits- oder Produktentscheidungen unbemerkt weitertragen.
12. Berichtsexporte ersetzen fehlende oder veraltete technische Werte nicht durch Annahmen.
13. Projektstatus, Übergabe und Unterschrift sind Dokumentation des Arbeitsstands und keine automatische Norm-/Förder-/Herstellerfreigabe.
14. HeizBalance erzeugt im Produktionsbericht freie handschriftliche Unterschriftszeilen, keine digitale/kryptografische Signatur oder automatische Abnahme.
15. Alle Teil-Snapshots eines Produktions-PDFs werden mit exakt demselben Exportzeitpunkt erzeugt.

## Aktueller Stand – Foundation Batch 21–30

### Projekt-/Gebäudeaufnahme
- Persistente lokale Struktur Projekt → Geschoss → Raum → Bauteil → Heizfläche.
- Projekt: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, System-VL/RL, Quellen, Hydraulik-Fluidwerte, Sanierungsziel, Notizen.
- Raum: Geometrie, Solltemperatur, Luftwechsel, Quelle, thermische Bauteile und Heizflächen.
- Bauteile: Art, Fläche, U-Wert, Quelle, thermische Randbedingung.
- Außenluft oder explizite Gegenseitentemperatur; keine versteckten Pauschalwerte für angrenzende Bereiche.

### Technische Wärmeverlust-/Heizflächenvorbereitung
- `HeizBalanceHeatLossPreviewCalculator`: Transmission + Lüftung aus expliziten Eingaben.
- Gebäudesumme nur bei vollständig erfassten Räumen.
- `technical-preview-v1` ausdrücklich nicht normativ.
- Heizflächen: Art, Hersteller/Modell, ΔT50-Nennleistung, Exponent, Quelle, zugeordnete erforderliche Leistung.
- Verfügbare Leistung und erforderliche Leistung bleiben getrennt.
- Ziel-Volumenstrom aus zugeordneter Leistung und expliziter Wasserspreizung.
- Niedertemperatur-Minimum und Temperatur-Szenario-Matrix; Sanierungsziel mit `Ziel erreichbar / Upgradebedarf / Daten unvollständig`.

### Produktdatenfundament
- Heizkörper: `radiator-product-dataset-v1`, explizite `radiator-replacement-selection-v1`, VDI-Mapping `vdi-3805-part6-mapped-v1`.
- Ventile: `valve-product-dataset-v1` mit diskreten `Voreinstellung → kv`-Punkten, VDI-Mapping `vdi-3805-part2-mapped-v1`.
- Pumpen: `pump-product-dataset-v1` mit dokumentierten Q/H-/optional-P₁-Kennlinien, VDI-Mapping `vdi-3805-part4-mapped-v1`.
- Alle Importe erhalten Hersteller, Datenstand, Quelle, Nutzungsgrundlage und Rechtehinweise.
- Mappingprofile verarbeiten autorisiert erzeugte normalisierte Eingaben; kein Rohparser geschützter VDI-Satzstrukturen.

### Hydraulische Berechnungsvorbereitung
- Explizite Fluiddichte und kinematische Viskosität.
- Rohrabschnitte: Rolle, Innendurchmesser, hydraulische Länge, Rauheit, ζ-Summe, ggf. expliziter Abschnittsvolumenstrom.
- Heizflächen-Anbindung nutzt terminalen Ziel-Q; gemeinsame Verteilung benötigt realen summierten Abschnitts-Q samt Quelle.
- Geschwindigkeit, Reynolds-Zahl, Rohrreibung, gerade/lokale Druckverluste.
- Hydraulische Bauteile: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Projektaggregation: Verbraucher-Gesamt-Q + hydraulisch ungünstigster Parallelkreis.
- Pumpen-Betriebspunkt nur bei kompletter Q-/Δp-Abdeckung.

### Ventil-kv und explizite Einstellungen
- `HeizBalanceValveSizingPreparationCalculator`: erforderlicher technischer kv aus Q, Ventil-Δp und Dichte.
- Mathematisch nächster diskreter Datenpunkt ist nur Vergleich, keine automatische Voreinstellung.
- `valve-setting-selection-v1`: Benutzer kann einen tatsächlich dokumentierten Produktdatenpunkt ausdrücklich festhalten.
- Eingefroren: Projekt/Kreis/Bauteil, Einstellung/kv, damaliger Soll-kv, Q, Δp, Dichte und Produkt-/Quellen-/Rechteprovenienz.
- `matchesCurrent` prüft Soll-kv, Q, Δp, Dichte und Produkt-/Datensatzidentität; Abweichung → `neu bewerten`.

### Pumpenkennlinie / Betriebspunkt
- `linear-documented-pump-curve-v1`: exakte Punkte + lineare Interpolation zwischen dokumentierten Punkten; keine Extrapolation.
- `pump-curve-selection-v1`: nur ausdrücklicher Tap kann eine technisch ausreichende Kennlinie festhalten.
- Auswahl friert Katalog-/Quelle-/Rechte-/Produkt-/Kennlinien-/Betriebspunktdaten ein und wird bei geänderter Hydraulik veraltet.
- Projektweiter Pumpen-Arbeitsbereich mit Statusfiltern.
- `pump-technical-metrics-v1`: hydraulische Leistungsanforderung, verfügbare hydraulische Leistung, H-Reserve m/%, Q-Bereichsposition, optional `Pₕ,erf/P₁`.
- `Pₕ,erf/P₁` ist kein Wirkungsgrad-, EEI-, ErP- oder Herstellernachweis.

### Batch 25 – schnelle Vor-Ort-Aufnahme
- Sichere Geschoss-/Raum-/Bauteil-/Heizflächenkopien mit neuen IDs.
- Raum-Schnellvorlagen und Bauteilsätze ohne versteckte Norm-/U-Wert-/Luftwechselannahmen.
- `component-favorite-v1` für eigene Bauteil-/U-Wert-Favoriten; niemals Fläche oder raumspezifische Gegenseitentemperatur.

### Batch 26 – sichere Hydraulik-Wiederverwendung
- `hydraulic-capture-template-v1` für wiederverwendbare Rohr-/Bauteilstruktur.
- Übernommen werden dürfen Geometrie, Rolle, Rauheit, ζ, Notizen und dokumentierte Ventilprodukt-Identität.
- Gemeinsame Abschnitts-Q, Bauteil-Δp, deren Quellen, Vollständigkeitsstatus und konkrete Einstellentscheidungen werden bewusst zurückgesetzt.
- Ganze Heizflächenkreise sowie einzelne Rohr-/Hydraulikbauteile können sicher kopiert werden.

### Batch 27 – Hydraulik-Aufnahme-Workspace
- Projektansicht `Hydraulik-Aufnahme & Einstellliste` zeigt alle Heizflächenkreise geschoss-/raumbezogen.
- Q, vollständiger Kreis-Δp und Rohrabschnittszahl direkt sichtbar.
- Rohrweg/Bauteile direkt bearbeiten, ergänzen, löschen, duplizieren oder als Vorlage speichern/anwenden.
- Verwaiste Ventileinstellungs-Snapshots werden beim Ersetzen/Löschen der zugehörigen Struktur entfernt.
- Vollständigkeitsbestätigung nur möglich, wenn erfasste hydraulische Bauteile gültige Δp-Werte besitzen.

### Batch 28 – explizite TV/RL-Entscheidung
- `valve-setting-selection-v1` mit unabhängigen Thermostat-/Rücklaufentscheidungen.
- Nur dokumentierte Produktdatenpunkte + ausdrücklicher Benutzer-Tap.
- Relevante Änderungen führen zu `neu bewerten` statt stiller Neuberechnung.

### Batch 29 – Baustellen-Einstellliste
- `technical-adjustment-list-v1` mit Geschoss/Raum/Heizfläche, Ziel-Q, vollständigem Kreis-Δp, TV/RL, Soll-kv, festgehaltenen Einstellungen und Aktualitätsstatus.
- Offene Punkte pro Kreis sichtbar.
- Festgehaltene Pumpenentscheidung inkl. Betriebspunkt/Reserve/Aktualitätsstatus.
- Eigenständiger kompakter A4-PDF-/Archivpfad, maximal 10 erfolgreiche Stände pro Projekt.
- Kein nachgebautes VdZ-/Verfahren-B-Formular.

### Batch 30 – Produktionsbericht & Übergabe
- Neuer projektbezogener Dokumentationsstore `project-documentation-v1`; bestehendes Projekt-JSON bleibt unverändert.
- Dokumentierbar: Firma/Betrieb, Techniker vor Ort, Bearbeiter/Ersteller, expliziter Projektstatus, optionaler Ausführungstag, Übergabeempfänger, Übergabehinweis/Restpunkte, Druckschriftname und Ort.
- Projektstatus ist eine Bearbeiterangabe: `In Bearbeitung`, `Aufnahme vollständig`, `Hydraulik technisch vorbereitet`, `Einstellwerte vorbereitet`, `Einstellung dokumentiert`, `Übergabe vorbereitet`.
- Neuer eingefrorener Snapshot `technical-handover-v1` mit Projekt-/Personendaten, Geschoss-/Raum-/Heizflächenumfang, Wärmeverlust-/Q-/Δp-Abdeckung, Ventil-/Pumpenstatus und offenen technischen Punkten.
- Eigenes Übergabe-Archiv mit maximal 10 erfolgreichen Ständen pro Projekt.
- Übergabe-PDF enthält kompakte technische Übersicht, Geschosszusammenfassung, Restpunkte und freie handschriftliche Unterschriftsbereiche für Techniker/Bearbeiter sowie Auftraggeber/Empfänger.
- Unterschrift bestätigt ausschließlich Übergabe/Kenntnisnahme des dokumentierten Arbeitsstands; keine automatische DIN-/Verfahren-B-/GEG-/BEG-/Förder-/Herstellerfreigabe.
- Neuer Projekt-Cockpit-Einstieg `Produktionsbericht & Übergabe`.
- Ein Produktions-PDF bündelt mit exakt einem `generatedAt` sieben versionierte Snapshots:
  1. `technical-handover-v1`
  2. `technical-report-v1`
  3. `technical-low-temperature-v1`
  4. `technical-temperature-scenarios-v1`
  5. `technical-radiator-replacements-v1`
  6. `technical-pump-curves-v1`
  7. `technical-adjustment-list-v1`
- Nach erfolgreichem Benutzerexport werden die sieben Snapshots in ihren jeweiligen lokalen Archiven gespeichert.
- UI kennzeichnet Projekte ab 20 Räumen als Großprojekt und ab 50 Räumen als 50+-Räume-Projekt; es existiert kein künstliches Raumlimit.
- Einstelllisten-PDF auf dynamische Writer-/Textmessungslogik gehärtet: wiederholte Kopf-/Fußzeilen, Geschossgruppierung, gemessene Ventilzeilen, wortweise Fortsetzung langer Hinweise und kontrollierte Mehrseiten-Kreise statt Abschneiden.
- Übergabe-PDF verwendet ebenfalls dynamische Seitenfortsetzung für lange Texte und Geschossübersichten.

## Aktive versionierte Berichts-/Entscheidungsschemata
Berichte/Snapshots:
- `technical-report-v1`
- `technical-low-temperature-v1`
- `technical-temperature-scenarios-v1`
- `technical-radiator-replacements-v1`
- `technical-pump-curves-v1`
- `technical-adjustment-list-v1`
- `technical-handover-v1`

Projekt-/Entscheidungsschemata u. a.:
- `component-favorite-v1`
- `hydraulic-capture-template-v1`
- `radiator-replacement-selection-v1`
- `pump-curve-selection-v1`
- `valve-setting-selection-v1`
- `project-documentation-v1`

## Release-Härtung
- Entwicklungs-Musterprojekt per `#if DEBUG` aus Release entfernt.
- CI baut die komplette App-Matrix in Debug.
- HeizBalance besitzt zusätzlich ein echtes Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden geprüft.
- PR-CI verwendet `cancel-in-progress`.
- Swift-6-Concurrency-Prüfungen bleiben aktiv; mutable UI-Persistenzstores sind `@MainActor`-isoliert.

## Validierte CI-Checkpoints
- #50–#100: Heizflächen-, Hydraulik-, Ventil-, PDF-, Archiv-, Niedertemperatur- und Release-Grundlagen grün.
- #111: Szenario-/3-PDF-Pfad grün.
- #120/#123: persistentes Sanierungsziel + Dashboard grün.
- #154/#159: Heizkörperdaten, Ersatzwahl, VDI-Blatt-6-Adapter grün.
- #173: Ventilkatalog + Blatt-2-Adapter grün.
- #181: Pumpenkatalog + Blatt-4-Adapter grün.
- #192: Pumpenkennlinien-/Betriebspunkt-Core + No-Extrapolation + Berichtspfad grün.
- #202/#203: explizite Pumpen-/Kennlinienauswahl + Stale-Erkennung + Release grün.
- #212/#213: Pumpen-Cockpit, katalogübergreifender Vergleich, Leistungskennzahlen, Report/PDF und Projektstatus grün.
- #231: Batch 25, Core + komplette Debug-iOS-Matrix + echter HeizBalance Release grün.
- #249: Gate fing einen reinen Swift-Syntaxfehler im failable Ventilauswahl-Initializer ab; kein fachlicher Rechenfehler.
- **#250: Batch 26–29 Code-Head vollständig grün: Core, gesamte Debug-iOS-Matrix, HeizBalance Debug und echter Release-Simulator-Build.**
- **#256: finaler Hydraulik-/Handoff-Dokumentations-Head vollständig grün.**
- **#266: Batch-30 Produktions-Code-Head `4c201688a40c939f63f9b5ee832c3477bc83700f` vollständig grün: Core, gesamte Debug-iOS-Matrix, HeizBalance Debug und echter Release-Simulator-Build.**

## Noch bewusst gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-Freigabe / GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung.
- Vollautomatische Auswahl konkreter Ersatzheizkörper.
- Automatische Pumpenproduktempfehlung/-auswahl, Regelartwahl und Effizienzfreigabe.
- Pumpenkennlinien-Extrapolation außerhalb dokumentierter Datenbereiche.
- EEI-/ErP-/Hersteller-Wirkungsgradaussage aus technischen Pumpenkennzahlen.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne rechtlich/fachlich verifizierte Datensatzspezifikation.
- Echte Wärmepumpenauslegung, COP-/Bivalenzbewertung.
- Flächenheizung nach DIN EN 1264 als eigener Fachblock.
- Normativer hydraulischer Abgleich / Verfahren-B-Nachweis bleibt gesperrt, auch wenn Einstellliste und Übergabedokumentation vollständig sind.

## Nächste größere Entwicklungsblöcke
1. Produktionsbericht praktisch mit realen Großprojekten/PDFs visuell prüfen und ggf. Tabellen-/Seitenlayout weiter verdichten.
2. Optionale Netzbaum-Struktur für automatische gemeinsame Abschnittsvolumenströme statt manueller Summenwerte.
3. Echte Hersteller-/Lizenzquellen für Heizkörper-, Ventil- und Pumpendaten rechtlich klären und über die vorhandenen Mappingprofile validieren.
4. Normative Heizlast-Spezifikation und belastbare Referenzfälle aufbauen; Freigabe erst nach echter fachlicher Validierung.
5. Danach getrennte Fachblöcke Flächenheizung bzw. Wärmepumpen-/Bivalenzbewertung.

## Batch-Verifikation
- Maßgeblicher Batch-30 Code-Head: `4c201688a40c939f63f9b5ee832c3477bc83700f`, CI #266 vollständig grün.
- Der finale Dokumentations-/PR-Head wird nach Abschluss erneut durch dieselbe vollständige CI-Matrix geprüft; erst dieser Lauf gilt als finaler Batch-30-Checkpoint.
