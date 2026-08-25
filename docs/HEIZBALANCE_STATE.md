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
- Keine DIN-/VDI-Texte, Tabellen, Grafiken, VdZ-Formularlayouts oder ungeklärten Herstellerdaten werden in App oder Repository kopiert.
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
13. Pumpenkennlinien werden außerhalb ihres dokumentierten Volumenstrombereichs nicht extrapoliert.
14. Ein technisch ausreichender Pumpenkennlinienvergleich ist keine automatische Pumpenauswahl oder Herstellerfreigabe.

## Aktueller Stand – Foundation Pass 19

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

### Hersteller-/Produktdaten und Ersatzheizkörper – Pass 15
- Internes, versioniertes Heizkörper-Katalogschema `radiator-product-dataset-v1`.
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

### VDI 3805 Produktdatenadapter – Heizkörper – Pass 16
- Adapterprofil `vdi-3805-part6-mapped-v1` für autorisiert erzeugte, normalisierte Mappings mit Bezug auf VDI 3805 Blatt 6.
- Der Adapter ist bewusst kein Rohparser der Richtlinie und enthält keine nachgebauten geschützten Satzbeschreibungen.
- `HeizBalanceRadiatorDatasetImportDecoder` erkennt automatisch natives `radiator-product-dataset-v1` oder `vdi-3805-part6-mapped-v1`.
- Standardbezug und Mappingprofil bleiben im Quellen-/Rechtehinweis nachvollziehbar.
- Format und fiktives Beispiel: `docs/HEIZBALANCE_VDI3805_IMPORT.md`.

### Hydraulik
- Explizite Fluiddichte und kinematische Viskosität; keine versteckten Wasser-/Glykolannahmen.
- Rohrabschnitte mit Rolle, Innendurchmesser, hydraulischer Länge, Rauheit, ζ-Summe und ggf. explizitem Abschnittsvolumenstrom.
- Trennung zwischen Heizflächen-Anbindung und gemeinsamer Verteilung.
- Berechnung von Geschwindigkeit, Reynolds-Zahl, Rohrreibung, geradem und lokalem Druckverlust.
- Hydraulische Bauteile getrennt erfassbar: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, vollständigen Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
- Projektaggregation bildet Verbraucher-Gesamtvolumenstrom und hydraulisch ungünstigsten Parallelkreis; parallele Kreisverluste werden nicht addiert.
- Technischer Pumpen-Betriebspunkt nur bei vollständiger Abdeckung.

### Ventile und Armaturen-Produktdaten – Pass 17
- `HeizBalanceValveSizingPreparationCalculator` berechnet den erforderlichen technischen kv aus Zielvolumenstrom, Ventil-Δp und Fluiddichte.
- Referenzfall 0,6 m³/h bei 12 kPa ergibt rund kv 1,73 m³/h.
- `HeizBalanceValvePresetComparisonCalculator` zeigt unteren/oberen und mathematisch nächstliegenden Punkt, Bereichsstatus und Abweichung.
- Mathematische Nähe wird ausdrücklich nicht als automatische Hersteller-Voreinstellung ausgegeben.
- Internes Katalogschema `valve-product-dataset-v1` mit Hersteller, Datensatzstand, Quelle/Nutzungsgrundlage, Produkten und diskreten `Voreinstellung → kv`-Punkten.
- Globaler transaktionaler `HeizBalanceValveDatasetStore` und Katalog-UI.
- Ein Katalogprodukt kann ausdrücklich einem konkreten Thermostat- oder Rücklaufventil im Projekt zugeordnet werden.
- Beim Übernehmen werden Hersteller, Produkt, Datenstand, Quelle, Artikel-/Katalogreferenzen und Kennlinienpunkte in das Projekt kopiert.
- VDI-Adapter `vdi-3805-part2-mapped-v1`; Format und fiktives Beispiel: `docs/HEIZBALANCE_VDI3805_VALVE_IMPORT.md`.
- Die Übernahme eines Ventilprodukts setzt ausdrücklich keine Voreinstellung automatisch.

