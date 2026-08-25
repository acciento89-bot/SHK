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
- Produktdatenadapter verarbeiten nur dokumentierte, rechtmäßig nutzbare Datenquellen; geschützte Roh-Datensatzbeschreibungen aus Regelwerken werden nicht im Repository nachgebaut.

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
12. Externe Produktdaten werden nur über versionierte, validierte Importschemata übernommen; Quelle, Datenstand und Nutzungsgrundlage bleiben erhalten.

## Aktueller Stand – Foundation Pass 17

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

### Hersteller-/Produktdaten und Ersatzheizkörper
- Internes, versioniertes Heizkörper-Katalogschema: `radiator-product-dataset-v1`.
- Pflichtmetadaten: eindeutige Datensatz-ID, Hersteller, Datensatzname, Datenstand/Version, Quellenreferenz und dokumentierte Nutzungsgrundlage.
- Produktdaten: eindeutige ID, Serie/Modell, Nennleistung ΔT50, Exponent sowie optionale Abmessungen, Artikelnummer und produktspezifische Quelle.
- Harte Importvalidierung für leere/doppelte IDs, reservierte Trenner, ungültige Leistungen/Exponenten und ungültige Abmessungen.
- Globaler lokaler Datensatzspeicher mit transaktionalem Import/Löschen: bei Schreibfehler wird der vorherige Zustand wiederhergestellt.
- `HeizBalanceRadiatorProductMatchingCalculator` vergleicht importierte Produkte gegen explizites Sanierungsziel, Raumtemperatur und erforderliche Heizflächenleistung.
- Optionale Einbauraumfilter für Breite/Höhe/Tiefe; Produkte ohne dokumentiertes gefordertes Maß werden bei aktivem Filter nicht still zugelassen.
- Kandidaten werden nach ausreichender Leistung und kleinster rechnerischer Reserve sortiert; dies ist ausdrücklich keine automatische Produktempfehlung.
- Eine Ersatzheizfläche wird nur nach explizitem Benutzer-Tap als `radiator-replacement-selection-v1` gespeichert.
- Auswahl-Snapshot enthält Hersteller, Datensatzversion, Quelle/Nutzungsgrundlage, Produktdaten, Ziel-VL/RL, Bedarf, verfügbare Leistung und Deckungsgrad.
- Ändert sich das Sanierungsziel nach einer Auswahl, wird der gespeicherte Vorschlag im Bericht als neu zu bewerten markiert.
- Produktdatenverwaltung ist global aus der Projektliste und projektspezifisch aus der Upgradeansicht erreichbar.

### VDI 3805 Produktdatenadapter – Heizkörper
- Adapterprofil `vdi-3805-part6-mapped-v1` für autorisiert erzeugte, normalisierte Mappings mit Bezug auf VDI 3805 Blatt 6.
- Der Adapter ist bewusst kein Rohparser der Richtlinie und enthält keine nachgebauten geschützten Satzbeschreibungen.
- Pflichtfelder des Mappings: Standardbezug, Mappingprofil-Version, Hersteller, Datenstand, Quelle/Nutzungsgrundlage und Produktdaten.
- `HeizBalanceRadiatorDatasetImportDecoder` erkennt automatisch natives `radiator-product-dataset-v1` oder `vdi-3805-part6-mapped-v1`.
- Erfolgreiche VDI-Mappings werden in das stabile interne HeizBalance-Schema konvertiert; Standardbezug und Mappingprofil bleiben im Quellen-/Rechtehinweis nachvollziehbar.
- Adaptertests prüfen Konvertierung, Schemaerkennung, falschen Standardteil, ungültige Abmessungen und unbekannte Schemas.
- Format und fiktives Beispiel: `docs/HEIZBALANCE_VDI3805_IMPORT.md`.
- Echte Rohdatenkonverter bleiben bis zu einer rechtmäßig nutzbaren Spezifikation bzw. Hersteller-/Lizenzquelle bewusst offen.

