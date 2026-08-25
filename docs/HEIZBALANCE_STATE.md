# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Wärmeverlust-/Heizlastvorbereitung, Heizflächenprüfung, Niedertemperaturbewertung, hydraulische Vorbereitung und nachvollziehbare Baustellendokumentation.

## Produkt
- App Store: `HeizBalance`
- Target: `HeizBalance`
- Bundle Identifier: `de.kamilunavo.heizbalance`
- App Store Connect: angelegt am 25.08.2026
- Branch: `feature/heizbalance-foundation`
- Draft-PR: #12

## Norm- und Compliance-Strategie
- Rechenverfahren werden eigenständig implementiert.
- Keine DIN-/VDI-Texte, Tabellen, Grafiken, VdZ-Formularlayouts oder ungeklärten Herstellerdaten werden in App oder Repository kopiert.
- Rechenengine, Produktdatenadapter, Auswahl-Snapshots und Berichte werden versioniert.
- Technische Vorbereitungen werden nicht als Norm-Heizlast, Verfahren-B-Nachweis, GEG-/BEG-Nachweis, Wärmepumpenauslegung oder Herstellerfreigabe bezeichnet.
- Das reservierte Profil `de-room-heat-load-2017-2020` bleibt technisch gesperrt, bis Spezifikation und Referenzfälle vollständig fachlich verifiziert sind.
- Regelwerks-/Quellenstand: `docs/HEIZBALANCE_NORM_RESEARCH.md`.
- Referenz-/Regressionstrategie: `docs/HEIZBALANCE_REFERENCE_CASES.md`.
- Produktdatenadapter verarbeiten nur dokumentierte, rechtmäßig nutzbare Datenquellen; geschützte Roh-Datensatzbeschreibungen werden nicht nachgebaut.

## Qualitäts-Gates
1. Keine proprietären Norminhalte im Repository.
2. Rechenfunktionen mit Unit-/Regressionstests absichern.
3. Normative Module benötigen verifizierte Spezifikation und Referenzabdeckung.
4. Spätere normative Ergebnisse gegen etablierte Fachsoftware bzw. fachlich geprüfte Referenzrechnungen gegenprüfen.
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
15. Eine Pumpe/Kennlinie darf nur nach ausdrücklicher Benutzeraktion und nur bei technisch ausreichender Abdeckung des aktuellen Betriebspunkts festgehalten werden.
16. Eine festgehaltene Pumpenauswahl wird eingefroren und bei geändertem/unvollständigem Betriebspunkt als neu zu bewerten markiert.
17. Hydraulische Pumpen-Leistungskennzahlen sind technische Rechengrößen; insbesondere `Pₕ,erf/P₁` ist kein EEI-/ErP-/Hersteller-Wirkungsgradnachweis.
18. Eine katalogübergreifende Sortierung technisch ausreichender Kennlinien darf nicht als Produktempfehlungs-Ranking ausgegeben werden.
19. Aufnahme-Schnellvorlagen dürfen keine versteckten normativen U-Werte, Luftwechselwerte oder thermischen Randtemperaturen einführen.
20. Beim Duplizieren werden neue IDs erzeugt; hydraulische Entscheidungen, Lastzuordnungen und Ersatzprodukt-Auswahlen werden nicht still mitkopiert.
21. Eigene Bauteilvorlagen speichern keine Fläche und keine raumspezifische Gegenseitentemperatur.
22. Hydraulikvorlagen dürfen Rohrgeometrie, Rauheit, ζ-Werte, Bauteilarten und dokumentierte Ventilprodukt-Identität übernehmen; flow-/druckabhängige Werte, deren Quellen und Vollständigkeitsfreigaben werden zurückgesetzt.
23. Eine konkrete Thermostat-/Rücklaufeinstellung darf ausschließlich durch ausdrückliche Benutzeraktion aus einem dokumentierten Produktdatenpunkt festgehalten werden; der mathematisch nächste kv-Punkt wird nie automatisch zur Einstellung.
24. Ändern sich Zielvolumenstrom, Ventil-Δp, Fluiddichte oder Ventilproduktdaten, wird eine festgehaltene Ventileinstellung als `neu bewerten` behandelt und nicht still aktualisiert.
25. Die Baustellen-Einstellliste ist ein technischer Arbeitsnachweis und ausdrücklich kein nachgebautes VdZ-/Verfahren-B-Formular.

