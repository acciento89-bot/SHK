# HeizBalance – Referenzfall-Validierung

## Zweck
Referenzfälle sind das zentrale Freigabeinstrument für die spätere normative Heizlast-Engine. Ein Rechenbaustein gilt nicht allein deshalb als korrekt, weil er kompiliert oder plausible Werte liefert. Er muss gegen fachlich verifizierte Referenzergebnisse geprüft werden.

## Grundregeln
1. Keine geschützten Normtexte, Tabellen oder Abbildungen werden als Testdaten in das Repository kopiert.
2. Jeder Referenzfall erhält eine eigene ID und dokumentiert die Herkunft der Eingabedaten und der erwarteten Ergebnisse.
3. Erwartete Werte werden als einzelne benannte Messgrößen mit zulässiger absoluter Toleranz abgelegt.
4. Zwischenergebnisse werden mitgeprüft, nicht nur die Endsumme. Dadurch lässt sich eine Abweichung einem Rechenbaustein zuordnen.
5. Fehlende, nicht-endliche oder außerhalb der Toleranz liegende Ergebnisse lassen den Referenzfall fehlschlagen.
6. Für ein Normmodul muss mindestens ein fachlich belastbarer Referenzfall vorhanden sein; vor Release werden mehrere unterschiedliche Fälle angestrebt.
7. Eine normative Ausgabe bleibt gesperrt, solange auch nur ein verpflichtender Rechenbaustein keine verifizierte Spezifikation oder keine vollständig bestandene Referenzabdeckung besitzt.

## Geplante Rechenbausteine
Die aktuelle Architektur trennt folgende Bereiche technisch voneinander. Die konkrete normative Ausgestaltung und Anwendbarkeit wird erst aus der verifizierten Fachspezifikation übernommen:

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

## Referenzmetriken
Beispiel für die Struktur eines späteren Referenzfalls – ausschließlich synthetisch, nicht als Normbeispiel:

```text
caseID: synthetic-room-001
metrics:
  room.transmissionW = 750 ± 1 W
  room.ventilationW  = 250 ± 1 W
  room.totalW        = 1000 ± 1 W
```

Der Core stellt dafür `HeizBalanceReferenceCaseValidator` bereit. Er vergleicht benannte Ist-Werte mit erwarteten Werten und absoluten Toleranzen.

## Technischer Regressionfall – Niedertemperatur
Dieser Fall ist ausdrücklich **kein Norm-Referenzfall**. Er dient ausschließlich dazu, die eigenständig implementierte technische Heizflächen-/Niedertemperatur-Logik stabil zu halten und die End-to-End-Demo in der App zu prüfen.

Rahmenbedingungen:
- konstante Wasserspreizung: 10 K
- Vergleichssystem: 45/35 °C
- Heizflächenkennwerte sind fiktive, produktunabhängige Testdaten

Erwartete Werte:

```text
caseID: technical-low-temp-demo-001
Wohnzimmer:
  Qn,ΔT50 = 2500 W
  n = 1.3
  Qrequired = 700 W
  Raum = 20 °C
  minimum VL/RL = 43.7805 / 33.7805 °C
  45/35 °C = ausreichend

Schlafzimmer:
  Qn,ΔT50 = 1800 W
  n = 1.3
  Qrequired = 500 W
  Raum = 19 °C
  minimum VL/RL = 42.6657 / 32.6657 °C
  45/35 °C = ausreichend

Bad:
  Qn,ΔT50 = 2200 W
  n = 1.3
  Qrequired = 600 W
  Raum = 24 °C
  minimum VL/RL = 47.4041 / 37.4041 °C
  45/35 °C = nicht ausreichend

System:
  begrenzende Heizfläche = Bad
  minimum VL/RL = 47.4041 / 37.4041 °C
  45/35 °C = nicht ausreichend
```

Der Fall ist als Unit-Test in `HeizBalanceLowTemperatureCheckTests` hinterlegt. Er darf nicht als fachliche oder normative Validierung der DIN-Heizlast interpretiert werden.

## Freigabekette
`developmentOnly` → `specificationVerified` → `referenceValidated` → `released`

Zusätzlich existiert ein expliziter Release-Schalter im Rechenprofil. Selbst ein versehentlich auf `released` gesetzter Profilstatus reicht daher nicht aus: Alle verpflichtenden Module müssen Spezifikation und Referenzabdeckung vollständig bestanden haben.

## Noch offen
- rechtmäßig zugängliche vollständige Fachspezifikation der relevanten Regelwerksausgaben
- Auswahl geeigneter unabhängiger Referenzrechnungen/Fachsoftware
- Definition zulässiger Toleranzen je Rechenbaustein
- fachliche Review-Dokumentation je Referenzfall
