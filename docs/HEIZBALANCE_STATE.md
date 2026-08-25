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

## Aktueller Stand – Foundation Pass 3
- Branch `feature/heizbalance-foundation` und Draft-PR #12 aktiv.
- XcodeGen-Target `HeizBalance` mit Bundle-ID `de.kamilunavo.heizbalance` eingebunden.
- Persistente lokale Projektstruktur Projekt → Geschoss → Raum → Bauteil vorhanden.
- Projektaufnahme: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, Quellenangaben und Notizen.
- Raumaufnahme: Geometrie, Solltemperatur, Luftwechsel und Quellenangabe.
- Bauteilaufnahme: Art, Fläche, U-Wert, U-Wert-Quelle und thermische Randbedingung.
- Randbedingungen unterstützen Außenluft oder explizite Gegenseitentemperatur; für Boden/Decke/unbeheizte Bereiche werden keine erfundenen Pauschalwerte eingesetzt.
- `HeizBalanceHeatLossPreviewCalculator` liegt getrennt im SHKCore und berechnet technische Transmission und Lüftung aus expliziten Eingaben.
- Vorberechnung je Raum zeigt Transmission, Lüftung, Summe und W/m².
- Gebäude-Dashboard ergänzt: vollständig erfasste Räume, fehlende Eingaben je Raum, Zwischenwerte und Gebäudesumme.
- Eine Gebäudesumme wird nur ausgegeben, wenn alle Räume vollständig sind; bei Lücken wird lediglich die Zwischensumme vollständig erfasster Räume gekennzeichnet.
- Große SwiftUI-Datei in Projektliste, Projekteditor, Gebäudeeditoren und Formularfelder aufgeteilt.
- UI kennzeichnet alle Ergebnisse ausdrücklich als technische Vorberechnung und nicht als Norm-Heizlast.
- Geometrie- und Wärmeverlust-Grundlagen besitzen automatisierte Core-Tests.
- CI Run #42 für die thermische Engine vollständig grün.
- CI Run #44 für Gebäude-Dashboard und View-Refactor vollständig grün, inklusive HeizBalance-iOS-Build und Core-Tests.

## Nächster Entwicklungsschritt
1. Datenmodell für die spätere normative Engine sauber von der technischen Vorberechnung trennen und versionieren.
2. Öffentliche/verifizierbare Spezifikation und Referenzfälle für DIN EN 12831-1 / DIN/TS 12831-1 zusammentragen, ohne geschützte Norminhalte zu kopieren.
3. Transmissionsfälle, Lüftung/Infiltration und zusätzliche Aufheizleistung als einzeln testbare normative Komponenten vorbereiten.
4. Normative Engine erst nach verifizierter Spezifikation implementieren und gegen Referenzfälle/Fachsoftware testen.
5. Danach Heizflächenmodul als Brücke zum hydraulischen Abgleich beginnen.