## Aktueller Stand – Foundation Batch 21–29

### 1. Projekt- und Gebäudeaufnahme
- Persistente lokale Struktur Projekt → Geschoss → Raum → Bauteil → Heizfläche.
- Projektfelder: Kunde, Adresse, Baujahr, Auslegungs-Außentemperatur, System-VL/RL, Quellen, Hydraulik-Fluidwerte, Sanierungsziel und Notizen.
- Raum: Geometrie, Solltemperatur, Luftwechsel, Quelle, thermische Bauteile und Heizflächen.
- Bauteile: Art, Fläche, U-Wert, Quelle und thermische Randbedingung.
- Außenluft oder explizite Gegenseitentemperatur; keine versteckten Pauschalwerte für angrenzende Bereiche.

### 2. Technische Wärmeverlust-Vorbereitung
- `HeizBalanceHeatLossPreviewCalculator` berechnet Transmission und Lüftung ausschließlich aus expliziten Eingaben.
- Raumübersicht zeigt Transmission, Lüftung, Summe und W/m².
- Gebäudesumme nur bei vollständig erfassten Räumen.
- Profil `technical-preview-v1` bleibt ausdrücklich nicht normativ.

### 3. Heizflächen / Niedertemperatur / Sanierungsziel
- Heizflächen enthalten Art, Bezeichnung, Hersteller/Modell optional, Nennleistung ΔT50, Exponent, Quelle, zugeordnete erforderliche Leistung und Notiz.
- Verfügbare Heizflächenleistung und erforderliche Leistung sind getrennt.
- Ziel-Volumenstrom aus zugeordneter erforderlicher Leistung und expliziter Wasserspreizung.
- `HeizBalanceLowTemperatureCheckCalculator` bestimmt bei fester Spreizung die minimal technisch ausreichende VL/RL-Kombination.
- System-Minimaltemperatur nur, wenn alle Heizflächen auswertbar sind.
- Persistentes Sanierungsziel und Szenario-Matrix u. a. 50/40, 45/35, 45/40 und 40/35 °C.
- Dashboard unterscheidet `Ziel erreichbar`, `Upgradebedarf` und `Daten unvollständig`.

### 4. Produktdatenfundament – Pass 15–18
- Heizkörper: `radiator-product-dataset-v1`, technisches Matching und ausdrückliche `radiator-replacement-selection-v1`.
- Heizkörper-VDI-Mapping: `vdi-3805-part6-mapped-v1`.
- Ventile: `valve-product-dataset-v1` mit diskreten `Voreinstellung → kv`-Punkten und VDI-Mapping `vdi-3805-part2-mapped-v1`.
- Pumpen: `pump-product-dataset-v1` mit dokumentierten Q/H-/optional-P₁-Kennlinien und VDI-Mapping `vdi-3805-part4-mapped-v1`.
- Alle Importe erhalten Hersteller, Datensatzstand, Quelle, Nutzungsgrundlage und Rechtehinweise.
- Mappingprofile sind autorisiert erzeugte normalisierte Eingaben, keine Rohparser geschützter VDI-Satzstrukturen.