### Hydraulik
- Explizite Fluiddichte und kinematische Viskosität; keine versteckten Wasser-/Glykolannahmen.
- Rohrabschnitte mit Rolle, Innendurchmesser, hydraulischer Länge, Rauheit, ζ-Summe und ggf. explizitem Abschnittsvolumenstrom.
- Trennung zwischen Heizflächen-Anbindung und gemeinsamer Verteilung.
- Berechnung von Geschwindigkeit, Reynolds-Zahl, Rohrreibung, geradem und lokalem Druckverlust.
- Hydraulische Bauteile getrennt erfassbar: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, vollständigen Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
- Projektaggregation bildet Verbraucher-Gesamtvolumenstrom und hydraulisch ungünstigsten Parallelkreis; parallele Kreisverluste werden nicht addiert.
- Technischer Pumpen-Betriebspunkt nur bei vollständiger Abdeckung.

### Ventile und Armaturen-Produktdaten
- `HeizBalanceValveSizingPreparationCalculator` berechnet den erforderlichen technischen kv aus Zielvolumenstrom, Ventil-Δp und Fluiddichte.
- Referenzfall 0,6 m³/h bei 12 kPa ergibt rund kv 1,73 m³/h.
- `HeizBalanceValvePresetComparisonCalculator` zeigt unteren/oberen und mathematisch nächstliegenden Punkt, Bereichsstatus und Abweichung.
- Mathematische Nähe wird ausdrücklich nicht als automatische Hersteller-Voreinstellung ausgegeben.
- Internes, versioniertes Ventilkatalogschema `valve-product-dataset-v1` mit Hersteller, Datensatzstand, Quelle/Nutzungsgrundlage, Produkten und diskreten `Voreinstellung → kv`-Punkten.
- Harte Validierung für IDs, Produktnamen, leere Kennlinien, doppelte Voreinstellungen und nicht-positive/ungültige kv-Werte.
- Globaler lokaler `HeizBalanceValveDatasetStore` mit transaktionalem Import/Löschen.
- Ventilkataloge sind global aus dem Produktdaten-Menü und projektspezifisch aus `Ventildaten & Kennlinien` erreichbar.
- Ein Katalogprodukt kann ausdrücklich einem konkreten Thermostat- oder Rücklaufventil im Projekt zugeordnet werden.
- Beim Übernehmen werden Hersteller, Produkt, Datenstand, Quelle, Artikel-/Katalogreferenzen und Kennlinienpunkte in das Projekt kopiert; ein späteres Löschen des globalen Katalogs zerstört die Projektdokumentation nicht.
- Die Übernahme eines Ventilprodukts setzt ausdrücklich keine Voreinstellung automatisch.

### VDI 3805 Produktdatenadapter – Heizungsarmaturen
- Adapterprofil `vdi-3805-part2-mapped-v1` für normalisierte, dokumentierte Mappings mit Bezug auf VDI 3805 Blatt 2.
- Adapter und Dokumentation bauen keine geschützten Roh-Satzbeschreibungen der Richtlinie nach.
- Pflichtfelder: Standardbezug, Mappingprofil-Version, Hersteller, Datensatzstand, Quelle/Nutzungsgrundlage, Produkte und diskrete Voreinstellung/kv-Datenpunkte.
- `HeizBalanceValveDatasetImportDecoder` erkennt automatisch natives `valve-product-dataset-v1` oder `vdi-3805-part2-mapped-v1`.
- Erfolgreiche Mappings werden in das stabile interne Ventilkatalogschema konvertiert; Standardbezug und Mappingprofil bleiben im Quellen-/Rechtehinweis erhalten.
- Adaptertests prüfen Konvertierung, Schemaerkennung, falschen Standardteil, Projektherkunft und doppelte Voreinstellungen.
- Format und ausschließlich fiktives Beispiel: `docs/HEIZBALANCE_VDI3805_VALVE_IMPORT.md`.
- Rohdatenkonverter bleiben bis zu einer rechtmäßig nutzbaren Hersteller-/Lizenzquelle und technisch verifizierten Datensatzspezifikation gesperrt.

