# HeizBalance – Hydraulischer Netzbaum & zentrale Pfadhydraulik

## Status
Foundation Batches 31–34 führen eine optionale, rückwärtskompatible Netzbaum- und Pfadstruktur für gemeinsame hydraulische Verteilungen ein.

- Q-Rechenprofil: `hydraulic-network-tree-v1`
- Pfad-/Druckverlustprofil: `hydraulic-network-path-v1`
- Persistenzschema: `hydraulic-network-v1`
- Berichtsschema: `technical-hydraulic-network-v1`

Die gesamte Funktion ist technische Vorbereitung und kein Verfahren-B-, GEG-/BEG- oder normativer hydraulischer Abgleich-Nachweis.

## Batch 31 – Baum- und Summenstromregeln
- Heizflächen sind terminale Verbraucher.
- Ein Verbraucher darf genau einem direkten, tiefsten Segment zugeordnet sein.
- Segmente dürfen direkte Verbraucher und Kindsegmente enthalten.
- Eltern summieren automatisch alle nachgelagerten Verbraucherströme.
- Fehlender terminaler Q lässt bekannte Zwischensummen sichtbar, blockiert aber den vollständigen Segment-Q.
- Doppelte direkte Verbraucherzuordnung, Selbstreferenz, unbekannte Eltern und Zyklen sind ungültig.
- Unzugeordnete Verbraucher bleiben sichtbar und werden nicht still zugewiesen.

### Q-Referenzfall
- Wohnzimmer: 100 l/h
- Bad: 150 l/h
- Schlafzimmer: 200 l/h
- EG = 250 l/h
- OG = 200 l/h
- Hauptstrang = 450 l/h

Fehlt Bad-Q:
- EG-Zwischensumme = 100 l/h
- vollständiger EG-Q offen
- vollständiger Hauptstrang-Q offen.

## Batches 32–34 – zentrale Shared-Edges & Verbraucherpfade
Ein Rohrabschnitt mit Rolle `Gemeinsame Verteilung` und gesetzter `networkSegmentID` ist im zentralen Pfadmodus ein **physischer Shared-Edge** des zugeordneten Netzsegments.

Harte Regeln:
- Jeder verknüpfte Shared-Rohrabschnitt wird in seinem Netzsegment genau einmal hydraulisch gerechnet.
- Mehrere reale, serielle Rohrabschnitte dürfen demselben Segment zugeordnet sein; sie werden innerhalb dieses Segments seriell addiert.
- Ein Verbraucherpfad besteht aus allen Segmenten von der Wurzel bis zum direkt zugeordneten Segment.
- Vollständiger Verbraucher-Kreis-Δp = Summe der vollständigen Shared-Segmentverluste dieses Pfads + terminaler Heizflächen-Anbindungsverlust + explizite terminale Bauteilverluste.
- Druckverluste paralleler Verbraucherpfade werden weiterhin **nicht** addiert. Für den Pumpenbedarf ist der höchste vollständige Verbraucherpfad maßgebend.
- Ein gemeinsamer Hauptstrang darf in vielen Verbraucherpfaden vorkommen, wird physisch aber nur einmal als Edge gespeichert/berechnet.
- Fehlende Fluidwerte, Segment-Q, Rohrmaße oder ζ blockieren den vollständigen Segment- und damit Verbraucherpfad-Δp. Fehlend bedeutet nie 0.
- Ein Segment ohne eigene Rohrabschnitte darf als reine Topologie-/Verzweigungsgruppe 0 kPa beitragen.

### Terminale Trennung
Im zentralen Pfadmodus werden an der Heizfläche ausschließlich Rohrabschnitte mit Rolle `Heizflächen-Anbindung` terminal gerechnet. Verknüpfte `Gemeinsame Verteilung`-Abschnitte werden nicht nochmals im Heizflächenkreis addiert.

Die hydraulischen Bauteilverluste der konkreten Heizfläche – z. B. Thermostatventil, Rücklaufverschraubung oder Heizflächenverlust – bleiben terminal und werden nur diesem Verbraucher zugerechnet.

### Legacy-/Kompatibilitätsregel
Ohne einen einzigen zentral verknüpften Shared-Rohrabschnitt bleibt die bisherige Legacy-/Manuellogik aktiv.

Sobald mindestens ein zentraler Shared-Edge vorhanden ist:
- zentral verknüpfte Shared-Rohre werden über `hydraulic-network-path-v1` gerechnet,
- unverknüpfte alte Shared-Rohre bleiben im Projekt erhalten,
- unverknüpfte Legacy-Shared-Rohre werden **nicht zusätzlich** in den zentralen Verbraucherpfad eingerechnet, damit kein physischer Strang doppelt zählt,
- die UI weist auf verbleibende Legacy-Rohre hin, damit diese fachlich geprüft, verknüpft oder entfernt werden können.