### 5. Hydraulische Berechnungsvorbereitung
- Explizite Fluiddichte und kinematische Viskosität; keine versteckten Wasser-/Glykolwerte.
- Rohrabschnitte mit Rolle, Innendurchmesser, hydraulischer Länge, Rauheit, ζ-Summe und ggf. explizitem Abschnittsvolumenstrom.
- Heizflächen-Anbindung nutzt den terminalen Zielvolumenstrom; gemeinsame Verteilung benötigt ihren realen summierten Abschnittsvolumenstrom samt Quelle.
- Berechnung von Geschwindigkeit, Reynolds-Zahl, Rohrreibung sowie geradem/lokalem Druckverlust.
- Hydraulische Bauteile getrennt erfassbar: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
- Projektaggregation: Verbraucher-Gesamtvolumenstrom + hydraulisch ungünstigster Parallelkreis; parallele Kreisverluste werden nicht addiert.
- Pumpen-Betriebspunkt nur bei vollständiger hydraulischer Abdeckung.

### 6. Ventil-kv-Vorbereitung
- `HeizBalanceValveSizingPreparationCalculator` berechnet erforderlichen technischen kv aus Zielvolumenstrom, Ventil-Δp und Dichte.
- Ventilproduktdaten können einem konkreten Thermostat-/Rücklaufventil zugeordnet werden.
- Der nächstliegende diskrete Datenpunkt wird ausschließlich als technischer Vergleich angezeigt und ist keine automatische Voreinstellung.

### 7. Pumpenkennlinie / Betriebspunkt – Pass 19–24
- `linear-documented-pump-curve-v1`: exakte Herstellerpunkte bleiben unverändert; lineare Interpolation nur zwischen dokumentierten Punkten.
- Keine Extrapolation unter/über dem dokumentierten Q-Bereich.
- Ergebnis: verfügbare H, erforderliche H, Reserve, technisch ausreichend/nicht ausreichend, optional interpoliertes P₁ und verwendete Begrenzungspunkte.
- `pump-curve-selection-v1`: nur ausdrücklicher Benutzer-Tap kann eine technisch ausreichende Pumpe/Kennlinie festhalten.
- Auswahl friert Katalog-/Quellen-/Rechte-/Produkt-/Kennlinien-/Betriebspunktdaten ein und wird bei geänderter Hydraulik `neu bewerten`.
- Projektweiter Pumpen-Arbeitsbereich vergleicht alle importierten Kennlinien; Filter `Alle / Ausreichend / Zu wenig / Außerhalb`.
- `pump-technical-metrics-v1`: hydraulische Leistungsanforderung, verfügbare hydraulische Leistung, H-Reserve m/%, Q-Bereichsposition und optional `Pₕ,erf/P₁`.
- `Pₕ,erf/P₁` ist ausdrücklich keine Wirkungsgrad-, EEI-, ErP- oder Herstellerfreigabe.

### 8. Projekt-Cockpit / Projektliste – Batch 21–24
- Projekteditor zeigt Raumstatus, Sanierungsziel, Hydraulikbetriebspunkt und Pumpenentscheidung auf einen Blick.
- Projektliste besitzt kompakte Statuschips `Räume`, `Hydraulik`, `Pumpe`.
- Veraltete Pumpenentscheidungen werden sichtbar orange als neu zu bewerten markiert.

### 9. Schnelle Vor-Ort-Aufnahme – Batch 25
- Geschosse und Räume können sicher dupliziert werden; alle relevanten IDs werden erneuert.
- Raum-Schnellvorlagen: Wohnzimmer, Schlafzimmer, Bad, Küche, Flur, Arbeitszimmer.
- Bauteilsätze legen ausschließlich Bauteilarten ohne versteckte U-Werte/Flächen/Normannahmen an.
- Bauteile können dupliziert werden.
- Physische Heizflächenkopien dürfen Hersteller/Modell/Nennleistung/Exponent übernehmen, setzen aber zugeordnete Last, Rohrnetz, Bauteilverluste, Vollständigkeitsstatus und Ersatzproduktentscheidung zurück.
- Persistentes `component-favorite-v1` für eigene Bauteil-/U-Wert-Favoriten.
- Favoriten speichern Art, Bezeichnung, U-Wert, Quelle und Notiz; niemals Fläche oder raumspezifische Gegenseitentemperatur.
- Favoriten können als neues Bauteil eingesetzt oder auf ein bestehendes Bauteil angewendet werden.
- Zentrale Verwaltung unter `Daten & Vorlagen → Bauteilvorlagen`.

