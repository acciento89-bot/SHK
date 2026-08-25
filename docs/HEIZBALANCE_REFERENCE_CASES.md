# HeizBalance – Referenzfall-Validierung

## Zweck
Diese Datei sammelt reproduzierbare technische Referenz- und Regressionsfälle für HeizBalance. Sie ersetzt keine DIN-Norm und enthält keine geschützten Normtabellen oder -texte.

## Status der Referenzfälle
- Technische Rechenkerne werden mit transparenten, selbst definierten Eingaben getestet.
- Normative Referenzfälle werden erst ergänzt, wenn die zugrunde liegende Spezifikation rechtmäßig verfügbar, fachlich verifiziert und dokumentiert ist.
- Aktuelle technische Regressionen dürfen nicht als DIN-/GEG-/BEG-Nachweis bezeichnet werden.

## Technischer kv-Referenzfall
Eingaben:
- Volumenstrom: 0,6 m³/h
- Ventil-Druckverlust: 12 kPa
- Dichte: 1.000 kg/m³

Erwartung:
- erforderlicher kv ≈ 1,73 m³/h

Der Fall dient nur der mathematischen Prüfung der technischen kv-Vorbereitung.

## Niedertemperatur / Temperaturszenario
Das Entwicklungs-Musterprojekt bleibt als technischer Referenzfall bestehen:
- Wohnzimmer: minimale Systemtemperatur ca. 43,8 / 33,8 °C
- Schlafzimmer: ca. 42,7 / 32,7 °C
- Bad: ca. 47,4 / 37,4 °C
- Bad ist begrenzend.
- 45 / 35 °C reicht bewusst nicht für alle Heizflächen.
- Bad bei 45 / 35 °C ca. 83 % Deckung, ca. 2.639 W erforderliche ΔT50-Nennleistung, Faktor ca. ×1,20 gegenüber 2.200 W.
- Ohne autorisierten Herstellerdatensatz wird daraus kein konkretes Ersatzmodell erfunden.

## Pumpenkennlinie `linear-documented-pump-curve-v1`
Dokumentierte Punkte:
- 1,0 m³/h → 4,0 m → 28 W
- 2,0 m³/h → 2,0 m → 40 W

Bei 1,5 m³/h:
- interpoliert 3,0 m
- interpoliert 34 W
- bei 3,2 m Bedarf Reserve −0,2 m → nicht ausreichend.

Harte Regeln:
- Exakter Punkt bleibt exakt.
- Nur lineare Zwischenwerte innerhalb dokumentierter Punkte.
- Keine Extrapolation.
- Keine automatische Pumpenauswahl.

## Pumpen-Leistungskennzahlen `pump-technical-metrics-v1`
Technischer Referenzfall:
- 1,5 m³/h
- 3,2 m erforderliche H
- 4,0 m verfügbare H
- 998 kg/m³
- P₁ 34 W

Erwartung:
- hydraulische Anforderung ca. 13,05 W
- hydraulisch verfügbar ca. 16,31 W
- H-Reserve 0,8 m / 25 %
- `Pₕ,erf/P₁` ca. 38,4 %
- Q-Bereichsposition 75 %.

`Pₕ,erf/P₁` ist ausdrücklich kein EEI-/ErP-/Hersteller-Wirkungsgradnachweis.

## Aufnahme-/Kopierregeln
- Kopien erhalten neue IDs.
- Physische Daten dürfen als Aufnahmehilfe übernommen werden.
- Last-, Flow-, Δp-, Vollständigkeits- und Produktentscheidungen werden nicht still auf einen neuen Heizkreis übertragen.
- `component-favorite-v1` speichert keine Fläche oder raumspezifische Gegenseitentemperatur.
- `hydraulic-capture-template-v1` darf Rohrgeometrie/Rauheit/ζ und dokumentierte Ventilproduktidentität übernehmen, nicht aber fertige Q-/Δp-/Einstellentscheidungen.

## Explizite Ventilentscheidungen `valve-setting-selection-v1`
Nur ausdrücklicher Benutzer-Tap auf einen dokumentierten Datenpunkt.
Relevante Änderungen an Q, Δp, Dichte, Soll-kv oder Produkt-/Datensatzidentität → `neu bewerten`, niemals stille automatische Ersetzung.

## Baustellen-Einstellliste `technical-adjustment-list-v1`
- Ziel-Q und vollständiger Kreis-Δp nur soweit fachlich verfügbar.
- TV/RL Soll-kv und ausdrücklich festgehaltene Einstellungen.
- Offene/veraltete Werte bleiben sichtbar.
- Pumpenauswahl optional mit aktuellem/veraltetem Status.
- Kein nachgebautes VdZ-/Verfahren-B-Formular.

## Hydraulischer Netzbaum – Batch 31
Die vollständige Netzbaum-Spezifikation und alle Struktur-/Stale-Regeln stehen in `docs/HEIZBALANCE_HYDRAULIC_NETWORK.md`.

### Kernreferenz
Verbraucher:
- Wohnzimmer = 100 l/h
- Bad = 150 l/h
- Schlafzimmer = 200 l/h

Baum:
- Hauptstrang
  - EG: Wohnzimmer + Bad
  - OG: Schlafzimmer

Erwartung:
- EG = 250 l/h
- OG = 200 l/h
- Hauptstrang = 450 l/h
- Verbraucher-Gesamt-Q = 450 l/h.

### Unvollständiger Verbraucher
Fehlt der Bad-Q:
- bekannte EG-Zwischensumme = 100 l/h
- vollständiger EG-Q bleibt offen
- vollständiger Hauptstrang-Q bleibt offen
- kein Q wird geschätzt.

### Struktur-Gates
Folgende Fälle müssen ungültig bleiben:
- doppelte direkte Verbraucherzuordnung
- Selbstreferenz
- unbekanntes Elternsegment
- Zyklus.

Unzugeordnete Verbraucher werden sichtbar gelassen und nicht still einem Strang zugewiesen.

### Netzbaum-/Rohr-Stale-Regel
Ein gemeinsamer Rohrabschnitt darf optional mit einem Netzsegment verbunden sein.
- vollständiger Segment-Q kann auf den Abschnitt synchronisiert werden
- Rohrgeometrie/ζ bleiben unverändert
- ohne Link bleibt der manuelle Summen-Q gültig
- normales Projektspeichern normalisiert Referenzen und synchronisiert vollständige Netz-Q.

Stored Q und aktuell berechneter Netz-Q müssen innerhalb 0,05 l/h übereinstimmen.
Bei Abweichung/offenem Segment-Q:
- `Netzbaum-Q neu synchronisieren`
- betroffener Kreis-Δp nicht als vollständig für die Systemaggregation verwenden
- technischer Pumpen-Betriebspunkt nicht als vollständig freigeben
- bestehende Pumpenentscheidung damit neu bewerten.

Diese Regeln sind technische Regressionen und kein normativer hydraulischer Abgleich.