### Pumpen-Produktdaten / VDI 3805 Blatt 4 – Pass 18
- Internes, versioniertes Pumpenkatalogschema `pump-product-dataset-v1`.
- Datensatzmetadaten: ID, Hersteller, Datensatzname, Datenstand, Quellenreferenz, Quellen-URL, Nutzungsgrundlage und Rechtehinweis.
- Pumpenprodukte enthalten Produkt-ID, Name, optionale Serie/Artikelnummer/Quelle und eine oder mehrere dokumentierte Kennlinien.
- Kennlinien enthalten ID, Bezeichnung, optionale Regel-/Betriebsart, optionale Drehzahl, Quelle und mindestens zwei Kennlinienpunkte.
- Kennlinienpunkte enthalten Volumenstrom in m³/h, Förderhöhe in m und optional elektrische Aufnahmeleistung in W.
- Harte Validierung für Produkt-/Kennlinien-/Punkt-IDs, doppelte Kennlinien-IDs, doppelte Volumenstrompunkte und ungültige/nicht-endliche Werte.
- Globaler transaktionaler `HeizBalancePumpDatasetStore` mit lokalem Import/Löschen.
- Globales UI `Pumpendaten` im Produktdaten-Menü mit Katalog-, Produkt- und Kennliniendetails.
- Adapterprofil `vdi-3805-part4-mapped-v1` für normalisierte, dokumentierte Mappings mit Bezug auf VDI 3805 Blatt 4.
- `HeizBalancePumpDatasetImportDecoder` erkennt natives `pump-product-dataset-v1` oder `vdi-3805-part4-mapped-v1`.
- Der Adapter ist kein Rohparser und baut keine geschützten VDI-Satzbeschreibungen nach.
- Dokumentation und fiktives Mapping-Beispiel: `docs/HEIZBALANCE_VDI3805_PUMP_IMPORT.md`.
- CI #181 validiert Pumpenkatalog-Unterbau, komplette Debug-Matrix und echten HeizBalance-Release-Build.

### Pumpenkennlinie gegen Projekt-Betriebspunkt – Pass 19
- Core-Baustein `HeizBalancePumpCurveOperatingPointCalculator` mit Rechenprofil `linear-documented-pump-curve-v1`.
- Eingaben: technischer Projekt-Gesamtvolumenstrom, erforderliche Förderhöhe und dokumentierte Punkte einer konkreten Pumpenkennlinie.
- Ein exakt dokumentierter Volumenstrompunkt wird unverändert verwendet.
- Zwischen zwei dokumentierten Punkten werden Förderhöhe und – nur wenn an beiden Punkten vorhanden – elektrische Aufnahmeleistung linear interpoliert.
- Unterhalb des kleinsten bzw. oberhalb des größten dokumentierten Volumenstroms wird kein Ergebnis erzeugt: keine Extrapolation.
- Ergebnis enthält verfügbare Förderhöhe, erforderliche Förderhöhe, Reserve, ausreichend/nicht ausreichend, optional elektrische Aufnahme sowie verwendete Begrenzungspunkte.
- Projekt-UI `Pumpenkennlinien & Betriebspunkt` zeigt den vollständigen hydraulischen Betriebspunkt und bewertet jede importierte Kennlinie einzeln.
- Außerhalb des dokumentierten Kennlinienbereichs zeigt die App ausdrücklich `nicht bewertbar – keine Extrapolation`.
- Ein ausreichendes Kennlinienergebnis ist ausdrücklich keine automatische Pumpenauswahl, Regelartwahl, Effizienzfreigabe oder Herstellerfreigabe.
- Technischer Regressionfall in `docs/HEIZBALANCE_REFERENCE_CASES.md`: 1,5 m³/h zwischen 1,0/4,0 m/28 W und 2,0/2,0 m/40 W ergibt 3,0 m und 34 W; bei 3,2 m Bedarf Reserve −0,2 m und damit nicht ausreichend.