### 10. Sichere Hydraulik-Wiederverwendung – Batch 26
- Neues persistentes Schema `hydraulic-capture-template-v1`.
- Hydraulikvorlagen speichern wiederverwendbare Rohrstruktur: Bezeichnung, Rolle, Innendurchmesser, Länge, Rauheit, ζ und Notiz.
- Gemeinsame Abschnittsvolumenströme und deren Quellen werden beim Speichern/Anwenden bewusst entfernt.
- Hydraulische Bauteile übernehmen Art/Bezeichnung/Notiz und ggf. dokumentierte Ventilprodukt-Identität.
- Bauteil-Δp, deren Quellen und die Vollständigkeitsbestätigung werden bewusst entfernt.
- Ganze Heizflächenkreise lassen sich im Projekt kopieren; physische Heizflächendaten und sichere Hydraulikstruktur dürfen mitkommen, Lastzuordnung und flow-/druckabhängige Entscheidungen nicht.
- Einzelne Rohrabschnitte und hydraulische Bauteile lassen sich ebenfalls sicher duplizieren.
- `HeizBalanceHydraulicCaptureTemplateStore` arbeitet lokal, versioniert und transaktional.
- Globale Verwaltung `Daten & Vorlagen → Hydraulikvorlagen`.

### 11. Hydraulik-Aufnahme-Workspace – Batch 27
- Neue Projektansicht `Hydraulik-Aufnahme & Einstellliste` zeigt alle Heizflächenkreise geschoss-/raumbezogen.
- Pro Kreis werden aktueller Zielvolumenstrom, vollständiger Kreis-Δp und Rohrabschnittszahl angezeigt.
- Per Kreis können Rohrweg und hydraulische Bauteile direkt bearbeitet, ergänzt, gelöscht oder dupliziert werden.
- Aktuelle Kreisstruktur kann als Vorlage gespeichert oder aus einer Vorlage ersetzt werden.
- Beim Ersetzen/Löschen einer Hydraulikstruktur werden dazugehörige verwaiste Ventileinstellungs-Snapshots transaktional entfernt.
- Die Vollständigkeitsbestätigung `Bauteilaufnahme vollständig` ist direkt im schnellen Kreiseditor verfügbar und bleibt gesperrt, solange ein erfasstes Bauteil keinen gültigen Δp-Wert besitzt.

### 12. Explizite Thermostat-/Rücklaufeinstellung – Batch 28
- Neues versioniertes Schema `valve-setting-selection-v1`.
- Eine Einstellung kann nur aus einem tatsächlich hinterlegten diskreten Produktdatenpunkt und nur durch ausdrücklichen Benutzer-Tap festgehalten werden.
- Eingefroren werden Projekt-/Kreis-/Bauteil-ID, Art/Name, gewählter Einstellpunkt und kv, damaliger Soll-kv, Zielvolumenstrom, Ventil-Δp, Fluiddichte sowie Hersteller-/Produkt-/Datensatz-/Quellen-/Rechteprovenienz.
- `HeizBalanceValveSettingSelectionStore` hält projekt-/bauteilbezogene Entscheidungen lokal und transaktional.
- `matchesCurrent` prüft aktuellen Soll-kv, Volumenstrom, Δp, Dichte und Produkt-/Datensatzidentität.
- Sobald sich relevante Eingaben ändern oder der Datenpunkt nicht mehr existiert, erscheint `neu bewerten`; die alte Auswahl wird nicht still ersetzt.
- Thermostat- und Rücklaufentscheidungen sind unabhängig voneinander festhaltbar.
- Der mathematisch nächste kv-Punkt bleibt lediglich Vergleich und wird niemals automatisch übernommen.

