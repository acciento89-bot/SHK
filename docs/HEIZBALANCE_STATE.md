# HeizBalance – Projektstand

## Ziel
Mobile SHK-Fachanwendung für raumweise Heizlast, Heizflächenprüfung, Niedertemperaturbewertung und hydraulischen Abgleich mit nachvollziehbarer Projektdokumentation.

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
- Rechenengine, Auswahl-Snapshots und Berichte werden versioniert.
- Technische Vorbereitungen werden nicht als Norm-Heizlast, Verfahren-B-Nachweis, Wärmepumpenauslegung oder Herstellerfreigabe bezeichnet.
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

## Aktueller Stand – Foundation Batch 21–24

### 1. Projekt- und Gebäudeaufnahme
- Persistente lokale Struktur Projekt → Geschoss → Raum → Bauteil.
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

### 4. Heizkörper-Produktdaten – Pass 15/16
- Versioniertes Schema `radiator-product-dataset-v1` mit harter Validierung und transaktionalem Store.
- Technisches Produktmatching gegen explizites Sanierungsziel und optionalen Einbauraum.
- Keine automatische Produktwahl; ausdrückliche Auswahl als `radiator-replacement-selection-v1`.
- VDI-Mappingprofil `vdi-3805-part6-mapped-v1` für autorisiert erzeugte normalisierte Mappings.
- Kein Rohparser geschützter Richtlinienstrukturen.

### 5. Hydraulik
- Explizite Fluiddichte und kinematische Viskosität; keine versteckten Wasser-/Glykolwerte.
- Rohrabschnitte mit Rolle, Innendurchmesser, hydraulischer Länge, Rauheit, ζ-Summe und ggf. Abschnittsvolumenstrom.
- Berechnung von Geschwindigkeit, Reynolds-Zahl, Rohrreibung sowie geradem/lokalem Druckverlust.
- Hydraulische Bauteile getrennt erfassbar: Thermostatventil, Rücklaufverschraubung, Heizfläche, Verteiler/Sammler, Armatur/Sonstiges.
- Vollständiger Kreis-Δp nur bei vollständigem Rohrweg, Bauteilverlusten und expliziter Vollständigkeitsbestätigung.
- Projektaggregation: Verbraucher-Gesamtvolumenstrom + hydraulisch ungünstigster Parallelkreis; parallele Kreisverluste werden nicht addiert.
- Pumpen-Betriebspunkt nur bei vollständiger hydraulischer Abdeckung.

### 6. Ventil-Produktdaten – Pass 17
- `HeizBalanceValveSizingPreparationCalculator` berechnet erforderlichen technischen kv aus Volumenstrom, Ventil-Δp und Dichte.
- `valve-product-dataset-v1` mit diskreten `Voreinstellung → kv`-Punkten.
- Globaler transaktionaler Ventilkatalog.
- Explizite Katalogprodukt-Zuordnung zu Projektventilen mit eingefrorener Provenienz.
- VDI-Mappingprofil `vdi-3805-part2-mapped-v1`.
- Mathematisch nächster Punkt bleibt ausdrücklich keine automatische Hersteller-Voreinstellung.

### 7. Pumpen-Produktdaten – Pass 18
- Versioniertes Katalogschema `pump-product-dataset-v1`.
- Hersteller/Datensatzstand/Quelle/Nutzungsgrundlage/Rechtehinweis werden dokumentiert.
- Produkte mit einer oder mehreren Kennlinien; Kennlinien mit Q/H-Punkten und optional elektrischer Aufnahme P₁.
- Harte Validierung für IDs, doppelte Volumenstrompunkte und ungültige Werte.
- Globaler transaktionaler Pumpendaten-Store und Import-UI.
- VDI-Mappingprofil `vdi-3805-part4-mapped-v1`.
- Kein Rohparser geschützter VDI-Datensatzlayouts.

### 8. Pumpenkennlinie gegen Betriebspunkt – Pass 19
- `HeizBalancePumpCurveOperatingPointCalculator`, Profil `linear-documented-pump-curve-v1`.
- Exakt dokumentierte Q-Punkte unverändert.
- Lineare Interpolation ausschließlich zwischen dokumentierten Punkten.
- Keine Extrapolation unter/über dem dokumentierten Q-Bereich.
- Ergebnis: verfügbare H, erforderliche H, Reserve, ausreichend/nicht ausreichend, optional interpoliertes P₁ und verwendete Begrenzungspunkte.

