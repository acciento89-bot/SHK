# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung, schnelle Vor-Ort-Aufnahme und reproduzierbare Baustellen-/Übergabedokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12
- Aktueller Stand: **Foundation Batches 31–34 – Netzbaum, zentrale Shared-Edges & Verbraucherpfade**

## Compliance-Grenzen
- Keine proprietären DIN-/VDI-/VdZ-Inhalte im Repository.
- Keine Norm-Heizlast-, Verfahren-B-, GEG-/BEG-, Wärmepumpen- oder Herstellerfreigabe ohne getrennte vollständige fachliche Validierung.
- Keine versteckten Fluid-, Rohr-, U-Wert-, Luftwechsel-, Pumpenreserve- oder Herstellerannahmen.
- Fehlende/veraltete technische Werte bleiben offen statt geschätzt zu werden.
- Serielle Druckverluste eines realen Verbraucherpfads dürfen addiert werden; Druckverluste paralleler Verbraucherpfade werden nicht miteinander addiert.

Fachdokumente:
- `docs/HEIZBALANCE_REFERENCE_CASES.md`
- `docs/HEIZBALANCE_HYDRAULIC_RESEARCH.md`
- `docs/HEIZBALANCE_PRODUCTION_REPORT.md`
- `docs/HEIZBALANCE_HYDRAULIC_NETWORK.md`

## Bereits implementiert
- Projekt → Geschoss → Raum → Bauteil → Heizfläche, lokal persistent.
- Technische Wärmeverlust-/Heizflächenvorbereitung.
- Niedertemperatur-Check, Szenariomatrix, persistentes Sanierungsziel.
- Versionierte Produktdatenadapter für Heizkörper/Ventile/Pumpen.
- Rohr-/Komponenten-Druckverlust und harte Kreis-Vollständigkeitsgates.
- Explizite TV/RL-Einstellungen mit Stale-Erkennung.
- Pumpenkennlinien-Interpolation ohne Extrapolation + explizite Pumpenauswahl.
- Sichere Aufnahme-/Hydraulikvorlagen und Baustellen-Einstellliste.
- Produktions-/Übergabebericht mit Firma/Techniker/Bearbeiter/Status, Großprojekt-Paginierung und freien handschriftlichen Unterschriftszeilen.

## Batch 31 – Hydraulischer Netzbaum / automatische Summen-Q
Schemata/Profile:
- `hydraulic-network-v1`
- `hydraulic-network-tree-v1`
- `technical-hydraulic-network-v1`

### Baumlogik
- Heizflächen sind terminale Verbraucher.
- Ein Verbraucher darf genau einem direkten tiefsten Segment zugeordnet sein.
- Segmente können Kindsegmente enthalten.
- Eltern summieren alle nachgelagerten Verbraucherströme automatisch.
- Fehlender Verbraucher-Q → bekannte Zwischensumme sichtbar, vollständiger Segment-Q offen.
- Doppelzuordnung, Selbstreferenz, unbekannte Eltern und Zyklen sind ungültig.

Technischer Q-Referenzfall:
- Wohnzimmer 100 l/h
- Bad 150 l/h
- Schlafzimmer 200 l/h
- EG 250 l/h
- OG 200 l/h
- Hauptstrang 450 l/h.

### Shared-Pipe-Verknüpfung / Kompatibilität
- `networkSegmentID` optional an gemeinsamen Rohrabschnitten.
- Ohne Link bleibt der bisherige manuelle Summen-Q für Legacyprojekte gültig.
- Mit Link wird vollständiger Segment-Q auf den Rohrabschnitt synchronisiert.
- Rohrgeometrie, Länge, Rauheit, ζ und Verbraucher-Q werden dabei nicht verändert.
- Synchronisierung erfolgt beim Verknüpfen, bei Baum-/Verbraucheränderung, beim Öffnen des Netzbaum-Workspace und beim Projektspeichern.
- Verwaiste Verbraucher-/Eltern-/Rohrreferenzen werden bereinigt, ohne Fachdaten zu erfinden.

