# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Heizlast, Heizflächenprüfung und hydraulischen Abgleich mit nachvollziehbarer Projektdokumentation.

## Produktname
- App Store: HeizBalance
- Technischer Target-Name: HeizBalance
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026

## Normstrategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-Texte, Tabellen, Grafiken oder sonstigen geschützten Norminhalte werden in die App kopiert.
- Rechenengine wird versioniert, damit Regelwerksstände später getrennt gepflegt werden können.
- Referenzfälle und Regressionstests werden vor einer fachlichen Release-Freigabe verpflichtend.
- Eine technische Vorberechnung darf nicht als Norm-Heizlast bezeichnet werden, solange die normative Engine und Referenzvalidierung nicht vollständig sind.

## Geplanter Funktionsumfang
### Phase 1 – Heizlast
- Projekte, Gebäude, Nutzungseinheiten und Räume
- Geometrie und Bauteilflächen
- U-Werte und Randbedingungen
- Transmissions- und Lüftungswärmeverluste
- Raumweise Heizlast und Gebäudeübersicht
- Eingabeherkunft kennzeichnen: Mess-/Nachweiswert / Plan / Hersteller / fachlich ermittelt / geschätzt
- PDF-Projektbericht

### Phase 2 – Hydraulischer Abgleich
- Vorhandene Heizflächen erfassen
- Heizflächenleistung bei gewählten Systemtemperaturen prüfen
- Soll-Volumenströme je Heizfläche
- Rohrnetz und Druckverluste
- Ventilauslegung / Soll-kv bzw. Durchfluss
- Pumpenanforderung und Anlagen-Gesamtvolumenstrom
- Dokumentation der Einstellwerte

### Phase 3 – Herstellerdaten & Wärmepumpen-Optimierung
- Freigegebene Hersteller-/Produktdatensätze
- Automatische Ventilvoreinstellungen
- Niedertemperatur-Check und minimale sinnvolle Vorlauftemperatur

### Phase 4 – Flächenheizung
- Fußboden-, Wand- und Deckenheizung als separates Fachmodul

## Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Jede normative Rechenfunktion erhält Unit Tests.
3. Referenzgebäude mit erwarteten Zwischenergebnissen.
4. Ergebnisse werden gegen etablierte Fachsoftware bzw. fachlich geprüfte Referenzrechnungen gegengeprüft.
5. Rechenweg und Annahmen müssen im Projektbericht nachvollziehbar sein.
6. Keine GEG-/BEG-Konformitätsaussage ohne fachliche Prüfung des vollständigen Verfahrens.
7. Nicht normative Vorberechnungen werden in UI und Code eindeutig als solche gekennzeichnet.

## Aktueller Stand – Foundation Pass 2
- Branch `feature/heizbalance-foundation` und Draft-PR #12 aktiv.
- XcodeGen-Target `HeizBalance` mit Bundle-ID `de.kamilunavo.heizbalance` eingebunden.
- App-Entry-Point und lokaler Projekt-Store über Swift Observation verdrahtet.
- Persistente lokale Projektspeicherung über Codable vorhanden.
- Projektaufnahme: Projektname, Kunde, Adresse, Baujahr und Notizen.
- Gebäudeaufnahme: Geschosse und Räume.
- Raumaufnahme: Länge, Breite, Höhe, Raumtemperatur, Grundfläche und Volumen.
- Bauteilaufnahme: Art, Fläche, U-Wert, Quelle und Notiz.
- Auslegungs-Außentemperatur als expliziter Projektwert inklusive Quellenkennzeichnung ergänzt.
- Luftwechsel je Raum als expliziter Eingabewert inklusive Quellenkennzeichnung ergänzt.
- Thermische Randbedingung je Bauteil ergänzt: Außenluft oder explizite Gegenseitentemperatur.
- Boden, Decken und angrenzende unbeheizte Bereiche erhalten bewusst keine erfundene Pauschalkorrektur.
- `HeizBalanceHeatLossPreviewCalculator` im SHKCore ergänzt.
- Technische Vorberechnung liefert getrennt Transmission, Lüftung, Summe und W/m², sobald alle erforderlichen Eingaben vorhanden sind.
- UI kennzeichnet dieses Ergebnis ausdrücklich als Vorberechnung und nicht als freigegebene Norm-Heizlast.
- Core-Geometrie und Wärmeverlust-Vorbereitung sind mit automatisierten Tests abgesichert.
- HeizBalance ist Bestandteil der iOS-CI-Matrix.
- CI Run #42 für Commit `69497766de248d4a9b20dd1bd3900669ba650ae8` vollständig grün: Core-Tests und HeizBalance-iOS-Build erfolgreich.

## Nächster Entwicklungsschritt
1. Projekt-/Gebäudeübersicht mit Vollständigkeitsstatus und aufsummierten Vorberechnungswerten ergänzen.
2. Datenmodell für normative Transmissionsfälle, Lüftung/Infiltration und zusätzliche Aufheizleistung getrennt vorbereiten.
3. Öffentliche/verifizierbare Spezifikation und Referenzfälle für DIN EN 12831-1 / DIN/TS 12831-1 zusammentragen, ohne geschützte Norminhalte zu kopieren.
4. Normative Engine erst nach verifizierter Spezifikation implementieren und gegen Referenzfälle testen.
5. Danach Heizflächenmodul als Brücke zum hydraulischen Abgleich beginnen.
