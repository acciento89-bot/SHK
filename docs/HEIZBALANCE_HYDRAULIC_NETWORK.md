# HeizBalance – Hydraulischer Netzbaum

## Status
Foundation Batch 31 führt eine optionale, rückwärtskompatible Netzbaum-Struktur für gemeinsame hydraulische Verteilungen ein.

Rechenprofil:
- `hydraulic-network-tree-v1`

Persistenzschema:
- `hydraulic-network-v1`

Berichtsschema:
- `technical-hydraulic-network-v1`

Der Netzbaum ist technische Vorbereitung und kein Verfahren-B-, GEG-/BEG- oder normativer hydraulischer Abgleich-Nachweis.

## Motivation
Bisher musste der Volumenstrom eines Rohrabschnitts mit Rolle `Gemeinsame Verteilung` explizit erfasst werden. Das bleibt für alte Projekte und manuelle Aufnahme weiterhin möglich.

Optional kann ein gemeinsamer Rohrabschnitt jetzt mit einem Netzsegment verbunden werden. Das Segment erhält seinen Bemessungsvolumenstrom automatisch aus den tatsächlich nachgelagerten Heizflächen-Zielvolumenströmen.

## Baumregeln
- Eine Heizfläche ist ein terminaler Verbraucher.
- Ein Verbraucher darf genau einem direkten, tiefsten Netzsegment zugeordnet sein.
- Ein Netzsegment kann direkte Verbraucher und untergeordnete Netzsegmente enthalten.
- Der Volumenstrom eines Segments ist die Summe seiner direkten Verbraucher und aller Verbraucher seiner Kindsegmente.
- Übergeordnete Segmente summieren die Teilstränge automatisch.
- Ein fehlender terminaler Zielvolumenstrom bleibt sichtbar: der bekannte Zwischenwert wird summiert, aber ein vollständiger Segment-Bemessungsvolumenstrom wird nicht freigegeben.
- Doppelte direkte Verbraucherzuordnung ist ungültig.
- Zyklen sind ungültig.
- Selbstreferenz und unbekannte Elternsegmente sind ungültig.
- Nicht zugeordnete Verbraucher bleiben im Netzstatus sichtbar; sie werden nicht heimlich einem Segment zugeschlagen.

## Referenzfall
Terminale Verbraucher:
- Wohnzimmer: 100 l/h
- Bad: 150 l/h
- Schlafzimmer: 200 l/h

Struktur:
- Hauptstrang
  - EG: Wohnzimmer + Bad
  - OG: Schlafzimmer

Erwartung:
- EG = 250 l/h
- OG = 200 l/h
- Hauptstrang = 450 l/h
- Verbraucher-Gesamtvolumenstrom = 450 l/h

Fehlt zum Beispiel der Zielvolumenstrom des Bads:
- bekannte Zwischensumme im EG bleibt 100 l/h,
- der vollständige EG-Bemessungsvolumenstrom bleibt `nil/offen`,
- dadurch bleibt auch der vollständige Hauptstrang-Q offen.

Diese Fälle sind in `HeizBalanceHydraulicNetworkTests` als Regression abgesichert.

## Verknüpfung mit realen Rohrabschnitten
`HeizBalancePipeSection` besitzt optional `networkSegmentID`.

Die Verknüpfung ist nur für Rohrabschnitte mit Rolle `sharedDistribution / Gemeinsame Verteilung` gültig.

Ohne Verknüpfung:
- das bisherige manuelle `explicitDesignVolumeFlowLPH` bleibt gültig.

Mit Verknüpfung:
- der vollständige berechnete Segment-Q kann auf `explicitDesignVolumeFlowLPH` des Rohrabschnitts synchronisiert werden,
- `volumeFlowSource` wird für diesen abgeleiteten Wert bewusst leer gelassen; die Herkunft wird über das Netzsegment und den versionierten Netzbaum-Bericht dokumentiert,
- Rohrabmessungen, Länge, Rauheit, ζ-Werte und Verbraucher-Zielströme werden durch die Synchronisierung nicht geändert.

## Automatische Synchronisierung
Vollständig berechenbare Netz-Q werden synchronisiert:
- beim Verknüpfen eines gemeinsamen Rohrabschnitts,
- beim Ändern der Baum-/Verbraucherzuordnung im Netzbaum-Workspace,
- beim Öffnen des Netzbaum-Workspace nach Referenzbereinigung,
- beim normalen Speichern des Projekts.