### 13. Baustellen-Einstellliste – Batch 29
- Neues unabhängiges Snapshot-Schema `technical-adjustment-list-v1`.
- Die Liste enthält pro Heizflächenkreis Geschoss/Raum/Heizfläche, Zielvolumenstrom, vollständigen Kreis-Δp, Thermostat- und Rücklaufdaten, Soll-kv, ausdrücklich festgehaltene Einstellungen und deren Aktualitätsstatus.
- Offene Punkte werden pro Kreis sichtbar aufgeführt: fehlender Q, fehlender vollständiger Δp, fehlendes Thermostatventil, fehlende Einstellung oder `neu bewerten`.
- Eine festgehaltene Pumpenentscheidung wird inkl. Betriebspunkt/Reserve und Aktualitätsstatus aufgenommen.
- Eigenständiger kompakter mehrseitiger A4-PDF-Renderer für die Baustelle.
- Permanenter Hinweis: technische Vorbereitung, keine Verfahren-B-/GEG-/BEG-/Herstellerfreigabe.
- Kein nachgebautes VdZ-Formularlayout.
- Erfolgreicher PDF-Export archiviert exakt den verwendeten JSON-Snapshot; abgebrochene/fehlgeschlagene Exporte erzeugen keinen falschen Archivstand.
- Eigenes Projektarchiv mit maximal 10 `technical-adjustment-list-v1`-Ständen.

### 14. Technischer Bericht / Reproduzierbarkeit
Bestehender Hauptbericht-Stack bleibt unverändert stabil:
- `technical-report-v1`
- `technical-low-temperature-v1`
- `technical-temperature-scenarios-v1`
- `technical-radiator-replacements-v1`
- `technical-pump-curves-v1`

Eigenschaften:
- ein Exportzeitpunkt für die Hauptberichtsteile,
- getrennte versionierte JSON-Archive,
- gemeinsames mehrteiliges A4-PDF über PDFKit,
- maximal letzte 10 Exportstände je Projekt/Berichtstyp.

Zusätzlich steht `technical-adjustment-list-v1` als bewusst eigenständiger Baustellen-PDF-/Archivpfad bereit, damit der stabile Hauptbericht nicht für jeden Baustellenworkflow umgebaut werden muss.

## Technische Regressionen / Invarianten
`docs/HEIZBALANCE_REFERENCE_CASES.md` enthält u. a.:
- technischer kv-Fall 0,6 m³/h bei 12 kPa → kv ≈ 1,73,
- Niedertemperatur-Musterprojekt mit begrenzendem Bad,
- 45/35-Szenario mit bewusstem Heizflächen-Upgradebedarf,
- Pumpenkennlinien-Interpolation mit harter No-Extrapolation-Regel,
- Pumpen-Leistungskennzahlen,
- Aufnahme-Invarianten für Geschoss-/Raum-/Heizflächenkopien und Bauteilfavoriten,
- Hydraulikvorlagen-/Kreiskopier-Invarianten,
- explizite Ventileinstellungs-/Stale-Regeln,
- Baustellen-Einstelllisten-Regeln.

## Release-Härtung
- Entwicklungs-Musterprojekt durch `#if DEBUG` vollständig aus Release entfernt.
- CI baut komplette App-Matrix in Debug.
- HeizBalance besitzt zusätzlich ein echtes Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden geprüft.
- PR-CI nutzt `cancel-in-progress`, sodass Zwischenstände automatisch abgebrochen werden.
- Swift-6-Concurrency-Prüfungen bleiben aktiv; mutable UI-Persistenzstores sind `@MainActor`-isoliert.

