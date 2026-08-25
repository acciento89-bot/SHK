# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Heizlast, Heizflächenprüfung, Niedertemperaturbewertung und hydraulischen Abgleich mit nachvollziehbarer Projektdokumentation.

## Produkt
- App Store: HeizBalance
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12

## Norm- und Compliance-Strategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-Texte, Tabellen, Grafiken, VdZ-Formularlayouts oder ungeklärten Herstellerdaten werden in App oder Repository kopiert.
- Rechenengine und Berichtsschemata werden versioniert.
- Technische Vorbereitungen werden nicht als Norm-Heizlast, Verfahren-B-Nachweis, Wärmepumpenauslegung oder Herstellerfreigabe bezeichnet.
- Das reservierte Profil `de-room-heat-load-2017-2020` bleibt technisch gesperrt, bis Spezifikation und Referenzfälle vollständig fachlich verifiziert sind.
- Regelwerks-/Quellenstand: `docs/HEIZBALANCE_NORM_RESEARCH.md`.
- Referenz- und Regressionstrategie: `docs/HEIZBALANCE_REFERENCE_CASES.md`.

## Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Rechenfunktionen mit Unit-/Regressionstests absichern.
3. Normative Module benötigen verifizierte Spezifikation und Referenzabdeckung.
4. Ergebnisse später gegen etablierte Fachsoftware bzw. fachlich geprüfte Referenzrechnungen gegenprüfen.
5. Eingabeherkunft, Rechenprofil, Annahmen und Ergebnisse im Bericht nachvollziehbar halten.
6. Keine GEG-/BEG-Konformitätsaussage ohne vollständige fachliche Prüfung.
7. Normative Ausgabe bleibt bis zur echten Freigabe technisch gesperrt.
8. Hersteller-Voreinstellungen nur aus dokumentierten, rechtmäßig nutzbaren Produktdaten.
9. Pumpen-Betriebspunkt nur bei vollständigen Verbraucherströmen und Kreis-Druckverlusten.
10. System-Minimaltemperatur nur bei vollständig auswertbaren Heizflächen.
11. Szenarioausgaben liefern benötigte Leistung/Faktor, erfinden aber kein Ersatzmodell.

## Aktueller Stand – Foundation Pass 14

### Projekt- und Gebäudeaufnahme
- Persistente lokale Struktur Projekt → Geschoss → Raum → Bauteil.
- Projekt: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, System-VL/RL, Quellen, Hydraulik-Fluidwerte, persistentes Sanierungsziel und Notizen.
- Raum: Geometrie, Solltemperatur, Luftwechsel, Quelle, thermische Bauteile und Heizflächen.
- Bauteile: Art, Fläche, U-Wert, Quelle und thermische Randbedingung.
- Außenluft oder explizite Gegenseitentemperatur werden unterstützt; keine versteckten Pauschalwerte für angrenzende Bereiche.

### Technische Wärmeverlust-Vorbereitung
- `HeizBalanceHeatLossPreviewCalculator` berechnet technische Transmission und Lüftung ausschließlich aus expliziten Eingaben.
- Raumübersicht zeigt Transmission, Lüftung, Summe und W/m².
- Eine Gebäudesumme wird nur bei vollständigen Räumen gezeigt.
- `technical-preview-v1` bleibt ausdrücklich nicht normativ.

### Heizflächen
- Heizflächen pro Raum: Art, Bezeichnung, Hersteller/Modell optional, Nennleistung ΔT50, Exponent, Quelle, zugeordnete erforderliche Leistung und Notiz.
- Verfügbare Heizflächenleistung und erforderliche Leistung sind getrennt.
- Ziel-Volumenstrom wird aus zugeordneter erforderlicher Leistung und Wasserspreizung berechnet.
- Raumebene aggregiert Heizflächenleistung, Leistungszuordnung und Ziel-Volumenströme.