### Batch-31-Verifikation
- **CI #295: finaler Batch-31-Head `47f9962519b1686d4d6d0524d34d1eaa733ac0d1` vollständig grün** – Core, komplette Debug-iOS-Matrix, HeizBalance Debug und echter HeizBalance Release-Simulator-Build.

## Batches 32–34 – zentrale Shared-Edges & Path-Hydraulik
Neues Rechenprofil:
- `hydraulic-network-path-v1`

### Zentrale Edge-Regel
- Ein `Gemeinsame Verteilung`-Rohrabschnitt mit `networkSegmentID` wird als zentraler physischer Edge des Netzsegments behandelt.
- Jeder verknüpfte Shared-Abschnitt wird innerhalb seines Segments genau einmal gerechnet.
- Mehrere reale serielle Abschnitte dürfen demselben Segment zugeordnet sein.
- Sobald mindestens ein zentraler Shared-Edge vorhanden ist, ist der zentrale Pfadmodus aktiv.
- Unverknüpfte Legacy-Shared-Rohre bleiben gespeichert, werden im zentralen Pfadmodus aber **nicht zusätzlich** in Verbraucherpfade eingerechnet.

### Terminale Trennung
Neue App-Helfer:
- `terminalPipeCircuitPreparation`
- `terminalCircuitPressureLossSummary`

Sie rechnen ausschließlich `Heizflächen-Anbindung` plus terminale hydraulische Bauteilverluste. Verknüpfte gemeinsame Verteilungen werden nicht nochmals pro Heizfläche addiert.

### Verbraucherpfad
Für jede Heizfläche:
1. direkt zugeordnetes tiefstes Netzsegment bestimmen,
2. Segmentkette bis zur Wurzel bilden,
3. jeden zentralen Segment-Δp genau einmal seriell addieren,
4. terminalen Heizflächen-Anbindungs-/Bauteilverlust addieren.

Vollständiger Kreis-Δp wird nur ausgegeben, wenn:
- alle für den Pfad nötigen Segment-Q vollständig sind,
- alle zentralen Rohrmaße gültig sind,
- alle erforderlichen ζ-Summen explizit vorhanden sind,
- Fluiddichte und kinematische Viskosität explizit gültig sind,
- die Heizfläche einem Segment zugeordnet ist,
- terminaler Rohrweg/Bauteilverlust vollständig ist.

Fehlende Werte bleiben als bekannte Teilsumme sichtbar; vollständiger Pfad bleibt `nil`.

### System/Pumpe
`hydraulicSystemPreparationState()` verwendet im zentralen Pfadmodus den neuen vollständigen Verbraucherpfad-Δp.

Damit gilt:
- Gesamt-Q bleibt Summe der terminalen Verbraucher-Q,
- maßgebender Netz-Δp = höchster vollständiger Verbraucherpfad,
- gemeinsame Hauptleitungen werden nicht pro Heizfläche dupliziert,
- parallele Pfade werden nicht addiert,
- ein unvollständiger Verbraucherpfad verhindert vollständige Druckabdeckung und damit den Pumpen-Betriebspunkt,
- bestehende Pumpenentscheidung wird bei geändertem Betriebspunkt automatisch `neu bewerten`.

### Baustellen-Einstellliste
`technical-adjustment-list-v1` verwendet im zentralen Modus denselben Verbraucherpfad-Δp wie System/Pumpe. Es gibt damit keine zweite hydraulische Wahrheit zwischen Einstellliste und Pumpenberechnung.

### UI
`Hydraulischer Netzbaum` zeigt zusätzlich:
- Pfadprofil,
- Anzahl zentral verknüpfter Shared-Rohre,
- Anzahl unverknüpfter Legacy-Shared-Rohre,
- zentralen Pfadmodusstatus.