Ein manueller Synchronisieren-Knopf bleibt verfügbar, insbesondere wenn Zielvolumenströme außerhalb des Netzbaum-Workspace verändert wurden, bevor das Projekt gespeichert wurde.

## Stale-/Sicherheitsregel
Ein verknüpfter gemeinsamer Rohrabschnitt ist nur `aktuell`, wenn:
- ein vollständiger Segment-Q vorhanden ist und
- der gespeicherte Abschnitts-Q mit dem aktuellen berechneten Segment-Q innerhalb der technischen Toleranz von 0,05 l/h übereinstimmt.

Ist der Q offen oder abweichend:
- wird die Verknüpfung als `neu synchronisieren` markiert,
- der vollständige Kreis-Druckverlust dieser Heizfläche wird für die Projektaggregation nicht verwendet,
- die Baustellen-Einstellliste zeigt keinen vollständigen Kreis-Δp für diesen Kreis,
- der technische Pumpen-Betriebspunkt wird dadurch nicht als vollständig freigegeben,
- eine bestehende Pumpenauswahl wird entsprechend als neu zu bewerten behandelt.

Ein alter Summenstrom darf damit nach einer Last-/Volumenstromänderung nicht unbemerkt in Pumpenauslegung oder Einstellliste weiterleben.

## Referenzbereinigung
Beim Normalisieren werden ausschließlich verwaiste Referenzen bereinigt:
- gelöschte Heizflächen werden aus Segment-Verbraucherlisten entfernt,
- gelöschte Elternsegmente werden nicht ersetzt; das betroffene Segment wird zur Wurzel,
- Links auf gelöschte Netzsegmente werden vom Rohrabschnitt entfernt,
- ein `networkSegmentID` an einer normalen Heizflächen-Anbindung wird entfernt.

Rohrgeometrie, ζ-Werte und manuelle hydraulische Fachdaten werden dabei nicht gelöscht.

## UI
Der Projekteditor besitzt `Hydraulischer Netzbaum`.

Dort können:
- Netzsegmente angelegt, verschachtelt und gelöscht werden,
- Heizflächen als direkte Verbraucher zugeordnet werden,
- gemeinsame Rohrabschnitte mit Segmenten verknüpft werden,
- berechnete Segment-Q und bekannte Zwischenstände geprüft werden,
- veraltete Rohrverknüpfungen erkannt und synchronisiert werden.

Der Projekt-Cockpit-Status zeigt veraltete Netz-Q orange und verhindert, dass ein technisch vollständiger Pumpen-Betriebspunkt behauptet wird.

## Reproduzierbarkeit / PDF
`technical-hydraulic-network-v1` friert ein:
- Profilversion,
- Segmenthierarchie,
- direkte Verbraucher,
- Anzahl nachgelagerter Verbraucher,
- bekannten und vollständigen Segment-Q,
- Verbraucher mit offenem Q,
- verknüpfte gemeinsame Rohrabschnitte,
- gespeicherten und aktuell berechneten Q,
- aktuellen/veralteten Synchronisationsstatus.

Der Produktionsbericht enthält den Netzbaum als eigenen PDF-Teil und umfasst acht gemeinsam datierte, getrennt versionierte Snapshots.

Der separate `Technischer Bericht & PDF` enthält den Netzbaum ebenfalls als eigenen Supplement-Teil und archiviert sechs gemeinsam datierte Snapshots: Hauptbericht, Netzbaum, Niedertemperatur, Szenarien, Heizkörper-Auswahl und Pumpenkennlinien.

## Bewusste Grenze dieses Batches
Der Netzbaum automatisiert die **Verbraucher-/Segment-Volumenströme**. Die physische Rohrgeometrie und die Druckverlustrechnung bleiben weiterhin an den realen Rohrabschnitten der Heizflächenpfade.

Ein späterer Fachblock kann daraus ein echtes gemeinsames Edge-/Path-Modell ableiten, bei dem gemeinsame Rohrstrecken nur einmal geometrisch erfasst und ihre Druckverluste entlang der Verbraucherpfade automatisch zusammengesetzt werden. Bis dahin wird keine solche Topologie behauptet oder erfunden.