## Gemeinsame Rohrabschnitte / Q-Synchronisierung
`HeizBalancePipeSection.networkSegmentID` ist optional und nur für `Gemeinsame Verteilung` fachlich gültig.

Ohne Link bleibt der bisherige manuelle `explicitDesignVolumeFlowLPH` für Legacyprojekte gültig.

Mit Link:
- vollständiger Segment-Q wird zusätzlich als Abschnitts-Q synchronisiert,
- Rohrmaße, Länge, Rauheit, ζ und Verbraucher-Q werden nicht verändert,
- der zentrale Pfad-Rechenkern verwendet direkt den aktuell berechneten Segment-Q,
- die gespeicherte Q-Synchronisierung bleibt für Nachvollziehbarkeit und ältere Ansichten bestehen.

Synchronisierung erfolgt:
- beim Verknüpfen,
- bei Baum-/Verbraucheränderungen,
- beim Öffnen des Netzbaum-Workspace nach Referenznormalisierung,
- beim normalen Projektspeichern.

## Stale-/Vollständigkeitsschutz
Stored und aktuell berechneter Netz-Q müssen im Batch-31-Kompatibilitätslayer innerhalb 0,05 l/h übereinstimmen.

Im zentralen Pfadmodus ist für die fachliche Freigabe jedoch der direkt berechnete Pfad maßgebend:
- unvollständiger Segment-Q → Segment-Δp offen,
- fehlende Rohrgeometrie/ζ → Segment-Δp offen,
- unzugeordneter Verbraucher → Verbraucherpfad offen,
- unvollständige terminale Anbindung/Bauteilverluste → Verbraucherpfad offen,
- mindestens ein offener Verbraucherpfad → Pumpen-Betriebspunkt nicht vollständig,
- bestehende Pumpenentscheidung wird dadurch `neu bewerten`.

## Referenznormalisierung
Bereinigt werden nur verwaiste Referenzen:
- gelöschte Heizflächen aus Segmenten,
- ungültige Elternreferenzen,
- Links auf gelöschte Segmente,
- Netzlinks an normalen Heizflächen-Anbindungen.

Rohr-/ζ-/Fachdaten werden dabei nicht erfunden oder gelöscht.

## UI
`Hydraulischer Netzbaum` im Projekt-Cockpit erlaubt:
- Segmente anlegen/löschen/verschachteln,
- direkte Verbraucher zuordnen,
- gemeinsame Rohrabschnitte mit Segmenten koppeln,
- vollständige/teilweise Segment-Q sehen,
- zentralen Shared-Edge-Modus erkennen,
- Legacy-/unverknüpfte Shared-Rohre erkennen.

`Netzpfade & Druckverluste` zeigt:
- zentral verknüpfte Shared-Rohre und Legacyanzahl,
- Segment-Q,
- bekannte/vollständige Segment-Δp,
- Verbraucherpfad `Wurzel → … → Zielsegment`,
- Shared-, terminale und gesamte bekannte/vollständige Kreisverluste.

## Reproduzierbarkeit / PDF
`technical-hydraulic-network-v1` bleibt das Berichtsschema. Batch-32+-Pfadfelder wurden ausschließlich optional ergänzt, damit ältere Batch-31-Archive weiterhin decodierbar bleiben.

Neue Exporte frieren zusätzlich ein:
- `hydraulic-network-path-v1`,
- zentralen Modusstatus,
- Anzahl zentraler und Legacy-Shared-Rohre,
- Rohrabschnittszahl und Δp je Segment,
- vollständige Verbraucherpfade mit Shared-/Terminal-/Gesamt-Δp.

Produktionsbericht: acht gemeinsam datierte Snapshots inklusive Netzbaum/Pfadhydraulik.

`Technischer Bericht & PDF`: sechs gemeinsam datierte Snapshots inklusive Netzbaum/Pfadhydraulik.

## Technischer Pfad-Referenzfall
Topologie:
- Hauptstrang → EG
- Hauptstrang → OG
- Wohnzimmer am EG
- Schlafzimmer am OG

Wenn der Hauptstrang einmal zentral erfasst wird und EG/OG jeweils ihren eigenen zentralen Strang besitzen:
- Wohnzimmer-Kreis = Hauptstrang-Δp + EG-Strang-Δp + Wohnzimmer-Terminal-Δp,
- Schlafzimmer-Kreis = Hauptstrang-Δp + OG-Strang-Δp + Schlafzimmer-Terminal-Δp.

Der Hauptstrang wird dabei in beiden **logischen Pfaden** benutzt, aber nur einmal als physischer Edge erfasst und je Netzsegment einmal hydraulisch berechnet.

Fehlt beim Hauptstrang die ζ-Summe:
- gerader bekannter Rohrverlust bleibt sichtbar,
- vollständiger Hauptstrang-Δp ist offen,
- beide nachgelagerten Verbraucherpfade bleiben vollständig offen,
- kein vollständiger Pumpenbetriebspunkt darf freigegeben werden.
