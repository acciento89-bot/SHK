# HeizBalance – Hydraulischer Netzbaum & zentrale Pfadhydraulik

## Status
Foundation Batches 31–35 führen eine optionale, rückwärtskompatible Netzbaum- und Pfadstruktur für gemeinsame hydraulische Verteilungen ein. Seit Batch 35 liegt neue gemeinsame Rohrgeometrie kanonisch direkt am Netzsegment.

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
Ein gemeinsamer Rohrabschnitt gehört fachlich zu genau einem Netzsegment und wird im zentralen Pfadmodus als physischer Shared-Edge dieses Segments gerechnet.

Harte Regeln:
- Jeder zentrale Shared-Rohrabschnitt wird in seinem Netzsegment genau einmal hydraulisch gerechnet.
- Mehrere reale, serielle Rohrabschnitte dürfen demselben Segment zugeordnet sein; sie werden innerhalb dieses Segments seriell addiert.
- Ein Verbraucherpfad besteht aus allen Segmenten von der Wurzel bis zum direkt zugeordneten Segment.
- Vollständiger Verbraucher-Kreis-Δp = Summe der vollständigen Shared-Segmentverluste dieses Pfads + terminaler Heizflächen-Anbindungsverlust + explizite terminale Bauteilverluste.
- Druckverluste paralleler Verbraucherpfade werden weiterhin **nicht** addiert. Für den Pumpenbedarf ist der höchste vollständige Verbraucherpfad maßgebend.
- Ein gemeinsamer Hauptstrang darf in vielen Verbraucherpfaden vorkommen, wird physisch aber nur einmal gespeichert/berechnet.
- Fehlende Fluidwerte, Segment-Q, Rohrmaße oder ζ blockieren den vollständigen Segment- und damit Verbraucherpfad-Δp. Fehlend bedeutet nie 0.
- Ein Segment ohne eigene Rohrabschnitte darf als reine Topologie-/Verzweigungsgruppe 0 kPa beitragen.

### Terminale Trennung
Im zentralen Pfadmodus werden an der Heizfläche ausschließlich Rohrabschnitte mit Rolle `Heizflächen-Anbindung` terminal gerechnet. Gemeinsame Verteilabschnitte werden nicht nochmals im Heizflächenkreis addiert.

Die hydraulischen Bauteilverluste der konkreten Heizfläche – z. B. Thermostatventil, Rücklaufverschraubung oder Heizflächenverlust – bleiben terminal und werden nur diesem Verbraucher zugerechnet.

## Batch 35 – Rohrgeometrie direkt am Netzsegment
`HeizBalanceHydraulicNetwork.Segment` besitzt optional `pipeSections`.

Diese Sammlung ist der kanonische Speicherort für neue gemeinsame Rohrgeometrie:
- Rolle wird auf `Gemeinsame Verteilung` normalisiert,
- `networkSegmentID` ist innerhalb des Segments nicht erforderlich und wird entfernt,
- `explicitDesignVolumeFlowLPH` wird nicht gespeichert,
- `volumeFlowSource` wird nicht gespeichert,
- ID, Bezeichnung, Innendurchmesser, hydraulische Länge, absolute Rauheit, ζ-Summe und Notiz bleiben physische Fachdaten des Abschnitts.

Der Abschnitts-Q ist **immer** der aktuell aus den zugeordneten Verbrauchern berechnete Segment-Q. Es gibt bewusst kein zweites manuelles Q-Feld und keine versteckte DN→Innendurchmesser-Annahme.

### Direkte Segment-Erfassung
Im Editor eines Netzsegments können gemeinsame Rohrabschnitte direkt angelegt, geöffnet, geändert und gelöscht werden.

Angezeigt werden:
- automatischer Segment-Q,
- Innendurchmesser,
- hydraulische Länge,
- absolute Rauheit,
- ζ-Summe,
- aktueller bekannte/vollständige Segment-Δp.

Ändert sich ein nachgelagerter Verbraucher-Q, wird beim nächsten Rechenlauf automatisch derselbe physische Segmentabschnitt mit dem neuen Segment-Q bewertet. Es muss kein Rohr-Q synchronisiert werden.

### Legacy-Migration
Alte Batch-31/34-Projekte können weiterhin gemeinsame Rohrabschnitte unter einer Heizfläche enthalten.

Für bereits mit einem gültigen Netzsegment verknüpfte Altabschnitte steht eine explizite Migration zur Verfügung:
- derselbe Abschnitt wird in `segment.pipeSections` übernommen,
- ID, Name, Innendurchmesser, Länge, Rauheit, ζ und Notiz bleiben erhalten,
- Legacy-`networkSegmentID`, gespeicherter Abschnitts-Q und dessen Quelle werden entfernt,
- die ursprüngliche Heizflächen-Kopie wird im selben Vorgang entfernt,
- dadurch kann derselbe physische Abschnitt nach der Migration nicht doppelt gerechnet werden.

Unverknüpfte Legacy-Shared-Rohre werden **nicht** automatisch migriert, weil ohne fachliche Segmentzuordnung kein Ziel geraten werden darf.

### Rückwärtskompatibilität
- `pipeSections` am Segment ist optional; alte `hydraulic-network-v1`-Projektdateien ohne dieses Feld bleiben decodierbar.
- Bereits verknüpfte Legacy-Shared-Rohre bleiben bis zur expliziten Migration rechenbar.
- Unverknüpfte Legacy-Shared-Rohre bleiben gespeichert, werden im aktiven zentralen Pfadmodus aber nicht zusätzlich eingerechnet.
- Die alte Q-Synchronisierung gilt nur noch für verknüpfte Legacy-Rohre unter Heizflächen.

