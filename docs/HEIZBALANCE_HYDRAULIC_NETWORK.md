# HeizBalance – Hydraulischer Netzbaum

## Status
Foundation Batch 31 führt eine optionale, rückwärtskompatible Netzbaum-Struktur für gemeinsame hydraulische Verteilungen ein.

- Rechenprofil: `hydraulic-network-tree-v1`
- Persistenzschema: `hydraulic-network-v1`
- Berichtsschema: `technical-hydraulic-network-v1`

Der Netzbaum ist technische Vorbereitung und kein Verfahren-B-, GEG-/BEG- oder normativer hydraulischer Abgleich-Nachweis.

## Baumregeln
- Heizflächen sind terminale Verbraucher.
- Ein Verbraucher darf genau einem direkten, tiefsten Segment zugeordnet sein.
- Segmente dürfen direkte Verbraucher und Kindsegmente enthalten.
- Eltern summieren automatisch alle nachgelagerten Verbraucherströme.
- Fehlender terminaler Q lässt bekannte Zwischensummen sichtbar, blockiert aber den vollständigen Segment-Q.
- Doppelte direkte Verbraucherzuordnung, Selbstreferenz, unbekannte Eltern und Zyklen sind ungültig.
- Unzugeordnete Verbraucher bleiben sichtbar und werden nicht still zugewiesen.

## Referenzfall
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

Die Core-Tests decken diese Fälle sowie Doppelzuordnung, Zyklus, unbekannte Eltern und unzugeordnete Verbraucher ab.

## Gemeinsame Rohrabschnitte
`HeizBalancePipeSection.networkSegmentID` ist optional und nur für `Gemeinsame Verteilung` fachlich gültig.

Ohne Link bleibt der bisherige manuelle `explicitDesignVolumeFlowLPH` gültig.

Mit Link:
- vollständiger Segment-Q wird als Abschnitts-Q synchronisiert,
- Rohrmaße, Länge, Rauheit, ζ und Verbraucher-Q werden nicht verändert,
- die Herkunft wird über Segment/Netzbaum-Snapshot dokumentiert.

## Auto-Sync
Vollständige Netz-Q werden synchronisiert:
- beim Verknüpfen,
- bei Baum-/Verbraucheränderungen,
- beim Öffnen des Netzbaum-Workspace nach Referenznormalisierung,
- beim normalen Projektspeichern.

Ein manueller Re-Sync bleibt verfügbar.

## Stale-Schutz
Stored und aktuell berechneter Netz-Q müssen innerhalb 0,05 l/h übereinstimmen.

Bei offenem oder abweichendem Q:
- `neu synchronisieren`,
- der betroffene vollständige Kreis-Δp wird nicht für die Systemaggregation freigegeben,
- die Einstellliste zeigt den Netzbaumfehler,
- der technische Pumpen-Betriebspunkt bleibt unvollständig,
- eine bestehende Pumpenentscheidung wird neu zu bewerten.

Damit kann ein alter Shared-Flow nach einer Laständerung nicht unbemerkt weiterverwendet werden.

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
- gemeinsame Rohrabschnitte koppeln,
- vollständige/teilweise Segment-Q sehen,
- stale Links erkennen und synchronisieren.

## Reproduzierbarkeit / PDF
`technical-hydraulic-network-v1` friert ein:
- Profilversion und Hierarchie,
- direkte/nachgelagerte Verbraucher,
- bekannte/vollständige Segment-Q,
- unresolved Verbraucher,
- Rohrverknüpfungen,
- stored/calculated/current.

Produktionsbericht: acht gemeinsam datierte Snapshots inklusive Netzbaum.

`Technischer Bericht & PDF`: sechs gemeinsam datierte Snapshots inklusive Netzbaum.

## Bewusste Grenze
Batch 31 automatisiert die Verbraucher-/Segment-Q. Physische gemeinsame Rohrgeometrie wird noch in den bestehenden Heizflächenpfaden geführt.

Der nächste große Fachblock ist ein echtes **Edge-/Path-Modell**, bei dem gemeinsame Rohrstrecken nur einmal geometrisch erfasst und Druckverluste automatisch entlang der Verbraucherpfade zusammengesetzt werden.
