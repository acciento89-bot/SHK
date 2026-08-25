# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung, schnelle Vor-Ort-Aufnahme und reproduzierbare Baustellen-/Übergabedokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12
- Aktueller Entwicklungsstand: **Foundation Batch 31 – Hydraulischer Netzbaum**

## Compliance-Grenzen
- Keine proprietären DIN-/VDI-/VdZ-Inhalte im Repository.
- Keine Norm-Heizlast-, Verfahren-B-, GEG-/BEG-, Wärmepumpen- oder Herstellerfreigabe ohne getrennte vollständige fachliche Validierung.
- Keine versteckten Fluid-, Rohr-, U-Wert-, Luftwechsel-, Pumpenreserve- oder Herstellerannahmen.
- Fehlende oder veraltete technische Werte bleiben offen und werden nicht geschätzt.

Fachdokumente:
- `docs/HEIZBALANCE_NORM_RESEARCH.md`
- `docs/HEIZBALANCE_HYDRAULIC_RESEARCH.md`
- `docs/HEIZBALANCE_REFERENCE_CASES.md`
- `docs/HEIZBALANCE_PRODUCTION_REPORT.md`
- `docs/HEIZBALANCE_HYDRAULIC_NETWORK.md`

## Bestehende Funktionsblöcke
- Persistente Projekt-/Geschoss-/Raum-/Bauteil-/Heizflächenaufnahme.
- Technische Wärmeverlust-Vorbereitung und Heizflächenprüfung.
- Niedertemperatur-Minimum, Szenario-Matrix und persistentes Sanierungsziel.
- Dokumentierte Heizkörper-, Ventil- und Pumpenproduktdaten mit versionierten VDI-Mappingprofilen.
- Rohrdruckverlust, Komponentenverluste und harte Kreis-Vollständigkeitsgates.
- Explizite TV/RL-Einstellungen `valve-setting-selection-v1` mit Stale-Erkennung.
- Pumpenkennlinie `linear-documented-pump-curve-v1`, No-Extrapolation und explizite `pump-curve-selection-v1`.
- Sichere Aufnahmevorlagen/Kopien, Bauteilfavoriten und Hydraulikvorlagen.
- Baustellen-Einstellliste `technical-adjustment-list-v1`.
- Produktions-/Übergabebericht `technical-handover-v1` mit Firma/Techniker/Bearbeiter/Status und freien handschriftlichen Unterschriftszeilen.
- Großprojekt-PDF-Härtung ohne künstliches Raumlimit.

## Batch 31 – Hydraulischer Netzbaum
### Schemata
- Persistenz: `hydraulic-network-v1`
- Rechenprofil: `hydraulic-network-tree-v1`
- Bericht: `technical-hydraulic-network-v1`

Alle neuen Projektfelder sind optional; alte Projekte ohne Netzbaum behalten ihr bisheriges manuelles Shared-Flow-Verhalten.

### Baumlogik
- Heizflächen sind terminale Verbraucher.
- Ein Verbraucher darf genau einem direkten tiefsten Netzsegment zugeordnet sein.
- Segmente können direkte Verbraucher und Kindsegmente enthalten.
- Eltern summieren automatisch alle nachgelagerten Verbraucherströme.
- Fehlender terminaler Ziel-Q → bekannte Zwischensumme bleibt sichtbar, vollständiger Segment-Q bleibt offen.
- Doppelte Verbraucherzuordnung, Selbstreferenz, unbekannte Eltern und Zyklen werden abgewiesen.
- Unzugeordnete Verbraucher bleiben sichtbar und werden nicht still zugeordnet.

### Technischer Referenzfall
- Wohnzimmer 100 l/h
- Bad 150 l/h
- Schlafzimmer 200 l/h
- EG = 250 l/h
- OG = 200 l/h
- Hauptstrang = 450 l/h

Core-Tests decken außerdem fehlende Verbraucher-Q, Doppelzuordnung, Zyklus, unbekannte Eltern und unzugeordnete Verbraucher ab.

### Verknüpfung gemeinsamer Rohrabschnitte
- `HeizBalancePipeSection.networkSegmentID` ist optional.
- Nur Rolle `Gemeinsame Verteilung` darf fachlich mit einem Netzsegment gekoppelt bleiben.
- Ohne Kopplung bleibt manueller `explicitDesignVolumeFlowLPH` gültig.
- Mit Kopplung wird ein vollständiger Segment-Q auf den Abschnitt synchronisiert.
- Rohrgeometrie, Länge, Rauheit, ζ und Verbraucher-Zielströme bleiben unangetastet.