### Niedertemperatur-Minimalcheck
- `HeizBalanceLowTemperatureCheckCalculator` bestimmt bei fester expliziter Wasserspreizung die minimal technisch ausreichende VL/RL-Kombination je Heizfläche.
- Projektweit wird die Heizfläche mit der höchsten erforderlichen Vorlauftemperatur als begrenzend ausgewiesen.
- Systemwert wird gesperrt, solange mindestens eine Heizfläche nicht auswertbar ist.
- Keine Wärmepumpenauslegung, COP-/Bivalenzbewertung oder Norm-Heizlast.

### Temperatur-Szenarien / Sanierungsbewertung
- Core: `HeizBalanceTemperatureScenarioCalculator`.
- Pro Heizfläche: mittlere Übertemperatur, verfügbare Leistung, Deckungsgrad, ausreichend/nicht ausreichend, erforderliche Nennleistung ΔT50 und Nennleistungsfaktor.
- Projekt-Matrix enthält persistentes Sanierungsziel, Projekt-Temperaturniveau sowie 50/40, 45/35, 45/40 und 40/35 °C.
- Frei eingegebenes Ziel-VL/RL samt Quelle kann als persistentes Sanierungsziel gespeichert/gelöscht werden.
- Dashboard zeigt `Ziel erreichbar`, `Upgradebedarf`, `Daten unvollständig` oder noch keine Heizflächen.
- Ohne importierte Produktdaten wird kein Ersatzmodell erfunden; mit gültigen Produktdaten werden technisch passende Kandidaten angezeigt, die Auswahl bleibt explizit beim Benutzer.

### Technisches Musterprojekt / Regression
- Fiktives Entwicklungsprojekt mit drei Räumen; Entwicklungsmenü ist `#if DEBUG` und fehlt im Release-Build.
- Fixed-spread Regression bei 10 K: Wohnzimmer ca. 43,8/33,8 °C, Schlafzimmer ca. 42,7/32,7 °C, Bad ca. 47,4/37,4 °C.
- 45/35 °C reicht bewusst nicht; Bad ist begrenzend.
- Szenario 45/35 °C: Wohnzimmer ca. 109 %, Schlafzimmer ca. 117 %, Bad ca. 83 %; Bad benötigt rund 2.639 W ΔT50 statt 2.200 W, Faktor rund ×1,20.
- Sämtliche Fälle in `docs/HEIZBALANCE_REFERENCE_CASES.md` sind technische Regressionen, keine DIN-/Norm-Referenzfälle.

### Bericht / PDF / Reproduzierbarkeit – Stand Pass 19
- Hauptsnapshot `technical-report-v1`.
- Niedertemperatur-Snapshot `technical-low-temperature-v1`, Profil `fixed-spread-emitter-check-v1`.
- Szenario-Snapshot `technical-temperature-scenarios-v1`, Profil `explicit-flow-return-emitter-sizing-v1`.
- Ersatzheizkörper-Snapshot `technical-radiator-replacements-v1`.
- Neuer Pumpenkennlinien-Snapshot `technical-pump-curves-v1`, Profil `linear-documented-pump-curve-v1`.
- Pumpen-Snapshot friert Projekt-Betriebspunkt, vollständige Katalog-/Quellenmetadaten, Kennlinien, dokumentierte Kennlinienpunkte und die daraus erzeugte technische Bewertung ein.
- Alle fünf Snapshots erhalten beim selben Export exakt denselben Zeitstempel und bleiben getrennt versioniert.
- Ein gemeinsames PDF wird aus fünf A4-Teilen über PDFKit zusammengeführt: Hauptbericht, Niedertemperatur, Temperatur-Szenarien, Ersatzheizkörper-Auswahl und Pumpenkennlinien/Betriebspunkt.
- Nach erfolgreichem PDF-Export werden alle fünf JSON-Snapshots getrennt archiviert; fehlgeschlagene/abgebrochene Exporte erzeugen keinen falschen Archivstand.
- Archivbegrenzung: letzte 10 Exportstände je Projekt und Berichtstyp.
- `technical-report-v1` enthält für dokumentierte Ventile weiterhin optionale Katalog-/Produkt-/Quellen-/Rechteprovenienz; alte Archive bleiben lesbar.

