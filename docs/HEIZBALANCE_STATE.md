# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung, schnelle Vor-Ort-Aufnahme und reproduzierbare Baustellen-/Übergabedokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12
- Aktueller Stand: **Foundation Batches 36–38 – segment-eigene Rohre & zentrale Netzbauteile**

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
- `docs/HEIZBALANCE_SHARED_NETWORK_COMPONENTS.md`

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

### Batch-31-Verifikation
- **CI #295: finaler Batch-31-Head `47f9962519b1686d4d6d0524d34d1eaa733ac0d1` vollständig grün.**

## Batches 32–34 – zentrale Shared-Edges & Path-Hydraulik
Rechenprofil:
- `hydraulic-network-path-v1`

### Pfadlogik
- Gemeinsame physische Rohrstrecken werden zentral pro Netzsegment gerechnet.
- Mehrere reale serielle Abschnitte innerhalb eines Segments werden seriell addiert.
- Terminal gerechnet werden ausschließlich `Heizflächen-Anbindung` plus terminale hydraulische Bauteilverluste.
- Verbraucherpfad = Wurzel → direkt zugeordnetes Zielsegment + terminaler Kreis.
- Gesamt-Q = Summe terminaler Verbraucher-Q.
- Maßgebender Netz-Δp = höchster vollständiger Verbraucherpfad.
- Parallele Verbraucherpfade werden nicht miteinander addiert.
- Fehlende Fluid-/Rohr-/Q-/ζ-Daten blockieren vollständige Segment-/Pfadwerte.
- Einstellliste, Systemaggregation und Pumpenbetriebspunkt verwenden dieselbe Pfadwahrheit.

### Batch-32–34-Verifikation
- **CI #309: finaler Head `d7e4797f00ce94a19b6b4c5616ab92339ead30d6` vollständig grün – Core, komplette Debug-iOS-Matrix, HeizBalance Debug und echter Release-Build.**

## Batch 35 – segment-eigene gemeinsame Rohrgeometrie
### Kanonischer Speicherort
`HeizBalanceHydraulicNetwork.Segment` besitzt optional `pipeSections`.

Neue gemeinsame Rohrstrecken werden direkt dort erfasst. Segment-eigene Rohrabschnitte speichern nur ihre physischen Fachdaten:
- ID / Bezeichnung
- Innendurchmesser
- hydraulische Länge
- absolute Rauheit
- ζ-Summe
- Notiz.

Bewusst nicht segment-eigen gespeichert werden:
- manueller Abschnitts-Q
- Q-Quelle
- `networkSegmentID`.

Der Rechen-Q ist immer der live aggregierte Segment-Q aus den zugeordneten Heizflächen. Damit gibt es für neue Shared-Edges keine zweite, potenziell veraltete Q-Wahrheit.

### Segment-Editor
Im `Hydraulischer Netzbaum` kann jedes Segment seine gemeinsamen Rohrabschnitte direkt verwalten:
- hinzufügen
- bearbeiten
- löschen
- automatischen Segment-Q sehen
- bekannten/vollständigen Segment-Δp sehen.

Der Rohr-Editor verlangt expliziten Innendurchmesser; es existiert weiterhin keine DN→ID-Automatik.

### Pfadengine
`hydraulicNetworkPathState()` bevorzugt segment-eigene Geometrie als neuen kanonischen Pfad. Für Altprojekte werden bereits verknüpfte Legacy-Shared-Rohre unter Heizflächen weiterhin zusätzlich eingelesen, bis sie explizit migriert wurden.

Zentraler Pfadmodus ist aktiv, sobald mindestens ein segment-eigener oder verknüpfter Legacy-Shared-Abschnitt vorhanden ist.

### Explizite Legacy-Migration
`migrateLinkedSharedPipesIntoNetworkSegments()` verschiebt bereits fachlich verknüpfte Alt-Rohre in das zugehörige Netzsegment.

Erhalten bleiben:
- ID
- Name
- Innendurchmesser
- Länge
- Rauheit
- ζ
- Notiz.

Entfernt werden Legacy-Metadaten:
- `networkSegmentID`
- `explicitDesignVolumeFlowLPH`
- `volumeFlowSource`.