## Validierte CI-Checkpoints
- #50–#100: Heizflächen-, Hydraulik-, Ventil-, PDF-, Archiv-, Niedertemperatur- und Release-Grundlagen grün.
- #111: Szenario-/3-PDF-Pfad grün.
- #120/#123: persistentes Sanierungsziel + Dashboard grün.
- #154/#159: Heizkörper-Produktdaten, Ersatzwahl, VDI-Blatt-6-Adapter grün.
- #173: Ventilkatalog + Blatt-2-Adapter grün.
- #181: Pumpenkatalog + Blatt-4-Adapter grün.
- #192: Pumpenkennlinien-/Betriebspunkt-Core + No-Extrapolation + fünfter Berichtspfad grün.
- #202/#203: explizite Pumpen-/Kennlinienauswahl + Stale-Erkennung + Release grün.
- #212/#213: Pumpen-Cockpit, katalogübergreifender Vergleich, Leistungskennzahlen, Report/PDF und Projektlistenstatus grün.
- #231: Batch 25 schnelle Vor-Ort-Aufnahme; Core, vollständige Debug-iOS-Matrix und echter HeizBalance-Release-Build grün.
- #249: Hydraulik-Batch fing im Gate einen reinen Swift-Syntaxfehler am failable Ventilauswahl-Initializer ab; kein fachlicher Rechenfehler.
- **#250: finaler Code-Head für Batch 26–29 vollständig grün: Core-Tests, gesamte Debug-iOS-Matrix, HeizBalance Debug und echter HeizBalance Release-Simulator-Build.**

## Noch bewusst gesperrt / offen
- Norm-Heizlast nach DIN EN 12831-1 + deutschem Ergänzungsregelwerk.
- Verfahren-B-Freigabe / GEG-/BEG-Konformitätsaussage.
- Automatische Ventilvoreinstellung.
- Vollautomatische Auswahl konkreter Ersatzheizkörper.
- Automatische Pumpenproduktempfehlung/-auswahl, Regelartwahl und Effizienzfreigabe.
- Pumpenkennlinien-Extrapolation außerhalb dokumentierter Datenbereiche.
- EEI-/ErP-/Hersteller-Wirkungsgradaussage aus den technischen Pumpenkennzahlen.
- Rohdatenparser für VDI-3805-Herstellerdateien ohne rechtlich/fachlich verifizierte Datensatzspezifikation.
- Echte Wärmepumpenauslegung, COP-/Bivalenzbewertung.
- Flächenheizung nach DIN EN 1264 als eigener Fachblock.
- Normativer hydraulischer Abgleich / Verfahren-B-Nachweis bleibt gesperrt, auch wenn die technische Einstellliste vollständig ist.

## Nächste größere Entwicklungsblöcke
1. Baustellenbericht produktionsreif machen: Techniker/Firma/Datum, Projektstatus, Unterschriftsbereich, kompakte Ergebniszusammenfassung und große Projekte/Seitenumbrüche härten.
2. Hydraulikdaten weiter produktionsnah machen: optionale Netzbaum-Struktur für automatische gemeinsame Abschnittsvolumenströme statt manueller Summenwerte.
3. Echte Hersteller-/Lizenzquellen für Heizkörper-, Ventil- und Pumpendaten rechtlich klären und über die vorhandenen Mappingprofile als Referenzdaten validieren.
4. Parallel normative Heizlast-Spezifikation und belastbare Referenzfälle aufbauen; Freigabe erst nach echter fachlicher Validierung.
5. Danach eigener Fachblock Flächenheizung bzw. echte Wärmepumpen-/Bivalenzbewertung – getrennt von den bereits vorhandenen Heizkörper-/Niedertemperaturprüfungen.

## Batch-Verifikation
- Der maßgebliche Code-Head `a618b2630b057f9bc6e85ec1b143a480a1a7670e` wurde in CI #250 vollständig erfolgreich validiert.
- Der finale Dokumentations-Head enthält ausschließlich Handoff-/Referenzdokumentation und wird zusätzlich durch dieselbe PR-CI geprüft.
