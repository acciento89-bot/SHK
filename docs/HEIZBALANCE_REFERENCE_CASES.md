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

## Technisches Niedertemperatur-Musterprojekt `technical-low-temp-demo-001`
Das Entwicklungsprojekt enthält drei Räume und bewusst unterschiedlich dimensionierte Heizflächen. Die Wasserspreizung beträgt 10 K.

Erwartete Minimaltemperaturen:
- Wohnzimmer: ca. 43,8 / 33,8 °C
- Schlafzimmer: ca. 42,7 / 32,7 °C
- Bad: ca. 47,4 / 37,4 °C

Erwartete Systemaussage:
- Das Bad ist thermisch begrenzend.
- 45 / 35 °C reicht für das Gesamtprojekt bewusst nicht aus.
- Eine System-Minimaltemperatur darf nur ausgegeben werden, wenn alle erfassten Heizflächen vollständig auswertbar sind.

Dieser Fall ist eine technische Regression für Heizflächenleistung und fixed-spread-Minimaltemperatur, keine Wärmepumpenauslegung und kein normativer Heizlastfall.

## Technisches 45/35-Szenario
Für dasselbe Musterprojekt wird das explizite Szenario 45 / 35 °C geprüft.

Erwartungen:
- Wohnzimmer: ca. 760 W verfügbar bei 700 W Bedarf → ca. 109 % Deckung.
- Schlafzimmer: ca. 583 W verfügbar bei 500 W Bedarf → ca. 117 % Deckung.
- Bad: ca. 500 W verfügbar bei 600 W Bedarf → ca. 83 % Deckung.
- Bad ist die thermisch schwächste Heizfläche.
- Für das Bad werden bei 45 / 35 °C ungefähr 2.639 W erforderliche ΔT50-Nennleistung ausgewiesen.
- Gegenüber der vorhandenen ΔT50-Nennleistung von 2.200 W ergibt sich ungefähr Faktor ×1,20.

Die App darf daraus ohne autorisierten Herstellerdatensatz kein konkretes Ersatzmodell oder Abmessungen erfinden.

## Persistentes Sanierungsziel / Dashboard
Wenn 45 / 35 °C im Musterprojekt als Sanierungsziel gespeichert wird, muss derselbe fachliche Zustand projektweit wiederverwendet werden:
- Zieltemperatur bleibt nach erneutem Öffnen des Projekts erhalten.
- Szenarioauswertung, PDF-Szenario-Snapshot und Archiv verwenden denselben gespeicherten Zielwert.
- Das Dashboard zeigt `Upgradebedarf`, weil nicht alle Heizflächen ausreichend sind.
- Begrenzende Heizfläche ist das Bad.
- Dashboard-Ausgabe für das Bad bleibt ungefähr 2.639 W erforderliche ΔT50-Nennleistung und Faktor ×1,20.
- Bei unvollständigen Heizflächendaten muss statt einer positiven/negativen Zielaussage `Daten unvollständig` erscheinen.

Auch diese Prüfung ist eine technische Regression und keine normative Aussage.