### Niedertemperatur-Minimalcheck
- `HeizBalanceLowTemperatureCheckCalculator` bestimmt bei fester expliziter Wasserspreizung die minimal technisch ausreichende VL/RL-Kombination je Heizfläche.
- Eingaben: Nennleistung ΔT50, Exponent, zugeordnete erforderliche Leistung und Raumtemperatur.
- Projektweit wird die Heizfläche mit der höchsten erforderlichen Vorlauftemperatur als begrenzend ausgewiesen.
- Systemwert wird gesperrt, solange mindestens eine Heizfläche nicht auswertbar ist.
- Vergleich einer frei wählbaren Vorlauftemperatur gegen alle Heizflächen ist vorhanden.
- Keine Wärmepumpenauslegung, COP-/Bivalenzbewertung oder Norm-Heizlast.

### Temperatur-Szenarien / Sanierungsbewertung
- Core: `HeizBalanceTemperatureScenarioCalculator`.
- Für ein explizites VL/RL-Szenario werden je Heizfläche mittlere Übertemperatur, verfügbare Leistung, Deckungsgrad, ausreichend/nicht ausreichend, erforderliche Nennleistung ΔT50 und Nennleistungsfaktor berechnet.
- Harte Eingabeprüfung: gültig nur bei `Vorlauf > Rücklauf > Raumtemperatur`, positiven Leistungen und positivem Exponenten.
- Projekt-Matrix enthält persistentes Sanierungsziel, aktuelles Projekt-Temperaturniveau sowie 50/40, 45/35, 45/40 und 40/35 °C.
- Die UI erlaubt ein frei eingegebenes Ziel-VL/RL einschließlich dokumentierter Quelle und kann dieses explizit als Sanierungsziel speichern oder löschen.
- Persistierte optionale Zielfelder bleiben rückwärtskompatibel zu älteren Projektdateien.
- Ein gespeichertes Sanierungsziel wird beim erneuten Öffnen geladen und im Projekt-Dashboard angezeigt.
- Die zentrale Szenario-Snapshot-Erzeugung priorisiert das gespeicherte Sanierungsziel und dedupliziert identische Szenarien.
- Ohne importierte Produktdaten wird keine konkrete Ersatzheizfläche erfunden; bei Unterdeckung werden Mindest-Nennleistung und Faktor ausgegeben.
- Mit gültigen Produktdaten können technisch passende Kandidaten angezeigt werden; die tatsächliche Auswahl bleibt explizit beim Benutzer.
- Das Projekt-Dashboard zeigt `Ziel erreichbar`, `Upgradebedarf`, `Daten unvollständig` oder noch keine Heizflächen.

### Technisches Musterprojekt / Regression
- Fiktives Entwicklungsprojekt mit drei Räumen und vollständiger technischer Heizflächen-/Hydraulikkette.
- Entwicklungsmenü ist mit `#if DEBUG` gekapselt und existiert nicht im Release-Build.
- Fixed-spread Regression bei 10 K: Wohnzimmer ca. 43,8/33,8 °C, Schlafzimmer ca. 42,7/32,7 °C, Bad ca. 47,4/37,4 °C.
- Damit reicht 45/35 °C bewusst nicht; das Bad ist begrenzend.
- Szenario 45/35 °C: Wohnzimmer ca. 109 %, Schlafzimmer ca. 117 %, Bad ca. 83 % Deckung; Bad benötigt rund 2.639 W ΔT50 statt 2.200 W, Faktor rund ×1,20.
- Die Fälle in `docs/HEIZBALANCE_REFERENCE_CASES.md` sind technische Regressionen, keine DIN-/Norm-Referenzfälle.