Neue Diagnoseansicht `Netzpfade & Druckverluste` zeigt:
- Segment-Q und Segment-Δp,
- Anzahl zentraler Rohrabschnitte je Segment,
- Verbraucherpfad `Wurzel → … → Zielsegment`,
- bekannte Shared-, terminale und gesamte Verluste,
- vollständigen Kreis-Δp nur bei kompletter Pfadabdeckung.

### Bericht / Reproduzierbarkeit
`technical-hydraulic-network-v1` bleibt bewusst dieselbe Schema-ID; neue Batch-32+-Felder sind optional, sodass ältere Batch-31-Archive weiter decodierbar bleiben.

Neue optionale Snapshotdaten:
- `pathProfileVersion`
- `centralPathModeActive`
- `centralLinkedPipeCount`
- `unlinkedLegacySharedPipeCount`
- Segment-Rohranzahl / bekannter-vollständiger Δp
- Verbraucherpfade mit Shared-/Terminal-/Gesamt-Δp.

Der Netzbaum-PDF-Teil zeigt diese Pfad-/Edge-Daten ebenfalls. Produktionsbericht bleibt bei 8 gemeinsam datierten Snapshots; `Technischer Bericht & PDF` bei 6, jeweils inklusive des erweiterten Netzbaum-/Pfad-Snapshots.

### Core-Regressionen
`HeizBalanceHydraulicNetworkPathTests` prüft:
- Root-/Kindsegmente werden genau einmal pro Verbraucherpfad addiert,
- derselbe physische Root-Edge kann logisch in mehreren Verbraucherpfaden vorkommen, ohne mehrfach gespeichert zu werden,
- fehlende ζ-Summe lässt bekannten geraden Verlust sichtbar, blockiert aber kompletten Segment-/Pfad-Δp,
- unzugeordneter Verbraucher erhält keinen vollständigen Pfad,
- Zyklen werden abgewiesen.

## Aktive Berichtssnapshots
- `technical-report-v1`
- `technical-hydraulic-network-v1`
- `technical-low-temperature-v1`
- `technical-temperature-scenarios-v1`
- `technical-radiator-replacements-v1`
- `technical-pump-curves-v1`
- `technical-adjustment-list-v1`
- `technical-handover-v1`

## Release-Gate
- komplette iOS-Debug-Matrix
- Core-Tests
- separater echter HeizBalance Release-Simulator-Build
- Swift-6-Concurrency aktiv
- `cancel-in-progress` für PR-Zwischenstände.

Historisch grün:
- #231 Batch 25
- #250/#256 Batches 26–29
- #266/#268 Batch 30
- #295 Batch 31 final.

Batches 32–34 gelten erst als abgeschlossen, wenn der **endgültige Branch-Head** nach Code + Handoff-Doku komplett grün ist.

## Bewusst noch gesperrt
- normative Heizlast / Verfahren B / GEG-/BEG-Konformität
- automatische Ventilvoreinstellung
- automatische konkrete Heizkörper-/Pumpenproduktempfehlung
- Pumpenkennlinien-Extrapolation
- EEI-/ErP-/Hersteller-Wirkungsgradclaims
- ungeprüfte Roh-VDI-Herstellerparser
- echte Wärmepumpenauslegung/COP/Bivalenz
- Flächenheizung nach DIN EN 1264.

## Nächste große Fachblöcke nach Stabilisierung
1. Zentrale Edge-Erfassung noch ergonomischer machen: physische Shared-Rohre direkt am Netzsegment anlegen/verschieben statt sie zunächst unter einer Heizfläche zu erfassen.
2. Reale große Netzbäume / PDF-Ausgaben mit 20–50 Räumen praktisch testen und UI verdichten.
3. Hersteller-/Lizenzquellen rechtlich klären und Mappingadapter produktiv befüllen.
4. Normative Heizlast-Spezifikation + belastbare Referenzfälle getrennt aufbauen.
5. Danach Flächenheizung bzw. Wärmepumpen-/Bivalenzmodule.