Die ursprüngliche Heizflächen-Kopie wird im selben Vorgang entfernt. Dadurch existiert nach der Migration genau eine physische Geometriequelle und keine Doppelzählung.

Unverknüpfte Alt-Rohre werden nicht automatisch verschoben; HeizBalance errät kein Zielsegment.

### Persistenz / Rückwärtskompatibilität
- `Segment.pipeSections` ist optional.
- Bestehendes Schema `hydraulic-network-v1` bleibt lesbar.
- Alte Projekte ohne Segment-Geometrie öffnen unverändert.
- Alte verknüpfte Shared-Rohre bleiben bis zur expliziten Migration rechenbar.
- Legacy-Q-Synchronisierung gilt nur noch für diese alten Heizflächen-Rohre.

### Snapshot / PDF
`technical-hydraulic-network-v1` bleibt bewusst bestehen; neue Felder sind optional.

Neu dokumentiert werden:
- Anzahl direkt segment-eigener Rohrabschnitte,
- Anzahl verbleibender Legacy-verknüpfter/unverknüpfter Abschnitte,
- Gesamt- und direkt segment-eigene Rohranzahl je Segment,
- Segment-Q / bekannter-vollständiger Δp,
- Verbraucherpfade mit Shared-/Terminal-/Gesamt-Δp.

Der Netzbaum-PDF-Teil kennzeichnet verbleibende Legacy-Geometrie ausdrücklich als Altformat und migriebar.

### Core-Regression
`testMultiplePhysicalSectionsInsideOneSegmentAreAddedInSeries` prüft:
- zwei physische Rohrabschnitte im selben Segment,
- beide werden mit demselben Segment-Q gerechnet,
- Segment-Δp = Δp A + Δp B,
- Verbraucherpfad = Segment-Δp + Terminal-Δp,
- das Segment wird im Pfad genau einmal gezählt.

### Batch-35-Verifikation
- **CI #317: Codehead `bbf0c7c6c09894d6a55e3e4b7f6b531680e6d431` vollständig grün.**
- **CI #320: finaler Batch-35-Handoff-Head `a11a6f647064e72b0f2ca4b58fc0ace976e43e9f` vollständig grün – Core, komplette Debug-iOS-Matrix, HeizBalance Debug und echter HeizBalance Release-Simulator-Build.**

## Batches 36–38 – zentrale Netzarmaturen & Bauteilverluste
### Persistenz
`HeizBalanceHydraulicNetwork.Segment` besitzt zusätzlich optional:
- `hydraulicLossComponents`
- `hydraulicComponentAssessmentComplete`.

Die Felder sind optional; alte `hydraulic-network-v1` Projekte bleiben rückwärtskompatibel decodierbar.

### Zentrale Bauteilarten
Der Netzsegment-Editor erlaubt bewusst generische zentrale Typen:
- Strangregulierventil
- Differenzdruckregler
- Wärmemengenzähler
- Schmutzfänger / Filter
- Rückschlagventil
- Verteiler / Sammler
- Armatur / Bauteil
- Sonstiger Verlust.

Thermostatventil und Rücklaufverschraubung bleiben terminale Heizflächenbauteile.

### Fachlogik
Ein zentraler Bauteilverlust wird ausschließlich mit explizitem Δp und dokumentierter Quelle erfasst. HeizBalance schätzt keinen Δp aus Bauteilart oder Namen und erzeugt keine Herstellerkennlinie.

Im bestehenden Profil `hydraulic-network-path-v1` gilt nun transparent:

`Segment-Δp = Rohr-Δp + zentrale Bauteil-Δp`

und weiterhin:

`Verbraucherpfad = Summe serieller Segment-Δp + terminaler Heizflächenkreis`.

Parallele Verbraucherpfade werden nicht miteinander addiert.

### Harte Vollständigkeitsgates
- fehlender zentraler Bauteil-Δp bleibt offen,
- bekannte Bauteil-Teilsumme bleibt sichtbar,
- bei vorhandenen zentralen Bauteilen ist eine ausdrückliche Vollständigkeitsbestätigung erforderlich,
- unbestätigte bzw. unvollständige zentrale Bauteilaufnahme blockiert vollständigen Segment-Δp,
- damit bleiben auch Verbraucherpfad und Pumpenbetriebspunkt unvollständig,
- ein Segment ohne zentrale Bauteile benötigt keine zusätzliche Bestätigung.