### Release-Härtung
- Entwicklungs-Musterprojekt im Release-Build durch `#if DEBUG` vollständig entfernt.
- CI baut die komplette App-Matrix in Debug.
- Für HeizBalance existiert zusätzlich ein echter Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden in CI geprüft.
- PR-CI nutzt `cancel-in-progress`, sodass veraltete Zwischenläufe automatisch abgebrochen werden.

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
- #100 Release-Gate: HeizBalance Debug + echter Release-Build grün.
- #111: Foundation Pass 12 grün – Szenario-/3-PDF-Pfad und Release-Build.
- #120: Foundation Pass 13 grün – persistentes Sanierungsziel und zentrale Reportszenariointegration.
- #123: Foundation Pass 14 grün – Sanierungsziel-Dashboardstatus.
- #154: Foundation Pass 15 grün – Heizkörper-Herstellerdatenschema, Matching, explizite Ersatzwahl und vierter Reportpfad.
- #159: Foundation Pass 16 grün – VDI-3805-Blatt-6-Mappingadapter und Importschemaerkennung.
- #173: Foundation Pass 17 grün – Ventilkatalogschema, VDI-3805-Blatt-2-Adapter, Katalog→Projektventil und Report-Provenienz.
- #181: **Foundation Pass 18 vollständig grün** – Pumpenkatalogschema, VDI-3805-Blatt-4-Adapter, globaler Pumpendaten-Store/UI, Core-Tests, komplette Debug-iOS-Matrix und echter HeizBalance-Release-Build.
- #192: **Foundation Pass 19 vollständig grün** – versionierter Pumpenkennlinien-/Betriebspunkt-Core, harte No-Extrapolation-Regel, Projektvergleich, `technical-pump-curves-v1`, fünfter PDF-/Archivpfad, Regressionstests, komplette Debug-iOS-Matrix und echter HeizBalance-Release-Build.

## Noch bewusst gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-Freigabe / GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung, auch bei importierten echten Herstellerdaten.
- Vollautomatische Auswahl konkreter Ersatzheizkörper; HeizBalance erlaubt technisch passende Kandidaten und eine explizite Benutzerauswahl.
- Automatische Pumpenproduktempfehlung/-auswahl, Regelartwahl und Effizienzfreigabe.
- Pumpenkennlinien-Extrapolation außerhalb dokumentierter Datenbereiche.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne rechtlich und fachlich verifizierte Datensatzspezifikation.
- Echte Wärmepumpenauslegung, COP-/Bivalenz- und Betriebspunktbewertung der Wärmepumpe.
- Flächenheizung nach DIN EN 1264 als eigener Fachblock.

## Nächste Entwicklungsschritte
1. Explizite Benutzer-Auswahl eines Pumpenprodukts/einer Kennlinie als versionierten Projektsnapshot ergänzen – analog zur Heizkörperauswahl, weiterhin ohne automatische Empfehlung.
2. Pumpenvergleich optional um dokumentierte elektrische Aufnahme und technische hydraulische Leistungskennzahlen erweitern, ohne eine Effizienz-/ErP-Aussage zu erfinden.
3. Erste echte Hersteller-/Lizenzquellen für Heizkörper-, Ventil- und Pumpendaten rechtlich klären und über die Mappingprofile als Referenzdaten validieren.
4. PDF-Ausgabe mit größeren realistischen Projekten und umfangreichen Produktkatalogen visuell sowie auf Seitenumbrüche testen.
5. Parallel die fachliche Spezifikation der späteren Norm-Heizlastmodule anhand rechtmäßig zugänglicher Regelwerksunterlagen und belastbarer Referenzfälle aufbauen.
6. Erst nach echter fachlicher Referenzvalidierung normative Gates schrittweise freigeben.