### Hydraulik
- Explizite Fluiddichte und kinematische Viskosität; keine versteckten Wasser-/Glykolannahmen.
- Rohrabschnitte mit Rolle, Innendurchmesser, hydraulischer Länge, Rauheit, ζ-Summe und ggf. explizitem Abschnittsvolumenstrom.
- Trennung zwischen Heizflächen-Anbindung und gemeinsamer Verteilung.
- Berechnung von Geschwindigkeit, Reynolds-Zahl, Rohrreibung, geradem und lokalem Druckverlust.
- Hydraulische Bauteile getrennt erfassbar: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, vollständigen Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
- Projektaggregation bildet Verbraucher-Gesamtvolumenstrom und hydraulisch ungünstigsten Parallelkreis; parallele Kreisverluste werden nicht addiert.
- Technischer Pumpen-Betriebspunkt nur bei vollständiger Abdeckung.

### Ventile
- `HeizBalanceValveSizingPreparationCalculator` berechnet den erforderlichen technischen kv aus Zielvolumenstrom, Ventil-Δp und Fluiddichte.
- Referenzfall 0,6 m³/h bei 12 kPa ergibt rund kv 1,73 m³/h.
- Optionale Produktdatensätze: Hersteller, Produkt, Datenstand, Quelle/Referenz und diskrete `Voreinstellung → kv`-Punkte.
- `HeizBalanceValvePresetComparisonCalculator` zeigt unteren/oberen und mathematisch nächstliegenden Punkt, Bereichsstatus und Abweichung.
- Mathematische Nähe wird ausdrücklich nicht als automatische Hersteller-Voreinstellung ausgegeben.
- Projektweiter Manager `Ventildaten & Kennlinien` ist vorhanden.

### Niedertemperatur-Minimalcheck
- `HeizBalanceLowTemperatureCheckCalculator` bestimmt bei fester expliziter Wasserspreizung die minimal technisch ausreichende VL/RL-Kombination je Heizfläche.
- Eingaben: Nennleistung ΔT50, Exponent, zugeordnete erforderliche Leistung und Raumtemperatur.
- Projektweit wird die Heizfläche mit der höchsten erforderlichen Vorlauftemperatur als begrenzend ausgewiesen.
- Systemwert wird gesperrt, solange mindestens eine Heizfläche nicht auswertbar ist.
- Vergleich einer frei wählbaren Vorlauftemperatur gegen alle Heizflächen ist vorhanden.
- Keine Wärmepumpenauslegung, COP-/Bivalenzbewertung oder Norm-Heizlast.

### Temperatur-Szenarien / Sanierungsbewertung
- Core: `HeizBalanceTemperatureScenarioCalculator`.
- Für ein explizites VL/RL-Szenario werden je Heizfläche berechnet:
  - mittlere Übertemperatur,
  - verfügbare Leistung,
  - Deckungsgrad,
  - ausreichend / nicht ausreichend,
  - erforderliche Nennleistung bei ΔT50,
  - Nennleistungsfaktor gegenüber der bestehenden Heizfläche.