### Bericht / PDF / Reproduzierbarkeit
- Hauptsnapshot `technical-report-v1`.
- Niedertemperatur-Snapshot `technical-low-temperature-v1`, Profil `fixed-spread-emitter-check-v1`.
- Szenario-Snapshot `technical-temperature-scenarios-v1`, Profil `explicit-flow-return-emitter-sizing-v1`.
- Ersatzheizkörper-Snapshot `technical-radiator-replacements-v1` für ausdrücklich ausgewählte Produktkandidaten.
- Jeder Snapshot bleibt eigenständig versioniert; ein Export nutzt einen gemeinsamen Zeitstempel.
- PDF besteht aus vier zusammengeführten A4-Teilen: Hauptbericht, Niedertemperatur, Temperatur-Szenarien und dokumentierte Ersatzheizkörper-Auswahl.
- Nach erfolgreichem PDF-Export werden die vier JSON-Snapshots getrennt archiviert; fehlgeschlagene/abgebrochene Exporte erzeugen keinen falschen Archivstand.
- Archivbegrenzung: letzte 10 Exportstände je Projekt und Berichtstyp.
- `technical-report-v1` enthält für dokumentierte Ventile weiterhin Hersteller, Produkt, Datenstand, Quellenreferenz und Kennlinienpunkte sowie optional Katalog-ID, Produkt-ID, Artikelnummer, Quellen-URL, Nutzungsgrundlage und Rechtehinweis.
- Die neuen optionalen Ventil-Provenienzfelder brechen alte `technical-report-v1`-Archive nicht.

### Release-Härtung
- Entwicklungs-Musterprojekt im Release-Build durch `#if DEBUG` vollständig entfernt.
- CI baut die komplette App-Matrix in Debug.
- Für HeizBalance existiert zusätzlich ein echter Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden in CI geprüft.
- PR-CI nutzt `cancel-in-progress`, sodass veraltete Zwischenläufe bei neuen Commits automatisch abgebrochen werden und nur der aktuelle Head relevant bleibt.

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
- #111: Foundation Pass 12 vollständig grün – Szenario-/3-PDF-Pfad und Release-Build erfolgreich.
- #120: Foundation Pass 13 grün – persistentes Sanierungsziel und zentrale Reportszenariointegration.
- #123: Foundation Pass 14 grün – Sanierungsziel-Dashboardstatus.
- #154: Foundation Pass 15 grün – Heizkörper-Herstellerdatenschema, Matching, explizite Ersatzwahl und vierter Reportpfad.
- #159: Foundation Pass 16 grün – VDI-3805-Blatt-6-Mappingadapter, automatische Importschemaerkennung und Adaptertests.
- #173: **Foundation Pass 17 vollständig grün** – Ventilkatalogschema, VDI-3805-Blatt-2-Mappingadapter, globale Katalogverwaltung, Katalog→Projektventil-Zuordnung, Report-Provenienz, Core-Tests, komplette Debug-iOS-Matrix und echter HeizBalance-Release-Build erfolgreich.

## Noch bewusst gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-Freigabe / GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung, auch bei importierten echten Herstellerdaten.
- Vollautomatische Auswahl konkreter Ersatzheizkörper; HeizBalance erlaubt technisch passende Kandidaten und eine explizite Benutzerauswahl.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne rechtlich und fachlich verifizierte Datensatzspezifikation.
- Echte Wärmepumpenauslegung, COP-/Bivalenz- und Betriebspunktbewertung der Wärmepumpe.
- Flächenheizung nach DIN EN 1264 als eigener Fachblock.

## Nächste Entwicklungsschritte
1. Erste echte Hersteller-/Lizenzquelle für Heizkörper- und/oder Ventildaten rechtlich klären und über die neuen Mappingprofile als Referenzdatensatz validieren.
2. Produktdatenstrategie für Pumpen auf dieselbe dokumentierte Architektur setzen, ohne automatische Pumpenauswahl vor fachlicher Validierung freizugeben.
3. PDF-Ausgabe mit größeren realistischen Projekten, Katalogventilen und ausgewählten Ersatzheizkörpern visuell sowie auf Seitenumbrüche testen.
4. Parallel die fachliche Spezifikation der späteren Norm-Heizlastmodule anhand rechtmäßig zugänglicher Regelwerksunterlagen und belastbarer Referenzfälle aufbauen.
5. Erst nach echter fachlicher Referenzvalidierung normative Gates schrittweise freigeben.
