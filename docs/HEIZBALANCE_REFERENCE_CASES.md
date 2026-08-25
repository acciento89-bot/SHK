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

## Freigabekette
`developmentOnly` → `specificationVerified` → `referenceValidated` → `released`

Zusätzlich existiert ein expliziter Release-Schalter im Rechenprofil. Selbst ein versehentlich auf `released` gesetzter Profilstatus reicht daher nicht aus: Alle verpflichtenden Module müssen Spezifikation und Referenzabdeckung vollständig bestanden haben.

## Noch offen
- rechtmäßig zugängliche vollständige Fachspezifikation der relevanten Regelwerksausgaben
- Auswahl geeigneter unabhängiger Referenzrechnungen/Fachsoftware
- Definition zulässiger Toleranzen je Rechenbaustein
- fachliche Review-Dokumentation je Referenzfall
