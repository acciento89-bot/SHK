# HeizBalance – gemeinsame Netzarmaturen und Bauteilverluste

## Stand
Foundation Batches 36–38 bauen auf dem vollständig grünen Batch 35 auf.

Ziel ist, dass ein gemeinsamer hydraulischer Verbraucherpfad nicht nur seine physische Rohrgeometrie, sondern auch zentrale Armaturen/Bauteile genau einmal am Netzsegment besitzt.

## Persistenz
`HeizBalanceHydraulicNetwork.Segment` besitzt optional:
- `hydraulicLossComponents`
- `hydraulicComponentAssessmentComplete`

Die Felder sind optional. Alte `hydraulic-network-v1` Projekte ohne diese Keys bleiben decodierbar und behalten ihr bisheriges Verhalten.

## Unterstützte zentrale Bauteilarten
Für den Netzbaum stehen derzeit bewusst generische, explizit dokumentierbare Typen zur Verfügung:
- Strangregulierventil
- Differenzdruckregler
- Wärmemengenzähler
- Schmutzfänger / Filter
- Rückschlagventil
- Verteiler / Sammler
- Armatur / Bauteil
- sonstiger Verlust

Thermostatventil und Rücklaufverschraubung bleiben terminale Heizflächenbauteile.

## Fachregel
Ein zentrales Bauteil wird nicht aus einem Namen oder Typ geschätzt.

Erforderlich ist ein expliziter Druckverlust in kPa mit dokumentierter Quelle. Der Wert muss zum vorgesehenen Segment-Q bzw. zu einem fachlich passenden Hersteller-/Messpunkt gehören.

HeizBalance erzeugt daraus keine pauschale Herstellerkennlinie und keine automatische Ventilfreigabe.

## Vollständigkeit
Für ein Netzsegment gilt:
- bekannte Rohrverluste bleiben sichtbar,
- bekannte zentrale Bauteilverluste bleiben sichtbar,
- beide bekannten Teilsummen werden seriell addiert,
- fehlender Bauteil-Δp bleibt offen,
- bei erfassten zentralen Bauteilen muss die Bauteilaufnahme ausdrücklich als vollständig bestätigt sein,
- ohne vollständige Rohr- und Bauteilabdeckung gibt es keinen vollständigen Segment-Δp,
- dadurch gibt es auch keinen vollständigen Verbraucherpfad/Pumpenbetriebspunkt.

Ein Segment ohne zentrale Bauteile bleibt rückwärtskompatibel ohne zusätzliche Pflichtbestätigung nutzbar.

## Rechenprofil
Das bestehende Profil `hydraulic-network-path-v1` bleibt bestehen. Die Mathematik des Pfads ändert sich nicht:

`Verbraucherpfad = Summe aller seriellen Netzsegmentverluste + terminaler Heizflächenkreis`

Neu ist nur, dass ein Segmentverlust jetzt aus zwei sauber getrennten Teilen bestehen kann:

`Segment-Δp = Rohr-Δp + zentrale Bauteil-Δp`

Parallele Verbraucherpfade werden weiterhin nicht miteinander addiert.

## Core-Regressionen
`HeizBalanceHydraulicNetworkComponentPathTests` prüft mindestens:

1. Zwei zentrale Bauteile mit 2 kPa und 3 kPa ergeben 5 kPa Segmentverlust. Mit 4 kPa terminalem Kreis ergibt sich 9 kPa vollständiger Verbraucherpfad.
2. Ein fehlender zentraler Bauteil-Δp erhält die bekannte Teilsumme, blockiert aber den vollständigen Segment-/Verbraucherpfad.
3. Nicht bestätigte zentrale Bauteilaufnahme blockiert den vollständigen Pfad auch dann, wenn alle einzelnen Δp-Werte vorhanden sind.

## UI
Im Netzsegment-Editor werden gemeinsam angezeigt:
- automatischer Segment-Q,
- bekannter Rohr-Δp,
- bekannter zentraler Bauteil-Δp,
- vollständiger Segment-Δp,
- gemeinsame Rohrabschnitte,
- zentrale Armaturen/Bauteile,
- explizite Vollständigkeitsbestätigung der zentralen Bauteilaufnahme.

Der zentrale Bauteil-Editor zeigt den aktuellen Segment-Q nur lesend an.

## Snapshot / PDF
`technical-hydraulic-network-v1` bleibt aus Rückwärtskompatibilitätsgründen die bestehende Schema-ID. Neue Felder sind optional.

Neu dokumentiert werden pro Segment:
- zentrale Bauteilanzahl,
- direkt segment-eigene Bauteilanzahl,
- bekannter Rohrverlust,
- bekannter Bauteilverlust,
- Bauteilabdeckung vollständig/offen,
- Anzahl fehlender Bauteil-Δp.

Das Netzbaum-PDF zeigt die getrennten Teilverluste und nennt bei unvollständigem Segment die konkrete Ursache.

## Harte Grenzen
- keine unbekannten Bauteile als 0 kPa behandeln,
- keine pauschalen Hersteller-Δp erfinden,
- keine automatische Kennlinie aus Bauteilart ableiten,
- keine parallelen Pfadverluste addieren,
- keine statische Gebäudehöhe als Pumpenförderhöhe addieren,
- keine automatische Hersteller-/Normfreigabe aus dem technischen Pfad ableiten.