### UI
Im Netzsegment-Editor stehen jetzt gemeinsam:
- automatischer Segment-Q,
- bekannter Rohr-Δp,
- bekannter zentraler Bauteil-Δp,
- vollständiger Segment-Δp,
- segment-eigene Rohre,
- zentrale Armaturen/Bauteile,
- Vollständigkeitsbestätigung der zentralen Bauteilaufnahme.

Der zentrale Bauteil-Editor zeigt den Segment-Q nur lesend an und verlangt einen expliziten Δp/Quelle.

### Core-Regressionen
`HeizBalanceHydraulicNetworkComponentPathTests` prüft:
1. 2 kPa + 3 kPa zentrale Bauteile + 4 kPa terminal = 9 kPa vollständiger Pfad.
2. Fehlender zentraler Bauteil-Δp erhält bekannte Teilsumme, blockiert aber kompletten Pfad.
3. Nicht bestätigte zentrale Bauteilaufnahme blockiert kompletten Pfad trotz vorhandener Einzelwerte.

### Snapshot / PDF
`technical-hydraulic-network-v1` bleibt bestehen und wird nur optional erweitert um:
- zentrale Bauteilanzahl,
- bekannten Rohr-Δp,
- bekannten Bauteil-Δp,
- Bauteilabdeckung vollständig/offen,
- Anzahl fehlender zentraler Bauteil-Δp.

Der Netzbaum-PDF-Teil zeigt beide Δp-Anteile getrennt und nennt bei unvollständigem Segment die konkrete Ursache.

Ausführlicher Handoff:
- `docs/HEIZBALANCE_SHARED_NETWORK_COMPONENTS.md`

### Main-Synchronisierung
Der zwischenzeitlich auf `main` gelandete Design-Commit `19f2ddb47d3ae44149695cf4c2fc284f4461b7da` wurde in den Feature-Branch übernommen. Die fünf dort neu gestalteten bestehenden SHK-Apps bleiben damit erhalten; HeizBalance-spezifische Änderungen wurden nicht überschrieben.

### Batches-36–38-Verifikation
- Finaler vollständiger CI-Nachweis auf dem aktuellen Head ist noch ausstehend; erst Core + komplette Debug-iOS-Matrix + HeizBalance Debug + echter Release-Build dürfen diesen Block als grün markieren.

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
- #295 Batch 31
- #309 Batches 32–34
- #317/#320 Batch 35.

## Bewusst noch gesperrt
- normative Heizlast / Verfahren B / GEG-/BEG-Konformität
- automatische Ventilvoreinstellung
- automatische konkrete Heizkörper-/Pumpenproduktempfehlung
- Pumpenkennlinien-Extrapolation
- EEI-/ErP-/Hersteller-Wirkungsgradclaims
- ungeprüfte Roh-VDI-Herstellerparser
- echte Wärmepumpenauslegung/COP/Bivalenz
- Flächenheizung nach DIN EN 1264.

## Nächste große Fachblöcke nach Batches 36–38
1. Realistische große Netzbäume mit 20–50 Räumen/Verbrauchern praktisch stressen: UI-Dichte, Navigation, Performance und PDF-Seitenumbrüche.
2. Netzbaum-Aufnahme weiter ergonomisieren: Segment-/Teilbaum kopieren oder verschieben nur mit sicheren Reset-/ID-Regeln, keine fertigen Q-/Δp-Entscheidungen klonen.
3. Hersteller-/Lizenzquellen rechtlich klären und die bereits vorhandenen Heizkörper-/Ventil-/Pumpenadapter mit autorisierten Produktdaten produktiv befüllen.
4. Normative Heizlast-Spezifikation und belastbare rechtmäßig verfügbare Referenzfälle getrennt aufbauen.
5. Erst danach Flächenheizung bzw. Wärmepumpen-/Bivalenzmodule freigeben.
