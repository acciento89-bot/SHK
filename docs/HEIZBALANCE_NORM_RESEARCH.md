# HeizBalance – Norm- und Regelwerksrecherche

Stand: 25.08.2026

Diese Datei dokumentiert ausschließlich öffentlich überprüfbare Metadaten und die daraus abgeleitete Entwicklungsstrategie. Sie enthält keine kopierten DIN-Tabellen, Normtexte oder Grafiken.

## Aktuell relevante Regelwerksstände

### DIN EN 12831-1:2017-09
DIN Media führt die Ausgabe 2017-09 weiterhin als aktuelle Norm für die Berechnung der Raumheizlast.

Quelle:
https://www.dinmedia.de/de/norm/din-en-12831-1/261292587

### DIN/TS 12831-1:2020-04
Nationale Ergänzungen zur DIN EN 12831-1. DIN Media beschreibt sowohl das ausführliche Verfahren als auch vereinfachte Verfahren sowie ein Verfahren zur überschlägigen Gebäudeheizlast aus Mess-/Verbrauchsdaten.

Quelle:
https://www.dinmedia.de/de/vornorm/din-ts-12831-1/316645651

### DIN EN 12831-1:2025-06
DIN Media führt diese Ausgabe derzeit als Norm-Entwurf, nicht als veröffentlichte Ersatznorm. Die App darf deshalb eine künftige Engine nicht stillschweigend auf diesen Entwurf umstellen.

Quelle:
https://www.dinmedia.de/de/norm-entwurf/din-en-12831-1/390800689

## Gesetzlicher Bezug hydraulischer Abgleich

§ 60c GEG nennt für die raumweise Heizlast ausdrücklich DIN EN 12831 Teil 1, Ausgabe September 2017, in Verbindung mit DIN/TS 12831 Teil 1, Ausgabe April 2020. Für den hydraulischen Abgleich wird Verfahren B der ZVSHK/VdZ-Fachregel „Optimierung von Heizungsanlagen im Bestand“, aktualisierte Neuauflage April 2022, oder ein gleichwertiges Verfahren genannt.

Quelle:
https://www.gesetze-im-internet.de/geg/GEG.pdf

VdZ-Fachregel:
https://vdzev.de/produkt/optimierung-von-heizungsanlagen-im-bestand/

Eine öffentlich zugängliche VdZ-Leistungsbeschreibung zu Verfahren B nennt unter anderem raumweise Heizlast, Heizflächendurchflüsse, Ventil-/Reguliereinstellungen, Pumpenförderhöhe und Gesamtdurchfluss als relevante Leistungen.

Quelle:
https://files.vdzev.de/pdfs/hydraulischer-abgleich-effizienzhaus/VDZ_Formular_HydrAbgleich_Effizienzhaus_BEG.pdf

## Architekturentscheidung

HeizBalance verwendet versionierte Rechenprofile. Ein gespeichertes Ergebnis muss dauerhaft erkennen lassen, mit welchem Rechenprofil und welchem Regelwerksstand es erzeugt wurde.

Aktuelle Profile:
- `technical-preview-v1`: rein technische Vorberechnung, keine Normausgabe erlaubt.
- `de-room-heat-load-2017-2020`: reserviertes Profil für DIN EN 12831-1:2017-09 + DIN/TS 12831-1:2020-04; normative Ausgabe bleibt gesperrt, bis Spezifikation und Referenzfälle validiert sind.

Eine künftige neue Normausgabe erhält eine eigene Engine-ID. Bestehende Projekte werden nicht automatisch auf eine neue Rechenlogik umgerechnet.

## Verbindliche Freigabe-Gates für normative Ausgabe

1. Rechtmäßiger Zugriff auf die benötigten Regelwerksausgaben für die fachliche Entwicklung.
2. Eigenständige technische Spezifikation ohne Übernahme geschützter Norminhalte in App oder Repository.
3. Jede Rechenkomponente getrennt implementiert und mit Unit-Tests versehen.
4. Referenzfälle mit erwarteten Zwischenergebnissen.
5. Gegenprüfung gegen etablierte Fachsoftware beziehungsweise fachlich geprüfte Referenzrechnung.
6. Erst danach Wechsel des Rechenprofils auf `referenceValidated` beziehungsweise `released` und Freigabe normativer Bezeichnungen in UI/PDF.

## Nächste fachliche Recherche

Für die tatsächliche normative Engine müssen insbesondere die detaillierten Regeln für folgende Bereiche verifiziert werden:
- Transmissionswärmeverluste nach außen,
- Wärmeübertragung zu unbeheizten und anders temperierten Bereichen,
- Wärmeübertragung gegen Erdreich,
- Wärmebrückenbehandlung,
- Lüftung, Mindestluftwechsel, Infiltration und mechanische Lüftung,
- zusätzliche Aufheizleistung,
- deutsche Klimadaten und nationale Randbedingungen,
- Gebäudeaggregation und zulässige Vereinfachungen im Bestand.

Bis diese Punkte verifiziert sind, bleibt die vorhandene Vorberechnung fachlich und technisch getrennt von der Norm-Heizlast.
