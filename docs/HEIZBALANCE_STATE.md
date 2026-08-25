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
- Aktueller Rechts-/Regelwerksbezug und öffentliche Quellen sind in `docs/HEIZBALANCE_NORM_RESEARCH.md` dokumentiert.

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
8. Normative Ausgaben bleiben im Rechenprofil technisch gesperrt, bis die Validierungsgates erfüllt sind.

## Aktueller Stand – Foundation Pass 4
- Branch `feature/heizbalance-foundation` und Draft-PR #12 aktiv.
- XcodeGen-Target `HeizBalance` mit Bundle-ID `de.kamilunavo.heizbalance` eingebunden.
- Persistente lokale Projektstruktur Projekt → Geschoss → Raum → Bauteil vorhanden.
- Projektaufnahme: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, Quellenangaben und Notizen.
- Raumaufnahme: Geometrie, Solltemperatur, Luftwechsel und Quellenangabe.
- Bauteilaufnahme: Art, Fläche, U-Wert, U-Wert-Quelle und thermische Randbedingung.
- Randbedingungen unterstützen Außenluft oder explizite Gegenseitentemperatur; für Boden/Decke/unbeheizte Bereiche werden keine erfundenen Pauschalwerte eingesetzt.
- `HeizBalanceHeatLossPreviewCalculator` liegt getrennt im SHKCore und berechnet technische Transmission und Lüftung aus expliziten Eingaben.
- Vorberechnung je Raum zeigt Transmission, Lüftung, Summe und W/m².
- Gebäude-Dashboard zeigt Vollständigkeit, fehlende Eingaben je Raum, Zwischenwerte und Gebäudesumme.
- Eine Gebäudesumme wird nur ausgegeben, wenn alle Räume vollständig sind.
- SwiftUI-Struktur in Projektliste, Projekteditor, Gebäudeeditoren und Formularfelder aufgeteilt.
- Versionierte Rechenprofile im SHKCore eingeführt.
- `technical-preview-v1` ist ausdrücklich nicht normativ.
- `de-room-heat-load-2017-2020` ist als reserviertes Profil für DIN EN 12831-1:2017-09 + DIN/TS 12831-1:2020-04 angelegt; normative Ausgabe ist technisch gesperrt.
- Profilstatus unterscheidet Entwicklung, verifizierte Spezifikation, Referenzvalidierung und Release.
- Profil-Gates besitzen automatische Tests, damit eine Entwicklungsengine nicht versehentlich normative Ausgabe freigibt.
- `docs/HEIZBALANCE_NORM_RESEARCH.md` dokumentiert öffentlich prüfbare Regelwerksstände und die weitere Validierungsstrategie.
- CI Run #42 thermische Vorbereitungsengine: grün.
- CI Run #44 Gebäude-Dashboard/View-Refactor: grün.
- CI Run #46 Rechenprofile/Normarchitektur: grün, inklusive Core-Tests und HeizBalance-iOS-Build.

## Nächster Entwicklungsschritt
1. Fachliche Spezifikation der einzelnen Normbausteine anhand rechtmäßig zugänglicher Regelwerksunterlagen und verifizierter Referenzfälle erstellen.
2. Transmissionsfälle als getrennte, testbare normative Komponenten vorbereiten.
3. Lüftung, Mindestluftwechsel, Infiltration und mechanische Lüftung als getrennte Komponente vorbereiten.
4. Zusätzliche Aufheizleistung und Gebäudeaggregation getrennt vorbereiten.
5. Erst nach Spezifikations- und Referenzvalidierung die normative Engine implementieren und freigeben.
6. Danach Heizflächenmodul als Brücke zum hydraulischen Abgleich beginnen.