- Harte Eingabeprüfung: gültig nur bei `Vorlauf > Rücklauf > Raumtemperatur`, positiven Leistungen und positivem Exponenten.
- Projekt-Matrix enthält persistentes Sanierungsziel, aktuelles Projekt-Temperaturniveau sowie 50/40, 45/35, 45/40 und 40/35 °C.
- Die UI erlaubt ein frei eingegebenes Ziel-VL/RL einschließlich dokumentierter Quelle und kann dieses explizit als Sanierungsziel speichern oder löschen.
- Persistiert werden optional `retrofitTargetFlowTemperatureC`, `retrofitTargetReturnTemperatureC` und `retrofitTargetTemperatureSource`; ältere Projektdateien ohne diese Keys bleiben decodierbar.
- Ein gespeichertes Sanierungsziel wird beim erneuten Öffnen wieder geladen und im Projekt-Dashboard angezeigt.
- Die zentrale Szenario-Snapshot-Erzeugung priorisiert das gespeicherte Sanierungsziel. Dadurch nutzen UI, PDF und Archiv denselben Datenpfad und es gibt keine separate Export-Sonderlogik.
- Wenn Zieltemperaturen identisch mit einem Standard-/Projektszenario sind, wird das Szenario nicht doppelt ausgegeben.
- Die Quelle des gespeicherten Sanierungsziels wird im Szenariotitel des Report-Snapshots dokumentiert, sofern angegeben.
- Pro Szenario: auswertbare Heizflächen, ausreichende Heizflächen, Systemstatus und thermisch schlechteste Heizfläche.
- Detailansicht zeigt jede Heizfläche einzeln.
- Keine konkrete Ersatzheizfläche oder Herstellerdimension wird erfunden; bei Unterdeckung wird stattdessen die mindestens benötigte ΔT50-Nennleistung und der Faktor ausgegeben.
- Das Projekt-Dashboard zeigt das gespeicherte Sanierungsziel jetzt als fachlichen Sofortstatus: `Ziel erreichbar`, `Upgradebedarf`, `Daten unvollständig` oder noch keine Heizflächen.
- Bei Upgradebedarf werden direkt die begrenzende Heizfläche, die mindestens erforderliche ΔT50-Nennleistung und der Größenfaktor angezeigt.
- Die dokumentierte Quelle des Zieltemperaturniveaus ist auch im Dashboard sichtbar.
- Der erwartete Dashboardzustand des technischen 45/35-Musterfalls ist in `docs/HEIZBALANCE_REFERENCE_CASES.md` festgehalten.

### Technisches Musterprojekt / Regression
- Fiktives Entwicklungsprojekt mit drei Räumen und vollständiger technischer Heizflächen-/Hydraulikkette.
- Entwicklungsmenü ist mit `#if DEBUG` gekapselt und existiert nicht im Release-Build.
- Fixed-spread Regression bei 10 K:
  - Wohnzimmer ca. 43,8/33,8 °C,
  - Schlafzimmer ca. 42,7/32,7 °C,
  - Bad ca. 47,4/37,4 °C.
- Damit reicht 45/35 °C bewusst nicht; das Bad ist begrenzend.
- Szenario 45/35 °C im Muster:
  - Wohnzimmer ca. 760 W verfügbar bei 700 W Bedarf → ca. 109 %.
  - Schlafzimmer ca. 583 W verfügbar bei 500 W Bedarf → ca. 117 %.
  - Bad ca. 500 W verfügbar bei 600 W Bedarf → ca. 83 %.
  - Bad benötigt bei diesem Szenario rund 2.639 W Nennleistung ΔT50 statt 2.200 W → Faktor rund ×1,20.
- Beide technischen Regressionfälle und ihre Bedeutung sind in `docs/HEIZBALANCE_REFERENCE_CASES.md` dokumentiert.
- Die Fälle sind technische Regressionen, keine DIN-/Norm-Referenzfälle.

### Bericht / PDF / Reproduzierbarkeit
- Hauptsnapshot `technical-report-v1`.
- Niedertemperatur-Snapshot `technical-low-temperature-v1`, Profil `fixed-spread-emitter-check-v1`.
- Szenario-Snapshot `technical-temperature-scenarios-v1`, Profil `explicit-flow-return-emitter-sizing-v1`.
- Jeder Snapshot bleibt eigenständig versioniert, damit alte Archive nicht still umdefiniert werden.
- Ein Export erzeugt exakt einen gemeinsamen Zeitstempel für alle drei Snapshots.
- PDF besteht aus drei zusammengeführten A4-Teilen: technischer Hauptbericht, Niedertemperatur-Supplement und Temperatur-Szenario-Supplement.
- Zusammenführung über PDFKit.
- Das gespeicherte Sanierungsziel fließt ohne Schemaänderung als priorisiertes Szenario in den bestehenden Szenario-Snapshot und damit in PDF und Archiv ein.
- Nach erfolgreichem PDF-Export werden die drei JSON-Snapshots getrennt archiviert; fehlgeschlagene/abgebrochene Exporte erzeugen keinen falschen Archivstand.
- Archivbegrenzung: letzte 10 Exportstände je Projekt und Berichtstyp.
- Szenario-PDF dokumentiert pro Szenario den Systemstatus sowie je Heizfläche verfügbare Leistung, Deckungsgrad und bei Unterdeckung erforderliche ΔT50-Nennleistung/Faktor.

