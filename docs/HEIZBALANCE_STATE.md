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

## Norm- und Compliance-Strategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-/VDI-Texte, Tabellen, Grafiken, VdZ-Formularlayouts oder ungeklärten Herstellerdaten werden in App oder Repository kopiert.
- Technische Vorbereitungen werden nicht als Norm-Heizlast, Verfahren-B-Nachweis, GEG-/BEG-Nachweis, Wärmepumpenauslegung oder Herstellerfreigabe bezeichnet.
- Das reservierte Profil `de-room-heat-load-2017-2020` bleibt technisch gesperrt, bis Spezifikation und Referenzfälle vollständig fachlich verifiziert sind.
- Produktdatenadapter verarbeiten nur dokumentierte/rechtmäßig nutzbare Datenquellen und behalten Quellen-/Rechteprovenienz.

Wichtige Fachdokumente:
- `docs/HEIZBALANCE_NORM_RESEARCH.md`
- `docs/HEIZBALANCE_HYDRAULIC_RESEARCH.md`
- `docs/HEIZBALANCE_REFERENCE_CASES.md`
- `docs/HEIZBALANCE_PRODUCTION_REPORT.md`
- `docs/HEIZBALANCE_HYDRAULIC_NETWORK.md`

## Harte Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Keine GEG-/BEG-/Verfahren-B-/Norm-Konformitätsaussage ohne vollständige fachliche Prüfung.
3. Keine versteckten Fluid-, Rohr-, U-Wert-, Luftwechsel-, Pumpenreserve- oder Herstellerannahmen.
4. Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, vollständigen Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
5. Pumpen-Betriebspunkt nur bei vollständigen Verbraucherströmen und vollständigen Kreis-Druckverlusten.
6. Parallelkreis-Druckverluste werden nicht addiert; maßgebend ist der hydraulisch ungünstigste vollständige Kreis.
7. Pumpenkennlinien werden außerhalb ihres dokumentierten Q-Bereichs nicht extrapoliert.
8. Hersteller-/Ventil-/Pumpenentscheidungen werden nur durch ausdrückliche Benutzeraktion festgehalten und bei relevanten Änderungen als `neu bewerten` markiert.
9. Aufnahmevorlagen/Kopien dürfen alte Last-, Flow-, Δp-, Vollständigkeits- oder Produktentscheidungen nicht still weitertragen.
10. Berichtsexporte ersetzen fehlende oder veraltete Werte niemals durch Annahmen.
11. Projektstatus/Übergabe/Unterschrift dokumentieren den Arbeitsstand und sind keine Norm-/Förder-/Herstellerfreigabe.
12. Netzbaum-Summenströme werden nur aus explizit berechenbaren Verbraucher-Zielvolumenströmen gebildet; ein fehlender Verbraucher-Q blockiert den vollständigen upstream Segment-Q.
13. Ein veralteter Netzbaum-Q an einer verknüpften gemeinsamen Rohrstrecke blockiert deren vollständigen Kreis-Δp für Projektaggregation/Einstellliste und damit den vollständigen Pumpen-Betriebspunkt.

## Thermik / Heizflächen / Sanierung
- Persistente Struktur Projekt → Geschoss → Raum → Bauteil → Heizfläche.
- Technische Wärmeverlust-Vorbereitung aus expliziten Eingaben; Gebäudesumme nur bei vollständigen Räumen.
- Heizflächenleistung und zugeordnete erforderliche Leistung sind getrennt.
- Ziel-Q aus zugeordneter Leistung und expliziter Wasserspreizung.
- Niedertemperatur-Minimum mit begrenzender Heizfläche.
- Temperaturszenarien inkl. gespeichertem Sanierungsziel und Status `Ziel erreichbar / Upgradebedarf / Daten unvollständig`.
- Ersatzheizkörper nur aus importierten dokumentierten Produktdaten und nur nach ausdrücklicher Auswahl.

## Produktdaten
- Heizkörper: `radiator-product-dataset-v1`, `vdi-3805-part6-mapped-v1`.
- Ventile: `valve-product-dataset-v1`, `vdi-3805-part2-mapped-v1`.
- Pumpen: `pump-product-dataset-v1`, `vdi-3805-part4-mapped-v1`.
- Kein Rohparser geschützter VDI-Satzstrukturen.

## Hydraulik-Grundlage
- Explizite Fluiddichte + kinematische Viskosität.
- Rohrabschnitte: Rolle, realer Innendurchmesser, Länge, Rauheit, ζ-Summe, Abschnitts-Q.
- Heizflächen-Anbindung nutzt terminalen Ziel-Q.
- Gemeinsame Verteilung kann weiterhin einen manuellen Summen-Q führen oder optional mit dem Netzbaum verknüpft werden.
- Geschwindigkeit, Reynolds-Zahl, Pa/m sowie gerade/lokale Verluste.
- Hydraulische Bauteile getrennt erfasst.
- Vollständiger Kreis-Δp nur bei vollständiger Rohr-/Bauteilaufnahme.
- System: Verbraucher-Gesamt-Q + hydraulisch ungünstigster Parallelkreis.

