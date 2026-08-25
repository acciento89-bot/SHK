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

## Aktueller Stand – Foundation Pass 1
- Branch `feature/heizbalance-foundation` angelegt.
- Draft-PR #12 angelegt.
- XcodeGen-Target `HeizBalance` eingebunden.
- Bundle-ID `de.kamilunavo.heizbalance` eingebunden.
- App-Entry-Point und Projekt-Store über Swift Observation verdrahtet.
- Persistente lokale Projektspeicherung als versionierbares Codable-Datenmodell angelegt.
- Projektaufnahme umgesetzt: Projektname, Kunde, Adresse, Baujahr, Notizen.
- Gebäudeaufnahme umgesetzt: Geschosse und Räume.
- Raumaufnahme umgesetzt: Länge, Breite, Höhe, Raumtemperatur, Grundfläche und Volumen.
- Bauteilaufnahme umgesetzt: Bauteilart, Fläche, optionaler U-Wert und Notiz.
- Herkunft von thermischen Kennwerten im Datenmodell vorgesehen.
- Heizlast- und Abgleichstatus bewusst noch ohne Rechenergebnis; keine unvalidierten Formeln eingebaut.
- HeizBalance in die iOS-Build-Matrix der GitHub-CI aufgenommen.

## Nächster Entwicklungsschritt
1. CI für den Foundation-Pass grün bekommen und ggf. Compilerfehler beheben.
2. Eingabemodell um Auslegungsort/Randbedingungen sowie Nachweisquelle erweitern.
3. Normative Rechenengine als getrenntes Modul entwerfen und erst nach verifizierter Spezifikation implementieren.
4. Erste Referenzfälle und Unit-Tests für nicht-normative Geometrie-/Datenlogik ergänzen.
