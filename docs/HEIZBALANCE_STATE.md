# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung, schnelle Vor-Ort-Aufnahme und reproduzierbare Baustellen-/Übergabedokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12
- Aktueller Stand: **Foundation Batch 31 – Hydraulischer Netzbaum**

## Compliance-Grenzen
- Keine proprietären DIN-/VDI-/VdZ-Inhalte im Repository.
- Keine Norm-Heizlast-, Verfahren-B-, GEG-/BEG-, Wärmepumpen- oder Herstellerfreigabe ohne getrennte vollständige fachliche Validierung.
- Keine versteckten Fluid-, Rohr-, U-Wert-, Luftwechsel-, Pumpenreserve- oder Herstellerannahmen.
- Fehlende/veraltete technische Werte bleiben offen statt geschätzt zu werden.

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

## Batch 31 – Hydraulischer Netzbaum
Schemata:
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

Technischer Referenzfall:
- Wohnzimmer 100 l/h
- Bad 150 l/h
- Schlafzimmer 200 l/h
- EG 250 l/h
- OG 200 l/h
- Hauptstrang 450 l/h.

### Shared-Pipe-Verknüpfung
- `networkSegmentID` optional an gemeinsamen Rohrabschnitten.
- Ohne Link bleibt manueller Summen-Q gültig.
- Mit Link wird vollständiger Segment-Q auf den Rohrabschnitt synchronisiert.
- Rohrgeometrie, Länge, Rauheit, ζ und Verbraucher-Q werden dabei nicht verändert.

### Auto-Sync
Synchronisierung erfolgt:
- beim Verknüpfen,
- bei Baum-/Verbraucheränderung,
- beim Öffnen des Netzbaum-Workspace,
- beim normalen Projektspeichern.

### Stale-Schutz
Stored/calculated Q müssen innerhalb 0,05 l/h übereinstimmen.

Bei Abweichung/offenem Netz-Q:
- `Netzbaum-Q neu synchronisieren`
- Kreis-Δp für Systemaggregation nicht vollständig
- Einstellliste nicht vollständig
- Pumpen-Betriebspunkt nicht vollständig
- bestehende Pumpenentscheidung neu zu bewerten.

### Referenznormalisierung
Verwaiste Verbraucher-, Elternsegment- und Rohrlinks werden bereinigt. Hydraulische Fachdaten werden dabei nicht erfunden oder gelöscht.

### UI
`Hydraulischer Netzbaum` im Projekt-Cockpit:
- Segmente anlegen/löschen/verschachteln
- Verbraucher zuordnen
- gemeinsame Rohrabschnitte koppeln
- Segment-Q / Zwischenstände sehen
- stale Verknüpfungen erkennen/synchronisieren.

### Bericht
Produktionsbericht jetzt 8 gemeinsam datierte Snapshots:
1. `technical-handover-v1`
2. `technical-report-v1`
3. `technical-hydraulic-network-v1`
4. `technical-low-temperature-v1`
5. `technical-temperature-scenarios-v1`
6. `technical-radiator-replacements-v1`
7. `technical-pump-curves-v1`
8. `technical-adjustment-list-v1`

Separater `Technischer Bericht & PDF`: 6 gemeinsam datierte Snapshots inkl. Netzbaum.

## Release-Gate
- komplette iOS-Debug-Matrix
- Core-Tests
- separater echter HeizBalance Release-Simulator-Build
- Swift-6-Concurrency aktiv
- `cancel-in-progress` für PR-Zwischenstände.

Historisch grün:
- #231 Batch 25
- #250/#256 Batches 26–29
- #266/#268 Batch 30.

Batch 31 gilt erst als abgeschlossen, wenn der **endgültige Branch-Head** nach Code + Handoff-Doku komplett grün ist.

## Bewusst noch gesperrt
- normative Heizlast / Verfahren B / GEG-/BEG-Konformität
- automatische Ventilvoreinstellung
- automatische konkrete Heizkörper-/Pumpenproduktempfehlung
- Pumpenkennlinien-Extrapolation
- EEI-/ErP-/Hersteller-Wirkungsgradclaims
- ungeprüfte Roh-VDI-Herstellerparser
- echte Wärmepumpenauslegung/COP/Bivalenz
- Flächenheizung nach DIN EN 1264.

## Nächster großer Fachblock
**Edge-/Path-Hydraulik:** gemeinsame Rohrstrecken nur einmal geometrisch erfassen, Verbraucherpfade aus dem Netz ableiten und Druckverluste entlang dieser Pfade automatisch zusammensetzen. Bis dahin wird diese Topologie nicht vorgetäuscht.