## Stale-/Vollständigkeitsschutz
Für segment-eigene Rohrgeometrie ist der live berechnete Segment-Q maßgebend. Es existiert kein gespeicherter Q, der veralten könnte.

Für den Batch-31-Kompatibilitätslayer gilt weiterhin: gespeicherter und aktuell berechneter Netz-Q eines verknüpften Legacy-Rohrs müssen innerhalb 0,05 l/h übereinstimmen.

Für vollständige Ergebnisse gelten unverändert harte Gates:
- unvollständiger Segment-Q → Segment-Δp offen,
- fehlende Rohrgeometrie/ζ → Segment-Δp offen,
- unzugeordneter Verbraucher → Verbraucherpfad offen,
- unvollständige terminale Anbindung/Bauteilverluste → Verbraucherpfad offen,
- mindestens ein relevanter offener Verbraucherpfad → Pumpen-Betriebspunkt nicht vollständig,
- bestehende Pumpenentscheidung wird bei geändertem Betriebspunkt `neu bewerten`.

## Referenznormalisierung
Bereinigt werden nur ungültige Referenzen und nicht-kanonische Metadaten:
- gelöschte Heizflächen aus Segmenten,
- ungültige Elternreferenzen,
- Links auf gelöschte Segmente,
- Netzlinks an normalen Heizflächen-Anbindungen,
- Legacy-Q-/Linkmetadaten innerhalb segment-eigener Rohrgeometrie.

Physische Rohr-/ζ-/Notizdaten werden dabei nicht erfunden oder gelöscht.

## UI
`Hydraulischer Netzbaum` erlaubt:
- Segmente anlegen/löschen/verschachteln,
- direkte Verbraucher zuordnen,
- gemeinsame Rohrabschnitte direkt im Segment anlegen/bearbeiten/löschen,
- automatischen Segment-Q und Segment-Δp sehen,
- zentralen Pfadmodus erkennen,
- Legacy-Shared-Rohre erkennen,
- bereits verknüpfte Alt-Rohre explizit in ihre Netzsegmente migrieren.

`Netzpfade & Druckverluste` zeigt:
- Anzahl direkt am Segment gespeicherter und verbleibender Legacy-Rohre,
- Segment-Q,
- bekannte/vollständige Segment-Δp,
- Verbraucherpfad `Wurzel → … → Zielsegment`,
- Shared-, terminale und gesamte bekannte/vollständige Kreisverluste.

## Reproduzierbarkeit / PDF
`technical-hydraulic-network-v1` bleibt das Berichtsschema. Neue Felder bleiben optional, damit ältere Archive decodierbar bleiben.

Neue Exporte frieren zusätzlich ein:
- `hydraulic-network-path-v1`,
- zentralen Modusstatus,
- Anzahl direkt segment-eigener, Legacy-verknüpfter und unverknüpfter Shared-Rohre,
- Gesamt-Rohrabschnittszahl und direkt segment-eigene Anzahl je Segment,
- bekannte/vollständige Segment-Δp,
- vollständige Verbraucherpfade mit Shared-/Terminal-/Gesamt-Δp.

Produktionsbericht: acht gemeinsam datierte Snapshots inklusive Netzbaum/Pfadhydraulik.

`Technischer Bericht & PDF`: sechs gemeinsam datierte Snapshots inklusive Netzbaum/Pfadhydraulik.

## Technischer Pfad-Referenzfall
Topologie:
- Hauptstrang → EG
- Hauptstrang → OG
- Wohnzimmer am EG
- Schlafzimmer am OG

Wenn der Hauptstrang direkt im Segment erfasst wird und EG/OG jeweils ihre eigenen Segment-Rohrabschnitte besitzen:
- Wohnzimmer-Kreis = Hauptstrang-Δp + EG-Strang-Δp + Wohnzimmer-Terminal-Δp,
- Schlafzimmer-Kreis = Hauptstrang-Δp + OG-Strang-Δp + Schlafzimmer-Terminal-Δp.

Der Hauptstrang wird dabei in beiden **logischen Pfaden** benutzt, aber nur einmal als physische Geometrie im Hauptstrang-Segment erfasst.

Mehrere reale Rohrabschnitte innerhalb desselben Segments werden seriell addiert. Die Regression prüft, dass `Δp Segment = Δp Abschnitt A + Δp Abschnitt B` und anschließend nur einmal in den Verbraucherpfad eingeht.

Fehlt bei einem Segmentabschnitt die ζ-Summe:
- gerader bekannter Rohrverlust bleibt sichtbar,
- vollständiger Segment-Δp ist offen,
- alle nachgelagerten Verbraucherpfade bleiben vollständig offen,
- kein vollständiger Pumpenbetriebspunkt darf freigegeben werden.

## Verifikation
- CI #295: Batch 31 final grün.
- CI #309: Batches 32–34 final grün.
- **CI #317: Batch-35-Codehead `bbf0c7c6c09894d6a55e3e4b7f6b531680e6d431` vollständig grün – Core, komplette iOS-Debug-Matrix, HeizBalance Debug und echter HeizBalance Release-Simulator-Build.**