## Ventile / Pumpe
- Erforderlicher technischer kv aus Q, Ventil-Δp und Dichte.
- Mathematisch nächster Herstellerpunkt bleibt nur Vergleich.
- `valve-setting-selection-v1` friert explizit gewählte TV/RL-Einstellungen ein und besitzt Stale-Erkennung.
- `linear-documented-pump-curve-v1`: exakte Herstellerpunkte bzw. lineare Interpolation nur innerhalb des dokumentierten Bereichs.
- `pump-curve-selection-v1`: nur technisch ausreichende Kennlinie kann per Benutzer-Tap festgehalten werden.
- `pump-technical-metrics-v1`: technische Leistungs-/Reservekennzahlen; kein EEI-/ErP-/Wirkungsgradnachweis.

## Schnelle Vor-Ort-Aufnahme – Batches 25–29
- Sichere Geschoss-/Raum-/Bauteil-/Heizflächenkopien mit neuen IDs.
- Raum-Schnellvorlagen ohne versteckte Normwerte.
- `component-favorite-v1` für eigene Bauteil-/U-Wert-Favoriten; nie Fläche oder raumspezifische Gegenseitentemperatur.
- `hydraulic-capture-template-v1` für sichere Rohr-/Bauteilstruktur; flow-/druckabhängige Entscheidungen werden beim Wiederverwenden entfernt.
- Zentraler Hydraulik-Aufnahme-Workspace.
- `technical-adjustment-list-v1` mit Ziel-Q, vollständigem Kreis-Δp, TV/RL-Einstellungen, Soll-kv, Pumpenstatus und offenen Punkten.
- Kein nachgebautes VdZ-/Verfahren-B-Formular.

## Produktionsbericht – Batch 30
- `project-documentation-v1`: Firma, Techniker, Bearbeiter, Status, optional Ausführungstag, Empfänger, Übergabehinweis und Druckschriftname.
- `technical-handover-v1`: eingefrorene Übergabe-/Projektzusammenfassung.
- Freie handschriftliche Unterschriftszeilen; keine Fake-Digitalsignatur und keine automatische Konformitäts-/Abnahmeaussage.
- Großprojekt-PDFs besitzen dynamische Mehrseitenlogik, wiederholte Kopf-/Fußzeilen und kontrollierte Fortsetzung langer Inhalte.
- Kein künstliches Raumlimit; UI kennzeichnet 20+ und 50+ Räume.

## Hydraulischer Netzbaum – Batch 31
### Persistenz / Rechenprofil
- Optionales rückwärtskompatibles Projekt-Schema `hydraulic-network-v1`.
- Core-Profil `hydraulic-network-tree-v1`.
- `networkSegmentID` ist optional an einem gemeinsamen Rohrabschnitt; alte Projekte ohne Netzbaum behalten ihr bisheriges Verhalten.

### Baumlogik
- Heizflächen sind terminale Verbraucher.
- Ein Verbraucher darf genau einem direkten tiefsten Segment zugeordnet sein.
- Ein Segment kann direkte Verbraucher und Kindsegmente haben.
- Eltern summieren automatisch alle nachgelagerten Verbraucherströme.
- Fehlender terminaler Q → bekannter Zwischenwert bleibt sichtbar, vollständiger Segment-Q bleibt offen.
- Doppelte Verbraucherzuordnung, Selbstreferenz, unbekannte Eltern und Zyklen werden abgewiesen.
- Unzugeordnete Verbraucher bleiben sichtbar; sie werden nicht automatisch irgendwo eingehängt.

### Netzbaum-Referenzfall
- Wohnzimmer 100 l/h
- Bad 150 l/h
- Schlafzimmer 200 l/h
- EG = 250 l/h
- OG = 200 l/h
- Hauptstrang = 450 l/h

Die Core-Regressionen prüfen zusätzlich fehlende Verbraucher-Q, Doppelzuordnung, Zyklen, unbekannte Eltern und unzugeordnete Verbraucher.

### Rohrverknüpfung / Auto-Sync
- Nur `Gemeinsame Verteilung` kann fachlich mit einem Netzsegment verknüpft werden.
- Ohne Verknüpfung bleibt manueller `explicitDesignVolumeFlowLPH` gültig.
- Mit Verknüpfung wird der vollständige Segment-Q auf den Abschnitt synchronisiert; Rohrgeometrie/ζ/Verbraucher-Q bleiben unangetastet.
- Synchronisierung erfolgt bei Netzbaum-/Verbraucheränderungen, beim Öffnen des Netzbaum-Workspace und beim normalen Projektspeichern.
- Verwaiste Verbraucher-/Segment-/Rohrreferenzen werden bereinigt, ohne hydraulische Fachdaten zu erfinden.