### Release-Härtung
- Entwicklungs-Musterprojekt im Release-Build durch `#if DEBUG` vollständig entfernt.
- CI baut die komplette App-Matrix in Debug.
- Für HeizBalance existiert zusätzlich ein echter Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden in CI geprüft.

## Validierte CI-Checkpoints
- #50 Heizflächenaufnahme/Leistungs- und Volumenstrom-Vorbereitung: grün.
- #53 erforderliche vs. verfügbare Leistung + Zielvolumenstrom: grün.
- #55 Raum-Heizflächenabdeckung: grün.
- #57 Rohrnetz-/Druckverlust-Vorbereitung: grün.
- #61 Bauteilverluste + harte Kreis-Vollständigkeit: grün.
- #62 Soll-kv-Engine + Referenzfall: grün.
- #66 abschnittsspezifische Volumenströme / gemeinsame Verteilung: grün.
- #68 hydraulische Projektaggregation: grün.
- #73 Ventil-Datensatzvergleich + Produktdatenmodelle: komplette Matrix grün.
- #78 PDF-Renderer/Export: komplette Matrix grün.
- #82 Berichtssnapshot-Archiv: komplette Matrix grün.
- #92 Niedertemperatur-Core, UI, Musterprojekt und Regression: komplette Matrix grün.
- #96 Niedertemperatur-Snapshot, PDF-Supplement und PDFKit-Merger: HeizBalance grün.
- #97 kombinierter Haupt-/Niedertemperatur-PDF-Export + Doppelarchiv: komplette Matrix grün.
- #100 Release-Gate: HeizBalance Debug + echter Release-Build grün; Debug-Musterinhalt release-seitig abgesichert.
- #104 / #109 / #110: während des Szenario-UI-Passes gefundene SwiftUI-Compilerprobleme; analysiert und behoben, nicht als Release-Checkpoint gewertet.
- #111: Foundation Pass 12 vollständig grün – Core-Tests, gesamte Debug-iOS-Matrix, HeizBalance Szenario-/3-PDF-Pfad und echter HeizBalance-Release-Build erfolgreich.
- #120: Foundation Pass 13 Code-Gate grün – persistentes Sanierungsziel, zentrale Report-Szenariointegration, Core-Tests, gesamte Debug-iOS-Matrix und echter HeizBalance-Release-Build erfolgreich.
- #123: **Foundation Pass 14 vollständig grün** – Sanierungsziel-Dashboardstatus, Core-Tests, komplette Debug-iOS-Matrix und echter HeizBalance-Release-Build erfolgreich.

## Noch bewusst gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-Freigabe / GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung aus echten Herstellerdaten.
- Automatische Auswahl konkreter Ersatzheizkörper.
- Echte Wärmepumpenauslegung, COP-/Bivalenz- und Betriebspunktbewertung der Wärmepumpe.
- Flächenheizung nach DIN EN 1264 als eigener Fachblock.

## Nächste Entwicklungsschritte
1. Herstellerdaten-Strategie für Heizkörper und Ventile definieren: ausschließlich autorisierte/legale strukturierte Daten; VDI-3805-kompatible Quellen prüfen.
2. Auf Basis echter Heizkörperdaten konkrete Ersatz-/Upgradevorschläge aus der bereits berechneten erforderlichen ΔT50-Leistung ableiten.
3. PDF-Ausgabe mit größeren realistischen Projekten visuell und auf Seitenumbrüche testen.
4. Parallel die fachliche Spezifikation der späteren Norm-Heizlastmodule anhand rechtmäßig zugänglicher Regelwerksunterlagen und belastbarer Referenzfälle aufbauen.
5. Erst nach echter fachlicher Referenzvalidierung normative Gates schrittweise freigeben.