### 9. Explizite Pumpen-/Kennlinienauswahl – Pass 20
- Versionierter Snapshot `pump-curve-selection-v1`.
- Nur ausdrücklicher Benutzer-Tap; HeizBalance wählt keine Pumpe selbstständig aus.
- Nicht ausreichende oder außerhalb des dokumentierten Bereichs liegende Kennlinien können nicht festgehalten werden.
- Snapshot friert Hersteller, Katalogstand, Quelle/Rechte, Produkt, Kennlinie, alle Kennlinienpunkte, Rechenprofil, damaligen Betriebspunkt, Förderhöhenreserve und ggf. P₁ ein.
- `HeizBalancePumpSelectionStore` hält genau eine aktuelle Auswahl je Projekt und ist Swift-6-konform `@MainActor`-isoliert.
- Auswahl bleibt dokumentierbar, selbst wenn der globale Katalog später geändert/gelöscht wird.
- Änderung des Projekt-Betriebspunkts führt zu `neu zu bewerten`, nicht zu stiller Neuberechnung.

### 10. Projekt-Cockpit – Batch 21
- Neues `HeizBalanceProjectTechnicalStatusView` direkt im Projekteditor.
- Zeigt auf einen Blick Raumdaten, Sanierungsziel, Hydraulikstatus und Pumpenentscheidung.
- Bei vollständiger Hydraulik werden Projekt-Q/H direkt angezeigt.
- Veraltete Pumpenentscheidungen werden deutlich als `neu bewerten` markiert.

### 11. Status direkt in der Projektliste – Batch 21
- Jede Projektzeile zeigt kompakte Statuschips `Räume`, `Hydraulik`, `Pumpe`.
- Grün = technischer Arbeitsschritt aktuell vollständig.
- Orange = festgehaltene Pumpenentscheidung ist wegen geändertem/unvollständigem Betriebspunkt veraltet.
- Statuschips sind ausdrücklich keine normative Freigabe.

### 12. Katalogübergreifender Pumpen-Arbeitsbereich – Batch 22
- Neues `HeizBalancePumpProjectWorkspaceView` als zentrale Projektansicht `Pumpe & Betriebspunkt`.
- Zeigt aktuellen Auslegungs-Volumenstrom und erforderliche Förderhöhe.
- Alle importierten Pumpenkataloge werden in einem direkten Kennlinienvergleich zusammengeführt.
- `HeizBalancePumpCurveComparisonCalculator` klassifiziert jede Kennlinie als technisch ausreichend, Förderhöhe zu gering oder außerhalb dokumentierter Kennlinie.
- Zusammenfassung mit Gesamtzahl, auswertbaren, ausreichenden, zu schwachen und außerhalb liegenden Kennlinien.
- Filter `Alle / Ausreichend / Zu wenig / Außerhalb`.
- Ausreichende Kennlinien werden zur Lesbarkeit zuerst gruppiert; innerhalb der Gruppen nur alphabetisch sortiert. Kein Ranking nach Produktgüte.
- Eine ausreichende Kennlinie kann direkt aus dem Vergleich per ausdrücklichem Tap festgehalten werden.
- Bestehende Detail-/Importansichten bleiben als vertiefende Werkzeuge erreichbar.

### 13. Technische Pumpen-Leistungskennzahlen – Batch 23
- Neuer Core `HeizBalancePumpTechnicalMetricsCalculator`, Profil `pump-technical-metrics-v1`.
- Aus explizitem Q, H und Fluiddichte werden erforderliche hydraulische Leistung, hydraulische Leistung bei verfügbarer Kennlinien-H, H-Reserve m/%, und Q-Bereichsposition berechnet.
- Wenn P₁ dokumentiert ist, zusätzlich `Pₕ,erf/P₁`.
- Ohne dokumentiertes P₁ wird kein Verhältniswert erfunden.
- `Pₕ,erf/P₁` wird ausdrücklich nicht als Pumpenwirkungsgrad/EEI/ErP-Freigabe bezeichnet.
- Core-Regressionsfälle prüfen Berechnung und harte Eingabevalidierung.

### 14. Pumpenbericht/PDF – Batch 24
- Bestehendes Snapshot-Schema `technical-pump-curves-v1` bleibt rückwärtskompatibel und erhält nur optionale neue Kennzahlenfelder.
- Optional eingefroren werden Projektdichte, erforderliche/verfügbare hydraulische Leistung, H-Reserve %, `Pₕ,erf/P₁`, Q-Bereichsposition und Profil `pump-technical-metrics-v1`.
- PDF zeigt diese Werte zusammen mit Katalog-/Quellen-/Kennlinienprovenienz und einer ggf. festgehaltenen Pumpenentscheidung.
- PDF-Hinweis stellt klar: technische Verhältniskennzahl ≠ Effizienz-/ErP-/Herstellerfreigabe.

### 15. Berichte / Reproduzierbarkeit gesamt
Aktive Snapshots:
- `technical-report-v1`
- `technical-low-temperature-v1`
- `technical-temperature-scenarios-v1`
- `technical-radiator-replacements-v1`
- `technical-pump-curves-v1`