### Automatische Synchronisierung
Vollständige Netz-Q werden angewendet:
- beim Verknüpfen eines Rohrabschnitts,
- bei Baum-/Verbraucheränderungen im Netzbaum-Workspace,
- beim Öffnen nach Referenzbereinigung,
- beim normalen Projektspeichern.

Ein manueller Re-Sync bleibt für den Baustellenworkflow vorhanden.

### Stale-Schutz
Stored und aktuell berechneter Netz-Q müssen innerhalb 0,05 l/h übereinstimmen.

Bei offenem/abweichendem Netz-Q:
- UI: `Netzbaum-Q neu synchronisieren`
- vollständiger Kreis-Δp des betroffenen Pfads wird für Projektaggregation nicht verwendet
- Einstellliste behandelt den Kreis als unvollständig
- Pumpen-Betriebspunkt wird nicht als vollständig freigegeben
- eine festgehaltene Pumpenentscheidung wird dadurch neu zu bewerten.

Damit kann nach einer Last-/Q-Änderung kein alter Shared-Flow unbemerkt in der Pumpenbewertung weiterleben.

### Referenznormalisierung
Ohne Fachdaten zu löschen werden:
- gelöschte Heizflächen aus Verbraucherlisten entfernt
- ungültige Elternreferenzen gelöst
- Links auf gelöschte Segmente entfernt
- Netzlinks an normalen Heizflächen-Anbindungen entfernt.

### UI
`Hydraulischer Netzbaum` im Projekt-Cockpit:
- Segmentstruktur aufbauen
- Elternsegmente wählen
- Heizflächen direkt zuordnen
- gemeinsame Rohrabschnitte koppeln
- berechnete Segment-Q / bekannte Zwischenstände sehen
- stale Verknüpfungen erkennen und synchronisieren.

### Bericht / Reproduzierbarkeit
`technical-hydraulic-network-v1` friert Hierarchie, Verbraucher, Segment-Q, offene Verbraucher, Rohrverknüpfungen sowie stored/calculated/current ein.

Produktionsbericht:
1. `technical-handover-v1`
2. `technical-report-v1`
3. `technical-hydraulic-network-v1`
4. `technical-low-temperature-v1`
5. `technical-temperature-scenarios-v1`
6. `technical-radiator-replacements-v1`
7. `technical-pump-curves-v1`
8. `technical-adjustment-list-v1`

Alle acht erhalten denselben Exportzeitpunkt und werden getrennt versioniert archiviert.

Der separate `Technischer Bericht & PDF` enthält jetzt ebenfalls den Netzbaum und archiviert sechs gemeinsam datierte Snapshots: Hauptbericht, Netzbaum, Niedertemperatur, Szenarien, Heizkörper-Auswahl und Pumpenkennlinien.

## Release-Härtung
- Entwicklungsdemo per `#if DEBUG` aus Release entfernt.
- CI baut komplette iOS-Debug-Matrix.
- HeizBalance besitzt zusätzlich echten Release-Simulator-Build.
- Swift-6-Concurrency bleibt aktiv.
- PR-CI verwendet `cancel-in-progress`.

## Validierte historische Checkpoints
- #231: Batch 25 grün.
- #250/#256: Batches 26–29 inkl. finalem Handoff grün.
- #266/#268: Batch 30 Produktionsbericht inkl. finalem Head grün.
- Batch 31 gilt erst nach erfolgreicher vollständiger CI des **endgültigen Branch-Heads** als abgeschlossen.

## Bewusst noch gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-/GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung.
- Vollautomatische konkrete Ersatzheizkörperauswahl.
- Automatische Pumpenproduktempfehlung/-auswahl, Regelartwahl oder Effizienzfreigabe.
- Pumpenkennlinien-Extrapolation.
- EEI-/ErP-/Hersteller-Wirkungsgradaussagen aus technischen Kennzahlen.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne verifizierte Spezifikation/Nutzungsrechte.
- Echte Wärmepumpenauslegung/COP/Bivalenz.
- Flächenheizung nach DIN EN 1264.
- Normativer hydraulischer Abgleich bleibt gesperrt, auch wenn technische Netzbaum-/Einstell-/Übergabedaten vollständig sind.

## Nächste große Entwicklungsblöcke
1. **Edge-/Path-Hydraulik:** gemeinsame Rohrstrecken nur einmal geometrisch erfassen und Druckverluste automatisch entlang jedes Verbraucherpfads zusammensetzen.
2. Produktions-PDF mit realistischen 20–50+-Raum-Projekten visuell/inhaltlich stressen.
3. Hersteller-/Lizenzquellen fachlich/rechtlich validieren.
4. Normative Heizlast-Spezifikation + belastbare Referenzfälle; Freigabe erst nach Gegenprüfung.
5. Später getrennte Fachblöcke Flächenheizung und Wärmepumpen-/Bivalenzbewertung.
