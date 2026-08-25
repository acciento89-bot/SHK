# HeizBalance – Referenzfall-Validierung

## Zweck
Referenzfälle sind das zentrale Freigabeinstrument für die spätere normative Heizlast-Engine. Ein Rechenbaustein gilt nicht allein deshalb als korrekt, weil er kompiliert oder plausible Werte liefert. Er muss gegen fachlich verifizierte Referenzergebnisse geprüft werden.

## Grundregeln
1. Keine geschützten Normtexte, Tabellen oder Abbildungen werden als Testdaten in das Repository kopiert.
2. Jeder Referenzfall erhält eine eigene ID und dokumentiert Herkunft und Status der Eingabedaten und erwarteten Ergebnisse.
3. Erwartete Werte werden als einzelne benannte Messgrößen mit zulässiger absoluter Toleranz abgelegt.
4. Zwischenergebnisse werden mitgeprüft, nicht nur Endwerte.
5. Fehlende, nicht-endliche oder außerhalb der Toleranz liegende Ergebnisse lassen den Referenzfall fehlschlagen.
6. Technische Regressionen und normative Referenzfälle werden strikt getrennt.
7. Eine normative Ausgabe bleibt gesperrt, solange verpflichtende Rechenbausteine keine verifizierte Spezifikation und keine vollständig bestandene Referenzabdeckung besitzen.

## Geplante normative Rechenbausteine
Die Architektur trennt unter anderem:
- Transmission Außenbauteile
- Transmission zu angrenzenden Bereichen
- Transmission Erdreich
- Wärmebrücken
- Lüftung / Mindestluftwechsel
- Infiltration
- mechanische Lüftung
- Wiederaufheizung
- Raumaggregation
- Gebäudeaggregation

Die konkrete normative Ausgestaltung wird erst aus rechtmäßig zugänglicher und fachlich verifizierter Spezifikation übernommen.

## Normative Referenzmetriken – Strukturbeispiel
Ausschließlich synthetisches Strukturbeispiel, kein Normbeispiel:

```text
caseID: synthetic-room-001
metrics:
  room.transmissionW = 750 ± 1 W
  room.ventilationW  = 250 ± 1 W
  room.totalW        = 1000 ± 1 W
```

Der Core stellt dafür `HeizBalanceReferenceCaseValidator` bereit.

## Technische Regressionen
Diese Fälle prüfen die Stabilität eigener technischer Funktionen. Sie sind ausdrücklich **keine DIN-/Norm-Referenzfälle** und dürfen keine normative Freigabe auslösen.

### technical-low-temp-demo-001
Fiktive Heizflächen des Entwicklungs-Musterprojekts, Wasserspreizung 10 K.

Erwartete minimale technische Systemtemperaturen:
- Wohnzimmer: ca. 43,8 / 33,8 °C
- Schlafzimmer: ca. 42,7 / 32,7 °C
- Bad: ca. 47,4 / 37,4 °C

Folgerung für diesen synthetischen Datensatz:
- 45 / 35 °C deckt nicht alle Heizflächen.
- Das Bad ist thermisch begrenzend.

### technical-temperature-scenario-demo-001
Explizites Szenario 45 / 35 °C auf demselben fiktiven Musterprojekt.

Erwartete Heizflächenbewertung:
- Wohnzimmer: ca. 760 W verfügbar bei 700 W zugeordneter Leistung → ca. 109 % Deckung, ausreichend.
- Schlafzimmer: ca. 583 W verfügbar bei 500 W zugeordneter Leistung → ca. 117 % Deckung, ausreichend.
- Bad: ca. 500 W verfügbar bei 600 W zugeordneter Leistung → ca. 83 % Deckung, nicht ausreichend.
- Bad: erforderliche Nennleistung bei ΔT50 ca. 2.639 W statt 2.200 W → Nennleistungsfaktor ca. ×1,20.

Der Fall prüft insbesondere:
- Leistungsumrechnung für ein explizites VL/RL-Niveau,
- Deckungsgrad,
- harte ausreichend/nicht-ausreichend-Entscheidung,
- Rückrechnung auf erforderliche ΔT50-Nennleistung,
- Nennleistungsfaktor,
- korrekte Identifikation der thermisch schlechtesten Heizfläche.

## Freigabekette normative Module
`developmentOnly` → `specificationVerified` → `referenceValidated` → `released`

Zusätzlich existiert ein expliziter Release-Schalter im Rechenprofil. Ein Profilstatus allein reicht nicht: Alle verpflichtenden Module müssen Spezifikation und Referenzabdeckung bestanden haben.

## Noch offen
- rechtmäßig zugängliche vollständige Fachspezifikation der relevanten Regelwerksausgaben
- Auswahl unabhängiger fachlicher Referenzrechnungen/Fachsoftware
- Definition zulässiger Toleranzen je Normmodul
- fachliche Review-Dokumentation je normativem Referenzfall