Eigenschaften:
- ein Exportzeitpunkt für alle Teil-Snapshots,
- getrennte versionierte JSON-Archive,
- gemeinsames mehrteiliges A4-PDF über PDFKit,
- maximal letzte 10 Exportstände je Projekt/Berichtstyp,
- fehlgeschlagene/abgebrochene Exporte erzeugen keinen falschen Archivstand.

## Technische Regressionen
`docs/HEIZBALANCE_REFERENCE_CASES.md` enthält u. a.:
- technischer kv-Fall 0,6 m³/h bei 12 kPa → kv ≈ 1,73,
- Niedertemperatur-Musterprojekt mit begrenzendem Bad,
- 45/35-Szenario mit bewusstem Heizflächen-Upgradebedarf,
- Pumpenkennlinien-Interpolation mit harter No-Extrapolation-Regel,
- Pumpen-Leistungskennzahlen: 1,5 m³/h, H_erf 3,2 m, H_verfügbar 4,0 m, ρ 998 kg/m³, P₁ 34 W → Pₕ,erf ≈ 13,05 W, H-Reserve 25 %, `Pₕ,erf/P₁` ≈ 38,4 %, Q-Bereichsposition 75 %.

## Release-Härtung
- Entwicklungs-Musterprojekt durch `#if DEBUG` vollständig aus Release entfernt.
- CI baut komplette App-Matrix in Debug.
- HeizBalance besitzt zusätzlich ein echtes Release-Simulator-Build-Gate.
- Export-Compliance und Buildnummer werden geprüft.
- PR-CI nutzt `cancel-in-progress`, sodass Zwischenstände automatisch abgebrochen werden.
- Swift-6-Concurrency-Prüfungen bleiben aktiv; keine unsichere globale Isolation für mutable UI-Persistenz.

## Validierte CI-Checkpoints
- #50–#100: Heizflächen-, Hydraulik-, Ventil-, PDF-, Archiv-, Niedertemperatur- und Release-Grundlagen grün.
- #111: Szenario-/3-PDF-Pfad grün.
- #120: persistentes Sanierungsziel grün.
- #123: Sanierungsziel-Dashboard grün.
- #154: Heizkörper-Herstellerdatenschema, Matching, explizite Ersatzwahl und vierter Reportpfad grün.
- #159: VDI-3805-Blatt-6-Mappingadapter grün.
- #173: Ventilkatalog + Blatt-2-Adapter + Katalog→Projektventil grün.
- #181: Pumpenkatalog + Blatt-4-Adapter + Store/UI + Release grün.
- #192: Pumpenkennlinien-/Betriebspunkt-Core + No-Extrapolation + fünfter Berichtspfad grün.
- #202/#203: explizite Pumpen-/Kennlinienauswahl, Stale-Erkennung, PDF-Auswahlnachweis und Release grün.
- #212: großer Batch-Unterbau mit Pumpen-Cockpit, Kennlinienvergleich, technischen Leistungskennzahlen, Report/PDF und Regressionstests: Core + HeizBalance Debug/Release sowie Matrix grün.
- #213: finaler Code-Head einschließlich Statuschips in der Projektliste: Core-Tests, komplette Debug-iOS-Matrix und HeizBalance Debug/Release grün.

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

## Nächste größere Entwicklungsblöcke
1. Vor-Ort-Aufnahme beschleunigen: Bauteil-/Raumvorlagen, Kopieren von Räumen/Geschossen, wiederverwendbare U-Wert-/Bauteilfavoriten und deutlich weniger Tipparbeit.
2. Hydraulik produktionsnäher machen: Rohrnetz-Erfassung vereinfachen, vollständige Kreise schneller duplizieren, Ventil-/Rücklaufdaten als echte Projektentscheidungen versioniert festhalten.
3. Bericht für reale Baustellen härten: große Projekte, Seitenumbrüche, kompakte Ergebniszusammenfassung, Unterschrift/Techniker/Projektstatus und druckbare Einstelllisten.
4. Erste echte Hersteller-/Lizenzquellen für Heizkörper-, Ventil- und Pumpendaten rechtlich klären und über die Mappingprofile als Referenzdaten validieren.
5. Parallel normative Heizlast-Spezifikation und belastbare Referenzfälle aufbauen; Freigabe erst nach echter fachlicher Validierung.

## Batch-Verifikation
- CI #213 hat den vollständigen Code-Head des Batches mit Core-Tests, kompletter Debug-iOS-Matrix sowie HeizBalance Debug- und echtem Release-Simulator-Build erfolgreich validiert.
- Nachgelagerte reine Dokumentations-Commits ändern keine Rechen- oder App-Logik; der abschließende Dokumentations-Head wird zusätzlich durch dieselbe PR-CI geprüft.