### Stale-Schutz
- Gespeicherter und aktuell berechneter Netz-Q müssen innerhalb 0,05 l/h übereinstimmen.
- Fehlender oder abweichender Netz-Q → `neu synchronisieren`.
- Betroffener Kreis wird für den vollständigen Projekt-Δp als unvollständig behandelt.
- Einstellliste zeigt `Netzbaum-Q neu synchronisieren`.
- Pumpen-Betriebspunkt und bestehende Pumpenauswahl werden nicht weiter als aktuell/fertig behauptet.

### Netzbaum-UI
- Projekt-Cockpit: `Hydraulischer Netzbaum`.
- Segmente anlegen/löschen/verschachteln.
- Heizflächen direkt einem Segment zuordnen.
- Gemeinsame Rohrabschnitte mit Segmenten verknüpfen.
- Segment-Q, bekannte Zwischenstände und stale Links sichtbar.
- Manueller Re-Sync bleibt als Sicherheits-/Arbeitsfunktion vorhanden.

### Bericht
- Neues Schema `technical-hydraulic-network-v1`.
- Friert Segmenthierarchie, Verbraucherzuordnung, bekannte/vollständige Q, unresolved Verbraucher und verknüpfte Rohrabschnitte samt stored/calculated/current ein.
- Eigener A4-PDF-Teil und separates 10er-Projektarchiv.
- Produktionsbericht wurde von 7 auf **8 gemeinsam datierte Snapshots** erweitert:
  1. `technical-handover-v1`
  2. `technical-report-v1`
  3. `technical-hydraulic-network-v1`
  4. `technical-low-temperature-v1`
  5. `technical-temperature-scenarios-v1`
  6. `technical-radiator-replacements-v1`
  7. `technical-pump-curves-v1`
  8. `technical-adjustment-list-v1`

## Aktive versionierte Schemata
Berichte/Snapshots:
- `technical-report-v1`
- `technical-hydraulic-network-v1`
- `technical-low-temperature-v1`
- `technical-temperature-scenarios-v1`
- `technical-radiator-replacements-v1`
- `technical-pump-curves-v1`
- `technical-adjustment-list-v1`
- `technical-handover-v1`

Projekt-/Entscheidungsschemata u. a.:
- `hydraulic-network-v1`
- `component-favorite-v1`
- `hydraulic-capture-template-v1`
- `radiator-replacement-selection-v1`
- `pump-curve-selection-v1`
- `valve-setting-selection-v1`
- `project-documentation-v1`

## Release-Härtung
- Entwicklungs-Musterprojekt per `#if DEBUG` aus Release entfernt.
- CI: komplette App-Matrix in Debug + echter HeizBalance Release-Simulator-Build.
- Export-Compliance und Buildnummer werden geprüft.
- PR-CI verwendet `cancel-in-progress`.
- Swift-6-Concurrency-Prüfungen bleiben aktiv.

## Wichtige validierte Checkpoints
- #231: Batch 25 grün.
- #250/#256: Hydraulik-Batches 26–29 + finaler Handoff grün.
- #266/#268: Batch 30 Produktionsbericht + finaler Head grün.
- Batch 31 wird erst als final grün markiert, wenn der **endgültige Branch-Head nach Netzbaum-Code und Handoff-Doku** Core, komplette Debug-iOS-Matrix, HeizBalance Debug und echten HeizBalance Release-Build bestanden hat.

## Bewusst noch gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-/GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung.
- Vollautomatische Auswahl konkreter Ersatzheizkörper.
- Automatische Pumpenproduktempfehlung/-auswahl, Regelartwahl und Effizienzfreigabe.
- Pumpenkennlinien-Extrapolation.
- EEI-/ErP-/Hersteller-Wirkungsgradaussage aus technischen Kennzahlen.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne rechtlich/fachlich verifizierte Spezifikation.
- Echte Wärmepumpenauslegung/COP/Bivalenz.
- Flächenheizung nach DIN EN 1264.
- Normativer hydraulischer Abgleich / Verfahren-B bleibt gesperrt, auch wenn technische Netzbaum-/Einstell-/Übergabedokumentation vollständig ist.

## Nächste größere Entwicklungsblöcke
1. Netzbaum zur echten gemeinsamen Edge-/Path-Geometrie weiterentwickeln: gemeinsame Rohrstrecken nur einmal erfassen und Druckverluste entlang Verbraucherpfaden automatisch zusammensetzen.
2. Produktions-PDF mit realen 20–50+-Raum-Projekten visuell prüfen/verdichten.
3. Hersteller-/Lizenzquellen für Heizkörper/Ventile/Pumpen rechtlich/fachlich validieren.
4. Normative Heizlast-Spezifikation + belastbare Referenzfälle aufbauen; normative Freigabe erst nach echter Gegenprüfung.
5. Danach getrennte Fachblöcke Flächenheizung bzw. Wärmepumpen-/Bivalenzbewertung.
