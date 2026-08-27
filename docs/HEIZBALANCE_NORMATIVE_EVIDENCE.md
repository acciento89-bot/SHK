# HeizBalance – Normative Evidence Contract

Stand der öffentlichen Metadatenprüfung: **2026-08-26**.

## Zweck

Dieses Dokument definiert ausschließlich den Freigabe- und Evidenzprozess für ein zukünftiges deutsches Raumheizlast-Profil. Es enthält **keine** kopierten Normtexte, Tabellen, Formelsammlungen oder Klimadatensätze und ersetzt keine Norm.

Das reservierte Profil `de-room-heat-load-2017-2020` bleibt gesperrt, bis Quellenbasis, Modulspezifikation, unabhängige Referenzfälle, Profil-Lifecycle und explizite Release-Freigabe gemeinsam erfüllt sind.

## Öffentlich verifizierte Regelwerks-Metadaten

### DIN EN 12831-1:2017-09

- Dokument: `DIN EN 12831-1`
- Ausgabe: `2017-09`
- DIN Media kennzeichnet diese Ausgabe bei der Prüfung am 2026-08-26 als aktuelle veröffentlichte Norm.
- DOI: `10.31030/2571775`
- Metadaten: https://www.dinmedia.de/de/norm/din-en-12831-1/261292587

Diese Metadaten dokumentieren Identität und Ausgabe. Sie sind **kein** Implementierungsrecht und kein Ersatz für den rechtmäßig verfügbaren fachlichen Inhalt.

### DIN/TS 12831-1:2020-04

- Dokument: `DIN/TS 12831-1`
- Ausgabe: `2020-04`
- Rolle: nationale Ergänzung zur DIN EN 12831-1.
- DOI: `10.31030/3124717`
- Metadaten: https://www.dinmedia.de/de/vornorm/din-ts-12831-1/316645651

Auch hier werden ausschließlich öffentlich sichtbare bibliografische Metadaten im Repository geführt.

### DIN EN 12831-1:2025-06 – Entwurf

- Dokument: `DIN EN 12831-1`
- Ausgabe: `2025-06`, Entwurf / `prEN 12831-1:2025`
- Erscheinungsdatum laut DIN Media: `2025-05-23`
- DOI: `10.31030/3613477`
- Metadaten: https://www.dinmedia.de/de/norm-entwurf/din-en-12831-1/390800689

DIN Media beschreibt den Entwurf als Änderung gegenüber `DIN EN 12831-1:2017-09` und `DIN/TS 12831-1:2020-04`. Deshalb wird er als **offener Nachfolge-Review** geführt. Ein Entwurf ersetzt die veröffentlichte Ausgabe nicht automatisch, darf vor einer späteren Normfreigabe aber auch nicht ignoriert werden.

## Quellenbasis-Gate

Für jede im Rechenprofil deklarierte Quellenausgabe braucht HeizBalance einen qualifizierten `HeizBalanceNormativeSourceRecord`.

Eine Quelle zählt für die Spezifikationsphase nur, wenn:

- Dokument und Ausgabe exakt zum Rechenprofil passen,
- die Metadatenquelle dokumentiert ist,
- das Recht zur Nutzung für die Implementierung ausdrücklich geklärt ist,
- eine konkrete Rechte-/Lizenzreferenz hinterlegt ist.

Öffentlich sichtbare Produktseiten allein erfüllen diese Anforderungen ausdrücklich nicht.

Vor einer Normausgabe müssen zusätzlich alle bekannten Nachfolgeentwürfe bewertet sein. `pending` oder `requiresProfileUpdate` hält die Normausgabe gesperrt.

## Zehn getrennte Pflichtmodule

Das Profil bleibt in folgende unabhängige Validierungsbausteine zerlegt:

1. Transmission Außenbauteile
2. Transmission angrenzende Bereiche
3. Transmission Erdreich
4. Wärmebrücken
5. Lüftung / Mindestluftwechsel
6. Infiltration
7. Mechanische Lüftung
8. Wiederaufheizung
9. Raumaggregation
10. Gebäudeaggregation

Kein Gesamt-PASS darf fehlende Module überdecken.

## Spezifikationsnachweis pro Modul

`HeizBalanceNormativeSpecificationEvidence` zählt nur, wenn:

- das Modul explizit benannt ist,
- die referenzierte Quellenbasis Implementierungsrechte dokumentiert,
- eine interne Spezifikationsversion vorliegt,
- Prüfer und Prüfdatum dokumentiert sind,
- eine unabhängige fachliche Review bestätigt wurde.

Die interne Spezifikation soll Rechenverhalten, Eingaben, Ausgaben, Randfälle und Fehlerzustände beschreiben, ohne geschützten Normtext zu vervielfältigen.

## Referenzfallnachweis pro Modul

`HeizBalanceNormativeReferenceCaseEvidence` zählt nur, wenn:

- die Quelle für Referenzvalidierung rechtlich dokumentiert ist,
- der Fall mindestens einen konkreten Erwartungswert besitzt,
- die Erwartungswerte unabhängig von der zu prüfenden Implementierung entstanden sind,
- die Validierung tatsächlich ausgeführt wurde.

Ein fehlgeschlagener qualifizierter Fall bleibt als Fall sichtbar und blockiert die Referenzabdeckung. Ein selbst erzeugter technischer Regressionstest wird nicht automatisch zum normativen Referenzfall.

## Release-Gleichung

Normative Ausgabe ist nur möglich, wenn gleichzeitig gilt:

`Quellenbasis bereit`

**und**

`alle 10 Spezifikationen verifiziert`

**und**

`alle qualifizierten Referenzfälle bestanden`

**und**

`Profil-Lifecycle mindestens referenceValidated`

**und**

`normativeOutputAllowed == true`.

Damit kann weder ein einzelner Boolean noch eine Sammlung synthetischer Tests die Normfreigabe umgehen.

## Aktueller Projektstatus

Mit Batch 42 werden nur Provenienz, Rechtegate, Nachfolge-Review und Evidenzaggregation implementiert. Die öffentlich sichtbaren DIN-Metadaten sind eingetragen; **Implementierungsrechte, vollständige Modulspezifikationen und unabhängige normative Referenzfälle sind weiterhin offen.**

Folglich bleibt die Norm-Heizlast in HeizBalance weiterhin gesperrt.
