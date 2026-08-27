# HeizBalance – Produktionsbericht & Übergabe

## Zweck
Der Produktionsbericht bündelt den technischen HeizBalance-Arbeitsstand zu einem druckbaren Übergabe- und Baustellenpaket. Er ergänzt die bestehenden technischen Fachberichte, ohne eine normative oder förderrechtliche Freigabe vorzutäuschen.

## Versionierte neue Daten
### `project-documentation-v1`
Lokal persistierte, projektbezogene Dokumentationsdaten:
- Firma / Betrieb
- Techniker vor Ort
- Bearbeiter / Ersteller
- ausdrücklich gesetzter Projektstatus
- optionales Ausführungs-/Ortstermindatum
- Übergabeempfänger
- Übergabehinweis / Restpunkte
- Name in Druckschrift für den Unterschriftsbereich
- Ort für den Unterschriftsbereich

Die Daten liegen absichtlich in einem separaten projektbezogenen Store und verändern das bestehende Projekt-JSON-Schema nicht.

### `technical-handover-v1`
Eingefrorener Übergabe-Snapshot mit:
- Projekt/Kunde/Adresse
- eingefrorenen Dokumentationsdaten
- Geschoss-/Raum-/Heizflächenumfang
- Anzahl technisch auswertbarer Räume
- Ziel-Volumenstrom-Abdeckung
- Kreis-Δp-Abdeckung
- aktuelle/veraltete/fehlende Ventileinstellungen
- Pumpenauswahl vorhanden/aktuell
- Anzahl offener technischer Punkte
- Geschosszusammenfassung
- eindeutigem technischen Haftungshinweis

Die letzten 10 erfolgreichen Übergabe-Snapshots je Projekt werden separat archiviert.

## Produktions-PDF
Der neue Projekt-Cockpit-Einstieg `Produktionsbericht & Übergabe` erzeugt ein gemeinsames PDF-Paket in dieser Reihenfolge:
1. `technical-handover-v1`
2. `technical-report-v1`
3. `technical-low-temperature-v1`
4. `technical-temperature-scenarios-v1`
5. `technical-radiator-replacements-v1`
6. `technical-pump-curves-v1`
7. `technical-adjustment-list-v1`

Alle sieben Snapshots werden mit exakt demselben `generatedAt` erzeugt. Nach erfolgreichem Benutzerexport werden die sieben Snapshot-Typen in ihren jeweiligen lokalen Archiven gespeichert.

## Unterschriftsregel
Der PDF-Bericht erzeugt freie handschriftliche Linien für:
- Techniker / Bearbeiter
- Auftraggeber / Empfänger
- Ort / Datum

Ein optional gespeicherter Name ist nur Druckschrift/Zuordnung. HeizBalance erzeugt keine kryptografische oder elektronische Signatur und behauptet keine digitale Abnahme.

Die PDF-Erklärung stellt ausdrücklich klar:
> Die Unterschrift bestätigt ausschließlich Übergabe bzw. Kenntnisnahme des dokumentierten technischen Arbeitsstands. Sie ist keine automatische DIN-, Verfahren-B-, GEG-/BEG-, Förder- oder Herstellerfreigabe.

## Projektstatus
Der Projektstatus wird ausschließlich durch den Bearbeiter gesetzt. Verfügbare Zustände:
- In Bearbeitung
- Aufnahme vollständig
- Hydraulik technisch vorbereitet
- Einstellwerte vorbereitet
- Einstellung dokumentiert
- Übergabe vorbereitet

Keiner dieser Zustände darf als automatische normative Konformitätsaussage interpretiert werden.

## Große Projekte / Seitenlogik
Für den Produktionsbericht gibt es kein künstliches Raumlimit.

UI-Hinweise:
- ab 20 Räumen: Großprojekt-Hinweis
- ab 50 Räumen: 50+-Räume-Hinweis

Die Baustellen-Einstellliste wurde von einer groben Zeilenhöhen-Schätzung auf eine dynamische Writer-Struktur umgestellt:
- Kopf-/Fußzeile je Seite
- Geschosse gruppiert und auf Folgeseiten fortgeführt
- tatsächliche Textmessung für Zeilen
- Ventilzeilen werden einzeln platzgesichert
- lange Offen-/Hinweis-Texte werden wortweise über Seiten fortgeführt
- übergroße Kreisblöcke dürfen kontrolliert über mehrere Seiten laufen, statt abgeschnitten zu werden

Auch der Übergabebericht verwendet dynamische Textfortsetzung für lange Übergabehinweise und paginiert Geschosszusammenfassungen.

Der bestehende technische Hauptbericht besitzt bereits seitenbasierte `ensureSpace`-Logik für Räume, Heizflächen, Rohrabschnitte und Hydraulikbauteile. Das neue kompakte Übergabeblatt vermeidet bei großen Projekten zusätzlich, dass der Empfänger zuerst Dutzende Detailseiten lesen muss, um den Projektstatus zu erfassen.

## Harte Produktregeln
- Unvollständige technische Daten dürfen exportiert werden, bleiben aber sichtbar unvollständig.
- Veraltete Ventil-/Pumpenentscheidungen bleiben sichtbar und werden nicht still aktualisiert.
- Keine versteckten Ersatzwerte zur Verschönerung des Berichts.
- Keine automatische Ventilvoreinstellung.
- Keine automatische Pumpen- oder Heizkörperfreigabe.
- Keine Norm-/GEG-/BEG-/Förderkonformitätsaussage aus Projektstatus oder Unterschrift.
- Kein Nachbau geschützter VdZ-/Verfahren-B-Formularlayouts.

## Verifikation
Der Code-Head des Produktionsbericht-Batches muss vor Abschluss mindestens bestehen:
- SHKCore Unit-/Regressionstests
- komplette iOS-Debug-Matrix
- HeizBalance Debug
- echter HeizBalance Release-Simulator-Build

Erst ein vollständig grüner gemeinsamer CI-Head gilt als Produktionsbericht-Checkpoint.
